#Requires -module ActiveDirectory

[CmdLetBinding()]
param (
    [Parameter(Position = 0)]
    [string]$Domain = (Get-ADDomain).DNSroot,
    [Parameter(Position = 1)]
    [ValidateNotNull()]
    [System.Management.Automation.PSCredential][System.Management.Automation.Credential()]
    $Credential = [System.Management.Automation.PSCredential]::Empty,
    [Parameter(Position = 2)]
    [switch]$AllowClobber,
    [Parameter(Position = 3)]
    [string]$Prefix,
    [Parameter(Position = 4)]
    [string]$ExchangeServerMatch
)

# validate that Domain provided exists and is reachable
if ($Domain) {
    try {
        $ADRootDSE = Get-ADRootDSE -Server $Domain -Verbose:$false
    }
    catch {
        if ($Domain -ne 'Office365') {
            Write-Warning -Message "Unable to connect to the domain $Domain"
            return
        }
    }
}

# check if there is a current session
$CurrentExchangeSessions = (Get-PSSession).Where({$_.ConfigurationName -eq "Microsoft.Exchange"})
if ($CurrentExchangeSessions) {
    Write-Verbose -Message "Found existing Exchange sessions"
    Write-Verbose -Message ($CurrentExchangeSessions | Out-String)
    if ($null -eq $Prefix -or $Prefix.Length -ne 3) {
        [string]$Prefix = Read-Host -Prompt "Please provide a three (3) character prefix for all imported commands"
    }
}

if ($Domain -eq "Office365") {
    if ($Credential -eq [System.Management.Automation.PSCredential]::Empty) {
        $Credential = Get-Credential -Message "Please provide administrative credentials for Office 365 (userPrincipalName)"
    }
    Write-Verbose -Message "Attempting to create new session for $Domain"
    try {
        $ExchangeSession = New-PSSession -Name $Domain -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $Credential -Authentication Basic -AllowRedirection -ErrorAction Stop
    }
    catch {
        Write-Output -Message "Unable to establish a new session to $Domain."
        Write-Error $Error[0].Exception.Message
    }

} else {

    $NewSessionSplat = @{}
    if ($Credential -ne [System.Management.Automation.PSCredential]::Empty) {
        $NewSessionSplat['Credential'] = $Credential
        $UsedCredential = "using provided credentials."
    } else {
        $UsedCredential = "using current credentials."
    }

    Write-Verbose -Message "Querying $Domain for Exchange Servers"
    $ExchangeServers = foreach ($Server in (Get-ADObject -Server $Domain -SearchBase $ADRootDSE.configurationNamingContext -Filter "objectClass -eq 'msExchExchangeServer'" -Verbose:$false) ) {
        try {
            Get-ADComputer -Identity $Server.Name -Server $Domain -Verbose:$false | Select-Object -ExpandProperty DNSHostName
        }
        catch { }
    }
    Write-Verbose -Message "Found $($ExchangeServers.count) Exchange Servers."

    if ($ExchangeServerMatch) {}
        $FilterExchangeServers = $ExchangeServers.Where({$_ -match $ExchangeServerMatch})
        Write-Verbose -Message "Found $($FilterExchangeServers.count) Exchange Servers with names matching $ExchangeServerMatch."
    } else {
        $FilterExchangeServers = $ExchangeServers
    }

    foreach ($ExchangeServer in $FilterExchangeServers) {
        Write-Verbose -Message "Attempting to create new session to $ExchangeServer in $domain Exchange environment $UsedCredential"
        try {
            $ExchangeSession = New-PSSession -Name $Domain -ConfigurationName Microsoft.Exchange -ConnectionUri "http://$ExchangeServer/PowerShell/" -Authentication Kerberos -AllowRedirection @NewSessionSplat -Verbose:$false -ErrorAction Stop
            if ($ExchangeSession.State -eq "Opened") {
                    Write-Verbose -Message "Successfully created session on $ExchangeServer"
                break
            }
        }
        catch {
            if ($_.FullyQualifiedErrorId -match "AccessDenied") {
                Write-Warning -Message "Access is denied."
                $Credential = Get-Credential -Message "Please provide administrative credentials for $Domain Exchange environment."
                $UsedCredential = "using provided credentials."
                try {
                    $ExchangeSession = New-PSSession -Name $Domain -ConfigurationName Microsoft.Exchange -ConnectionUri "http://$ExchangeServer/PowerShell/" -Authentication Kerberos -AllowRedirection -Credential $Credential -Verbose:$false -ErrorAction Stop
                    if ($ExchangeSession.State -eq "Opened") {
                        Write-Verbose -Message "Successfully created session on $ExchangeServer"
                        break
                    }
                }
                catch {
                    Write-Warning -Message "$ExchangeServer in $Domain does not recognize the user $UsedCredential"
                    break
                }
            } else {
                Write-Warning -Message "$ExchangeServer in $Domain is not responding."
                break
            }
        }
    }
}

if ($ExchangeSession) {

    $ImportSessionSplat = @{}

    if ($AllowClobber) {
        $ImportSessionSplat['AllowClobber'] = $true
    }

    if ($Prefix) {
        $ImportSessionSplat['Prefix'] = $Prefix
        Write-Verbose -Message "Using $Prefix as imported command prefix."
        Write-Verbose -Message "The prefix will be just before the Noun in Verb-Noun, e.g. Get-AHMMailbox."
    }

    Write-Verbose -Message "Importing session $($ExchangeSession.Name)"

    $OriginalVerbosePreference = $VerbosePreference
    $OriginalWarningPreference = $WarningPreference
    $VerbosePreference = $WarningPreference = "SilentlyContinue"

    try {
        Import-PSSession -Session $ExchangeSession @ImportSessionSplat | Out-Null
        Write-Output "NOTE: Exchange PowerShell commands for $Domain Exchange environment are ready for use."
        if ($Prefix) {
            Write-Output "NOTE: Remember that all Exchange PowerShell commands will have $Prefix before the Noun in Verb-Noun."
        }
    }
    catch {
        Write-Error -Message $Error[0].Exception.Message
    }
    $VerbosePreference = $OriginalVerbosePreference
    $WarningPreference = $OriginalWarningPreference

} else {
    Write-Warning -Message "No remote PowerShell session to import."
    exit
}
function Invoke-ADReplication {
    [Alias("adrep")]
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0)]
        [string]$Domain,        
        [Parameter(Position = 1)]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential][System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,
        [Parameter(ParameterSetName='Wait',Position = 2)]
        [switch]$Wait,
        [Parameter(ParameterSetName='Wait',Position = 3)]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1,30)]
        [int]$WaitTime=5,
        [Parameter(ParameterSetName='Wait',Position = 3)]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1,600)]
        [int]$Timeout=120

    )    

    begin {

        $credSplat = @{}
        if ($Credential -ne [System.Management.Automation.PSCredential]::Empty) {
            $credSplat['Credential'] = $Credential
            $UsedCredential = "provided credentials"
        }
        else {
            $UsedCredential = "current credentials"
        }
        
        if (!$Domain) {            
            $Domain = Get-ADDomain | Select-Object -ExpandProperty DNSRoot
            Write-Verbose -Message "No domain provided, defaulting to $Domain"
        }

        Write-Verbose -Message "Discovering domain controllers in $Domain"
        $ADServer = Get-ADDomainController -DomainName $Domain -Discover -Service PrimaryDC -ErrorAction SilentlyContinue | Select-Object -ExpandProperty HostName
        if ($ADServer) {
            Write-Verbose -Message "Found PrimaryDC server ($ADServer) for $Domain"
        } else {
            Write-Verbose -Message "PrimaryDC not discovered, defaulting to any global catalog"
            try {
                $ADServer = Get-ADDomainController -DomainName $Domain -Discover -Service GlobalCatalog -ErrorAction Stop | Select-Object -ExpandProperty HostName            
                Write-Verbose -Message "Found GlobalCatalog server ($ADServer) for $Domain"
            } 
            catch {
                $PSCmdlet.ThrowTerminatingError($PSitem)
            }
        }

        Write-Verbose -Message "Querying Active Directory for domain controller list using $UsedCredential"
        try {
            $DomainControllers = Get-ADDomainController -Server $ADServer -Filter * -ErrorAction Stop @credSplat | Select-Object Name,HostName,IPv4Address,IsGlobalCatalog,IsReadOnly | Sort-Object -Property HostName
            Write-Verbose -Message "Found $($DomainControllers.Count) domain controllers"
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }
    }
    
    process {
        Write-Output ''
        Write-Output "Starting AD replication jobs on $($DomainControllers.Count) domain controllers using $UsedCredential"
        
        # test creds
        $DomainControllers | ForEach-Object {
            $JobName = 'ADREP_' + $_.HostName
            if ($_.IsReadOnly) {
                Invoke-Command -ComputerName $_.HostName -ScriptBlock { repadmin /syncall /Aed } -AsJob -JobName $JobName @credSplat | Out-Null
            } else {
                Invoke-Command -ComputerName $_.HostName -ScriptBlock { repadmin /syncall /APed } -AsJob -JobName $JobName @credSplat | Out-Null
            }                
        }

        if ($PSCmdlet.ParameterSetName -eq 'Wait') {
            Write-Output "Waiting up to $Timeout seconds for replication jobs to complete"
            Write-Output ''
            $Timer = [System.Diagnostics.Stopwatch]::StartNew()
            while ( (Get-Job -Name ADREP_* | Where-Object {$_.State -eq "Running"}) -And ($Timer.Elapsed.Seconds -le $Timeout ) ) { 
                $RemainingJobs = Get-Job -Name ADREP_* | Where-Object {$_.State -eq "Running"} | Measure-Object | Select-Object -ExpandProperty Count
                Write-Output "$RemainingJobs replication jobs remain, waiting $WaitTime seconds..."                
                Start-Sleep $WaitTime
            }
            Write-Output ''
            $Jobs = Get-Job -Name ADREP_*
            $TotalJobCount = $Jobs.Count         
            $UnfinishedCount = $Jobs.Where({$_.State -eq 'Running'}).Count
            if ($UnfinishedCount -gt 0) {
                Write-Output "$UnfinishedCount replication jobs did not finish within $Timeout seconds"
            } 
            Write-Output "$TotalJobCount replication jobs completed in $($Timer.Elapsed.Seconds) seconds"
            $Timer.Stop | Out-Null
            $JobState = $Jobs | Group-Object -Property State | Sort-Object -Property Count -Descending | Select-Object -Property @{l='JobCount';e={$_.Count}},@{l='JobState';e={$_.Name}}
            
            Write-Verbose -Message 'Removing all replication jobs'
            Write-Output $JobState                     
            $Jobs | Remove-Job
            
        } else {
            Write-Output 'AD replication jobs have been started'
            Write-Output ''
            Write-Output 'The jobs will remain in this session unless you close the session or manually purge them using:'
            Write-Output '  Get-Job -Name ADREP* | Remove-Job'

        }

    }

    end {
        Write-Output ''
    }

}

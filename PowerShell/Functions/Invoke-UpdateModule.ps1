function Invoke-UpdateModule {
    [CmdLetBinding()]
    param(
        [string[]]$Name,
        [PSCredential]$Credential,
        [Version]$MaximumVersion,
        [Version]$RequiredVersion,
        [Uri]$Proxy,
        [PSCredential]$ProxyCredential,
        [switch]$Force
    )

    begin {

        function ConvertFrom-UpdateModuleVerbose {
            param($Output)
            $UpdateAction = $Output | Select-String -Pattern '^Checking|^Skipping|^Performing|installed successfully'
            $UpdateObject = foreach ($Action in $UpdateAction) {
                if ($Action -match 'Checking') {
                    $Action -match "(?:^|\S|\s)'(\S+)'(?:\S|\s|$)" | Out-Null
                    [PSCustomObject]@{
                        Name = $Matches[1]
                        CurrentVersion = $null
                        UpdatedVersion = $null
                        InstallState = $null
                    }
                }
            }
            foreach ($Module in $UpdateObject) {
                $ModuleInfo = $UpdateAction.Where({$_ -match $Module.Name -And $_ -notmatch 'Checking'})
                if ($ModuleInfo[0] -match 'Skipping') {
                    $ModuleInfo[0] -match "(?:^|\S|\s)(\d+.*)(?:.$|\S|\s|$)" | Out-Null
                    $Module.CurrentVersion = $Matches[1] -Replace ("$($Module.Name)|\s|.$",'')
                    $Module.InstallState = 'Skipped'
                } elseif ($ModuleInfo[0] -match 'Performing') {
                    $UpdateInfo = $ModuleInfo[0]| Select-String -Pattern "(?:^|\S|\s)'(\S+)'(?:\S|\s|$)" -AllMatches
                    $Module.CurrentVersion = $UpdateInfo.Matches[0].Groups[1].Value
                    $Module.UpdatedVersion = $UpdateInfo.Matches[2].Groups[1].Value
                    if ($ModuleInfo[1] -match 'installed successfully') {
                        $Module.InstallState = 'Installed'
                    } else {
                        $Module.InstallState = 'Failed'
                    }
                }
                $Module
            }

        }

        [void]$PSBoundParameters.Remove('Verbose')

        if ($PSBoundParameters.Name) {
            $Modules = $PSBoundParameters.Name
            [void]$PSBoundParameters.Remove('Name')
        }

        Write-Verbose -Message 'Beginning Update-Module'
    }

    process {

        if ($PSBoundParameters) {
            if ($Modules) {
                $UpdateModules = @()
                foreach ($ModuleName in $Modules) {
                    try {
                        $UpdateModules += Update-Module -Name $ModuleName @PSBoundParameters -ErrorAction Stop -Verbose 4>&1
                    }
                    catch {
                        Write-Warning -Message $_.ToString()
                    }
                }
            } else {
                try {
                    $UpdateModules = Update-Module @PSBoundParameters -ErrorAction Stop -Verbose 4>&1
                }
                catch {
                    Write-Warning -Message $_.ToString()
                }
            }
        } else {
            try {
                $UpdateModules = Update-Module -Verbose 4>&1
            }
            catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }

        ConvertFrom-UpdateModuleVerbose -Output $UpdateModules
    }
}
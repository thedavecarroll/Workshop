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
                #$UpdateModules = @()
                foreach ($ModuleName in $Modules) {
                    try {
                        $UpdateModule = Update-Module -Name $ModuleName @PSBoundParameters -ErrorAction Stop -Verbose 4>&1
                        ConvertFrom-UpdateModuleVerbose -Output $UpdateModule
                    }
                    catch {
                        Write-Warning -Message $_.ToString()
                    }
                }
            } else {
                try {
                    $AllModules = Get-Module -All
                    foreach ($ModuleName in $AllModules.Name) {
                        $UpdateModule = Update-Module @PSBoundParameters -ErrorAction Stop -Verbose 4>&1
                        ConvertFrom-UpdateModuleVerbose -Output $UpdateModule
                    }
                }
                catch {
                    Write-Warning -Message $_.ToString()
                }
            }
        } else {
            try {
                $AllModules = Get-InstalledModule
                foreach ($ModuleName in $AllModules.Name) {
                    ConvertFrom-UpdateModuleVerbose -Output ( Update-Module -Name $ModuleName -Verbose 4>&1 )
                }
            }
            catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }

        ConvertFrom-UpdateModuleVerbose -Output $UpdateModules
    }
}
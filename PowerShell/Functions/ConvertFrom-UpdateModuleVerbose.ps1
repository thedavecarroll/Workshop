function ConvertFrom-UpdateModuleVerbose {
    [CmdLetBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [Object[]]$Output
    )

        $UpdateAction = $Output | Select-String -Pattern '^Checking|^Skipping|^Performing|installed successfully'
        $UpdateAction
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
            try {
                $Module.CurrentVersion = $UpdateInfo.Matches[0].Groups[1].Value
            }
            catch {
                $Module.CurrentVersion = 'Error'
            }
            try {
                $Module.UpdatedVersion = $UpdateInfo.Matches[2].Groups[1].Value
            }
            catch {
                $Module.UpdatedVersion = 'Error'
            }
            if ($ModuleInfo[1] -match 'installed successfully') {
                $Module.InstallState = 'Installed'
            } else {
                $Module.InstallState = 'Failed'
            }
        }
        $Module
    }

}
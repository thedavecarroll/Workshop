# script to update all PowerShell help, scripts, modules, functions
$Separator = "*" * 200

Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

$MaxLogSize = 50MB
$UpdateTranscript = 'C:\ITOps\Logs\UpdatePowerShellResources.log'
$AppendMaxLog = Get-Date -Format 'yyyyMMdd_HHmmss'
$LogSize = Get-ChildItem -Path $UpdateTranscript -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Length
if ($LogSize -ge $MaxLogSize) {
    $RenameLog = $UpdateTranscript + '.' + $AppendMaxLog
    Rename-Item -Path $UpdateTranscript -NewName $RenameLog
    Start-Transcript -Path $UpdateTranscript
    Write-Output $Separator
    Write-Output "Log file $UpdateTranscript reached maximum size of $MaxLogSize bytes."
    Write-Output "Log file was renamed to $RenameLog."
    Write-Output $Separator
} else {
    Start-Transcript -Path $UpdateTranscript -Append
}

# help
Write-Output $Separator
Write-Output "Updating PowerShell Help"
Write-Output $Separator
$UpdateHelp = Update-Help -Verbose -ErrorAction SilentlyContinue 4>&1
Write-Output ($UpdateHelp | Select-String -Pattern '^Performing|^Skipping|already installed')

# scripts
Write-Output $Separator
Write-Output "Updating Scripts"
Write-Output $Separator
$UpdateScripts = Update-Script -Verbose -ErrorAction SilentlyContinue 4>&1
Write-Output ($UpdateScripts | Select-String -Pattern '^Checking|^Skipping|^Performing|installed successfully')

# modules
Write-Output $Separator
Write-Output "Updating Modules"
Write-Output $Separator
$UpdateModules = Update-Module -Verbose -ErrorAction SilentlyContinue 4>&1
$UpdateAction = $UpdateModules | Select-String -Pattern '^Checking|^Skipping|^Performing|installed successfully'
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
        $Module.CurrentVersion = $Matches[1] -Replace ('.$','')
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
}
Write-Output ($UpdateObject | Format-Table -AutoSize | Out-String)

Stop-Transcript
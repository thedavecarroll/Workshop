$Settings = New-ScheduledTaskSettingsSet -Hidden -Compatibility Win8 -StartWhenAvailable
$Trigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek Wednesday -At 2am
$Action = New-ScheduledTaskAction `
    -Execute 'Powershell.exe' `
    -Argument '-WindowStyle Hidden -File D:\Scripts\UpdatePowerShellResources.ps1'

Register-ScheduledTask -Action $Action -Trigger $Trigger -TaskName "UpdatePowerShellResources" -Description "Update PowerShell modules, scripts, and Chocolatey packages" -User "NT AUTHORITY\SYSTEM" -RunLevel Highest -Settings $Settings
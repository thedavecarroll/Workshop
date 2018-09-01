Update-Module -Verbose
Set-ExecutionPolicy -ExecutionPolicy Unrestricted
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-Script -Name Install-VSCode,Install-Git

Install-Git.ps1
Install-VSCode.ps1 -AdditionalExtensions shan.code-settings-sync -LaunchWhenDone
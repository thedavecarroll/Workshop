
$ScriptsToInstall = 'Install-VSCode','Install-Git'
$ModulesToInstall = 'PoShEvents','PoShGroupPolicy','ImportExcel','Plaster','PSake'

Update-Module -Verbose
Set-ExecutionPolicy -ExecutionPolicy Unrestricted
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

Install-Script -Name $ScriptsToInstall
Install-Module -Name $ModulesToInstall

Install-Git.ps1
Install-VSCode.ps1 -AdditionalExtensions shan.code-settings-sync -LaunchWhenDone
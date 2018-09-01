# -----------------------------------------------------------------------------
# Set location, default module location, and import base functions
# -----------------------------------------------------------------------------
# set base location
Set-Location D:\Development\PowerShell\Temp

# import base functions
$FunctionPath = "D:\Development\PowerShell\Functions"
Get-ChildItem $FunctionPath -Recurse -File | Where-Object { $_.Name -like '*.ps1' -And $_.Name -notlike "__*" } | ForEach-Object { . $_.FullName }

# extend Module Path for Local Repository
$ModulePath = "D:\Development\PowerShell\Modules"
$machinePath = [Environment]::GetEnvironmentVariable('PSModulePath', [System.EnvironmentVariableTarget]::Machine)
if($machinePath.Contains($ModulePath) -eq $false) {
	$machinePath += ";$ModulePath"
    [Environment]::SetEnvironmentVariable('PSModulePath', $machinePath, [System.EnvironmentVariableTarget]::Machine)
    $env:PSModulePath += ";$ModulePath"
}

# -----------------------------------------------------------------------------
# Customize the console window
# -----------------------------------------------------------------------------
$Console = (Get-Host).UI.RawUI

# http://blog.dabasinskas.net/customizing-windows-powershell-command-prompt/
[System.Security.Principal.WindowsPrincipal]$global:currentUser = New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())
if($global:currentUser.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
  $DisplayUser = $global:currentUser.Identities.Name + " (Administrator)"
} else {
  $DisplayUser = $global:currentUser.Identities.Name
}
$Console.WindowTitle =  $DisplayUser
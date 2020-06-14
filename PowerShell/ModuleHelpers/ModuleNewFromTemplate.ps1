[CmdLetBinding()]
param (
    [Parameter(Mandatory=$true)]
    $ModulePath,
    [Parameter(Mandatory=$true)]
    $ModuleName,
    [Parameter(Mandatory=$true)]
    $Author,
    [Parameter(Mandatory=$true)]
    $CompanyName,
    [Parameter(Mandatory=$true)]
    $Description,
    [Parameter(Mandatory=$true)]
    $PowerShellVersion=5.0

)

$ModuleVersion = '0.0.1'
$GUID = [Guid]::NewGuid().Guid
$Copyright = "(c) $((Get-Date).Year) $Author. All rights reserved."

$FullModulePath = Join-Path $ModulePath $ModuleName
New-Item -Path $FullModulePath -ItemType Directory | Out-Null

$ModuleFolders = 'en-US','Private','Public','TypeData','Scripts','Tests'
foreach ($Folder in $ModuleFolders) {
    New-Item -Path (Join-Path $FullModulePath $Folder) -ItemType Directory | Out-Null
    New-Item -Path (Join-Path $FullModulePath "$Folder\.gitignore") -ItemType File | Out-Null
}

$ModuleManifestFileName = Join-Path $FullModulePath ($ModuleName + ".psd1")

$RootModuleName = $ModuleName + ".psm1"

$AboutFileName = Join-Path $FullModulePath ("en-US\about_" + $ModuleName + ".help.txt")
New-Item -Path $AboutFileName -ItemType File | Out-Null

$FormatFileName = Join-Path $FullModulePath ($ModuleName + ".Format.ps1xml")
New-Item -Path $FormatFileName -ItemType File | Out-Null

$PsmFileContent = @'
#Get public and private function definition files.
$Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

#Dot source the files
foreach ( $import in @($Public + $Private) ) {
    try {
        write-output $import.fullname
        . $import.fullname
    }
    Catch  {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

Export-ModuleMember -Function $Public.Basename
'@

New-ModuleManifest -Path $ModuleManifestFileName `
    -Author $Author `
    -Guid $GUID `
    -CompanyName $CompanyName `
    -RootModule $RootModuleName `
    -Description $Description `
    -PowerShellVersion $PowerShellVersion `
    -ModuleVersion $ModuleVersion `
    -Copyright $Copyright

$RootModulePath = (Join-Path $FullModulePath $RootModuleName)
$RootModulePath
New-Item -Path $RootModulePath -ItemType File -Force | Out-Null
Set-Content -Path $RootModulePath -Value $PsmFileContent -Force
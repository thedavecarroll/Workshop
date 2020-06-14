# How to Use this Plaster Template

## From Kevin Marquette

* Pre-Validate
  * Before publishing into repository, use `Test-ModuleManifest` to pre-validate.
  * `Test-ModuleManifest -Path $ModulePath -Verbose`
* Verify Module can be Imported
  * `Remove-Module -Name $Name -Force -ErrorAction Ignore`
  * `Import-Module -Name $Name -Force`
* Publish the folder, not the psd1
* Verified module actually published

```powershell
$Manifest = Invoke-Expression (Get-Content $PSD1 -Raw)
$Find = @{
    Name = $ModuleName
    Repository = $Repository
    RequiredVersion = $Manifest.ModuleVersion
}
try {
    Find-Module @Find -ErrorAction Stop
}
catch {
    Write-Error -Message 'New version of the module did not publish'
}
```

* Verify NuGet API is not blank

```powershell
if ([string]:IsNullOrEmpty($env:NugetApiKey)) {
    Write-Error -Message '[NugetApiKey] is not defined'
}
```
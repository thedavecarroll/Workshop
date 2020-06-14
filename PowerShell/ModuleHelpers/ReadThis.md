# Documentation HowTo

There will be 2 folders in the project root:

* docs - used to create the ReadTheDocs site
* UpdateHelp - used to store the updatable help files - cab, xml, zip - that will later be put on blog site.

The docs folder will contain a copy of the project's README.md and CHANGELOG.md files.

After writing the functions for a new module, here is how to manage the documentation.

## Create Help for a New Module

## Bit.ly Link for Usage Tracking

Create bit.ly link for updatable help - hosted on blog
Backside link - ModuleNameHelp
Name - ModuleName Updatable Help
Link - https://powershell.anovelidea.org/modulehelp

Create Read the Docs project

1. Login with GitHub
2. Import Project
3. Edit Advanced Project Options

Description - same as module
Documentation Type - Mkdocs (Markdown)
Programming Language - Only Words
Tags - same as PowerShellGallery

Domains - add new domain
modulename.anovelidea.org (all lowercase)
Canonical - checked
HTTPS - checked
Save

Advanced Settings
Stable (once available)
Show version warning

Google Analytics - add new property and get analytics code
Google Domains - add new CNAME

Create GitHubProject/docs
Create GitHubProject/mkdocs.yml
Create GitHubProject/docs/requirements.txt (mkdoc-material)

```powershell
New-MyMarkdownHelp -ModuleName PoShEvents -OutputFolder docs
New-MarkdownAboutHelp -OutputFolder .\docs\ -AboutName about_PoShEvents
Update-MkDocYaml -ModuleName PoShEvents -MkDocYaml .\mkdocs.yml
Copy-ModuleMarkdownDocs -ProjectPath . -DocPath .\docs\
New-ExternalHelp -Path .\docs\*-*.md -OutputPath .\PoShEvents\en-US\ -ShowProgress -Force
New-ExternalHelpCab -CabFilesFolder .\PoShEvents\PoShEvents\en-US\ -LandingPagePath .\PoShEvents\docs\PoShEvents.md -OutputFolder D:\GitHub\PoShEvents\UpdateHelp
# build module
```

## Update Help for an Existing Module

```powershell

# update CHANGELOG
$ProjectPath = 'D:\GitHub\PoShEvents'
$ProjectOwner = 'thedavecarroll'
$ChangeLogPath = Join-Path -Path $ProjectPath -ChildPath 'CHANGELOG.md'

$AddChangeLog = Add-ChangeLog -ProjectPath $ProjectPath -ReleaseType Feature,Bugfix,Maintenance -UpdateRequired 'Strongly Recommended' -ProjectOwner $ProjectOwner -TargetRelease 0.4.1 -TargetReleaseDate '2020-01-19'

# update module manifest
$UpdateReleaseNotes = New-ReleaseChangeLog -
Update-MyModuleManifest -

# update markdown help
Update-MarkdownHelp -Path $PathToDocs -Force

# create new external help
New-ExternalHelp -Path .\docs\*-*.md -OutputPath .\PoShEvents\en-US\ -ShowProgress -Force

# create new updatable help
New-ExternalHelpCab -CabFilesFolder .\PoShEvents\PoShEvents\en-US\ -LandingPagePath .\PoShEvents\docs\PoShEvents.md -OutputFolder D:\GitHub\PoShEvents\UpdateHelp

# copy to blog and build


# update mkdocs.yml with functions and cmdlets
Update-MkDocYaml -ModuleName PoShEvents -MkDocYaml .\mkdocs.yml

# copy readme and changelog
Copy-ModuleMarkdownDocs -ProjectPath . -DocPath .\docs\

# build release
.\build.ps1 -Task Compile

# test publish to docker nuget

# publish to psgallery

# zip output folder
Compress-Archive -Path 'D:\GitHub\PoShEvents\BuildOutput\PoShEvents\0.4.1\*' -DestinationPath 'D:\GitHub\PoShEvents\BuildOutput\PoShEvents.zip'

# update changelog (both) with direct link of last commit

# draft new release in GitHub
<#
Tag Version - v.0.4.0
Release Title - v.0.4.0 - 2020-01-07
## Bugfix and Feature Release, Update Strongly Recommended

### Added

* [Issue #23](https://github.com/thedavecarroll/PoShEvents/issues/23) - `Get-ServiceEvent` - add switch for EventType
* [Issue #33](https://github.com/thedavecarroll/PoShEvents/issues/33) - `Import-KmsProductSku` - new private function

### Fixed

* [Issue #25](https://github.com/thedavecarroll/PoShEvents/issues/25) - `New-EventFilterXml` does not produce a valid xml filter under certain circumstances
* [Issue #26](https://github.com/thedavecarroll/PoShEvents/issues/26) - `Get-KmsProductSku` - Import-Csv : Could not find file 'C:\KmsProductSku.csv'
* [Issue #27](https://github.com/thedavecarroll/PoShEvents/issues/27) - `Get-RemoteLogonEvent` - Error 'ParameterSetName' is a ReadOnly property
* [Issue #34](https://github.com/thedavecarroll/PoShEvents/issues/34) - `New-EventDataFilter` - data of array uses "and" instead of "or"

### Changed

* [Issue #24](https://github.com/thedavecarroll/PoShEvents/issues/24) - Updatable Help - Convert Module HelpInfoUri to Bit.ly Link
* [Issue #28](https://github.com/thedavecarroll/PoShEvents/issues/28) - `Get-OSVersionFromEvent` - Should only return the latest event
* [Issue #29](https://github.com/thedavecarroll/PoShEvents/issues/29) - `Get-OSVersionFromEvent` - add All switch to return all events
* [Issue #31](https://github.com/thedavecarroll/PoShEvents/issues/31) - `ConvertFrom-EventLogRecord` - for KMS events, import CSV in begin{} block
* [Issue #32](https://github.com/thedavecarroll/PoShEvents/issues/32) - `Get-KmsProductSku` - remove import CSV code
* [Issue #35](https://github.com/thedavecarroll/PoShEvents/issues/35) - `New-EventFilterXml` - replace LogLevelName with enum

Upload zip
Select pre-release

Target same commit as above
#>

```

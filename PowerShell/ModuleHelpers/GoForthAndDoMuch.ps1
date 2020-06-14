[CmdLetBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({Test-Path -Path $_})]
    [string]$ProjectPath,
    [Parameter(Mandatory)]
    [ValidateSet('Feature','Bugfix','Security','Maintenance')]
    [string[]]$ReleaseType,
    [Parameter(Mandatory)]
    [ValidateSet('No','Recommended','Strongly Recommended')]
    [string]$UpdateRequired,
    [Parameter(Mandatory)]
    [string]$GitHubOwner,
    [Parameter(Mandatory)]
    [version]$TargetRelease,
    [ValidateScript({$_ -match '^\d{4}\-(0[1-9]|1[012])\-(0[1-9]|[12][0-9]|3[01])$|Unreleased'})]
    [string]$TargetReleaseDate='Unreleased',
    [string]$ChangeLog = 'CHANGELOG.md',
    [Parameter(Mandatory)]
    [uri]$ChangeLogUri,
    [uri]$ReleaseLink,
    [string]$DocPath = 'docs',
    [string]$HelpPath = 'en-US',
    [string]$UpdateHelpPath = 'UpdateHelp'
)

Import-Module D:\GitHub\Workshop\PowerShell\ModuleHelpers\ModuleHelp.psm1 -Force


$ProjectPath = 'D:\GitHub\PoShEvents'
$ProjectOwner = 'thedavecarroll'
$Project = Split-Path -Path $ProjectPath -Leaf
$ModulePath = Join-Path -Path $ProjectPath -ChildPath $Project
$DocLocation = Join-Path -Path $ProjectPath -ChildPath 'docs'
$ExternalHelpPath = Join-Path -Path $ModulePath -ChildPath 'en-US'
$UpdatableHelpPath = Join-Path -Path $ProjectPath -ChildPath 'UpdateHelp'
$ChangeLogPath = Join-Path -Path $ProjectPath -Child 'CHANGELOG.md'


$TargetReleaseDate = '2020-01-25'
[version]$TargetRelease = '0.4.1'
$ReleaseType = 'Feature','Bugfix','Maintenance'
$UpdateRequired = 'Strongly Recommended'

$ChangeLogUri = 'https://{0}.anovelidea.org/en/latest/CHANGELOG/' -f $Project.ToLower()

$ChangeLogUpdateParam = @{
    ProjectPath = $ProjectPath
    ReleaseType = $ReleaseType
    UpdateRequired = $UpdateRequired
    ProjectOwner = $ProjectOwner
    TargetRelease = $TargetRelease
    TargetReleaseDate = $TargetReleaseDate
    ReleaseLink = $ReleaseLink
}
$ChangeLogUpdate = Get-ChangeLogUpdate @ChangeLogUpdateParam

Set-ChangeLog -ChangeLogPath $ChangeLogPath -ChangeLogUpdate $ChangeLogUpdate

$ReleaseNotes = Get-ReleaseNotes -ChangeLogPath $ChangeLogPath -ChangeLogUri $ChangeLogUri

Update-MyModuleManifest -ProjectPath $ModulePath -ReleaseNotes $ReleaseNotes

Update-MarkdownHelp -Path $DocLocation -Force

New-ExternalHelp -Path "$DocLocation\*-*.md" -OutputPath $ExternalHelpPath -ShowProgress -Force

New-ExternalHelpCab -CabFilesFolder $ExternalHelpPath -LandingPagePath "$DocLocation\$Project.md" -OutputFolder $UpdatableHelpPath

# Update help version in XML?

Copy-ModuleMarkdownDocs -ProjectPath $ProjectPath -DocPath $DocLocation

# test publish to local nuget
# docker start nuget-server

# create draft release

# get
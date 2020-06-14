#Requires -Module Configuration

[CmdLetBinding()]
param(
    [ValidateScript({Test-Path $_})]
    [string]$ModulePath,
    [string]$ChangeLogName = 'CHANGELOG.md',
    [string]$GitHubPath = 'https://github.com/thedavecarroll/{0}/blob/master/{1}'
)

Import-Module -Name Configuration -Verbose:$false | Out-Null

function Update-PSDataFile {
    [CmdLetBinding()]
    param(
        [string]$Path,
        [string]$Property,
        [object[]]$Value
    )
    try {
        $SetProperty = @{
            $Property = $Value
        }
        Update-ModuleManifest -Path $Path @SetProperty -Verbose:$false
        return
    }
    catch {
        try {
            Update-Metadata -Path $Path -PropertyName $Property -Value $Value -Verbose:$false
            (Get-Content -Path $Path -Raw).Trim() | Set-Content -Path $Path
        }
        catch {
            'Failed to update property {0} in data file {1}' -f $Property,$Path | Write-Warning
        }
    }
}

$ModuleLocation = Resolve-Path -Path $ModulePath
$ModuleName = Split-Path $ModuleLocation.Path -Leaf
if ($ModuleLocation.Path -match '\\$') {
    $ReplacePath = $ModuleLocation.Path
} else {
    $ReplacePath = $ModuleLocation.Path + [System.IO.Path]::DirectorySeparatorChar
}
$ProjectPath = Split-Path -Path $ModuleLocation.Path

$ReleaseNotesFile = Join-Path -Path $ProjectPath -ChildPath $ChangeLogName
$AppendToReleaseNotes = "For full CHANGELOG, see $GitHubPath" -f $ModuleName,$ChangeLogName

$PsDataFile = Join-Path -Path $ModuleLocation.Path -ChildPath "$ModuleName.psd1"
$ModuleManifest = Test-ModuleManifest -Path $PsDataFile -ErrorAction SilentlyContinue -Verbose:$false
 if (!$ModuleManifest) {
    '{0} not found' -f $PsDataFile | Write-Warning
    return
}

$Files = Get-ChildItem -Path $ModuleLocation.Path -Recurse -Exclude '.gitignore' -File
$FileList = $Files.FullName | ForEach-Object {
    $_.Replace($ReplacePath,'')
}
if ($FileList) {
    'FileList' | Write-Verbose
    if ($FileList -ne $ModuleManifest.FileList) {
        '... updating' | Write-Verbose
        Update-ModuleManifest -Path $ModuleManifest.Path -FileList $FileList
        #Update-PSDataFile -Path $ModuleManifest.Path -Property FileList -Value $FileList
    } else {
        '... no change' | Write-Verbose
    }
}

$PublicFunctionPath = Join-Path -Path $ModuleLocation.Path -ChildPath 'Public'
$FunctionsToExport =  (Get-ChildItem -Path $PublicFunctionPath -Recurse -File | ForEach-Object { $_.BaseName })
if ($FunctionsToExport) {
    'FunctionsToExport' | Write-Verbose
    if ($FunctionsToExport -ne $ModuleManifest.FunctionsToExport) {
        '... updating' | Write-Verbose
        Update-ModuleManifest -Path $ModuleManifest.Path -FunctionsToExport $FunctionsToExport
        #Update-PSDataFile -Path $ModuleManifest.Path -Property FunctionsToExport -Value $FunctionsToExport
    } else {
        '... no change' | Write-Verbose
    }
}

$Formats = Join-Path -Path $ModuleLocation.Path -ChildPath 'TypeData' | Join-Path -ChildPath "$ModuleName.Format.ps1xml"
if (Test-Path -Path $Formats) {
    $FormatsToProcess = $Formats.Replace($ReplacePath,'')
}
if ($FormatsToProcess) {
    'FormatsToProcess' | Write-Verbose
    if ($FormatsToProcess -ne $ModuleManifest.FormatsToProcess) {
        '... updating' | Write-Verbose
        Update-ModuleManifest -Path $ModuleManifest.Path -FormatsToProcess $FormatsToProcess
        #Update-PSDataFile -Path $ModuleManifest.Path -Property FormatsToProcess -Value $FormatsToProcess
    } else {
        '... no change' | Write-Verbose
    }
}

$TypeData = Join-Path -Path $ModuleLocation.Path -ChildPath 'TypeData'  | Join-Path -ChildPath "$ModuleName.Types.ps1xml"
if (Test-Path -Path $TypeData) {
    $TypesToProcess = $TypeData.Replace($ReplacePath,'')
}
if ($TypesToProcess) {
    'TypesToProcess' | Write-Verbose
    if ($FunctionsToExport -ne $ModuleManifest.TypesToProcess) {
        '... updating' | Write-Verbose
        Update-ModuleManifest -Path $ModuleManifest.Path -TypesToProcess $TypesToProcess
        #Update-PSDataFile -Path $ModuleManifest.Path -Property TypesToProcess -Value $TypesToProcess
    } else {
        '... no change' | Write-Verbose
    }
}

if (Test-Path -path $ReleaseNotesFile) {
    $ReleaseNotes = [System.Text.StringBuilder]::new()
    $ReleaseNoteLines = Get-Content -Path $ReleaseNotesFile
    $Count = 0
    foreach ($Line in $ReleaseNoteLines) {
        if ($Line -match '^## \[\d\.|^## \d\.') {
            if ($null -eq $LastReleaseBegin) {
                $LastReleaseBegin = $Count
            } elseif ($null -eq $LastReleaseEnd) {
                $LastReleaseEnd = $Count - 1
                break
            }
        }
        $Count++
    }
    [void]$ReleaseNotes.Append($ReleaseNoteLines[$LastReleaseBegin..$LastReleaseEnd] -join [System.Environment]::NewLine)
    [void]$ReleaseNotes.Append([System.Environment]::NewLine)
    [void]$ReleaseNotes.Append($AppendToReleaseNotes)
    $ReleaseNotesText = $ReleaseNotes.ToString()
}
if ($ReleaseNotesText) {
    'ReleaseNotes' | Write-Verbose
    if ($ReleaseNotesText -ne $ModuleManifest.ReleaseNotes) {
        '... updating' | Write-Verbose
        Update-ModuleManifest -Path $ModuleManifest.Path -ReleaseNotes $ReleaseNotesText
        #Update-PSDataFile -Path $ModuleManifest.Path -Property ReleaseNotes -Value $ReleaseNotesText
    } else {
        '... no change' | Write-Verbose
    }
}

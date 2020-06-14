#Requires -Module platyPS,PowerShellforGitHub,Configuration

function New-OnlineHelpLanding {
    [CmdLetBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName
    )

    $Description = Get-Module -Name $ModuleName | Select-Object -ExpandProperty Description
    $Functions = Get-Command -Module $ModuleName -CommandType Function | Select-Object -ExpandProperty Name
    $CmdLets = Get-Command -Module $ModuleName -CommandType CmdLets | Select-Object -ExpandProperty Name

    $OnlineHelp = [System.Text.StringBuilder]::new()
    [void]$OnlineHelp.AppendLine('# {0} Module' -f $ModuleName)
    [void]$OnlineHelp.AppendLine()

    [void]$OnlineHelp.AppendLine('## Description')
    [void]$OnlineHelp.AppendLine()

    [void]$OnlineHelp.AppendLine($Description)
    [void]$OnlineHelp.AppendLine()

    if ($CmdLets) {
        [void]$OnlineHelp.AppendLine('## {0} CmdLets' -f $ModuleName)
        [void]$OnlineHelp.AppendLine()

        foreach ($Command in $CmdLets) {
            $Synopsis = Get-Help -Name $Command | Select-Object -ExpandProperty Synopsis
            [void]$OnlineHelp.AppendLine('### [{0}]({0})' -f $Command)
            [void]$OnlineHelp.AppendLine()
            [void]$OnlineHelp.AppendLine($Synopsis)
        }
    }

    if ($Functions) {
        [void]$OnlineHelp.AppendLine('## {0} Functions' -f $ModuleName)
        [void]$OnlineHelp.AppendLine()

        foreach ($Command in $Functions) {
            $Synopsis = Get-Help -Name $Command | Select-Object -ExpandProperty Synopsis
            [void]$OnlineHelp.AppendLine('### [{0}]({0})' -f $Command)
            [void]$OnlineHelp.AppendLine()
            [void]$OnlineHelp.AppendLine($Synopsis)
        }
    }

    $OnlineHelp.ToString()

}

function New-MyMarkdownHelp {
    [CmdLetBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,
        [Parameter(Mandatory)]
        [string]$OutputFolder
    )

    # verify that platyPS is available
    if (Get-Module -ListAvailable -Name platyPS -Verbose:$false) {
        $Version = (Get-Module -Name platyPS -Verbose:$false).Version.ToString()
        'Using platyPS version {0}' -f $Version | Write-Verbose
    } else {
        'Please install platyPS and try again.' | Write-Warning
        return
    }

    # verify that ModuleName is available
    $ModuleCommands = Get-Command -Module $ModuleName
    if ($null -eq $ModuleCommands) {
        'Module {0} not found in $env:PSModulePath and is not loaded in the current session.' -f $ModuleName | Write-Warning
        'Please correct this and try again.' | Write-Warning
        return
    }

    foreach ($Command in (Get-Command -Module $ModuleName -CommandType Function)) {
        if (-Not (Test-Path -Path $OutputFolder)) {
            try {
                New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
            }
            catch {
                'Unable to create {0}' -f $OutputFolder | Write-Warning
                return
            }
        }

        $OnlineVersionUri = "https://{0}.anovelidea.org/en/latest/{1}/" -f $ModuleName.ToLower(),$Command

        $NewMarkdownHelpParams = @{
            Command             = $Command
            OutputFolder        = $OutputFolder
            OnlineVersionUrl    = $OnlineVersionUri
            Force               = $true
        }

        New-MarkdownHelp @NewMarkdownHelpParams
    }
}

function Copy-ModuleMarkdownDocs {
    [CmdLetBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path -Path $_})]
        [string]$ProjectPath,
        [ValidateScript({Test-Path -Path $_})]
        [string]$DocPath
    )

    foreach ($file in 'CHANGELOG.md','README.md') {
        $FilePath = Join-Path -Path $ProjectPath -ChildPath $file
        if (Test-Path -Path $FilePath) {
            try {
                Copy-Item -Path $FilePath -Destination $DocPath
            }
            catch {
                'Unable to copy {0} to {1}' -f $FilePath,$DocPath | Write-Warning
            }
        }
    }

}

function Update-MkDocYaml {
    [CmdLetBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path -Path $_})]
        [string]$MkDocYaml
    )

    $MkDocYamlBuilder = [System.Text.StringBuilder]::new()
    [void]$MkDocYamlBuilder.Append(((Get-Content -Path $MkDocYaml -Raw) -split '    - Functions:',2)[0])

    <#
    $CmdLets = (Get-Command -Module $ModuleName -CommandType Cmdlet) | Select-Object -ExpandProperty Name | Sort-Object
    if ($CmdLets) {
        [void]$MkDocYamlBuilder.AppendLine('    - CmdLets:')
        foreach ($Command in $CmdLets) {
            [void]$MkDocYamlBuilder.AppendLine('        - {0}: {0}.md' -f $Command)
        }
    }
    #>
    $Functions = (Get-Command -Module $ModuleName -CommandType Function) | Select-Object -ExpandProperty Name | Sort-Object
    if ($Functions) {
        [void]$MkDocYamlBuilder.AppendLine('    - Functions:')
        foreach ($Command in $Functions) {
            [void]$MkDocYamlBuilder.AppendLine('        - {0}: {0}.md' -f $Command)
        }
    }

    try {
        Set-Content -Path $MkDocYaml -Value $MkDocYamlBuilder.ToString() -Force
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }

}

function Get-GitLog {
    [CmdLetBinding(DefaultParameterSetName='Default')]
    param (

        [Parameter(ParameterSetName='Default',ValueFromPipeline)]
        [Parameter(ParameterSetName='SourceTarget',ValueFromPipeline)]
        [ValidateScript({Resolve-Path -Path $_ | Test-Path})]
        [string]$GitFolder='.',

        [Parameter(ParameterSetName='SourceTarget',Mandatory)]
        [string]$StartCommitId,
        [Parameter(ParameterSetName='SourceTarget')]
        [string]$EndCommitId='HEAD'
    )

    Push-Location
    try {
        $GitPath = (Resolve-Path -Path $GitFolder).Path
        $GitCommand = Get-Command -Name git -ErrorAction Stop
        if ((Get-Location).Path -ne $GitPath) {
            Set-Location -Path $GitFolder
        }
        Write-Verbose -Message "Folder - $GitPath"
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }

    if ($StartCommitId) {
        $GitLogCommand = '"{0}" log --oneline --format="%H`t%h`t%ai`t%an`t%ae`t%ci`t%cn`t%ce`t%G?`t%s`t%f" {1}...{2} 2>&1' -f $GitCommand.Source,$StartCommitId,$EndCommitId
    #} elseif ($Branch) {
    #    $GitLogCommand = '"{0}" log --oneline --format="%H`t%h`t%ai`t%an`t%ae`t%ci`t%cn`t%ce`t%G?`t%s`t%f" --branches 2>&1' -f $GitCommand.Source
    } else {
        $GitLogCommand = '"{0}" log --oneline --format="%H`t%h`t%ai`t%an`t%ae`t%ci`t%cn`t%ce`t%G?`t%s`t%f" 2>&1' -f $GitCommand.Source
    }

    Write-Verbose -Message "Command - $GitLogCommand"
    $GitLog = Invoke-Expression -Command "& $GitLogCommand" -ErrorAction SilentlyContinue

    if ((Get-Location).Path -ne $GitPath) {
        Pop-Location
    }

    $GitLogFormat = 'CommitId',
        'ShortCommitId',
        'AuthorDate',
        'AuthorName',
        'AuthorEmail',
        'CommitterDate',
        'CommitterName',
        'ComitterEmail',
        @{label='CommitterSignature';expression={
            switch ($_.CommitterSignature) {
                'G' { 'Valid'}
                'B' { 'BadSignature'}
                'U' { 'GoodSignatureUnknownValidity'}
                'X' { 'GoodSignatureExpired'}
                'Y' { 'GoodSignatureExpiredKey'}
                'R' { 'GoodSignatureRevokedKey'}
                'E' { 'MissingKey'}
                'N' { 'NoSignature'}
            }
        }},
        'CommitMessage',
        'SafeCommitMessage'

    if ($GitLog[0] -notmatch 'fatal:') {
        $GitLog | ConvertFrom-Csv -Delimiter "`t" -Header 'CommitId','ShortCommitId','AuthorDate','AuthorName','AuthorEmail','CommitterDate','CommitterName','ComitterEmail','CommitterSignature','CommitMessage','SafeCommitMessage' | Select-Object $GitLogFormat
    } else {
        if ($GitLog[0] -like "fatal: ambiguous argument '*...*'*") {
            Write-Warning -Message 'Unknown revision. Please check the values for StartCommitId or EndCommitId; omit the parameters to retrieve the entire log.'
        } else {
            Write-Error -Category InvalidArgument -Message ($GitLog -join "`n")
        }
    }
    Pop-Location
}

function Get-ReleaseNotes {
    [CmdLetBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path -Path $_})]
        [string]$ChangeLogPath,
        [Parameter(Mandatory)]
        [uri]$ChangeLogUri
    )

    $FullChangeLogLocation = "For full CHANGELOG, see $ChangeLogUri" -f $ChangeLogUri.AbsoluteUri

    $ChangeLog = [System.Text.StringBuilder]::new()
    $Lines = Get-Content -Path $ChangeLogPath
    $Count = 0
    foreach ($Line in $Lines) {
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
    [void]$ChangeLog.Append($Lines[$LastReleaseBegin..$LastReleaseEnd] -join [System.Environment]::NewLine)
    [void]$ChangeLog.AppendLine()

    [void]$ChangeLog.AppendLine($FullChangeLogLocation)

    $ChangeLog.ToString()
}

function Get-ChangeLogUpdate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path -Path $_})]
        [string]$ProjectPath,
        [Parameter(Mandatory)]
        [ValidateSet('Bugfix','Security','Feature','Maintenance')]
        [string[]]$ReleaseType,
        [Parameter(Mandatory)]
        [ValidateSet('No Required','Recommended','Strongly Recommended')]
        [string]$UpdateRequired,
        [Parameter(Mandatory)]
        [string]$ProjectOwner,
        [Parameter(Mandatory)]
        [version]$TargetRelease,
        [uri]$ReleaseLink,
        [string]$TargetReleaseDate='Unreleased'
    )

    try {
        enum ChangeLogEntryType {
            Security; Deprecated; Removed; Fixed; Changed; Added; Maintenance
        }
        $ProjectPath = Resolve-Path -Path $ProjectPath
        $Project = Split-Path -Path $ProjectPath -Leaf
        $LastReleaseCommit = Get-GitHubRelease -OwnerName $ProjectOwner -RepositoryName $Project | Sort-Object -Property created_at -Descending | Select-Object -First 1
        $GitLog = Get-GitLog -GitFolder $ProjectPath -StartCommitId $LastReleaseCommit.target_commitish
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }

    $NewChangeLogEntry = [System.Text.StringBuilder]::new()
    [void]$NewChangeLogEntry.AppendLine()

    if ($ReleaseLink) {
        $TargetReleaseText = '## [{0}] - {1}' -f $TargetRelease.ToString(),$TargetReleaseDate
    } else {
        $TargetReleaseText = '## {0} - {1}' -f $TargetRelease.ToString(),$TargetReleaseDate
    }
    [void]$NewChangeLogEntry.AppendLine($TargetReleaseText)
    [void]$NewChangeLogEntry.AppendLine()

    switch ($ReleaseType.Count) {
        1 { $ReleaseTags = $ReleaseType[0] }
        2 { $ReleaseTags = '{0} and {1}' -f $ReleaseType[0],$ReleaseType[1] }
        3 { $ReleaseTags = '{0}, {1}, and {2}' -f $ReleaseType[0],$ReleaseType[1],$ReleaseType[2] }
        4 { $ReleaseTags = '{0}, {1}, {2}, and {3}' -f $ReleaseType[0],$ReleaseType[1],$ReleaseType[2],$ReleaseType[3] }
    }
    $ReleaseTypeText = '{0}; Update {1}' -f $ReleaseTags,$UpdateRequired
    [void]$NewChangeLogEntry.AppendLine($ReleaseTypeText)
    [void]$NewChangeLogEntry.AppendLine()

    $ChangeLogCommits = foreach ($Commit in $GitLog) {
        $IssueNumber = $GitHubIssue = $null
        $Action,$Message = $Commit.CommitMessage -Split ' '

        if ([ChangeLogEntryType].GetEnumNames() -match "^$Action") {
            $EntryType = [ChangeLogEntryType]$Action
        } else {
            $EntryType = 'Maintenance'
        }
        if ($Message -match '#') {
            $Issue = $Message -match '#'
            if ($Issue -is [boolean]) {
                $IssueNumber = $Message.Replace('#','')
            } else {
                $IssueNumber = $Issue.Replace('#','')
            }

            $GitHubIssue = Get-GitHubIssue -OwnerName $ProjectOwner -RepositoryName $Project -Issue $IssueNumber |
                Select-Object -Property number,html_url,title |
                Sort-Object -Property number
        }

        [PSCustomObject]@{
            ShortCommitId = $Commit.ShortCommitId
            CommitDate = $Commit.CommitDate
            EntryType = $EntryType
            CommitMessage = $Commit.CommitMessage
            GitHubIssue = $GitHubIssue
        }
    }
    $ChangeLogCommits | Out-String | Write-Verbose

    foreach ($EntryType in [ChangeLogEntryType].GetEnumNames()) {
        $SectionCommits = $ChangeLogCommits.Where({$_.EntryType -match $EntryType -and $_.GitHubIssue}) | Sort-Object -Property GitHubIssue.created_at,CommitterDate,CommitMessage

        if ($SectionCommits) {
            $SectionHeader = '### {0}' -f $EntryType
            [void]$NewChangeLogEntry.AppendLine($SectionHeader)
            [void]$NewChangeLogEntry.AppendLine()

            foreach ($Entry in $SectionCommits) {
                if ($Entry.GitHubIssue) {
                    $EntryText = '* [Issue #{0}]({1}) - {2}' -f $Entry.GitHubIssue.number,$Entry.GitHubIssue.html_url,$Entry.GitHubIssue.title
                }
                $EntryText | Write-Verbose
                [void]$NewChangeLogEntry.AppendLine($EntryText)
            }
            [void]$NewChangeLogEntry.AppendLine()
        }
    }

    if ($ReleaseLink) {
        $ReleaseLinkText = '[{0}]: {1}' -f $TargetRelease.ToString(),$ReleaseLink.AbsoluteUri
        [void]$NewChangeLogEntry.AppendLine($ReleaseLinkText)
    }

    $NewChangeLogEntry.ToString()
}

function Set-ChangeLog {
    [CmdletBinding()]
    param(
        [ValidateScript({Test-Path $_})]
        [string]$ChangeLogPath,
        [Parameter(Mandatory)]
        [string]$ChangeLogUpdate
    )

    $ChangeLog = [System.Text.StringBuilder]::new()
    $Lines = Get-Content -Path $ChangeLogPath
    $Count = 0
    foreach ($Line in $Lines) {
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

    if ($Lines[$LastReleaseBegin] -ne $ChangeLogUpdate.Split([System.Environment]::NewLine)[2]) {

        # use original heading
        [void]$ChangeLog.Append($Lines[0..($LastReleaseBegin-1)] -join [System.Environment]::NewLine)

        # add updated entry
        [void]$ChangeLog.Append($ChangeLogUpdate)

        # use original remainer
        [void]$ChangeLog.Append($Lines[($LastReleaseBegin)..($Lines.Count)] -join [System.Environment]::NewLine)

        Set-Content -Path $ChangeLogPath -Value $ChangeLog.ToString() -Force

    } else {
        ' No changes made to {0}' -f $ChangeLogPath | Write-Warning
    }
}

function Update-MyModuleManifest {
    [CmdLetBinding()]
    param(
        [ValidateScript({Test-Path $_})]
        [string]$ProjectPath,
        [Parameter(Mandatory)]
        [string]$ReleaseNotes
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

    $ModuleLocation = Resolve-Path -Path $ProjectPath
    $ModuleName = Split-Path $ModuleLocation.Path -Leaf
    if ($ModuleLocation.Path -match '\\$') {
        $ReplacePath = $ModuleLocation.Path
    } else {
        $ReplacePath = $ModuleLocation.Path + [System.IO.Path]::DirectorySeparatorChar
    }
    $ProjectPath = Split-Path -Path $ModuleLocation.Path

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

    'ReleaseNotes' | Write-Verbose
    if ($ReleaseNotes -ne $ModuleManifest.ReleaseNotes) {
        '... updating' | Write-Verbose
        Update-ModuleManifest -Path $ModuleManifest.Path -ReleaseNotes $ReleaseNotes
        #Update-PSDataFile -Path $ModuleManifest.Path -Property ReleaseNotes -Value $ReleaseNotesText
    } else {
        '... no change' | Write-Verbose
    }

}
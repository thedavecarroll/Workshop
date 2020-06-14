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

}
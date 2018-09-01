[CmdLetBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ModuleName,
    [Parameter(Mandatory)]
    [string]$OutputFolder
)

if (Get-Module -ListAvailable -Name platyPS) {
    $Version = (Get-Module -Name platyPS).Version.ToString()
    Write-Verbose -Message "Using platyPS version $Version"
} else {
    Write-Warning -Message 'Please install platyPS and try again.'
    exit 1
}

foreach ($Command in (Get-Command -Module $ModuleName)) {
    $FrontMatter = @{
        'layout' = 'onlinehelp'
        'search' = 'false'
        'classes' = 'wide'
        'permalink' = "/modulehelp/$ModuleName/$($Command.Name).html"
    }

    New-MarkdownHelp -Command $Command -OutputFolder $OutputFolder -Metadata $FrontMatter -Force
}
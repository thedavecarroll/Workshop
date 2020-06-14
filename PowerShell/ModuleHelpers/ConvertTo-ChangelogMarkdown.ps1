function ConvertTo-ChangelogMarkdown {
    [CmdLetBinding()]
    param(

        [Parameter(Mandatory,ValueFromPipeline)]
        [object]$GitLog,

        [Parameter(Mandatory)]
        [Alias('OutFile')]
        [string]$MarkdownFile
    )

    # Filter to commits that pass the conventional commit format.
    # See: https://www.conventionalcommits.org/
    $CommitFilter = '^[a-z]+(\([a-z]+\))?:\s.+'

    try {

    }
    catch {

    }
}
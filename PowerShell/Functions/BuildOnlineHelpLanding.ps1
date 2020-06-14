function New-OnlineHelpLanding {
    [CmdLetBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName
    )

    $NewLine = [System.Environment]::NewLine
    $Description = Get-Module -Name $ModuleName | Select-Object -ExpandProperty Description
    $Commands = Get-Command -Module $ModuleName  | Select-Object -ExpandProperty Name

    '# {0} Module' -f $ModuleName
    $NewLine

    '## Description'
    $NewLine

    $Description
    $NewLine

    '## {0} CmdLets' -f $ModuleName
    $NewLine

    foreach ($Command in $Commands) {
        $Synopsis = Get-Help -Name $Command | Select-Object -ExpandProperty Synopsis
        '### [{0}]({0}.html)' -f $Command
        $NewLine
        $Synopsis
    }

}
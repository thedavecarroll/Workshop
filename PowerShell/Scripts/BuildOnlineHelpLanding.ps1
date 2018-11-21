
$Module = 'PoShDynDnsApi'

$Body = "# $Module Module`n"
$Body += "## Description`n"

$Description = Get-Module -Name $Module | Select-Object -ExpandProperty Description
$Body += "$Description`n"
$Body += "`n"
$Body += "## $Module CmdLets"

$Commands = Get-Command -Module $Module  | Select-Object -ExpandProperty Name

Foreach ($Command in $Commands) {
    $Synopsis = Get-Help -Name $Command | Select-Object -ExpandProperty Synopsis
    $Body += "### [$Command]($Command.html)`n"
    $Body += "$Synopsis`n`n"
}

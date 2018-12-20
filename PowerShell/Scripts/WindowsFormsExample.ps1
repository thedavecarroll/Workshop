[CmdLetBinding()]
param()

Import-Module D:\GitHub\Workshop\PowerShell\Scripts\WindowsForms.psm1

$RowHighlight = @{
    'Cell' = 'ProcessName'
    'Values' = @{
        'powershell' = 'LightGreen'
        'chrome' = 'Red'
        'code' = 'LightBlue'
        'Default' = 'White'
    }
}

#region event scriptblocks
$CloseButton_OnClick = [scriptblock]::Create({
    $WindowsFormExample.Close()
})

$RefreshButton_OnClick = [scriptblock]::Create({
    if ($Script:WindowsFormData) {
        $StatusStrip = Set-StatusStrip -StatusStrip $StatusStrip -Operation 'Process:' -Progress 'Refreshing process data'
        $WindowsFormExample.Refresh()
        Start-Sleep -Seconds 1

        $Script:WindowsFormData = Get-Process -Name powershell,pwsh,chrome,code | Select-Object -Property ProcessName,Id,Handles,CPU
        $DataGridView = Update-DataGridView -Data $WindowsFormData -DataGridView $DataGridView -RowHighlight $RowHighlight
        $WindowsFormExample.Refresh()

        $StatusStrip = Set-StatusStrip -StatusStrip $StatusStrip -Operation 'Refresh completed'
        $WindowsFormExample.Refresh()
    }
})


$Form_OnLoad = [scriptblock]::Create({
    $WindowsFormExample.Refresh()
    $StatusStrip = Set-StatusStrip -StatusStrip $StatusStrip -Operation 'Process:' -Progress 'Loading process data'
    $WindowsFormExample.Refresh()
    Start-Sleep -Seconds 1

    $Script:WindowsFormData = Get-Process -Name powershell,pwsh,chrome,code | Select-Object -Property ProcessName,Id,Handles,CPU
    $DataGridView = Update-DataGridView -Data $WindowsFormData -DataGridView $DataGridView -RowHighlight $RowHighlight
    $WindowsFormExample.Refresh()

    $StatusStrip = Set-StatusStrip -StatusStrip $StatusStrip -Operation 'Load completed'
    $WindowsFormExample.Refresh()
})
#endregion event script blocks

# build form
$WindowsFormExample = New-WindowsForm -Name 'Windows Form Example' -Width 810 -Height 410 -NoIcon

# assign header label
$FormLabel = New-FormLabel -Name "My Grand Form" -Index 0 -Width 300 -Height 30 -DrawX 5 -DrawY 15

# add buttons
$Buttons = @()
$Buttons += New-FormButton -Name 'Refresh' -Index 1 -Width 100 -Height 25 -DrawX 5  -DrawY 50 -Action $RefreshButton_OnClick
$Buttons += New-FormButton -Name 'Close' -Index 3 -Width 100 -Height 25 -DrawX 700 -DrawY 50 -Action $CloseButton_OnClick -Anchor 'Right,Top'
# add data
$DataGridView = New-DataGridView -Name 'WindowsFormExample' -Index 2 -Width 800 -Height 300 -DrawX 5 -DrawY 80 -Anchor 'Left,Top,Right,Bottom'

# create status strip/bar
$StatusStrip = New-StatusStrip

# update form
$WindowsFormExampleParams = @{
    WindowsForm   = $WindowsFormExample
    FormLabel     = $FormLabel
    FormButton    = $Buttons
    DataGridView  = $DataGridView
    StatusStrip   = $StatusStrip
    OnLoad        = $Form_OnLoad
}
$WindowsFormExample = Set-WindowsForm @WindowsFormExampleParams

[void]$WindowsFormExample.ShowDialog()
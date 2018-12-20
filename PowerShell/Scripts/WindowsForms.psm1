# ----------------------------------------------------------------------------------------------------------------------
# Function required to create PowerShell GUI using System.Windows.Forms
# ----------------------------------------------------------------------------------------------------------------------

#region load assemblies
try {
    [Void][reflection.assembly]::loadwithpartialname('System.Windows.Forms')
    [Void][reflection.assembly]::loadwithpartialname('System.Drawing')
}
catch {
    Write-Warning -Message 'Unable to load required assemblies'
    return
}
#endregion load assemblies

#region New-WindowsForm
function New-WindowsForm {
    [CmdLetBinding()]
    [OutputType([System.Windows.Forms.Form])]
    param(
        [string]$Name,
        [int]$Width,
        [int]$Height,
        [switch]$NoIcon
    )

    try {
        $WindowsForm = [System.Windows.Forms.Form]::new()
        $WindowsForm.Name = ($Name -Replace '[^a-zA-Z]','') + 'WindowsForm'
        $WindowsForm.Text = $Name
        $WindowsForm.ClientSize = [System.Drawing.Size]::new($Width,$Height)
        $WindowsForm.DataBindings.DefaultDataSourceUpdateMode = 0
        #$WindowsForm.AutoSize = $true
        $WindowsForm.AutoSizeMode = 'GrowAndShrink'
        $WindowsForm.AutoScroll = $true
        $WindowsForm.Margin = 5
        $WindowsForm.WindowState = [System.Windows.Forms.FormWindowState]::new()
        if ($NoIcon) {
            $WindowsForm.ShowIcon = $false
        }
        $WindowsForm
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
#endregion New-WindowsForm

#region New-DrawingFont
function New-DrawingFont {
    [CmdLetBinding()]
    param(
        [string]$Name,
        [single]$Size,
        [System.Drawing.FontStyle]$Style
    )
    try {
        [System.Drawing.Font]::new($Name,$Size,$Style,'Point',0)
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
#endregion New-DrawingFont

#region New-DrawingColor
function New-DrawingColor {
    [CmdLetBinding()]
    param()
    try {
        [System.Drawing.Color]::FromArgb(255,0,102,204)
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
#endregion New-DrawingColor

#region New-FormLabel
function New-FormLabel {
    [CmdLetBinding()]
    [OutputType([System.Windows.Forms.Label])]
    param(
        [string]$Name,
        [int]$Index,
        [int]$Width,
        [int]$Height,
        [int]$DrawX,
        [int]$DrawY#,
        #[System.Drawing.Font]$Font,
        #[System.Drawing.Color]$ForeColor,
        #[System.Drawing.Color]$BackColor
    )
    try {
        $FormLabel = [System.Windows.Forms.Label]::new()
        $FormLabel.Name = ($Name -Replace '[^a-zA-Z]','') + 'FormLabel'
        $FormLabel.Text = $Name
        $FormLabel.TabIndex = $Index
        $FormLabel.Size = [System.Drawing.Size]::new($Width,$Height)
        #$FormLabel.Font = $Font
        #$FormLabel.ForeColor = New-DrawingColor
        #if ($BackColor) {
        #    $FormLabel.ForeColor = $BackColor
        #}
        $FormLabel.Location = [System.Drawing.Point]::new($DrawX,$DrawY)
        $FormLabel.DataBindings.DefaultDataSourceUpdateMode = 0
        $FormLabel
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
#endregion New-FormLabel

#region New-FormButton
function New-FormButton {
    [CmdLetBinding()]
    [OutputType([System.Windows.Forms.Button])]
    param(
        [string]$Name,
        [int]$Index,
        [int]$Width,
        [int]$Height,
        [int]$DrawX,
        [int]$DrawY,
        [System.Windows.Forms.AnchorStyles]$Anchor='None',
        [scriptblock]$Action
    )
    try {
        $FormButton = [System.Windows.Forms.Button]::new()
        $FormButton.TabIndex = $Index
        $FormButton.Name = ($Name -Replace '[^a-zA-Z]','') + 'FormButton'
        $FormButton.Text = $Name
        $FormButton.Size = [System.Drawing.Size]::new($Width,$Height)
        $FormButton.Location = [System.Drawing.Point]::new($DrawX,$DrawY)
        $FormButton.UseVisualStyleBackColor = $True
        $FormButton.DataBindings.DefaultDataSourceUpdateMode = 0
        if ($Anchor) {
            $FormButton.Anchor = $Anchor
        }
        $FormButton.Add_Click($Action)
        $FormButton
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
#endregion New-FormButton

#region New-DataGridView
function New-DataGridView {
    [CmdLetBinding()]
    [OutputType([System.Windows.Forms.DataGridView])]
    param(
        [string]$Name,
        [int]$Index,
        [int]$Width,
        [int]$Height,
        [int]$DrawX,
        [int]$DrawY,
        [System.Windows.Forms.AnchorStyles]$Anchor='None'
    )

    try {
        $DataGridView = [System.Windows.Forms.DataGridView]::new()
        $DataGridView.TabIndex = $Index
        $DataGridView.Name = $Name.Replace('[^a-zA-Z]','') + 'DataGridView'
        $DataGridView.AutoSizeColumnsMode = 'AllCells'
        $DataGridView.Size = [System.Drawing.Size]::new($Width,$Height)
        $DataGridView.Location = [System.Drawing.Point]::new($DrawX,$DrawY)
        $DataGridView.DataBindings.DefaultDataSourceUpdateMode = 'OnValidation'
        $DataGridView.DataMember = ""
        if ($Anchor) {
            $DataGridView.Anchor = $Anchor
        }
        $DataGridView
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
#endregion New-DataGridView

#region Update-DataGridView
function Update-DataGridView {
    [CmdLetBinding()]
    [OutputType([System.Windows.Forms.DataGridView])]
    param(
        [object]$Data,
        [System.Windows.Forms.DataGridView]$DataGridView,
        [hashtable]$RowHighlight
    )
    try {
        $GridData = [System.Collections.ArrayList]::new()
        $GridData.AddRange(@($Data))
        $DataGridView.DataSource = $GridData

        if ($RowHighlight) {
            $Cell = $RowHighlight['Cell']
            foreach ($Row in $DataGridView.Rows) {
                [string]$CellValue = $Row.Cells[$Cell].Value
                Write-Verbose ($CellValue.Gettype())
                if ($RowHighlight['Values'].ContainsKey($CellValue)) {
                    Write-Verbose "Setting row based on $Cell cell of $CellValue to $($RowHighlight['Values'][$CellValue]) color"
                    $Row.DefaultCellStyle.BackColor = $RowHighlight['Values'][$CellValue]
                } elseif ($RowHighlight['Values'].ContainsKey('Default')) {
                    Write-Verbose "Setting $Cell cell for $CellValue to $($RowHighlight['Values'].Default) color"
                    $Row.DefaultCellStyle.BackColor = $RowHighlight['Values']['Default']
                }
            }
        }

        $DataGridView
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
#endregion Update-DataGridView

#region New-StatusStrip
function New-StatusStrip {
    [CmdLetBinding()]
    [OutputType([System.Windows.Forms.StatusStrip])]
    param()

    try {
        $StatusStrip = [System.Windows.Forms.StatusStrip]::new()
        $StatusStrip.Name = 'StatusStrip'
        $StatusStrip.AutoSize = $true
        $StatusStrip.Left = 0
        $StatusStrip.Visible = $true
        $StatusStrip.Enabled = $true
        $StatusStrip.Dock = [System.Windows.Forms.DockStyle]::Bottom
        $StatusStrip.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
        $StatusStrip.LayoutStyle = [System.Windows.Forms.ToolStripLayoutStyle]::Table

        $Operation = [System.Windows.Forms.ToolStripLabel]::new()
        $Operation.Name = 'Operation'
        $Operation.Text = $null
        $Operation.Width = 50
        $Operation.Visible = $true

        $Progress = [System.Windows.Forms.ToolStripLabel]::new()
        $Progress.Name = 'Progress'
        $Progress.Text = $null
        $Progress.Width = 50
        $Progress.Visible = $true

        $ProgressBar = [System.Windows.Forms.ToolStripProgressBar]::new()
        $ProgressBar.Name = 'ProgressBar'
        $ProgressBar.Width = 50
        $ProgressBar.Visible = $false

        $StatusStrip.Items.AddRange(
            [System.Windows.Forms.ToolStripItem[]]@(
                $Operation,
                $Progress,
                $ProgressBar
            )
        )
        $StatusStrip
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
#endregion New-StatusStrip

#region Set-StatusStrip
function Set-StatusStrip {
    [CmdLetBinding()]
    [OutputType([System.Windows.Forms.StatusStrip])]
    param(
        [System.Windows.Forms.StatusStrip]$StatusStrip,
        [string]$Operation = $null,
        [string]$Progress = $null,
        [int]$ProgressBarMinimum = 0,
        [int]$ProgressBarMaximum = 0,
        [int]$ProgressBarValue = 0
    )
    try {

        if ($null -ne $Operation) {
            $StatusStrip.Items.Find('Operation',$true)[0].Text = $Operation
            $StatusStrip.Items.Find('Operation',$true)[0].Width = 200
            $StatusStrip.Items.Find('Operation',$true)[0].Visible = $true
        }

        if ($null -ne $Progress) {
            $StatusStrip.Items.Find('Progress',$true)[0].Text = $Progress
            $StatusStrip.Items.Find('Progress',$true)[0].Width = 100
            $StatusStrip.Items.Find('Progress',$true)[0].Visible = $true
        }

        if ($null -ne $StatusStrip.Items.Find('ProgressBar',$true)) {
            if ($null -ne $ProgressBarMinimum) {
                $StatusStrip.Items.Find('ProgressBar',$true)[0].Minimum = $ProgressBarMinimum
            }
            if ($null -ne $ProgressBarMaximum) {
                $StatusStrip.Items.Find('ProgressBar',$true)[0].Maximum = $ProgressBarMaximum
            }
            if ($null -ne $ProgressBarValue) {
                $StatusStrip.Items.Find('ProgressBar',$true)[0].Value = $ProgressBarValue
            }
            if ($StatusStrip.Items.Find('ProgressBar',$true)[0].Minimum -eq $StatusStrip.Items.Find('ProgressBar',$true)[0].Maximum ) {
                $StatusStrip.Items.Find('ProgressBar',$true)[0].Visible = $false
            } else {
                $StatusStrip.Items.Find('ProgressBar',$true)[0].Visible = $true
            }
        }
        $StatusStrip
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
#endregion Set-StatusStrip

#region Set-WindowsForm
function Set-WindowsForm {
    [CmdLetBinding()]
    [OutputType([System.Windows.Forms.Form])]
    param(
        [Parameter(Mandatory=$true)]
        [System.Windows.Forms.Form]$WindowsForm,

        [System.Windows.Forms.Label[]]$FormLabel,
        [System.Windows.Forms.Button[]]$FormButton,
        [System.Windows.Forms.DataGridView]$DataGridView,
        [System.Windows.Forms.StatusStrip]$StatusStrip,
        [ScriptBlock]$OnLoad,
        [int]$HeaderWidth
    )

    try {
        if ($PSBoundParameters.Keys -contains 'FormLabel') {
            foreach ($Label in $FormLabel) {
                $WindowsForm.Controls.Add($Label)
            }
        }
        if ($PSBoundParameters.Keys -contains 'FormButton') {
            foreach ($Button in $FormButton) {
                $WindowsForm.Controls.Add($Button)
            }
        }
        if ($PSBoundParameters.Keys -contains 'DataGridView') {
            $WindowsForm.Controls.Add($DataGridView)
        }
        if ($PSBoundParameters.Keys -contains 'StatusStrip') {
            $WindowsForm.Controls.Add($StatusStrip)
        }
        if ($PSBoundParameters.Keys -contains 'OnLoad') {
            $WindowsForm.add_Shown($OnLoad)
        }
        if ($PSBoundParameters.Keys -contains 'HeaderWidth') {
            $WindowsForm.Width = $HeaderWidth + 5
        }
        $WindowsForm.StartPosition = 1

        $WindowsForm
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
#endregion Set-WindowsForm

#region Get-OpenFileDialog
function Get-OpenFileDialog {
    [CmdLetBinding()]
    [OutputType([System.Windows.Forms.OpenFileDialog])]
    param (
        [string]$StartingFolder = (Join-Path -Path $env:HOMEDRIVE -ChildPath $env:HOMEPATH),
        [string]$Filter = 'All files (*.*)|*.*'
    )
    try {
        [Void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
        $OpenFileDialog = [System.Windows.Forms.OpenFileDialog]::new()
        $OpenFileDialog.InitialDirectory = $StartingFolder
        $OpenFileDialog.Filter = $Filter
        [Void]$OpenFileDialog.ShowDialog()
        $OpenFileDialog
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
#endregion Get-OpenFileDialog

#region Set-SaveFileDialog
function Set-SaveFileDialog {
    [CmdLetBinding()]
    [OutputType([System.Windows.Forms.SaveFileDialog])]
    param (
        [string]$StartingFolder = (Join-Path -Path $env:HOMEDRIVE -ChildPath $env:HOMEPATH),
        [string]$Filter = 'All files (*.*)|*.*'
    )
    try {
        [Void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
        $SaveFileName = [System.Windows.Forms.SaveFileDialog]::new()
        $SaveFileName.InitialDirectory = $StartingFolder
        $SaveFileName.Filter = $Filter
        $SaveFileName.SupportMultiDottedExtensions = $true
        [Void]$SaveFileName.ShowDialog()
        $SaveFileName
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
#endregion Set-SaveFileDialog

Export-ModuleMember -Function New-WindowsForm,Set-WindowsForm,New-FormLabel,New-FormButton,New-DataGridView,Update-DataGridView,New-StatusStrip,Set-StatusStrip,Get-OpenFileDialog,Set-SaveFileDialog
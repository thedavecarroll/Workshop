[CmdLetBinding()]
param(
    [Parameter(ParameterSetName='File')]
    [ValidateScript({Test-Path -Path $_})]
    [string]$InputFile,

    [Parameter(ParameterSetName='Array',ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [string[]]$ComputerName,

    [Parameter(ParameterSetName='File')]
    [Parameter(ParameterSetName='Array')]
    [int]$WaitTime=15,

    [Parameter(ParameterSetName='File')]
    [Parameter(ParameterSetName='Array')]
    [string]$Log

)


function startTimer() {
    $RefreshTimer.start()
}

function stopTimer() {
    $RefreshTimer.Enabled = $false
}

#region Resolve-DNSHostName
function Resolve-DNSHostName {
    [CmdLetBinding()]
    param(
        [string[]]$ComputerName
    )
    begin {
        $Counter = 1
        $LooseIPAddressRegEx = '\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b'
    }
    process {
        foreach ($Computer in $ComputerName) {

            # test if item is a valid IP address
            try {
                $IPAddress = ([IPAddress]$Computer).IPAddressToString
                $IsValidIPAddress = $true
            }
            catch {
                $IsValidIPAddress = $false
            }

            if ($IsValidIPAddress) {
                # valid IP address provided, obtain hostname
                try {
                    $HostName = [System.Net.Dns]::GetHostByAddress($IPAddress).HostName
                    $DNSStatus = 'Valid'
                }
                catch {
                    $HostName = $null
                    $DNSStatus = $_.Exception.InnerException.SocketErrorCode
                }

            } else {
                # not valid IP, assum hostname provided
                try {
                    $HostName = $Computer.ToString().ToUpper()
                    $IPAddress = [System.Net.Dns]::GetHostByName($Computer).Addresslist[0].IPAddressToString
                    $DNSStatus = 'Valid'
                }
                catch {
                    if ($Computer -match $LooseIPAddressRegEx) {
                        # item looks like an IP address
                        $IPAddress = $Computer
                        $HostName = $null
                        $DNSStatus = 'InvalidIPAddress'
                    } else {
                        $HostName = $Computer.ToUpper()
                        $IPAddress = $null
                        $DNSStatus = $_.Exception.InnerException.SocketErrorCode
                    }
                }
            }
            [PsCustomObject]@{
                Id        = $Counter++
                HostName  = $HostName
                IPAddress = $IPAddress
                DNSStatus = $DNSStatus
            }

        }
    }
}
#endregion Resolve-DNSHostName

#region Invoke-PingView
function Invoke-PingView {
    [CmdLetBinding()]
    param(
        [Parameter(ParameterSetName='Start',ValueFromPipeline=$true)]
        [PSCustomObject[]]$DnsHostName
    )
    process {
        foreach ($HostName in $DnsHostName) {
            # clear iteration properties
            $Status = $PingReset = $LastPingTime = $null
            $Success = $Failure = $Attempts = 0

            if ($HostName.DNSStatus -eq 'Valid') {
                try {
                    $Ping = [System.Net.NetworkInformation.Ping]::new()
                    $PingReply = $Ping.Send($HostName.IPAddress) | Select-Object -Property Status,RoundtripTime
                }
                catch  {
                    $PingReply = [PsCustomObject]@{
                        Status = 'NA'
                        RoundtripTime = 'NA'
                    }
                }
            } else {
                $PingReply = [PsCustomObject]@{
                    Status = 'NA'
                    RoundtripTime = 'NA'
                }
            }

            if ($PingReply.Status -eq 'Success') {
                $Success = 1
            } elseif ($PingReply.Status -ne 'NA') {
                $Failure = 1
            }

            if ($PingReply.Status -ne 'NA') {
                $Attempts = 1
            } else {
                $Attempts = 'NA'
            }

            [PsCustomObject]@{
                Id = $HostName.Id
                HostName = $HostName.HostName
                IPAddress = $HostName.IPAddress
                DNSStatus = $HostName.DNSStatus
                Status = $PingReply.Status
                RoundtripTime = $PingReply.RoundtripTime
                Success = $Success
                Failure = $Failure
                Attempts = $Attempts
                PingReset = $null
                LastPingTime = (Get-Date -Format G)
            }
        }
    }
}
#endregion Invoke-PingView

#region Invoke-PingViewContinue
function Invoke-PingViewContinue {
    [CmdLetBinding()]
    param(
        [Parameter(ParameterSetName='Start',ValueFromPipeline=$true)]
        [PSCustomObject[]]$PingView
    )
    process {
        foreach ($PingStatus in $PingView) {
            $Success = $Failure = $Attempts = 0

            if ($PingStatus.DNSStatus -eq 'Valid') {
                try {
                    $Ping = [System.Net.NetworkInformation.Ping]::new()
                    $PingReply = $Ping.Send($PingStatus.IPAddress) | Select-Object -Property Status,RoundtripTime
                }
                catch  {
                    $PingReply = [PsCustomObject]@{
                        Status = 'NA'
                        RoundtripTime = 'NA'
                    }
                }
            } else {
                $PingReply = [PsCustomObject]@{
                    Status = 'NA'
                    RoundtripTime = 'NA'
                }
            }

            if ($PingReply.Status -eq 'Success') {
                $Success = 1
            } elseif ($PingReply.Status -ne 'NA') {
                $Failure = 1
            }

            if ($PingReply.Status -ne 'NA') {
                $Attempts = $PingStatus.Attempts + 1
            } else {
                $Attempts = 'NA'
            }

            [PsCustomObject]@{
                Id = $PingStatus.Id
                HostName = $PingStatus.HostName
                IPAddress = $PingStatus.IPAddress
                DNSStatus = $PingStatus.DNSStatus
                Status = $PingReply.Status
                RoundtripTime = $PingReply.RoundtripTime
                Success = $PingStatus.Success + $Success
                Failure = $PingStatus.Failure + $Failure
                Attempts = $Attempts
                PingReset = $null
                LastPingTime = (Get-Date -Format G)
            }

        }
    }

}
#endregion Invoke-PingViewContinue

#region Get-PingViewNew
function Get-PingViewNew  {
    param($PingViewNew)
    $GridData = New-Object System.Collections.ArrayList
    $GridData.AddRange(@($PingViewNew))
    $dataGrid1.DataSource = $GridData
    $form1.refresh()
}
#endregion Get-PingViewNew

#region Get-PingViewRefresh
function Get-PingViewRefresh  {
    param($PingViewContinue)
    $GridData = New-Object System.Collections.ArrayList
    $GridData.AddRange(@($PingViewContinue))
    $dataGrid1.DataSource = $GridData
    $form1.refresh()
}
#endregion Get-PingViewRefresh

function Invoke-PingViewRefresh {

    $Script:PingView = $Script:PingView | Invoke-PingViewContinue
    Get-PingViewRefresh -PingViewContinue $Script:PingView

    $GridData = New-Object System.Collections.ArrayList
    $GridData.AddRange(@($Script:PingView))
    $dataGrid1.DataSource = $GridData
    $form1.refresh()
}


#region Show-PingViewForm
function Show-PingViewForm {
    param(
        [System.Collections.ArrayList]$GridData
    )

    ########################################################################
    # Code Generated By: SAPIEN Technologies PrimalForms (Community Edition) v1.0.8.0
    # Generated On: 2/24/2010 11:38 AM
    # Generated By: Ravikanth Chaganti (http://www.ravichaganti.com/blog)
    ########################################################################

    #region Import the Assemblies
    [reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
    [reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null
    #endregion

    #region Generated Form Objects
    $form1 = New-Object System.Windows.Forms.Form
    $label1 = New-Object System.Windows.Forms.Label
    $button3 = New-Object System.Windows.Forms.Button
    $button1 = New-Object System.Windows.Forms.Button
    $dataGrid1 = New-Object System.Windows.Forms.DataGrid
    $InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState
    #endregion Generated Form Objects

    #----------------------------------------------
    #Generated Event Script Blocks
    #----------------------------------------------
    #Provide Custom Code for events specified in PrimalForms.
    $button3_OnClick={
        $Form1.Close()
    }

    $button1_OnClick={
        $Script:PingView = $Script:PingView | Invoke-PingViewContinue
        Get-PingViewRefresh -PingViewContinue $Script:PingView
    }

    $OnLoadForm_UpdateGrid={
        $Script:PingView = $DnsHostName | Invoke-PingView
        Get-PingViewNew -PingViewNew $Script:PingView
    }

    #----------------------------------------------
    #region Generated Form Code
    $form1.Text = "PingView"
    $form1.Name = "form1"
    $form1.DataBindings.DefaultDataSourceUpdateMode = 0
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Width = 800
    $System_Drawing_Size.Height = 600
    $form1.ClientSize = $System_Drawing_Size

    $label1.TabIndex = 4
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Width = 155
    $System_Drawing_Size.Height = 23
    $label1.Size = $System_Drawing_Size
    $label1.Text = "Ping Status"
    $label1.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",9.75,2,3,0)
    $label1.ForeColor = [System.Drawing.Color]::FromArgb(255,0,102,204)

    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 13
    $System_Drawing_Point.Y = 13
    $label1.Location = $System_Drawing_Point
    $label1.DataBindings.DefaultDataSourceUpdateMode = 0
    $label1.Name = "label1"

    $form1.Controls.Add($label1)

    $button3.TabIndex = 3
    $button3.Name = "button3"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Width = 75
    $System_Drawing_Size.Height = 23
    $button3.Size = $System_Drawing_Size
    $button3.UseVisualStyleBackColor = $True

    $button3.Text = "Close"

    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 429
    $System_Drawing_Point.Y = 378
    $button3.Location = $System_Drawing_Point
    $button3.DataBindings.DefaultDataSourceUpdateMode = 0
    $button3.add_Click($button3_OnClick)

    $form1.Controls.Add($button3)

    $button1.TabIndex = 1
    $button1.Name = "button1"
    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Width = 75
    $System_Drawing_Size.Height = 23
    $button1.Size = $System_Drawing_Size
    $button1.UseVisualStyleBackColor = $True

    $button1.Text = "Refresh"

    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 13
    $System_Drawing_Point.Y = 379
    $button1.Location = $System_Drawing_Point
    $button1.DataBindings.DefaultDataSourceUpdateMode = 0
    $button1.add_Click($button1_OnClick)

    $form1.Controls.Add($button1)

    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Width = 800
    $System_Drawing_Size.Height = 600
    $dataGrid1.Size = $System_Drawing_Size
    $dataGrid1.DataBindings.DefaultDataSourceUpdateMode = 0
    $dataGrid1.HeaderForeColor = [System.Drawing.Color]::FromArgb(255,0,0,0)
    $dataGrid1.Name = "dataGrid1"
    $dataGrid1.DataMember = ""
    $dataGrid1.TabIndex = 0
    $System_Drawing_Point = New-Object System.Drawing.Point
    $System_Drawing_Point.X = 13
    $System_Drawing_Point.Y = 48
    $dataGrid1.Location = $System_Drawing_Point

    $form1.Controls.Add($dataGrid1)

    #endregion Generated Form Code

    #Save the initial state of the form
    $InitialFormWindowState = $form1.WindowState

    #Add Form event
    $form1.add_Load($OnLoadForm_UpdateGrid)

    $RefreshTimer = [System.Windows.Forms.Timer]::new()
    $RefreshTimer.Interval = $WaitTime * 1000
    $RefreshTimer.Add_Tick({ Invoke-PingViewRefresh })

    #Show the Form
    $form1.ShowDialog() | Out-Null

}
#endregion Show-PingViewForm


$DnsHostName = Resolve-DNSHostName -ComputerName $ComputerName

#Call the Function
Show-PingViewForm
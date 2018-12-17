[CmdLetBinding(DefaultParameterSetName='File')]
param(
    [Parameter(ParameterSetName='File',Position=0)]
    [string]$InputFile,

    [Parameter(ParameterSetName='Array',ValueFromPipeline=$true)]
    [string[]]$ComputerName,

    [Parameter(ParameterSetName='File')]
    [Parameter(ParameterSetName='Array')]
    [int]$WaitTime=15,

    [Parameter(ParameterSetName='File')]
    [Parameter(ParameterSetName='Array')]
    [string]$Log

)

# ----------------------------------------------------------------------------------------------------------------------
# dot source or create required functions
# ----------------------------------------------------------------------------------------------------------------------

. D:\GitHub\Workshop\PowerShell\Scripts\WindowsForms.ps1

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
    [CmdLetBinding(DefaultParameterSetName='Start')]
    param(
        [Parameter(ParameterSetName='Start',ValueFromPipeline=$true)]
        [Parameter(ParameterSetName='Continue',ValueFromPipeline=$true)]
        [PSCustomObject[]]$PingView,

        [Parameter(ParameterSetName='Continue')]
        [switch]$Continue
    )
    process {
        foreach ($PingRecord in $PingView) {
            if ($PingRecord.IPAddress -as [ipaddress] -And $PingRecord.DNSStatus -eq 'NoData') {
                $Ping = [System.Net.NetworkInformation.Ping]::new()
                $PingReply = $Ping.Send($PingRecord.IPAddress) | Select-Object -Property Status,RoundtripTime
            } elseif ($PingRecord.DNSStatus -eq 'Valid') {
                try {
                    $Ping = [System.Net.NetworkInformation.Ping]::new()
                    $PingReply = $Ping.Send($PingRecord.IPAddress) | Select-Object -Property Status,RoundtripTime
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
            switch ($PSCmdlet.ParameterSetName) {
                'Start' {
                    switch ($PingReply.Status) {
                        'NA' {
                            $Success = 'NA'
                            $Failure = 'NA'
                            $Attempts = 'NA'
                            $LastPingTime = 'NA'
                        }
                        'Success' {
                            $Success = 1
                            $Failure = 0
                            $Attempts = 1
                            $LastPingTime = Get-Date -Format G
                        }
                        default {
                            $Success = 0
                            $Failure = 1
                            $Attempts = 1
                            $LastPingTime = Get-Date -Format G
                        }
                    }
                }
                'Continue' {
                    switch ($PingReply.Status) {
                        'NA' {
                            $Success = 'NA'
                            $Failure = 'NA'
                            $Attempts = 'NA'
                            $LastPingTime = 'NA'
                        }
                        'Success' {
                            $Success = $PingRecord.Success + 1
                            $Failure = $PingRecord.Failure
                            $Attempts = $PingRecord.Attempts + 1
                            $LastPingTime = Get-Date -Format G
                        }
                        default {
                            $Success = $PingRecord.Success
                            $Failure = $PingRecord.Failure + 1
                            $Attempts = $PingRecord.Attempts + 1
                            $LastPingTime = Get-Date -Format G
                        }
                    }
                }
            }

            [PsCustomObject]@{
                Id = $PingRecord.Id
                HostName = $PingRecord.HostName
                IPAddress = $PingRecord.IPAddress
                DNSStatus = $PingRecord.DNSStatus
                Status = $PingReply.Status
                RoundtripTime = $PingReply.RoundtripTime
                Success = $Success
                Failure = $Failure
                Attempts = $Attempts
                LastPingTime = $LastPingTime
            }
        }
    }
}
#endregion Invoke-PingView

#region Write-PingView
function Write-PingView {
    [CmdLetBinding()]
    param(
        [string]$OutFile,
        [object]$PingView
    )
    try {
        if (-Not (Test-Path -Path  $OutFile)) {
            [void](New-Item -Path $OutFile -ItemType File -Force)

        }
        $PingView | Export-Csv -Path $OutFile -Append -NoTypeInformation
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
#endregion Write-PingView

# ----------------------------------------------------------------------------------------------------------------------
# being main script
# ----------------------------------------------------------------------------------------------------------------------

switch ($PSCmdlet.ParameterSetName) {
    'File' {
        if ($InputFile) {
            if (Test-Path -Path $InputFile) {
                $Script:FilePath = Get-ChildItem -Path $InputFile
                $ComputerName = Get-Content -Path $InputFile
            } else {
                $ComputerName = $null
            }
        } else {
            $ComputerName = $null
        }
    }
    'Array' {
        if ($ComputerName -isnot [array]) {
            if ($ComputerName -match ',') {
                $ComputerName = $ComputerName -split ','
            }
            if ($ComputerName -match ';') {
                $ComputerName = $ComputerName -split ';'
            }
        }
    }

}

$RowHighlight = @{
    'Cell' = 'Status'
    'Values' = @{
        'NA' = 'LightGray'
        'Failure' = 'Red'
        'Success' = 'White'
        'Default' = 'Red'
    }
}

#region event scriptblocks
$CloseButton_OnClick = [scriptblock]::Create({
    $PingViewer.Close()
})

$RefreshButton_OnClick = [scriptblock]::Create({
    if ($Script:PingView) {
        $StatusStrip = Set-StatusStrip -StatusStrip $StatusStrip -Operation 'Process:' -Progress 'Refreshing ping data'
        $PingViewer.Refresh()
        Start-Sleep -Seconds 1

        $Script:PingView = $PingView | Invoke-PingView -Continue
        if ($Script:FilePath) {
            $StatusStrip = Set-StatusStrip -StatusStrip $StatusStrip -Operation 'Input File:' -Progress $Script:Progress
        } elseif ($ComputerName) {
            $StatusStrip = Set-StatusStrip -StatusStrip $StatusStrip -Operation 'Hostnames Provided:' -Progress $ComputerName.Count
        }
        $DataGridView = Update-DataGridView -Data $PingView -DataGridView $DataGridView -RowHighlight $RowHighlight
        $PingViewer.Refresh()
    } else {
        $StatusStrip = Set-StatusStrip -StatusStrip $StatusStrip -Operation 'Nothing to refresh'
        $PingViewer.Refresh()
    }
})

$ResetCounters_OnClick = [scriptblock]::Create({
    if ($Script:PingView) {
        $StatusStrip = Set-StatusStrip -StatusStrip $StatusStrip -Operation 'Process:' -Progress 'Resetting status counters'
        $PingViewer.Refresh()
        Start-Sleep -Seconds 1

        $StatusStrip = Set-StatusStrip -StatusStrip $StatusStrip -Operation 'Process:' -Progress 'Pinging systems'
        $PingViewer.Refresh()
        Start-Sleep -Seconds 1

        $Script:PingView = $Script:OriginalPingView | Invoke-PingView
        if ($Script:FilePath) {
            $StatusStrip = Set-StatusStrip -StatusStrip $StatusStrip -Operation 'Input File:' -Progress $Script:Progress
        } elseif ($ComputerName) {
            $StatusStrip = Set-StatusStrip -StatusStrip $StatusStrip -Operation 'Hostnames Provided:' -Progress $ComputerName.Count
        }
        $DataGridView = Update-DataGridView -Data $PingView -DataGridView $DataGridView -RowHighlight $RowHighlight
        $PingViewer.Refresh()
    } else {
        $StatusStrip = Set-StatusStrip -StatusStrip $StatusStrip  -Operation 'No counters to reset'
        $PingViewer.Refresh()
    }
})

$LoadFile_OnClick = [scriptblock]::Create({
    $Script:FilePath = Get-FileName -StartingFolder $PSScriptRoot -Filter 'Text files or CSV files|*.txt;*.csv'
    if ($FilePath.FileName) {
        $StatusStrip = Set-StatusStrip -StatusStrip $StatusStrip -Operation 'Opening File:' -Progress $FilePath.FileName
        $PingViewer.Refresh()
        Start-Sleep -Seconds 1

        $ComputerName = Get-Content -Path $FilePath.FileName
        $Script:Progress = $FilePath.FileName + ' (' + $ComputerName.Count + ' systems)'
        $StatusStrip = Set-StatusStrip -StatusStrip $StatusStrip -Operation 'Process:' -Progress 'Resolving host names'
        $PingViewer.Refresh()

        $DnsHostName = Resolve-DNSHostName -ComputerName $ComputerName
        $StatusStrip = Set-StatusStrip -StatusStrip $StatusStrip -Operation 'Process:' -Progress 'Pinging systems'
        $PingViewer.Refresh()
        Start-Sleep -Seconds 1

        $Script:PingView = $DnsHostName | Invoke-PingView
        $Script:OriginalPingView = $PingView
        $StatusStrip = Set-StatusStrip -StatusStrip $StatusStrip -Operation 'Input File:' -Progress $Script:Progress
        $DataGridView = Update-DataGridView -Data $PingView -DataGridView $DataGridView -RowHighlight $RowHighlight
        $PingViewer.Refresh()
    } else {
        $StatusStrip = Set-StatusStrip -StatusStrip $StatusStrip -Operation 'No file selected'
        $PingViewer.Refresh()
    }
})

$Form_OnLoad = [scriptblock]::Create({
    $PingViewer.Refresh()
    if ($ComputerName) {
        if ($PSCmdlet.ParameterSetName -eq 'File') {
            $ComputerName = Get-Content -Path $Script:FilePath.FullName
            $Script:Progress = $FilePath.FullName + ' (' + $ComputerName.Count + ' systems)'
            $StatusStrip = Set-StatusStrip -StatusStrip $StatusStrip -Operation 'Loading File:' -Progress $FilePath.FullName
        } else {
            $Script:Progress = $ComputerName.Count
            $StatusStrip = Set-StatusStrip -StatusStrip $StatusStrip -Operation 'Hostnames Provided:' -Progress $ComputerName.Count
        }
        $PingViewer.Refresh()
        Start-Sleep -Seconds 1

        $StatusStrip = Set-StatusStrip -StatusStrip $StatusStrip -Operation 'Process:' -Progress 'Resolving host names'
        $PingViewer.Refresh()
        Start-Sleep -Seconds 1

        $DnsHostName = Resolve-DNSHostName -ComputerName $ComputerName
        $StatusStrip = Set-StatusStrip -StatusStrip $StatusStrip -Operation 'Process:' -Progress 'Pinging systems'
        $PingViewer.Refresh()
        Start-Sleep -Seconds 1

        $Script:PingView = $DnsHostName | Invoke-PingView
        $script:OriginalPingView = $PingView
        if ($FilePath) {
            $StatusStrip = Set-StatusStrip -StatusStrip $StatusStrip -Operation 'Input File:' -Progress $($FilePath.FullName + ' (' + $ComputerName.Count + ' systems)')
        } elseif ($ComputerName) {
            $StatusStrip = Set-StatusStrip -StatusStrip $StatusStrip -Operation 'Hostnames Provided:' -Progress $ComputerName.Count
        }
        $DataGridView = Update-DataGridView -Data $PingView -DataGridView $DataGridView -RowHighlight $RowHighlight
        $PingViewer.Refresh()
    }
})
#endregion event script blocks

# build form
$PingViewer = New-WindowsForm -Name 'Ping Viewer' -Width 810 -Height 410 -NoIcon

# assign header label
$FormLabel = New-FormLabel -Name "HostName: $($env:COMPUTERNAME)" -Index 0 -Width 300 -Height 30 -DrawX 5 -DrawY 15

# add buttons
$Buttons = @()
$Buttons += New-FormButton -Name 'Refresh'       -Index 1 -Width 100 -Height 25 -DrawX 5  -DrawY 50 -Action $RefreshButton_OnClick
$Buttons += New-FormButton -Name 'LoadFile'      -Index 2 -Width 100 -Height 25 -DrawX 110 -DrawY 50 -Action $LoadFile_OnClick
$Buttons += New-FormButton -Name 'ResetCounters' -Index 3 -Width 130 -Height 25 -DrawX 215 -DrawY 50 -Action $ResetCounters_OnClick
$Buttons += New-FormButton -Name 'Close'         -Index 4 -Width 100 -Height 25 -DrawX 700 -DrawY 50 -Action $CloseButton_OnClick    -Anchor 'Right,Top'

# add data
$DataGridView = New-DataGridView -Name 'PingViewer' -Index 5 -Width 800 -Height 300 -DrawX 5 -DrawY 80 -Anchor 'Left,Top,Right,Bottom'

# create status strip/bar
$StatusStrip = New-StatusStrip

# update form
$PingViewerParams = @{
    WindowsForm   = $PingViewer
    FormLabel     = $FormLabel
    FormButton    = $Buttons
    DataGridView  = $DataGridView
    StatusStrip   = $StatusStrip
    OnLoad        = $Form_OnLoad
}
$PingViewer = Set-WindowsForm @PingViewerParams

[void]$PingViewer.ShowDialog()


<#
Things to Do:

1. Header font not italicized, Bold?
2. Display label on data load or refresh
3> statusbar?


#$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState
#$InitialFormWindowState = $PingViewer.WindowState


<#
$RefreshTimer = [System.Windows.Forms.Timer]::new()
$RefreshTimer.Interval = $WaitTime * 1000
$RefreshTimer.Add_Tick({
    Invoke-PingViewRefresh
})

$handler_Output_Click={
    Add-Type -AssemblyName System.Windows.Forms
    $SaveAs1 = New-Object System.Windows.Forms.SaveFileDialog
    $SaveAs1.Filter = "CSV Files (*.csv)|*.csv|Text Files (*.txt)|*.txt|Excel Worksheet (*.xls)|*.xls|All Files (*.*)|*.*"
    $SaveAs1.SupportMultiDottedExtensions = $true;
    $SaveAs1.InitialDirectory = "C:\temp\"

    if($SaveAs1.ShowDialog() -eq 'Ok'){
        $User = Get-Aduser $textBox1.Text -Properties DisplayName,sAMAccountName,EmailAddress,Mobile,Company,Title,Enabled,LockedOut,Description,Created,Modified,LastLogonDate,AccountExpirationDate,AccountLockoutTime,BadLogonCount,CannotChangePassword,LastBadPasswordAttempt,PasswordLastSet,PasswordExpired,LogonWorkstations,CanonicalName | Select DisplayName,sAMAccountName,EmailAddress,Mobile,Company,Title,Enabled,LockedOut,Description,Created,Modified,LastLogonDate,AccountExpirationDate,AccountLockoutTime,BadLogonCount,CannotChangePassword,LastBadPasswordAttempt,PasswordLastSet,PasswordExpired,LogonWorkstations,CanonicalName | Export-CSV $($SaveAs1.filename) -NoTypeInformation ';' -Encoding UTF8
        $richTextBox1.Text = "A file $($SaveAs1.filename) has been created based on the user: $($textBox1.Text)"
    }
}
#>
function Get-DiskSpace {
    [CmdLetBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string[]]$ComputerName=$env:COMPUTERNAME,
        [string[]]$DriveLetter
    )

    begin {
        if ($DriveLetter) {
            $DriveLetter = foreach ($Drive in $DriveLetter) {
                if ($Drive -match '^[A-Za-z]$') {
                    '{0}:' -f $Drive
                } elseif ($Drive -match '^[A-Za-z]:$') {
                    $Drive
                }
            }
        }

        enum DriveType {
            Unknown         = 0
            NoRootDirectory = 1
            RemovableDisk   = 2
            LocalDisk       = 3
            NetworkDrive    = 4
            OpticalDisk     = 5
            RamDisk         = 6
        }

        $CIMInstanceParams = @{
            ClassName = 'Win32_LogicalDisk'
            ErrorAction = 'Stop'
            Verbose = $false
        }

        $DiskSpaceFormat = @{l='ComputerName';e={$_.SystemName}},
            @{l='DeviceId';e={$_.DeviceID}},
            @{l='DriveType';e={[enum]::GetName([DriveType],$_.DriveType)}},
            @{l='VolumeName';e={$_.VolumeName}},
            @{l='Size';e={ '{0:N2} GB' -f ($_.Size / 1GB )}},
            @{l='FreeSpace';e={'{0:N2} GB' -f ($_.FreeSpace / 1GB )}},
            @{l='FreeSpacePercent';e={'{0:N2} %' -f ($_.FreeSpace / $_.Size * 100 )}}
    }

    process {

        foreach ($Computer in $ComputerName) {
            if ($Computer -ne $env:COMPUTERNAME) {
                $CIMInstanceParams.Add('ComputerName',$Computer)
            }
            try {
                if ($DriveLetter) {
                    Get-CimInstance @CIMInstanceParams |
                        Where-Object { $_.DeviceID -in $DriveLetter } |
                        Select-Object $DiskSpaceFormat
                } else {
                    Get-CimInstance @CIMInstanceParams |
                        Select-Object $DiskSpaceFormat
                }

            }
            catch {
                [PsCustomObject]@{
                    ComputerName = $Computer
                    DeviceId = $null
                    DriveType = $null
                    VolumeName = $null
                    Size = $null
                    FreeSpace = $null
                    FreeSpacePercent = $null
                }
            }
            if ($Computer -ne $env:COMPUTERNAME) {
                $CIMInstanceParams.Remove('ComputerName')
            }
        }
    }
    end {

    }
}
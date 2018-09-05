# Get a list of current sysinternals
function Get-Sysinternals {
    [CmdLetBinding()]
    param(
        [string]$InstallLocation
    )

    if ($InstallLocation) {
        Get-ChildItem -Path $InstallLocation | Select-Object -Property Name,Length,LastWriteTime,@{l='Updated';e={Get-Date $_.LastWriteTime -Format d}}

    } else {
        $SysinternalsLiveUrl = 'https://live.sysinternals.com'
        Write-Verbose -Message "Getting list of current Sysinternals tools from $SysinternalsLiveUrl"
        try {
            $SysinternalsLive = Invoke-WebRequest -Uri $SysinternalsLiveUrl
        }
        catch {
            Write-Warning -Message "Unable to get list of current Sysinternals tools from $SysinternalsLiveUrl"
            $PSCmdlet.ThrowTerminatingError($_)
        }
        $SysinternalsList = ($SysinternalsLive.Content -Split('<br>')).Where({$_ -notmatch '<pre|pre>|&lt;dir&gt;'})

        foreach ($File in $SysinternalsList) {
            $LineParts = $File.Trim().Split(' ')
            $LineParts[-1] -match '>(.*?\..*?)<' | Out-Null
            $LastWriteTime = [datetime]($LineParts[0..9] -join ' ').trim()

            [PSCustomObject]@{
                Name = $Matches[1]
                Length = (($LineParts | Select-Object -Skip 10) -join ' ').Trim().Split(' ')[0]
                LastWriteTime = $LastWriteTime
                Updated = Get-Date $LastWriteTime -Format d
            }
        }
    }
}

function Update-Sysinternals {
    [CmdLetBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$InstallLocation,
        [switch]$Force,
        [switch]$IgnoreDownloadErrors
    )

    $DownloadErrorsPath = Join-Path -Path $InstallLocation -ChildPath 'DownloadErrors.json'
    $DownloadErrors = @()

    if (-Not (Test-Path -Path $InstallLocation)) {
        Write-Output "The path $InstallLocation does not exist."
        $Response = Read-Host -Prompt "Do you want to create it? (Y/N)"
        if ($Response -ne 'Y') {
            Write-Warning -Message 'Install location does not exist. Cannot save sysinternals.'
            exit
        } else {
            try {
                New-Item -Path $InstallLocation -Force -Type Directory | Out-Null
                Write-Verbose -Message "$InstallLocation successfully created."
            }
            catch {
                Write-Warning -Message 'Unable to create the install location.'
                exit 1
            }
        }
    }

    if (-Not $IgnoreDownloadErrors) {
        Write-Verbose -Message 'Checking for previous download errors.'
        $SkipFiles = Get-Content -Path $DownloadErrorsPath -ErrorAction SilentlyContinue | ConvertFrom-Json
    }

    Write-Verbose -Message 'Getting current Sysinternals file list.'
    try {
        $Sysinternals = Get-Sysinternals -Verbose:$false
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }

    Write-Verbose -Message 'Getting local Sysinternals file list.'
    $LocalFiles = Get-Sysinternals -InstallLocation $InstallLocation

    if ($Force) {
        Write-Verbose -Message 'Force switch used, downloading all files.'
        $DownloadFiles = $Sysinternals
    } elseif ($LocalFiles) {
        Write-Verbose -Message 'Checking if local files are up-to-date.'
        $DownloadFiles = Compare-Object -Property Updated -ReferenceObject $LocalFiles -DifferenceObject $Sysinternals -PassThru | Where-Object {$_.SideIndicator -eq '=>'}
    } else {
        Write-Verbose -Message "Path $InstallLocation is empty, downloading all files."
        $DownloadFiles = $Sysinternals
    }

    if ($SkipFiles) {
        Write-Verbose -Message "Skipping the following files:"
        Write-Verbose -Message ("`n" + ($SkipFiles | Format-Table -AutoSize | Out-String).Trim())
        $DownloadFiles = $DownloadFiles | Where-Object {$SkipFiles.Name -notcontains $_.Name}
    }

    $OriginalProgressPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'

    Write-Verbose -Message 'Downloading newer Sysinternals tools.'
    $Count = 0
    foreach ($Tool in $DownloadFiles) {

        Write-Output "Downloading $($Tool.Name)"
        $Uri = 'https://live.sysinternals.com/tools/' + $Tool.Name
        $OutFile = Join-Path -Path $InstallLocation -ChildPath $Tool.Name

        try {
            Invoke-WebRequest -Uri $Uri -OutFile $OutFile -Verbose:$false

            Write-Verbose -Message "Setting LastWriteTime for $($Tool.Name) to $($Tool.LastWriteTime)"
            $UpdateLastWriteTime = Get-ChildItem -Path $OutFile
            $UpdateLastWriteTime.LastWriteTime = $Tool.LastWriteTime
            $Count++
        }
        catch {
            if (-Not $IgnoreDownloadErrors) {
                Write-Warning -Message "Unable to download $($Tool.Name)"
                $DownloadErrors += $Tool
            }
        }
    }
    $ProgressPreference = $OriginalProgressPreference

    if ($DownloadErrors) {
        Write-Warning -Message "Download errors occurred."
        $Response = Read-Host -Prompt "Do you want to ignore these files next time? (Y/N)"

        if ($Response -eq 'Y') {
            $DownloadFiles | Select-Object -Property Name,Length,LastWriteTime,Updated | ConvertTo-Json |
                Out-File -FilePath $DownloadErrorsPath -Force
        }
    }

    Write-Output ''
    Write-Output "Downloaded $Count Sysinternals tools"

    if ($Count -gt 0) {
        Write-Output ''
        if ($env:Path -notlike "*$InstallLocation*") {
            Write-Output "The path $InstallLocation is not included in the system PATH variable."
            $Response = Read-Host -Prompt "Would you like to update the system PATH variable? (Y/N)"
            if ($Response -eq 'Y') {
                try {
                    [Environment]::SetEnvironmentVariable( "Path", $env:Path + ";$InstallLocation", [System.EnvironmentVariableTarget]::Machine )
                }
                catch {
                    Write-Warning -Message 'Error setting PATH system variable. Please update it manually.'
                }
            }
        }
    }

    Write-Output ''
}


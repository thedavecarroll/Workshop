# Get a list of current sysinternals
function Get-Sysinternals {
    [CmdLetBinding()]
    param()

    $SysinternalsLive = Invoke-WebRequest -Uri 'https://live.sysinternals.com'
    $SysinternalsList = $SysinternalsLive.Content.Split('<br>').Where({$_ -notmatch '<pre|pre>|&lt;dir&gt;'})

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

function Sync-Sysinternals {
    [CmdLetBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$InstallLocation,
        [switch]$Force
    )

    if (-Not (Test-Path -Path $InstallLocation)) {
        Write-Output "The path $InstallLocation does not exist."
        $Response = Read-Host -Prompt "Do you want to create it? (Y/N)"
        if ($Response -ne 'Y') {
            Write-Output 'Install location does not exist. Cannot save sysinternals.'
            exit
        } else {
            try {
                New-Item -Path $InstallLocation -Force -Type Directory | Out-Null
                Write-Verbose -Message "$InstallLocation successfully created."
            }
            catch {
                Write-Output 'Unable to create the install location.'
                exit 1
            }
        }
    }

    Write-Verbose -Message 'Getting current Sysinternals file list.'
    $Sysinternals = Get-Sysinternals -Verbose:$false

    Write-Verbose -Message 'Getting local sysinternal file list.'
    $LocalFiles = Get-ChildItem -Path $InstallLocation | Select-Object -Property Name,Length,LastWriteTime,@{l='Updated';e={Get-Date $_.LastWriteTime -Format d}}

    if ($Force) {
        Write-Verbose -Message 'Force switch used, downloading all files.'
        $DownloadFiles = $Sysinternals
    } elseif ($LocalFiles) {
        Write-Verbose -Message 'Checking if local files are up-to-date.'
        $DownloadFiles = Compare-Object -Property Updated -ReferenceObject $LocalFiles -DifferenceObject $Sysinternals -PassThru | Where-Object {$_.SideIndicator -eq '=>'}
    }

    $OriginalProgressPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'

    Write-Verbose -Message 'Downloading newer Sysinternals tools.'
    foreach ($Tool in $DownloadFiles) {

        Write-Verbose -Message "Downloading $($Tool.Name)"
        $Uri = 'https://live.sysinternals.com/tools/' + $Tool.Name
        $OutFile = Join-Path -Path $InstallLocation -ChildPath $Tool.Name

        try {
            Invoke-WebRequest -Uri $Uri -OutFile $OutFile -Verbose:$false

            Write-Verbose -Message "Setting LastWriteTime for $($Tool.Name) to $($Tool.LastWriteTime)"
            $UpdateLastWriteTime = Get-ChildItem -Path $OutFile
            $UpdateLastWriteTime.LastWriteTime = $Tool.LastWriteTime
        }
        catch {
            Write-Warning -Message "Unable to download $($Tool.Name)"
        }
    }
    $ProgressPreference = $OriginalProgressPreference
}


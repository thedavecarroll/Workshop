function Start-ProcessWithOutput {
    [CmdLetBinding()]
    param(
        [string]$Path,
        [string[]]$Arguments,
        [int]$Timeout
    )

    #https://stackoverflow.com/questions/11531068/powershell-capturing-standard-out-and-error-with-process-object

    'Attempting to create process start info' | Write-Verbose
    try {
        $ProcessStartInfo = [System.Diagnostics.ProcessStartInfo]::new()
        $ProcessStartInfo.CreateNoWindow = $true
        $ProcessStartInfo.LoadUserProfile = $false
        $ProcessStartInfo.FileName = $Path
        $ProcessStartInfo.RedirectStandardOutput = $true
        $ProcessStartInfo.RedirectStandardError = $true
        $ProcessStartInfo.UseShellExecute = $false
        if ($Arguments.Count -gt 0) {
            $ProcessStartInfo.Arguments = $Arguments
        }
        'Successfully created process start info' | Write-Verbose
        $ProcessString = '{0} {1}' -f $ProcessStartInfo.FileName,$ProcessStartInfo.Arguments
        'Process: {0}' -f $ProcessString | Write-Verbose
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }

    $StandardOutput = [System.Text.StringBuilder]::new()
    $StandardError = [System.Text.StringBuilder]::new()

    try {
        $Process = [System.Diagnostics.Process]::new()
        $Process.StartInfo = $ProcessStartInfo

        $TimeoutReached = $null

        'Attempting to create process' | Write-Verbose
        [void]$Process.Start()

        'Waiting for process to exit or timeout' | Write-Verbose
        while (!$Process.HasExited) {
            if ($Timeout) {
                if ($Process.StartTime -le (Get-Date).AddSeconds(-$Timeout)) {
                    try { [void]$Process.Kill() }
                    catch {}
                    [void]$Process.Refresh()
                    break
                }
            }
            if (!$Process.StandardOutput.EndOfStream) {
                [void]$StandardOutput.AppendLine($Process.StandardOutput.ReadLine())
            }
            if (!$Process.StandardError.EndOfStream) {
                [void]$StandardError.AppendLine($Process.StandardError.ReadLine())
            }
            Start-Sleep -Milliseconds 10
        }
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }

    'Process completed' | Write-Verbose

    if ($Timeout) {
        if ($Process.StartTime -le (Get-Date).AddSeconds(-$Timeout)) {
            $TimeoutReached = $true
            [void]$StandardError.AppendLine('Process terminated due exceeded timeout')
            'Timeout of {0} seconds exceeded' -f $Timeout | Write-Verbose
        } else {
            $TimeoutReached = $false
            'Timeout of {0} seconds not exceeded' -f $Timeout | Write-Verbose
        }
    }

    while (!$Process.StandardOutput.EndOfStream) {
        [void]$StandardOutput.AppendLine($Process.StandardOutput.ReadLine())
    }
    while (!$Process.StandardError.EndOfStream) {
        [void]$StandardError.AppendLine($Process.StandardError.ReadLine())
    }

    [PsCustomObject]@{
        Process = $ProcessString
        Output = $StandardOutput.ToString()
        #Error = if ($StandardError.ToString() -ne '') { $StandardError.ToString() } else { $null }
        Error = $StandardError.ToString()
        StartTime = $Process.StartTime
        ExitTime = $Process.ExitTime
        ElapsedTime = New-TimeSpan -Start $Process.StartTime -End $Process.ExitTime
        TimeoutReached = $TimeoutReached
        ExitCode = $Process.ExitCode
        TheProcess = $Process
    }
}

#Start-ProcessWithOutput -Path ping -Arguments 'www.google.com','-t' -Timeout 60 -Verbose
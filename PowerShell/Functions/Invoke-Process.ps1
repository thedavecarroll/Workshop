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

    'Attempting to create process' | Write-Verbose
    try {
        $Process = [System.Diagnostics.Process]::new()
        $Process.StartInfo = $ProcessStartInfo
        'Creating process' | Write-Verbose
        [void]$Process.Start()

        'Waiting for idle input' | Write-Verbose
        [void]$Process.WaitForInputIdle()

        if ($Timeout) {
            $TimeoutReached = $false
            do {
                if (!$Process.StandardOutput.EndOfStream) {
                    [void]$StandardOutput.AppendLine($Process.StandardOutput.ReadLine())
                }
                if (!$Process.StandardError.EndOfStream) {
                    [void]$StandardError.AppendLine($Process.StandardError.ReadLine())
                }
                Start-Sleep -Milliseconds 5

                if ((Get-Date) -lt $Process.StartTime.AddSeconds($Timeout)) {
                    [void]$Process.Kill
                }
            } until ($Process.WaitForExit())

            if ((Get-Date) -lt $Process.StartTime.AddSeconds($Timeout)) {
                $TimeoutReached = $true
                [void]$StandardError.AppendLine('Killed process')
            }

        } else {
            do {
                if (!$Process.StandardOutput.EndOfStream) {
                    [void]$StandardOutput.AppendLine($Process.StandardOutput.ReadLine())
                }
                if (!$Process.StandardError.EndOfStream) {
                    [void]$StandardError.AppendLine($Process.StandardError.ReadLine())
                }
                Start-Sleep -Milliseconds 5

            } until ($Process.HasExited)
        }
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }

    'Process completed' | Write-Verbose

    if ($Timeout -and $TimeoutReached) {
        'Timeout of {0} seconds reached' -f $Timeout | Write-Verbose
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
        Error = if ($StandardError.ToString() -ne '') { $StandardError.ToString() } else { $null }
        StartTime = $Process.StartTime
        ExitTime = $Process.ExitTime
        ElapsedTime = New-TimeSpan -Start $Process.StartTime -End $Process.ExitTime
        TimeoutReached = $TimeoutReached
        ExitCode = $Process.ExitCode
        TheProcess = $Process
    }
}

#Start-ProcessWithOutput -Path ping -Arguments 'www.google.com','-t' -Timeout 60 -Verbose
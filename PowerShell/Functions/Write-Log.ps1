function Write-Log {
    [Alias('log')]
    [CmdletBinding()]
    Param(
        [Parameter()]
        [ValidateSet("INFO","WARN","ERROR","FATAL","DEBUG","HAF")]
        [String]$Level = 'INFO',
        [Parameter(ValueFromPipeline=$true,Mandatory=$True)]
        [string]$Message,
        [Parameter()]
        [string]$Logfile,
        [Parameter()]
        [switch]$PassThru,
        [Parameter()]
        [switch]$Force
    )

    begin {

        # We want the -Force parameter to create the file, regardless of the value of the WhatIfPreference variable.
        $OriginalWhatIfPreference = $WhatIfPreference
        $WhatIfPreference = $false

        $TimeStamp = Get-Date -Format s

        #region Out-ColorConsole
        #http://blogs.microsoft.co.il/scriptfanatic/2007/09/01/colorize-matching-output-in-the-pipeline/
        function Out-ColorConsole {
            param(
                [Parameter()]
                [string]$Color,
                [Parameter(ValueFromPipeline)]
                [string]$Line
            )

            if ($Host.Name -notmatch 'ISE') {
                $ForegroundColor = [System.Console]::ForegroundColor
                try {
                    [void][System.ConsoleColor]::$Color
                    [System.Console]::ForegroundColor = $Color
                }
                catch {
                    Write-Verbose -Message "$Color is not a valid color"
                }
            }

            Write-Output $Line

            if ($Host.Name -notmatch 'ISE') {
                if ([System.Console]::ForegroundColor -ne $ForegroundColor) {
                    [System.Console]::ForegroundColor = $ForegroundColor
                }
            }
            #endregion Out-ColorConsole
        }
    }

    process {

        if ($Logfile) {
            if (-Not (Test-Path -Path $Logfile -ErrorAction SilentlyContinue)) {
                if ($PSBoundParameters.ContainsKey('Force')) {
                    try {
                        $LogfileExists = New-Item -Path $Logfile -ItemType File -Force -ErrorAction Stop
                        Write-Verbose -Message "Created the logfile - $Logfile"
                    }
                    catch {
                        $LogfileExists = $false
                        Write-Warning -Message "Unable to create the logfile - $Logfile"
                        Write-Warning -Message ($_.CategoryInfo.Reason + ': '  + $_.Exception.Message)
                    }
                } else {
                    $LogfileExists = $false
                    Write-Warning -Message "The -Force switch was not used, therefore the log file, $Logfile,  will not be created."
                }
            } else {
                $LogfileExists = $true
            }
        }

        if ($Level -eq 'HAF'){
            $Line = $Message
        } else {
            $Line = "$TimeStamp : " + [string]::Format("{0,-5}",$Level) + " : " + $Message
        }

        if ($PSBoundParameters.ContainsKey('PassThru')) {
            switch -regex ($Level) {
                'WARN'        { Out-ColorConsole -Line $Line -Color 'Yellow' }
                'ERROR|FATAL' { Out-ColorConsole -Line $Line -Color 'Red' }
                'DEBUG'       { Out-ColorConsole -Line $Line -Color 'Magenta' }
                default       { Write-Output $Line }
            }
        }

        if ($LogfileExists) {
            try {
                Out-File -InputObject $Line -FilePath $Logfile -Append
            }
            catch {
                Write-Warning "Unable to write log $Logfile"
                Write-Warning ($_.CategoryInfo.Reason + ': ' + $_.Exception.Message)
            }
        }
    }

    end {
        $WhatIfPreference = $OriginalWhatIfPreference
    }
}

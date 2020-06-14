function ConvertFrom-DcDiagOutput {
    [CmdletBinding()]
    param($DcDiagOutput)

    $SplitDiag = $DcDiagOutput -Split 'doing primary tests'

    if ($SplitDiag[0] -match '(?:Testing server: )(\w+|\w+-)\\(\w+)') {
        $ComputerName = $Matches[2]
        $SiteName = $Matches[1]
    }

    if ($SplitDiag[0] -match '(?:(failed|passed) test)') {
        $Connectivity = $Matches[1].ToUpper()
    }

    $TestResults = $SplitDiag[1] -split 'starting test: ' | Select-Object -Skip 1

    $TestDetails = '(?!\w+)([\s\S]+)(?:(failed:passed) test)(\w+)'
    $TestEvents = '((?s).*)(?:\n\s*\.+ ([\w+.]*|[\w+]*))\s*$'
    $Event = '(?:\n+)\s*\w+'
    $StartOfEvent = '\s{9}(A \w+ event|Error|\[)'

    $DcDiagObject = foreach ($Result in $TestResults) {
        if ($Result -match $TestDetails) {
            $TestName = $Matches[3]
            $Status = $Matches[2].ToUpper()
            $Info = $Matches[1]

            if ($Info -like '*warning*') {
                $Status += ' WARNING'
            }
            $TestTarget = $Details = $null
            if ($Info -match $TestEvents) {
                $TestTarget = $Matches[2]
                $Details = $Matches[1]
                if ($Details -notmatch $Events) {
                    $Details = [string]::Empty
                } else {
                    $Lines = $Details -Split '\n'
                    $Details = for ($Counter = 0; $Counter -le $Lines.Count; $Counter++) {
                        if ($Lines[$Counter] -match $StartOfEvent) {
                            $Message = $Lines[$Counter].Trim()
                        } elseif ($Lines[$Counter+1] -match $StartOfEvent) {
                            $Message
                        } else {
                            if ($null -ne $Lines[$Counter]) {
                                $Message += ' ' + $Lines[$Counter].Trim()
                            }
                        }
                        if (($Counter + 1) -gt $Lines.Count) {
                            $Message
                        }
                    }
                }
            }

            if ($TestName -match 'LocatorCheck|Intersite|FsmoCheck') {
                $TestType = 'Enterprise'
            } elseif ($TestName -match 'CheckSDRefDom|CrossRefValidation') {
                $TestType = 'Partition'
            } else {
                $TestType = 'DomainController'
            }

            [PSCustomObject]@{
                TestName = $TestName
                Status = $Status
                TestType = $TestType
                TestTarget = $TestTarget
                Details = $Details
            }
        }
    }

    [PSCustomObject]@{
        ComputerName = $ComputerName
        SiteName = $SiteName
        Connectivity = $Connectivity
        DcDiagTests = $DcDiagObject
        DcDiagRaw = $DcDiagOutput
    }
}
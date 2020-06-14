function Test-MarkdownFileLinks7 {
    [CmdLetBinding()]
    param(
        [ValidateScript({Test-Path -Path $_})]
        [string[]]$MarkdownFile,
        [uri[]]$SkipUri,
        [switch]$ShowProgress
    )

    begin {

        $FileCount = 1
        $FoundLink = 'Found one ore more links on line {0}'
    }

    process {

        foreach ($Markdown in $MarkdownFile) {

            $File = Get-ChildItem -Path $Markdown
            $Content = Get-Content -path $File.FullName
            $LineCount = 1

            $Content | ForEach-Object -Parallel {
                if ($using:LineCount -eq 1) { $LineCount = 1 }


                $InlineLink = '(?:]\()(?<Inline>\S+\w)(?:\))'
                $InlineWithTitleLink = '(?:]\()(?<InlineWithTitle>\S+\w)'
                $ReferenceLink ='(?:\S+\]:\s*)(?<Reference>\S+)'
                $AngleBracketLink = '(<(?<AngleBracket>\S+)>)'
                $RelativeLink = '^(?!www\.|(?:http|ftp)s?://|[A-Za-z]:\\|//|\\\\).*'
                $RawLink = '(?:(?:https?|ftp):\/\/)(?:\S+(?::\S*)?@)?(?:(?!10(?:\.\d{1,3}){3})(?!127(?:\.\d{1,3}){3})(?!169\.254(?:\.\d{1,3}){2})(?!192\.168(?:\.\d{1,3}){2})(?!172\.(?:1[6-9]|2\d|3[0-1])(?:\.\d{1,3}){2})(?:[1-9]\d?|1\d\d|2[01]\d|22[0-3])(?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}(?:\.(?:[1-9]\d?|1\d\d|2[0-4]\d|25[0-4]))|(?:(?:[a-z\x{00a1}-\x{ffff}0-9]+-?)*[a-z\x{00a1}-\x{ffff}0-9]+)(?:\.(?:[a-z\x{00a1}-\x{ffff}0-9]+-?)*[a-z\x{00a1}-\x{ffff}0-9]+)*(?:\.(?:[a-z\x{00a1}-\x{ffff}]{2,})))(?::\d{2,5})?(?:\/[^\s]*)?'

                #foreach ($Line in $Content) {

                if ($using:ShowProgress) {
                    $ProgressParams = @{
                        Activity = 'Checking Links'
                        Status = '{0} - {1}/{2}' -f $using:File.Name,$using:FileCount,$using:MarkdownFile.Count
                        CurrentOperation = 'Line {0}/{1}' -f $LineCount,$using:Content.Count

                    }
                    Write-Progress @ProgressParams
                }
                if ($_ -match "$InlineLink|$InlineWithTitleLink|$ReferenceLink|$AngleBracketLink") {
                    $FoundLink -f $LineCount | Write-Verbose

                    foreach ($MatchUrl in $Matches) {
                        $StatusCode = $null

                        if ($MatchUrl['Inline']) {
                            $LinkType = 'Inline'
                        } elseif ($MatchUrl['InlineWithTitle']) {
                            $LinkType = 'InlineWithTitle'
                        } elseif ($MatchUrl['Reference']) {
                            $LinkType = 'Reference'
                        } elseif ($MatchUrl['AngleBracket']) {
                            $LinkType = 'AngleBracket'
                        }

                        $Url = $MatchUrl[$LinkType]
                        if ($Url -match $RelativeLink) {
                            $LinkType = 'Relative'
                            $StatusCode = 'Skipped'
                        }

                        if ($SkipUri.AbsoluteUri -contains $Url) {
                            $StatusCode = 'Skipped'
                        }

                        if ($StatusCode -ne 'Skipped') {
                            try {
                                $OriginalProgress = $ProgressPreference
                                $ProgressPreference = 'SilentlyContinue'
                                $StatusCode = (Invoke-WebRequest -Uri $Url -Verbose:$false).StatusCode
                                $ProgressPreference = $OriginalProgress
                            }
                            catch {
                                $StatusCode = $_.Exception.Message
                            }
                        }

                        [PsCustomObject]@{
                            Name = $using:File.Name
                            FullName = $using:File.FullName
                            LineNumber = $LineCount
                            Line = $_
                            Url = $Url
                            LinkType = $LinkType
                            StatusCode = $StatusCode
                        }

                    }
                }
                <# elseif ($_ -match $RawLink) {
                    $FoundLink -f $LineCount | Write-Verbose

                    foreach ($MatchUrl in $Matches) {
                        $StatusCode = $null

                        if ($MatchUrl['Raw']) {
                            $LinkType = 'Raw'
                        }

                        $Url = $MatchUrl[$LinkType]
                        if ($Url -match $RelativeLink) {
                            $LinkType = 'Relative'
                            $StatusCode = 'Skipped'
                        }

                        if ($SkipUri.AbsoluteUri -contains $Url) {
                            $StatusCode = 'Skipped'
                        }

                        if ($StatusCode -ne 'Skipped') {
                            try {
                                $OriginalProgress = $ProgressPreference
                                $ProgressPreference = 'SilentlyContinue'
                                $StatusCode = (Invoke-WebRequest -Uri $Url -Verbose:$false).StatusCode
                                $ProgressPreference = $OriginalProgress
                            }
                            catch {
                                $StatusCode = $_.Exception.Message
                            }
                        }

                        [PsCustomObject]@{
                            Name = $using:File.Name
                            FullName = $using:File.FullName
                            LineNumber = $LineCount
                            Line = $_
                            Url = $Url
                            LinkType = $LinkType
                            StatusCode = $StatusCode
                        }
                    }
                } #>
                $LineCount++
            }
            $FileCount++
        }
    }

    end {

    }
}


function Test-MarkdownFileLinks {
    [CmdLetBinding()]
    param(
        [ValidateScript({Test-Path -Path $_})]
        [string[]]$MarkdownFile,
        [uri[]]$SkipUri,
        [switch]$ShowProgress
    )

    begin {

        $InlineLink = '(?:]\()(?<Inline>\S+\w)(?:\))'
        $InlineWithTitleLink = '(?:]\()(?<InlineWithTitle>\S+\w)'
        $ReferenceLink ='(?:\S+\]:\s*)(?<Reference>\S+)'
        #$AngleBracketLink = '(<(?<AngleBracket>\S+)>)'
        $AngleBracketLink = '(<(?<AngleBracket>((http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)))>)'
        #$RelativeLink = '^(?!www\.|(?:http|ftp)s?://|[A-Za-z]:\\|//|\\\\).*'
        $RelativeLink = '(?:\((?<Relative>\/\S+|\.+\/\S+)\))'
        $RawLink = '^(http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)$'
        $HtmlComment = '<!-- .* -->'

        $BigMatch = '(?:]\()(^\((\/\S+|\.+\/\S+)\))(?<Inline>\S+\w)(?:\))|(?:]\()(^\((\/\S+|\.+\/\S+)\))(?<InlineWithTitle>\S+\w)|(?:\S+\]:\s*)(?<Reference>\S+)|(?:\((?<Relative>\/\S+|\.+\/\S+)\))|(?:(?<Raw>(http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)))|(<(?<AngleBracket>((http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)))>)'

        $FileCount = 1
    }

    process {

        foreach ($Markdown in $MarkdownFile) {
            $LineCount = 1
            $File = Get-ChildItem -Path $Markdown
            $Content = Get-Content -path $File.FullName
            $LinkCount = 0
            foreach ($Line in $Content) {
                if ($ShowProgress) {
                    $ProgressParams = @{
                        Activity = 'Checking Links'
                        Status = '{0} - {1}/{2}' -f $File.Name,$FileCount,$MarkdownFile.Count
                        CurrentOperation = 'Line {0}/{1}' -f $LineCount,$Content.Count
                    }
                    Write-Progress @ProgressParams
                }
                if ($Line -match "$InlineLink|$InlineWithTitleLink|$ReferenceLink|$AngleBracketLink|$RelativeLink") {
                    'Found one or more links on line {0}' -f $LineCount | Write-Verbose

                    foreach ($MatchUrl in $Matches) {
                        $StatusCode = $null

                        if ($MatchUrl['RelativeLink']) {
                            $LinkType = 'RelativeLink'
                            $StatusCode = 'Skipped'
                        } elseif ($MatchUrl['Inline']) {
                            $LinkType = 'Inline'
                        } elseif ($MatchUrl['InlineWithTitle']) {
                            $LinkType = 'InlineWithTitle'
                        } elseif ($MatchUrl['Reference']) {
                            $LinkType = 'Reference'
                        } elseif ($MatchUrl['AngleBracket']) {
                            $LinkType = 'AngleBracket'
                        }

                        $Url = $MatchUrl[$LinkType]
                        if ($Url -match $RelativeLink) {
                            $LinkType = 'Relative'
                            $StatusCode = 'Skipped'
                        }
                        if ($Url -match $AngleBracketLink -and $Url -notmatch $RawLink) {
                            continue
                        }

                        if ($SkipUri.AbsoluteUri -contains $Url) {
                            $StatusCode = 'Skipped'
                        }

                        if ($StatusCode -ne 'Skipped') {
                            try {
                                $OriginalProgress = $ProgressPreference
                                $ProgressPreference = 'SilentlyContinue'
                                $StatusCode = (Invoke-WebRequest -Uri $Url -Verbose:$false).StatusCode
                                $ProgressPreference = $OriginalProgress
                            }
                            catch {
                                $StatusCode = $_.Exception.Message
                            }
                        }

                        [PsCustomObject]@{
                            Name = $File.Name
                            FullName = $File.FullName
                            LineNumber = $LineCount
                            Line = $Line
                            Url = $Url
                            LinkType = $LinkType
                            StatusCode = $StatusCode
                        }
                        $LinkCount++
                    }
                }

                foreach ($Word in $Line.Split(' ')) {
                    if ($Word -match $RawLink.ToString() -and $Line -notmatch $ReferenceLink -and $Line -notmatch $HtmlComment) {
                        'Found one ore more links by word on line {0}' -f $LineCount | Write-Verbose

                        foreach ($MatchUrl in $Matches) {
                            $StatusCode = $null
                            $LinkCount++
                            $Url = $Word
                            $LinkType = 'RawUrl'

                            if ($SkipUri.AbsoluteUri -contains $Url) {
                                $StatusCode = 'Skipped'
                            }

                            if ($StatusCode -ne 'Skipped') {
                                try {
                                    $OriginalProgress = $ProgressPreference
                                    $ProgressPreference = 'SilentlyContinue'
                                    $StatusCode = (Invoke-WebRequest -Uri $Url -Verbose:$false).StatusCode
                                    $ProgressPreference = $OriginalProgress
                                }
                                catch {
                                    $StatusCode = $_.Exception.Message
                                }
                            }

                            [PsCustomObject]@{
                                Name = $File.Name
                                FullName = $File.FullName
                                LineNumber = $LineCount
                                Line = $Line
                                Url = $Url
                                LinkType = $LinkType
                                StatusCode = $StatusCode
                            }
                        }
                    }
                }
                $LineCount++
            }
            'Found {0} links in {1}' -f $LinkCount,$File.FullName | Write-Verbose
            $FileCount++
        }
    }

    end {

    }
}


function Test-MarkdownFileLinksNew {
    [CmdLetBinding()]
    param(
        [ValidateScript({Test-Path -Path $_})]
        [string[]]$MarkdownFile,
        [uri[]]$SkipUri,
        [switch]$ShowProgress
    )

    begin {

        $InlineLink = '(?:]\s*\(\s*)(?<Inline>(http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*))(?:\s*\)\s*)'
        $InlineWithTitleLink = '(?:]\s*\(\s*)(?<InlineWithTitle>\S+)(?:\s*(?:"|'').*\)\s*)'
        $AngleBracketLink = '(<(?<AngleBracket>((http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)))>)'
        $RelativeLink = '(?:]\s*\((?<Relative>\/\S+|\.+\/\S+|\w+\/\S+)\))'
        $ReferenceLink = '(?:\S+\]:\s*<?\s*)(?<Reference>(http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*))(?<!>)'
        $RawLink = '(?<Url>(http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*))'
        #$InlineLink = '(?:\(\s*)(?<Inline>\S+)(?:\s*\))'
        #$InlineLink = '(?:]\s*\(\s*)(?<Inline>\S+)(?:\s*\)\s*)'

        #$InlineWithTitleLink = '(?:]\(\s*)(?<InlineWithTitle>\S+) (.+\))'

        #$RelativeLink = '(?:\((?<Relative>\/\S+|\.+\/\S+|\w+\/\S+)\))'

        #$ReferenceLink = '(?:\S+\]:\s*<?\s*)(?<Reference>\S+)(?<!>)'

        #$RawLink = '^(?!(]:\s))(http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)$'
        #$RawLink = '(http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)'



# inline and inline with title
# search for anyting between parentheses

        $FileCount = 1
    }

    process {

        foreach ($Markdown in $MarkdownFile) {
            $LineCount = 1
            $File = Get-ChildItem -Path $Markdown
            $Content = Get-Content -path $File.FullName
            $LinkCount = 0
            foreach ($Line in $Content) {
                if ($ShowProgress) {
                    $ProgressParams = @{
                        Activity = 'Checking Links'
                        Status = '{0} - {1}/{2}' -f $File.Name,$FileCount,$MarkdownFile.Count
                        CurrentOperation = 'Line {0}/{1}' -f $LineCount,$Content.Count
                    }
                    Write-Progress @ProgressParams
                }


                if ($Line -match "$InlineLink|$InlineWithTitleLink|$ReferenceLink|$AngleBracketLink|$RelativeLink") {
                    'Found one or more links on line {0}' -f $LineCount | Write-Verbose

                foreach ($Word in $Line.Split(' ')) {
                    $Url = $LinkType = $StatusCode = $null

                    if ($Word -match $RelativeLink) {
                        $LinkType = 'Relative'
                        [uri]$Url = $Matches['Relative']
                        $StatusCode = 'Skipped'
                    } elseif ($Word -match $AngleBracketLink) {
                        $LinkType = 'AngleBracket'
                        [uri]$Url = $Matches['AngleBracket']
                    } elseif ($Word -match $InlineLink) {
                        $LinkType = 'Inline'
                        [uri]$Url = $Matches['Inline']
                    } elseif ($Word -match $InlineWithTitleLink) {
                        $LinkType = 'InlineWithTitle'
                        [uri]$Url = $Matches['InlineWithTitle']
                    } elseif ($Word -match $RawLink) {
                        [uri]$Url = $Word
                        if ($null -eq $Url.AbsoluteUri) {
                            continue
                        }
                        $Location = $Line.IndexOf($Word)
                        if ($Line[$Location - 2] -eq ':') {
                            $LinkType = 'Reference'
                        } else {
                            $LinkType = 'RawUrl'
                        }
                    }
                    if ($null -eq $Url.AbsoluteUri) {
                        $StatusCode = 'Skipped'
                    }

                    try {
                        if ($SkipUri.AbsoluteUri -match $Url.AbsoluteUri -or $Url.Host -eq 'localhost') {
                            $StatusCode = 'Skipped'
                        }
                    }
                    catch {
                        'File {0} : Line {1} : URL {2} : LinkType {3}' -f $File.Name,$LineCount,$url,$LinkType | Write-Warning
                    }

                    if ($StatusCode -ne 'Skipped') {
                        try {
                            $OriginalProgress = $ProgressPreference
                            $ProgressPreference = 'SilentlyContinue'
                            $StatusCode = (Invoke-WebRequest -Uri $Url -Verbose:$false).StatusCode
                            $ProgressPreference = $OriginalProgress
                        }
                        catch {
                            $StatusCode = $_.Exception.Message
                        }
                    }

                    $LinkCount++

                    [PsCustomObject]@{
                        Name = $File.Name
                        FullName = $File.FullName
                        LineNumber = $LineCount
                        Line = $Line
                        Url = $Url
                        LinkType = $LinkType
                        StatusCode = $StatusCode
                    }
                }}
                $LineCount++
            }
            'Found {0} links in {1}' -f $LinkCount,$File.FullName | Write-Verbose
            $FileCount++
        }
    }

    end {

    }
}

function Test-MarkdownFileLinks{
    [CmdLetBinding()]
    param(
        [ValidateScript({Test-Path -Path $_})]
        [string[]]$MarkdownFile,
        [uri[]]$SkipUri,
        [switch]$ShowProgress
    )

    begin {

        $InlineLink = '(?:]\s*\(\s*)(?<Inline>(http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*))(?:\s*\)\s*)'
        $InlineWithTitleLink = '(?:]\s*\(\s*)(?<InlineWithTitle>\S+)(?:\s+(?:"|'').*\)\s*)'
        $AngleBracketLink = '(<(?<AngleBracket>((http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)))>)'
        $RelativeLink = '(?:]\s*\((?<Relative>\/\S+|\.+\/\S+|\w+\/\S+)\))'
        $ReferenceLink = '(?:\S+\]:\s*<?\s*)(?<Reference>(http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*))(?<!>)'
        $EmailAddress = '^[a-zA-Z0-9.!#$%&''*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$'
        $FileCount = 1
    }

    process {

        foreach ($Markdown in $MarkdownFile) {

            $LinkCount = $InlineCount = $InlineWithTitleCount = $AngleBracketCount = $ReferenceCount = $RelativeCount = 0

            $File = Get-ChildItem -Path $Markdown

            if ($ShowProgress) {
                $ProgressParams = @{
                    Activity = 'Checking Links'
                    Status = '{0} - {1}/{2}' -f $File.Name,$FileCount,$MarkdownFile.Count
                }
                Write-Progress @ProgressParams
            }

            $Content = Get-Content -Path $File.FullName -Raw
            $ContentLines = Get-Content -Path $File.FullName

            # Create a regex object with all of the link type regexes
            $LinkRegex = [regex]::new("$InlineLink|$InlineWithTitleLink|$ReferenceLink|$AngleBracketLink|$RelativeLink")

            # Match the regex against the entire file
            $LinkMatches = $LinkRegex.Matches($Content)

            foreach ($Link in $LinkMatches) {
                $StatusCode = $null

                # The Groups[0] is the full match of a given regex, which is a large portion of text that can be used to find the line
                $LinkGroup = $Link.Where{$_.Captures}.Groups[0].Groups[0].Value.Trim()

                # Find the line where the link occurs
                $LineCount = 1
                foreach ($Line in $ContentLines) {
                    if ($Line | Select-String $LinkGroup -SimpleMatch -Quiet) {
                        $LineNumber = $LineCount
                    }
                    $LineCount++
                }

                $LinkMatch = $Link.Where{$_.Captures}.Groups[0].Groups.Where{$_.Name -match 'Inline|Angle|Rel|Ref' -and $_.Success -eq $true}

                # Only continue processing for named groups from regex for each link type
                if ($null -eq $LinkMatch.Name) {
                    continue
                }

                # The AngleBracket regex also grabs email addresses, so we need to ignore those.
                if ($LinkMatch.Name -eq 'AngleBracket' -and $LinkMatch.Value -match $EmailAddress) {
                    continue
                }

                # Relative links cannot be validated.
                if ($LinkMatch.Name -eq 'Relative') {
                    $StatusCode = 'Skipped'
                }

                # Skip any Url with host of localhost
                if (([Uri]$LinkMatch.Value).Host -eq 'localhost') {
                    $StatusCode = 'Skipped'
                }

                # Test the Url
                if ($StatusCode -ne 'Skipped') {
                    try {
                        $OriginalProgress = $ProgressPreference
                        $ProgressPreference = 'SilentlyContinue'
                        $StatusCode = (Invoke-WebRequest -Uri $LinkMatch.Value -Verbose:$false).StatusCode
                        $ProgressPreference = $OriginalProgress
                    }
                    catch {
                        $StatusCode = $_.Exception.Message
                    }
                }

                # Output the result to the pipeline
                [PsCustomObject]@{
                    Name = $File.Name
                    FullName = $File.FullName
                    LineNumber = $LineNumber
                    Line = $ContentLines[$LineNumber-1]
                    LinkType = $LinkMatch.Name
                    Url = $LinkMatch.Value
                    StatusCode = $StatusCode
                }

                # Increment counters
                $LinkCount++
                switch ($LinkMatch.Name) {
                    'Inline' { $InlineCount++ }
                    'InlineWithTitle' { $InlineWithTitleCount++ }
                    'AngleBracket' { $AngleBracketCount++ }
                    'Reference' { $ReferenceCount++ }
                    'Relative' { $RelativeCount++ }
                }
            }
            'Found {0} links in {1}' -f $LinkCount,$File.FullName | Write-Verbose
            $LinkTypeCount = 'Inline({0}) : InlineWithTitle({1}) : AngleBracket({2}) : Reference({3}) : Relative({4})' -f $InlineCount,$InlineWithTitleCount,$AngleBracketCount,$ReferenceCount,$RelativeCount
            $LinkTypeCount | Write-Verbose
            $FileCount++
        }
    }

    end {

    }
}
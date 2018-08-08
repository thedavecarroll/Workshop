function Get-PSGalleryModuleStatistics {
    [CmdLetBinding()]
    param($Name)

    # http://www.leeholmes.com/blog/2015/01/05/extracting-tables-from-powershells-invoke-webrequest/

    $Uri = 'https://www.powershellgallery.com/packages/' + $Name
    $WebRequest = Invoke-WebRequest -Uri $Uri

    $tables = @($WebRequest.ParsedHtml.getElementsByTagName("table"))
    $versionTable = $tables[1]
    $titles = @()
    $rows = @($versionTable.rows)

    $TotalDownloads = 0

    foreach ($row in $rows) {
        $cells = @($row.Cells)
        if($cells[0].tagName -eq "th") {
            $titles = @($cells | ForEach-Object { ("" + $_.InnerText).Replace(' ','').Trim() })
            continue
        }
        if (-not $titles) {
            $titles = @(1..($cells.Count + 2) | ForEach-Object { "P$_" })
        }
        $resultObject = [Ordered] @{}
        for($counter = 0; $counter -lt $cells.Count; $counter++)  {
            $title = $titles[$counter]
            if (-not $title) { continue }

            $Text = ("" + $cells[$counter].InnerText).Trim()

            if ($Text -as [datetime]) {
                [datetime]$DateText = $Text
                $Text = $DateText.ToShortDateString()
            }
            if ($title -eq 'Downloads') {
                $TotalDownloads += ($Text -as [int])
            }
            $resultObject[$title] = $Text
        }
        [PSCustomObject] $resultObject
    }
    Write-Information -MessageData ' ' -InformationAction Continue
    Write-Information -MessageData ('Total Downloads: ' + "{0:N0}" -f $TotalDownloads) -Tags Downloads -InformationAction Continue
    Write-Information -MessageData ' ' -InformationAction Continue
}

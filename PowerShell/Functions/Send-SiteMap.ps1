function Send-SiteMap {
    [CmdLetBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({$_ -match '\/.+?.xml$'})]
        [uri]$Uri,
        [switch]$ShowEncodedUrl
    )

    begin {
        # add [System.Web] assembly, primarily for Windows PowerShell
        try {
            Add-Type -AssemblyName System.Web -ErrorAction Stop
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }

        $SiteMapPing = @(
            [PsCustomObject]@{
                Name = 'Google Webmaster Tools'
                PingUrl = 'http://www.google.com/webmasters/tools/ping?sitemap={0}'
            },
            [PsCustomObject]@{
                Name = 'Bing Webmaster Tools'
                PingUrl = 'http://www.bing.com/ping?siteMap={0}'
            }
        )
    }

    process {

        # ensure encoding by attempting to decode url, then encode
        $Url = [System.Web.HttpUtility]::UrlDecode($Uri)
        $Url = [System.Web.HttpUtility]::UrlEncode($Url)

        if ($ShowEncodedUrl) {
            '{0} : {1} URL : {2}' -f (Get-Date -Format s),'Original',$Url
            '{0} : {1} URL : {2}' -f (Get-Date -Format s),'Encoded',$Url
        }

        foreach ($SEO in $SiteMapPing) {
            $PingUrl = $SEO.PingUrl -f $Url
            'Submitting sitemap to {0} using url {1}' -f $SEO.Name,$PingUrl | Write-Verbose

            $PingResult = Invoke-WebRequest -Uri $PingUrl -Verbose:$false
            if ($PingResult.StatusCode -eq 200) {
                '{0} : SUCCESS : {1} : {2}' -f (Get-Date -Format s),$SEO.Name,'You have successfully submitted your sitemap.'
            } else {
                '{0} : FAILURE : {1} : {2}' -f (Get-Date -Format s),$SEO.Name,'An error occurred trying to submit your sitemap.'
            }
        }
    }

    end {

    }


}
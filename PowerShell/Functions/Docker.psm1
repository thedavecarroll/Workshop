function Get-DockerImages {
    [CmdLetBinding(DefaultParameterSetName='Default')]
    param(
        [ValidateNotNullOrEmpty()]
        [string]$Repo,
        [ValidateNotNullOrEmpty()]
        [string[]]$Filter,
        [switch]$All,
        [switch]$Digests,
        [switch]$NoTrunc,
        [Parameter(ParameterSetName='Quiet')]
        [switch]$Quiet,
        [Parameter(ParameterSetName='Default')]
        [switch]$Full
    )

    try {
        Get-Command -Name docker | Out-Null
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }

    $Command = [System.Text.StringBuilder]::new()
    [void]$Command.Append('docker images')

    if ($All) {
        [void]$Command.Append(' --all')
    }
    if ($Digests) {
        [void]$Command.Append(' --digests')
    }
    if ($NoTrunc) {
        [void]$Command.Append(' --no-trunc')
    }
    if ($Filter) {
        foreach ($MyFilter in $Filter) {
            [void]$Command.Append(' --filter={0}' -f $MyFilter.ToLower())
        }
    }

    if ($Quiet) {
        [void]$Command.Append(' --quiet')
    }

    if ($Full) {
        [void]$Command.Append(' --format "{{.Repository}},{{.Tag}},{{.Digest}},{{.ID}},{{.CreatedSince}},{{.CreatedAt}},{{.Size}}"')
        $CsvHeader = 'Repository','Tag','Digest','Id','Created','CreatedAt','Size'
    } elseif ($Digests) {
        [void]$Command.Append(' --format "{{.Repository}},{{.Tag}},{{.Digest}},{{.ID}},{{.CreatedSince}},{{.Size}}"')
        $CsvHeader = 'Repository','Tag','Digest','Id','Created','Size'
    } elseif (!$Quiet) {
        [void]$Command.Append(' --format "{{.Repository}},{{.Tag}},{{.ID}},{{.CreatedSince}},{{.Size}}"')
        $CsvHeader = 'Repository','Tag','Id','Created','Size'
    }

    if ($Repo) {
        [void]$Command.Append(' {0}' -f $Repo.ToLower())
    }

    $Command.ToString() | Write-Verbose
    try {
        if ($Quiet) {
            Invoke-Expression -Command $Command.ToString()
        } else {
            Invoke-Expression -Command $Command.ToString() | ConvertFrom-Csv -Header $CsvHeader
        }
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }

}

function Get-DockerInfo {
    [CmdletBinding()]
    param()
    try {
        Invoke-Expression -Command "docker info --format '{{json .}}'" | ConvertFrom-Json
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}

function Get-DockerInspect {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [Alias('Id')]
        [string]$Name,
        [ValidateSet('container','image','volume','network','node','service','task')]
        [string]$Type
    )

    try {
        if ($Type) {
            docker inspect --type $Type $Name | ConvertFrom-Json
        } else {
            docker inspect $Name | ConvertFrom-Json
        }
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }

}


$FilterHashtable = @{
    dangling = true
    label = com.example.version
    before = $image
    since = $image
    reference = @(
        'busy*:*libc',
        '*:latest'
    )
}


$UpdateDockerImages = @{
    Path = 'function:global:Update-DockerImages'
    Value = {
        try {
            Invoke-Expression -Command 'Get-DockerImages | Where-Object { $_.Tag -ne "<none>"} | ForEach-Object { "-" * 80; "Updating ... {0}:{1}" -f $_.Repository,$_.Tag; docker pull $("{0}:{1}" -f $_.Repository,$_.Tag) }'
        }
        catch {
            Write-Error -ErrorRecord $_
        }
    }
}
New-Item @UpdateDockerImages | Out-Null
New-Alias -Name 'udi' -Value Update-DockerImages

Invoke-Expression -Command 'Get-DockerImages | Where-Object { $_.Tag -ne "<none>"} | ForEach-Object { "-" * 80; "Updating ... {0}:{1}" -f $_.Repository,$_.Tag; docker pull $("{0}:{1}" -f $_.Repository,$_.Tag) }'
$DockerImagesFormat = '{{.Repository}},{{.Tag}},{{.Digest}},{{.ID}},{{.CreatedSince}},{{.CreatedAt}},{{.Size}}'


$GetDockerImages = @{
    Path = 'function:global:Get-DockerImages'
    Value = {
        try {
            Invoke-Expression -Command 'docker images --format "{{.Repository}},{{.Tag}},{{.ID}},{{.CreatedAt}},{{.Size}}" | ConvertFrom-CSV -Header Repository,Tag,ImageId,Created,Size'
        }
        catch {
            Write-Error -ErrorRecord $_
        }
    }
}
New-Item @GetDockerImages | Out-Null
New-Alias -Name 'gdi' -Value Get-DockerImages
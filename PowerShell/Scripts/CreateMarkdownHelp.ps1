[CmdLetBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ModuleName,
    [Parameter(Mandatory)]
    [string]$OutputFolder
)

# verify that platyPS is available
if (Get-Module -ListAvailable -Name platyPS -Verbose:$false) {
    $Version = (Get-Module -Name platyPS -ListAvailable -Verbose:$false).Version.ToString()
    Write-Verbose -Message "Using platyPS version $Version"
} else {
    Write-Warning -Message 'Please install platyPS and try again.'
    exit 1
}

# verify that ModuleName is available
$ModuleCommands = Get-Command -Module $ModuleName
if ($null -eq $ModuleCommands) {
    Write-Warning -Message "Module $ModuleName not found in $env:PSModulePath and is not loaded in the current session."
    Write-Warning -Message 'Please correct this and try again.'
    exit 1
}

# validate output folder
if ((Split-Path -Path $OutputFolder -Leaf) -notmatch $ModuleName) {
    Write-Verbose -Message "Appending $ModuleName to $OutputFolder"
    $OutputFolder = Join-Path -Path $OutputFolder -ChildPath $ModuleName
}

if (-Not (Test-Path -Path $OutputFolder)) {
    try {
        New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
    }
    catch {
        Write-Warning -Message "Unable to create $OutputFolder"
        exit 1
    }
}

foreach ($Command in (Get-Command -Module $ModuleName)) {
    $Link = "modulehelp/$ModuleName/$($Command.Name).html"
    $FrontMatter = @{
        'layout' = 'onlinehelp'
        'search' = 'false'
        'classes' = 'wide'
        'permalink' = "/$Link"
    }

    $OnlineVersionUri = "https://powershell.anovelidea.org/$Link)"

    $NewMarkdownHelpParams = @{
        Command             = $Command
        OutputFolder        = $OutputFolder
        Metadata            = $FrontMatter
        OnlineVersionUrl    = $OnlineVersionUri
        Force               = $true
    }

    New-MarkdownHelp @NewMarkdownHelpParams
}
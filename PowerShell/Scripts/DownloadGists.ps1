[CmdLetBinding()]
param(
    [Uri]$GitHubProfile,
    [hashtable]$Gists
)

foreach ($GistId in $Gists.Keys) {
    $Path = $Gists[$GistId].path
    $FileName = $Gists[$GistId].filename
    $FullPath = Join-Path -Path $Path -ChildPath $FileName

    Write-Output "Downloading $FileName to $Path"
    if (Test-Path -Path $FullPath) {
        Write-Warning -Message "A file with $FileName exists in $Path. Do you want to overwrite it?"
        $Response = Read-Host -Prompt "Y/N"
        if ($Response -eq 'Y') {
            Invoke-WebRequest -Uri "$GitHubProfile/$GistId/raw/$FileName" -OutFile $FullPath
        }
    } else {
        if (-Not (Test-Path -Path $Path)) {
            Write-Output "The path $Path does not exist. Attempting to create."
            try {
                New-Item -Path $Path -Type Directory -Force | Out-Null
            }
            catch {
                Write-Warning -Message "Unable to create $Path."
            }
        }

        if (Test-Path -Path $Path) {
            Invoke-WebRequest -Uri "$GitHubProfile/$GistId/raw/$FileName" -OutFile $FullPath
        } else {
            Write-Warning -Message "Unable to save $FileName to $Path."
        }


    }
   
}
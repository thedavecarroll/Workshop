[CmdLetBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$GitHubRootPath,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$GitHubUserName
)

$GitHubUrl = 'https://github.com'

Install-Module -Name GitHubConnect
Push-Location -Path $GitHubRootPath

$GitHubRepos = Get-GithubPublicRepositories -GitHubUsername $GitHubUserName

foreach ($Repo in $GitHubRepos) {
    $RepoPath = Join-Path -Path $GitHubRootPath -ChildPath $Repo.Name

    if (Test-Path -Path $RepoPath) {
        Write-Output "Repo $($Repo.Name) exists in $GitHubRootPath"
        continue
    } else {
        git clone "$GitHubUrl/$GitHubUserName/$($Repo.Name).git"
    }
}
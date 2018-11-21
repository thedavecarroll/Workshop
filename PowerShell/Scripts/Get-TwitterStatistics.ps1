[CmdLetBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({Test-Path $_})]
    [string]$TwitterCSV,
    [int]$FollowerCount
)

try {
    $HeaderFromAnalytics = Import-CSV -Path $TwitterCSV
    $TextInfo = (Get-Culture).TextInfo
    $NewHeader = $HeaderFromAnalytics[0].PsObject.Properties | Select-Object @{l='Name';e={$TextInfo.ToTitleCase($_.Name.Trim()).Replace(' ','')}} | Select-Object -ExpandProperty Name

    $Analytics = Get-Content -Path $TwitterCSV -Encoding Default | Select-Object -Skip 1 | ConvertFrom-Csv -UseCulture -Header $NewHeader

}
catch {
    Write-Output "The file $TwitterCSV does not appear to be a valid CSV."
    exit
}

foreach ($Tweet in $Analytics) {
    $MeasuredTweet = $Tweet.TweetText | Measure-Object -Word -Character
    Add-Member -InputObject $Tweet -MemberType NoteProperty -Name TweetCharacterLength -Value $MeasuredTweet.Characters -Force
    Add-Member -InputObject $Tweet -MemberType NoteProperty -Name TweetWordLength -Value $MeasuredTweet.Words -Force

    if ($FollowerCount) {
        Add-Member -InputObject $Tweet -MemberType NoteProperty -Name ReachPercentage -Value ($Tweet.Impressions/$FollowerCount)
    }

    $TweetHour = [DateTime]::Parse($Tweet.Time)
}
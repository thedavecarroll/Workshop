$AppsToRemove = '828B5831.HiddenCityMysteryofShadows','Microsoft.MinecraftUWP','king.com.CandyCrushSaga',
    'king.com.CandyCrushSodaSaga','ZhuhaiKingsoftOfficeSoftw.WPSOffice','Microsoft.MicrosoftOfficeHub','Microsoft.MicrosoftSolitaireCollection',
    'Microsoft.OneConnect'

foreach ($Appx in $AppsToRemove) {

    $AppInstalled = Get-AppxPackage $Appx
    if ($AppInstalled) {
        Write-Output "$Appx - package found"

        Write-Output "Attempting to remove package - $Appx"
        $AllUsersApp  = $AppInstalled | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        if ($AllUsersApp) {
            Write-Output "$Appx - successfully removed package from all users"
        } else {
            Write-Output "$Appx - package not installed for all users"
            $UserApp  = $AppInstalled | Remove-AppxPackage -ErrorAction SilentlyContinue
            if ($UserApp) {
                Write-Output "$Appx - successfully removed package from current user"
            } else {
                Write-Output "$Appx - unable to remove package"
            }
        }
    } else {
        Write-Output "$Appx - package not found"
    }
}
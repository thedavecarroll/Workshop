function Import-RDCManagerFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [ValidateScript({Resolve-Path -Path $_ | Test-Path -Path $_})]
        $Path
    )

    function Get-XPath {
        param($Node)
        if ($Node.GetType().Name -ne 'XmlDocument') {
            if ($null -ne $Node.ParentNode) {
                '{0}/{1}' -f (Get-XPath -Node $Node.ParentNode, $Node.properties.Name)
            }
        }
    }

    function ConvertFrom-RDGLogonCredentials {
        param($LogonCredentials)
        if ($null -ne $LogonCredentials) {
            [PsCustomObject]@{
                PSTypeName = 'RemoteDesktopConnectionManager.LogonCredentials'
                ProfileName = $LogonCredentials.profileName.'#text'
                Scope = $LogonCredentials.profileName.scope
                UserName = $LogonCredentials.UserName
                Domain = $LogonCredentials.domain
                Inherit = $LogonCredentials.inherit
            }
        }
    }

    function ConvertFrom-RDGRemoteDesktop {
        param($RemoteDesktop)
        if ($null -ne $RemoteDesktop) {
            [PsCustomObject]@{
                PSTypeName = 'RemoteDesktopConnectionManager.RemoteDesktop'
                Size = $RemoteDesktop.size
                SameSizeAsClientArea = $RemoteDesktop.sameSizeAsClientArea
                FullScreen = $RemoteDesktop.fullScreen
                ColorDepth = $RemoteDesktop.ColorDepth
                Inherit = $RemoteDesktop.inherit
            }
        }
    }

    function ConvertFrom-RDGSecuritySettings {
        param($SecuritySettings)
        if ($null -ne $SecuritySettings) {
            [PsCustomObject]@{
                PSTypeName = 'RemoteDesktopConnectionManager.SecuritySettings'
                Authentication = $SecuritySettings.authentication
                Inherit = $SecuritySettings.inherit
            }
        }
    }

    function ConvertFrom-RDGDisplaySettings {
        param($DisplaySettings)
        if ($null -ne $DisplaySettings) {
            [PsCustomObject]@{
                PSTypeName = 'RemoteDesktopConnectionManager.DisplaySettings'
                LiveThumbnailUpdates = $DisplaySettings.liveThumbnailUpdates
                AllowThumbnailSessionInteraction = $DisplaySettings.allowThumbnailSessionInteraction
                ShowDisconnectedThumbnails = $DisplaySettings.showDisconnectedThumbnails
                ThumbnailScale = $DisplaySettings.thumbnailScale
                SmartSizeDockedWindows = $DisplaySettings.smartSizeDockedWindows
                SmartSizeUndockedWindows = $DisplaySettings.smartSizeUndockedWindows
                Inherit = $DisplaySettings.inherit
            }
        }
    }

    function ConvertFrom-RDGServer {
        param($Server)
        if ($null -ne $Server) {
            [PsCustomObject]@{
                PSTypeName = 'RemoteDesktopConnectionManager.Server'
                ComputerName = $Server.properties.name
                DisplayName = $Server.properties.displayName
                Comment = $Server.properties.comment
                ConnectionType = $Server.properties.connectionType
                VMId = $Server.properties.vmId
                LogonCredentials = ConvertFrom-RDGLogonCredentials -LogonCredentials $Server.logonCredentials
                RemoteDesktop = ConvertFrom-RDGRemoteDesktop -RemoteDesktop $Server.remoteDesktop
                SecuritySettings = ConvertFrom-RDGSecuritySettings -SecuritySettings $Server.securitySettings
                DisplaySettings = ConvertFrom-RDGDisplaySettings -DisplaySettings $Server.displaySettings
                ParentNode = $Server.parentNode.properties.name
                XPath = Get-XPath -Node $Server
                XmlElement = $Server
            }
        }
    }

    function ConvertFrom-RDGGroup {
        param($Group)
        if ($Group.Group) {
            $GroupList = foreach ($GroupItem in $Group.Group) { ConvertFrom-RDGGroup -Group $GroupItem}
        } else {
            $GroupList = $null
        }
        if ($Group.Server) {
            $ServerList = foreach ($ServerItem in $Group.Server) { ConvertFrom-RDGServer -Server $ServerItem}
        } else {
            $ServerList = $null
        }

        [PsCustomObject]@{
            PSTypeName = 'RemoteDesktopConnectionManager.Group'
            Name = $Group.properties.name
            Expanded = $Group.properties.expanded
            Groups = $GroupList
            Servers = $ServerList
            LogonCredentials = ConvertFrom-RDGLogonCredentials -LogonCredentials $Group.logonCredentials
            RemoteDesktop = ConvertFrom-RDGRemoteDesktop -RemoteDesktop $Group.remoteDesktop
            SecuritySettings = ConvertFrom-RDGSecuritySettings -SecuritySettings $Group.securitySettings
            DisplaySettings = ConvertFrom-RDGDisplaySettings -DisplaySettings $Group.displaySettings
            ParentNode = $Group.parentNode.properties.name
            XPath = Get-XPath -Node $Group
            XmlElement = $Group
        }
    }

    $FullPath = (Resolve-Path -Path $Path).Path

    try {
        [xml]$RDGFile = Get-Content -Path $FullPath -Raw
    }
    catch {
        '{0} : does not appear to be a valaid XML file' | Write-Warning
        return
    }

    $RDGDisplayName = $RDGFile.RDCMan.file.properties.name
    $RDGVersion = $RDGFile.RDCMan.programVersion
    $RDGSchemaVersion = $RDGFile.RDCMan.schemaVersion

    $CredentialsProfiles = foreach ($CredentialsProfile in $RDGFile.RDCMan.file.credentialsProfiles.credentialProfile) {
        ConvertFrom-RDGLogonCredentials -LogonCredentials $CredentialsProfile
    }
    $FileCredentials = ConvertFrom-RDGLogonCredentials -LogonCredentials $RDGFile.RDCMan.file.logonCredentials
    $FileRemoteDesktop = ConvertFrom-RDGRemoteDesktop -RemoteDesktop $RDGFile.RDCMan.file.remoteDesktop
    $FileSecuritySettings = ConvertFrom-RDGSecuritySettings -SecuritySettings $RDGFile.RDCMan.file.securitySettings
    $FileDisplaySettings = ConvertFrom-RDGDisplaySettings -DisplaySettings $RDGFile.RDCMan.file.displaySettings

    $Groups = foreach ($Group in $RDGFile.RDCMan.file.group) {
        ConvertFrom-RDGGroup -Group $Group
    }

    [PsCustomObject]@{
        PSTypeName = 'RemoteDesktopConnectionManager.ManagerFile'
        FileName = $FullPath
        DisplayName = $RDGDisplayName
        AppVersion = $RDGVersion
        SchemaVersion = $RDGSchemaVersion
        FileCredentials = $FileCredentials
        FileRemoteDesktop = $FileRemoteDesktop
        FileSecuritySettings = $FileSecuritySettings
        FileDisplaySettings = $FileDisplaySettings
        Groups = $Groups
    }
}
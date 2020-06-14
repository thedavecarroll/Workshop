# Create Home Lab
$LabName = 'HomeLab'
$ALPath = 'D:\{0}\Definitions' -f $LabName
$VMPath = 'D:\{0}\VMS' -f $LabName
$VirtualEngine = 'HyperV'

$DomainName = 'lab.anovelidea.org'
$OSFull = 'Windows Server 2019 Standard Evaluation (Desktop Experience)'
$OSCore = 'Windows Server 2019 Standard Evaluation'

$LabDefinition = @{
    Name = $LabName
    DefaultVirtualizationEngine = $VirtualEngine
    Path = $ALPath
    VmPath = $VMPath
}

$LabNetwork = @{
    Name = '{0}Network' -f $LabName
    AddressSpace = '192.168.100.0/24'
    HyperVProperties = @{SwitchType = 'Internal'}
}

$RootDCRole = Get-LabMachineRoleDefinition -Role 'RootDC' @{
    ForestFunctionalLevel = 'Win2012R2'
    DomainFunctionalLevel = 'Win2012R2'
    SiteName = 'NASH'
    SiteSubnet = '192.168.100.0/24'
}

$FirstDC = @{
    Name = 'DC01'
    OperatingSystem = $OSFull
    Roles = $RootDCRole
    DomainName = $DomainName
}

$MemberServer1 = @{
    Name = 'SERVER01'
    OperatingSystem = $OSCore
    IsDomainJoined = $true
    DomainName = $DomainName
}

New-LabDefinition @LabDefinition
Add-LabVirtualNetworkDefinition @LabNetwork
Add-LabMachineDefinition @FirstDC
Add-LabMachineDefinition @MemberServer1
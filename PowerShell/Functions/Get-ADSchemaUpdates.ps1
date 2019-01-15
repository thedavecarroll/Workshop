function Get-ADSchemaUpdates {
    [CmdLetBinding()]
    param(
        [string]$Server
    )

    if ($Server) {
        try {
            $RootDSE = Get-ADRootDSE -Server $Server
            $Server = $RootDSE.dnsHostName
        }
        catch {
            Write-Warning -Message "Server $Server is not an Active Directory domain controller"
            exit
        }
    } else {
        $RootDSE = Get-ADRootDSE
        $Server = $RootDSE.dnsHostName
    }

    $SchemaParams = @{
        SearchBase = $RootDSE.schemaNamingContext
        SearchScope = 'OneLevel'
        Filter = '*'
        Property = 'objectClass','name','whenChanged','whenCreated'
        Server = $RootDSE.dnsHostName
    }

    #$AllSchemaUpdates = 
    Get-ADObject @SchemaParams | Select-Object -Property objectClass,Name,
        @{name='Created';expression={($_.whenCreated).Date.ToShortDateString()}},
        @{name='Modified';expression={($_.whenChanged).Date.ToShortDateString()}}

#    $ADSchemaUpdates = Get-ADSchemaVersion -Server $Server
#    $ADSchemaExchUpdates = Get-ADSchemaExchVersion -Server $Server
#    $ADSchemaLyncUpdates = Get-ADSchemaLyncVersion -Server $Server


}

function Get-ADSchemaVersion {
    [CmdLetBinding()]
    param(
        [string]$Server
    )
    #https://eightwone.com/references/ad-schema-versions/


    if ($Server) {
        try {
            $Domain = Get-ADDomain -Server $Server
            $RootDSE = Get-ADRootDSE -Server $Server
            $Server = $RootDSE.dnsHostName
        }
        catch {
            Write-Warning -Message "Server $Server is not an Active Directory domain controller"
            exit
        }
    } else {
        $Domain = Get-ADDomain
        $RootDSE = Get-ADRootDSE
        $Server = $RootDSE.dnsHostName
    }

    $ForestObjectVersionParams = @{
        Filter = 'Name -eq "Schema"'
        SearchBase = $RootDSE.SchemaNamingContext
        Property = 'objectVersion'
        Server = $Server
    }

    $ADSchema = Get-ADObject @ForestObjectVersionParams
    $ADSchemaMetadata = Get-ADReplicationAttributeMetadata -Object $ADSchema.DistinguishedName -Server $Server
    $LastUpdate = $ADSchemaMetadata.Where({$_.AttributeName -eq 'objectVersion'})

    switch ($ADSchema.objectVersion) {
        13 { $VersionName = 'Windows Server 2000' }
        30 { $VersionName = 'Windows Server 2003' }
        31 { $VersionName = 'Windows Server 2003 R2' }
        44 { $VersionName = 'Windows Server 2008' }
        47 { $VersionName = 'Windows Server 2008 R2' }
        56 { $VersionName = 'Windows Server 2012' }
        69 { $VersionName = 'Windows Server 2012 R2' }
        87 { $VersionName = 'Windows Server 2016' }
    }

    [PSCustomObject]@{
        SchemaType = 'ActiveDirectory'
        Forest = $Domain.Forest
        Domain = $Domain.DNSRoot
        VersionNumber = $ADSchema.objectVersion
        VersionName = $VersionName
        LastUpdate = Get-Date -Date $LastUpdate.LastOriginatingChangeTime -Format d
    }
}

function Get-ADSchemaExchVersion {
    [CmdLetBinding()]
    param(
        [string]$Server
    )
    #https://eightwone.com/references/schema-versions/

    $ExchSchemaVersions = @{
        '4397-N/A-4406' = '2000 RTM'
        '4406-N/A-4406' = '2000 SP3'
        '6870-6903-6936' = '2003 RTM/SP2'
        '10637-10666-10628' = '2007 RTM'
        '11116-11221-11221' = '2007 SP1'
        '14622-11222-11221' = '2007 SP2'
        '14625-11222-11221' = '2007 SP3'
        '14622-12640-12639' = '2010 RTM'
        '14726-13214-13040' = '2010 SP1'
        '14732-14247-13040' = '2010 SP2'
        '14734-14322-13040' = '2010 SP3'
        '15137-15449-13236' = '2013'
        '15254-15614-13236' = '2013 CU1'
        '15281-15688-13236' = '2013 CU2'
        '15283-15763-13236' = '2013 CU3'
        '15292-15844-13236' = '2013 SP1/CU4'
        '15300-15870-13236' = '2013 CU5'
        '15303-15965-13236' = '2013 CU6'
        '15312-15965-13236' = '2013 CU7-9'
        '15317-16041-13236' = '2016 Preview'
    }

    if ($Server) {
        try {
            $Domain = Get-ADDomain -Server $Server
            $RootDSE = Get-ADRootDSE -Server $Server
            $Server = $RootDSE.dnsHostName
        }
        catch {
            Write-Warning -Message "Server $Server is not an Active Directory domain controller"
            exit
        }
    } else {
        $Domain = Get-ADDomain
        $RootDSE = Get-ADRootDSE
        $Server = $RootDSE.dnsHostName
    }

    $ForestRangeUpperParams = @{
        Filter = "CN -eq 'ms-Exch-Schema-Version-Pt'"
        SearchBase = $RootDSE.SchemaNamingContext
        SearchScope = 'OneLevel'
        Property = 'rangeUpper'
        Server = $Server
    }

    $ExchForestRangeUpper = Get-ADObject @ForestRangeUpperParams
    $ADSchemaMetadata = Get-ADReplicationAttributeMetadata -Object $ExchForestRangeUpper.DistinguishedName -Server $Server
    $ForestRangeUpperLastUpdate = $ADSchemaMetadata.Where({$_.AttributeName -eq 'rangeUpper'}).LastOriginatingChangeTime

    $ForestObjectVersionParams = @{
        Filter = "objectClass -eq 'msExchOrganizationContainer'"
        SearchBase = "CN=Microsoft Exchange,CN=Services,$($RootDSE.configurationNamingContext)"
        SearchScope = 'OneLevel'
        Property = 'objectVersion'
        Server = $Server
    }

    $ExchForestObjectVersion = Get-ADObject @ForestObjectVersionParams
    $ADSchemaMetadata = Get-ADReplicationAttributeMetadata -Object $ExchForestObjectVersion.DistinguishedName -Server $Server
    $ForestObjectVersionLastUpdate = $ADSchemaMetadata.Where({$_.AttributeName -eq 'objectVersion'}).LastOriginatingChangeTime

    $DomainObjectVersionParams = @{
        Filter = "CN -eq 'Microsoft Exchange System Objects'"
        Searchbase = $RootDSE.rootDomainNamingContext
        SearchScope = 'OneLevel'
        Property = 'objectVersion'
        Server = $Server
    }

    $ExchDomainObjectVersion = Get-ADObject @DomainObjectVersionParams
    $ADSchemaMetadata = Get-ADReplicationAttributeMetadata -Object $ExchDomainObjectVersion.DistinguishedName -Server $Server
    $DomainObjectVersionLastUpdate = $ADSchemaMetadata.Where({$_.AttributeName -eq 'objectVersion'}).LastOriginatingChangeTime

    $Key = "$($ExchForestRangeUpper.rangeUpper)-$($ExchForestObjectVersion.objectVersion)-$($ExchDomainObjectVersion.objectVersion)"

    if ($ExchSchemaVersions.ContainsKey( $Key ) ) {
        [PsCustomObject]@{
            SchemaType = 'Exchange'
            Forest = $Domain.Forest
            Domain = $Domain.DNSRoot
            ForestRangeUpperVersion = $ExchForestRangeUpper.rangeUpper
            ForestRangeUpperLastUpdate = Get-Date -Date $ForestRangeUpperLastUpdate -Format d
            ForestObjectVersion = $ExchForestObjectVersion.objectVersion
            ForestObjectVersionLastUpdate = Get-Date -Date $ForestObjectVersionLastUpdate -Format d
            DomainObjectVersion = $ExchDomainObjectVersion.objectVersion
            DomainObjectVersionLastUpdate = Get-Date -Date $DomainObjectVersionLastUpdate -Format d
            VersionNumber = $Key
            VersionName = 'Exchange ' + $ExchSchemaVersions.$Key
        }
    } else {
        [PsCustomObject]@{
            SchemaType = 'Exchange'
            Forest = $Domain.Forest
            Domain = $Domain.DNSRoot
            ForestRangeUpperVersion = $ExchForestRangeUpper.rangeUpper
            ForestRangeUpperLastUpdate = Get-Date -Date $ForestRangeUpperLastUpdate -Format d
            ForestObjectVersion = $ExchForestObjectVersion.objectVersion
            ForestObjectVersionLastUpdate = Get-Date -Date $ForestObjectVersionLastUpdate -Format d
            DomainObjectVersion = $ExchDomainObjectVersion.objectVersion
            DomainObjectVersionLastUpdate = Get-Date -Date $DomainObjectVersionLastUpdate -Format d
            VersionNumber = 'Unknown'
            VersionName = 'Unknown'
        }
    }
}

function Get-ADSchemaLyncVersion {
    [CmdLetBinding()]
    param(
        [string]$Server
    )

    #https://blogs.technet.microsoft.com/heyscriptingguy/2012/01/05/how-to-find-active-directory-schema-update-history-by-using-powershell/

    if ($Server) {
        try {
            $Domain = Get-ADDomain -Server $Server
            $RootDSE = Get-ADRootDSE -Server $Server
            $Server = $RootDSE.dnsHostName
        }
        catch {
            Write-Warning -Message "Server $Server is not an Active Directory domain controller"
            exit
        }
    } else {
        $Domain = Get-ADDomain
        $RootDSE = Get-ADRootDSE
        $Server = $RootDSE.dnsHostName
    }

    $ForestRangeUpperParams = @{
        Filter = "CN -eq 'ms-RTC-SIP-SchemaVersion'"
        SearchBase = $RootDSE.SchemaNamingContext
        SearchScope = 'OneLevel'
        Property = 'rangeUpper'
        Server = $Server
    }

    $ADSchema = Get-ADObject @ForestRangeUpperParams
    $ADSchemaMetadata = Get-ADReplicationAttributeMetadata -Object $ADSchema.DistinguishedName -Server $Server
    $LastUpdate = $ADSchemaMetadata.Where({$_.AttributeName -eq 'rangeUpper'})

    switch ($ADSchema.rangeUpper) {
        1006 { $VersionName = 'OCS 2005'}
        1007 { $VersionName = 'OCS 2007'}
        1008 { $VersionName = 'OCS 2007 R2'}
        1100 { $VersionName = 'Lync 2010'}
        1150 { $VersionName = 'Lync 2013'}
    }

    [PSCustomObject]@{
        SchemaType = 'Lync'
        Forest = $Domain.Forest
        Domain = $Domain.DNSRoot
        VersionNumber = $ADSchema.rangeUpper
        VersionName = $VersionName
        LastUpdate = Get-Date -Date $LastUpdate.LastOriginatingChangeTime -Format d
    }
}



# Get-ADObject -Filter { cn -eq 'System Management' } -SearchBase $RootDSE.defaultNamingContext -server $RootDSE.dnsHostName  -Properties *
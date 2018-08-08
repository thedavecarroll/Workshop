Function New-AttributeID {

    $Prefix="1.2.840.113556.1.8000.2554"
    $GUID=[System.Guid]::NewGuid().ToString()
    $Parts=@()
    $Parts+=[UInt64]::Parse($guid.SubString(0,4),"AllowHexSpecifier")
    $Parts+=[UInt64]::Parse($guid.SubString(4,4),"AllowHexSpecifier")
    $Parts+=[UInt64]::Parse($guid.SubString(9,4),"AllowHexSpecifier")
    $Parts+=[UInt64]::Parse($guid.SubString(14,4),"AllowHexSpecifier")
    $Parts+=[UInt64]::Parse($guid.SubString(19,4),"AllowHexSpecifier")
    $Parts+=[UInt64]::Parse($guid.SubString(24,6),"AllowHexSpecifier")
    $Parts+=[UInt64]::Parse($guid.SubString(30,6),"AllowHexSpecifier")
    $AttributeID=[String]::Format("{0}.{1}.{2}.{3}.{4}.{5}.{6}.{7}",$prefix,$Parts[0],
        $Parts[1],$Parts[2],$Parts[3],$Parts[4],$Parts[5],$Parts[6])

    $AttributeID

}

Function Update-ADUserSchema {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact='High')]
    param(
        [Parameter(Mandatory,ValueFromPipelinebyPropertyName)]
        $Name,
        [Parameter(Mandatory,ValueFromPipelinebyPropertyName)]
        [Alias('Description')]
        $AdminDescription,
        [Alias('SingleValued')]
        [bool]$IsSingleValued=$true,
        [Alias('OID')]
        $AttributeID = (New-AttributeID),
        [ValidateSet('Boolean','Integer','Enumeration','LargeInteger','OID','CaseSensitiveString',
            'CaseInsensitiveString','UTCTimeString','GeneralizedTime')]
        [string]$AttributeType='CaseInsensitiveString',
        [ValidateSet('None','Indexed','IndexedByContainer','ANR','TombstonePreserved','Duplicated')]
        [string[]]$SearchFlags

    )

    BEGIN {

        $SchemaMaster = (Get-ADForest).SchemaMaster
        [int]$oMSyntax = switch ($AttributeType) {
            'Boolean' { 1 }
            'Integer' { 2 }
            'Enumeration' { 10 }
            'LargeInteger' { 65 }
            'OID' { 6 }
            'CaseSensitiveString' { 27 }
            'CaseInsensitiveString' { 20 }
            'UTCTimeString' { 23 }
            'GeneralizedTime' { 24 }
            default { $false }
        }

        $SearchFlagsValue = 0
        foreach ($Flag in $SearchFlags) {
            $FlagValue = switch ($Flag) {
                'None' { 0 }
                'Indexed' { 1 }
                'IndexedByContainer' { 2 }
                'ANR' { 4 }
                'TombstonePreserved' { 8 }
                'Duplicated' { 16 }
            }
            $SearchFlagsValue += $FlagValue
        }

    }

    PROCESS {

        $SchemaPath = (Get-ADRootDSE -Server $SchemaMaster).schemaNamingContext
        $Type = 'attributeSchema'

        $CNName = $Name -creplace '(?<=\w)([A-Z])', '-$1'

        $Attributes = @{
            lDAPDisplayName = $Name
            attributeId = $AttributeID
            oMSyntax = $oMSyntax
            attributeSyntax = "2.5.5.4"
            isSingleValued = $IsSingleValued
            adminDescription = $AdminDescription
            searchflags = $SearchFlagsValue
        }

        Write-Output ''
        Write-Output 'Preparing to create the attribute object with the following attributes:'
        Write-Output ''
        Write-Output $Name
        Write-Output ''
        Write-Output ($Attributes.GetEnumerator() | Sort-Object -Property Name | Out-String -Stream | Select-Object -Skip 3).Trim()
        Write-Output ''

        if ($PSCmdlet.ShouldProcess("$SchemaPath. This cannot be undone",'Active Directory Schema Update')) {

            try {
                New-ADObject -Name $CNName -Type $Type -Path $SchemaPath -Server $SchemaMaster -OtherAttributes $Attributes
            }
            catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }

            try {
                $UserSchema = Get-ADObject -SearchBase $SchemaPath -Filter 'name -eq "user"' -Server $SchemaMaster
                $UserSchema | Set-ADObject -Add @{mayContain = $Name}
            }
            catch {
                $PSCmdlet.ThrowTerminatingError($_)
            }
        }

    }

    END {}

}
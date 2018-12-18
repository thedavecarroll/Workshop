$global:CertStoresRoots = @("CA","AuthRoot","Root")
$global:CertStoresGeneral = @("My","Remote Desktop","Operations Manager","SMS","Web Hosting","SharePoint")
$global:CertStoresAllCommon = @("My","Remote Desktop","Operations Manager","SMS","Web Hosting","SharePoint","CA","AuthRoot","Root")

#region Get-X509Certificate
function Get-X509Certificate {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName="Pfx")]
        [ValidateScript({Test-Path $_})]
        [string]$PfxFile,
        [Parameter(ParameterSetName="Pfx")]
        [string]$PfxPassword=$null,

        [Parameter(ParameterSetName="Local")]
        [ValidateScript({Test-Path $_})]
        [string]$LocalCertificate,

        [Parameter(ParameterSetName="PEM")]
        [string]$PEM,

        [Parameter(ParameterSetName="X509Certificate")]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$X509,

        [Parameter(ParameterSetName="Null")]
        [Switch]$Generate
    )

    Begin {

        $Format =
            [ordered]@{Label="Subject";Expression={$_.Subject.Split(",")[0].Replace("CN=","")}},
            @{Label="DNSNameList";Expression={$_.DNSNameList -join ("`n")}},
            @{Label="Issuer";Expression={$_.Issuer.Split(",")[0].Replace("CN=","")}},
            @{Label="Thumbprint";Expression={$_.Thumbprint}},
            @{Label="NotBefore";Expression={(Get-Date $_.NotBefore -Format "MM/dd/yyy")}},
            @{Label="NotAfter";Expression={(Get-Date $_.Notafter -Format "MM/dd/yyy")}},
            @{Label="SignatureAlgorithm";Expression={$_.SignatureAlgorithm.FriendlyName}},
            @{Label="KeyLength";Expression={$_.PublicKey.Key.KeySize}},
            @{Label="SerialNumber";Expression={$_.SerialNumber}},
            @{Label="EnhancedKeyUsage";Expression={$_.EnhancedKeyUsageList -Join ("`n")}},
            @{Label="ServiceProvider";Expression={$_.PrivateKey.CspKeyContainerInfo.ProviderName}},
            @{Label="HasPrivateKey";Expression={$_.HasPrivateKey}},
            @{Label="Exportable";Expression={$_.PrivateKey.CspKeyContainerInfo.Exportable}},
            @{Label="MachineKeyStore";Expression={$_.PrivateKey.CspKeyContainerInfo.MachineKeyStore}},
            @{Label="UniqueKeyContainerName";Expression={$_.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName}},
            @{Label="Certificate";Expression={$_}},
            @{Label="Path";Expression={$_.Path}}

    }

    Process {
        if ($PSCmdlet.ParameterSetName -eq "Pfx") {
            try {
                $FileName = Get-Item $PfxFile | Select-Object -ExpandProperty FullName
                $X509Certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
                $X509Certificate.Import($PfxFile,$PfxPassword,"PersistKeySet")
                Add-Member -InputObject $X509Certificate -MemberType NoteProperty -Name Path -Value $FileName
                Write-Verbose "Successfully accessed Pfx certificate $PfxFile."
            }
            catch {
                Write-Warning "Error processing $PfxFile. Please check the Pfx certificate password."
                return $false
            }

        } elseif ($PSCmdlet.ParameterSetName -eq "PEM") {
            try {
                $FileName = Get-Item $PEM | Select-Object -ExpandProperty FullName
                $X509Certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
                $X509Certificate.Import($PEM)
                Add-Member -InputObject $X509Certificate -MemberType NoteProperty -Name Path -Value $FileName
                Write-Verbose "Successfully accessed $PEM."
            }
            catch {
                Write-Warning "Error processing $PEM. Ensure that you supply a valid x509 certificate file."
                return $false
            }

        } elseif ($PSCmdlet.ParameterSetName -eq "Local") {
            try {
                $LocalCert = Get-Item $LocalCertificate
                $FileName = $env:COMPUTERNAME + ":" + $LocalCert.PSParentPath.Split(":")[2]
                $X509Certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($LocalCert)
                Add-Member -InputObject $X509Certificate -MemberType NoteProperty -Name Path -Value $FileName
                Write-Verbose "Successfully accessed local certificate with thumbprint $($LocalCert.Thumbprint)."
            }
            catch {
                Write-Warning "Error processing $LocalCertificate."
                return $false
            }

        } elseif ($PSCmdlet.ParameterSetName -eq "X509Certificate") {
            try {
                $X509Certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($X509)
                Add-Member -InputObject $X509Certificate -MemberType NoteProperty -Name Path -Value $FileName
                Write-Verbose "Successfully accessed X509 certificate with thumbprint $($X509.Thumbprint)."
            }
            catch {
                Write-Warning "Error processing $X509."
                return $false
            }
        } elseif ($PSCmdlet.ParameterSetName -eq "Null") {
            $X509Certificate = New-Object PSObject
            Write-Verbose "Generating Null Object."
        }


        $X509Certificate = $X509Certificate | Select-Object $Format

        try {
            $Template = $X509Certificate.Certificate.Extensions | Where-Object {$_.Oid.FriendlyName -match "template"}
            $TemplateName = $Template.Format(1).Split("(")[0].Replace("Template=","")
        }
        catch {
            $TemplateName = $null
        }
        Add-Member -InputObject $X509Certificate -MemberType NoteProperty -Name Template -Value $TemplateName

        try {
            if ((Get-Date $X509Certificate.NotAfter) -lt (Get-Date)) {
                $Expiration = "Expired"
            } elseif ((Get-Date $X509Certificate.NotAfter) -le (Get-Date).AddDays(30)) {
                $Expiration = "30 days"
            } elseif ((Get-Date $X509Certificate.NotAfter) -le (Get-Date).AddDays(60)) {
                $Expiration = "60 days"
            } elseif ((Get-Date $X509Certificate.NotAfter) -le (Get-Date).AddDays(90)) {
                $Expiration = "90 days"
            } elseif ((Get-Date $X509Certificate.NotAfter) -le (Get-Date).AddDays(120)) {
                $Expiration = "120 days"
            } else {
                $Expiration = "Over 120 days"
            }
            Add-Member -InputObject $X509Certificate -MemberType NoteProperty -Name Expiration -Value $Expiration
        }
        catch {
            Add-Member -InputObject $X509Certificate -MemberType NoteProperty -Name Expiration -Value $null
        }
    }

    End {
        return $X509Certificate
    }

}
#endregion Get-X509Certificate

#region Get-X509CertificateStore
function Get-X509CertificateStore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false,Position=0)]
        [string[]]$ComputerName="localhost",

        [Parameter(Mandatory=$false,Position=1)]
        [ValidateScript({$CertStoresAllCommon -contains $_})]
        [string[]]$Store=$CertStoresGeneral
    )

    Begin {
        $X509CertificateStore = @()
        $ComputerCounter = 0
    }

    Process {

        foreach ($Computer in $ComputerName) {
            $ComputerCounter++
            Write-Progress -Id 1 -Activity "Checking certificate stores..." -CurrentOperation "$Computer" -PercentComplete (($ComputerCounter / $ComputerName.count) * 100)

            if (Test-Connection -ComputerName $Computer -Count 1 -Quiet) {
                $CertStoreCounter = 0
                foreach ($CertStore in $Store) {
                    $CertStoreCounter++
                    Write-Progress -Id 2 -ParentId 1 -Activity "Opening Store..." -CurrentOperation "LocalMachine\$CertStore" -PercentComplete ($CertStoreCounter / $Store.count)

                    try {
                        $CertificateStore = New-Object System.Security.Cryptography.X509Certificates.X509Store("\\$Computer\$CertStore","LocalMachine")
                        $CertificateStore.Open("OpenExistingOnly")
                        foreach ($Certificate in $CertificateStore.Certificates) {
                            $X509Certificate = Get-X509Certificate -X509 $Certificate
                            Add-Member -InputObject $X509Certificate -MemberType NoteProperty -Name ComputerName -Value $Computer
                            Add-Member -InputObject $X509Certificate -MemberType NoteProperty -Name Path -Value "LocalMachine\$CertStore" -Force
                            Add-Member -InputObject $X509Certificate -MemberType NoteProperty -Name Status -Value "Success"
                            $X509CertificateStore += $X509Certificate
                        }

                        $CertificateStore.Close()
                    }

                    catch {
                        $X509Certificate = Get-X509Certificate -Generate
                        Add-Member -InputObject $X509Certificate -MemberType NoteProperty -Name ComputerName -Value $Computer
                        Add-Member -InputObject $X509Certificate -MemberType NoteProperty -Name Path -Value "LocalMachine\$CertStore" -Force
                        Add-Member -InputObject $X509Certificate -MemberType NoteProperty -Name Status -Value "Failure - Unable to access"
                        $X509CertificateStore += $X509Certificate
                    }
                }

            } else {
                Write-Warning "Unable to connect to $Computer. Please verify that the system is online and accessible by this process."
                $X509Certificate = Get-X509Certificate -Generate
                Add-Member -InputObject $X509Certificate -MemberType NoteProperty -Name ComputerName -Value $Computer
                Add-Member -InputObject $X509Certificate -MemberType NoteProperty -Name Path -Value "" -Force
                Add-Member -InputObject $X509Certificate -MemberType NoteProperty -Name Status -Value "Failure - Unable to connect"
                $X509CertificateStore += $X509Certificate
            }
        }

    }

    End {
        $X509CertificateStore
    }
}
#endregion Get-X509CertificateStore

#region Search-X509Certificate
function Search-X509Certificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false,Position=0)]
        [string[]]$ComputerName="localhost",

        [Parameter(Mandatory=$false,Position=1)]
        [ValidateScript({$CertStoresAllCommon -contains $_})]
        [string[]]$Store="My",

        [Parameter(Mandatory=$true,Position=2)]
        [ValidateSet("Thumbprint","SerialNumber","Issuer","Subject","Template","HasPrivateKey")]
        [Alias("Search","Attribute")]
        [string]$SearchAttribute,

        [Alias("Item")]
        [string]$SearchItem
    )

    Begin {
        $X509CertificateStore = Get-X509CertificateStore -ComputerName $ComputerName -Store $Store -Verbose:$false
    }

    Process {

        $X509Certificate = $X509CertificateStore | ? { $_.$SearchAttribute -match $SearchItem }
        if ($X509Certificate) {
            if ($X509Certificate.count -ge 1) {
                Write-Verbose "Found $($X509Certificate.count) certificates with '$SearchAttribute' matching '$SearchItem'."
            } else {
                Write-Verbose "Found 1 certificate with '$SearchAttribute' matching '$SearchItem'."
            }
        }
    }

    End {
        $X509Certificate
    }
}
#endregion Search-X509Certificate

#region Remove-X509Certificate
function Remove-X509Certificate {
    [CmdletBinding(
        SupportsShouldProcess=$true,
        ConfirmImpact="High"
    )]
    param(
        [Parameter(Mandatory=$false,Position=0)]
        [string[]]$ComputerName="localhost",

        [Parameter(Mandatory=$true,Position=1)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(Mandatory=$false,Position=2)]
        [ValidateScript({$CertStoresAllCommon -contains $_})]
        [string[]]$Store="My",

        [Parameter(Mandatory=$true,Position=3)]
        [ValidateSet("Thumbprint","SerialNumber","Issuer","Subject","Template")]
        [Alias("Search","Attribute")]
        [string]$SearchAttribute,

        [Parameter(Mandatory=$true,Position=4)]
        [Alias("Item")]
        [string]$SearchItem
    )

    Begin {
        $Remove = $false
        $X509Certificate = Search-X509Certificate -ComputerName $ComputerName -Store $Store -SearchAttribute $SearchAttribute -Item $SearchItem -Verbose:$false

        $ScriptBlock = {
            param (
                [string]$Thumbprint,
                [string]$Store,
                [string]$VerbosePreference
            )
            try {
                Remove-Item -Path "Cert:\$Store\$Thumbprint" -DeleteKey -Verbose
            }
            catch {
                $_
            }
        }

    }

    Process {
        $RemovedCerts = @()
        if ($X509Certificate) {
            foreach ($Certificate in $X509Certificate) {
                $ComputerFqdn = [System.Net.Dns]::GetHostByName($Certificate.ComputerName) | Select-Object -ExpandProperty HostName
                Invoke-Command -ComputerName $ComputerFqdn -ScriptBlock $ScriptBlock -ArgumentList $Certificate.Thumbprint,$Certificate.Path,$VerbosePreference -Credential $Credential -Authentication Credssp -Verbose
                $RemovedCerts += New-Object PSObject -Property ([ordered]@{
                    ComputerName = $Certificate.ComputerName
                    Subject = $Certificate.Subject
                    Issuer = $Certificate.Issuer
                    NotBefore = $Certificate.NotBefore
                    NotAfter = $Certificate.NotAfter
                    Store = $Certificate.Path
                    Thumbprint = $Certificate.Thumbprint
                    SerialNumber = $Certificate.SerialNumber
                })
            }

        } else {
            Write-Warning "Certificate with $SearchAttribute of $SearchItem not found in any provided ComputerName in LocalMachine stores: $($Store -Join (","))"
        }

    }

    End {
        return $RemovedCerts
    }

}
#endregion Remove-X509Certificate
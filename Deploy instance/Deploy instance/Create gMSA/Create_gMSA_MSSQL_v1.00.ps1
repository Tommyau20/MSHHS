# I have used the following website in order to create this script/process.
# https://www.mssqltips.com/sqlservertip/5340/using-group-managed-service-accounts-with-sql-server/
# David Shaw
# 17/02/2020

# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Create variables.
$DNShostname = "METRODC01P.sth.health.qld.gov.au"
$gMSAgroup = "gMSAQCCATsql"
$gMSAgroup_description = “Security group for QCCAT MSSQL servers using the gMSA accounts's (i.e. gMSAsvcQCCATDE)”
$QCCAT_MSSQL_server_01 = “QCCATCL1DDEV01P$” # NOTE: server names must be suffixed with "$".
$QCCAT_MSSQL_server_02 = “QCCATCL1DDEV02P$” # NOTE: server names must be suffixed with "$".
$QCCAT_MSSQL_server_03 = “QCCATDDEV01P$” # NOTE: server names must be suffixed with "$".
$QCCAT_MSSQL_DatabaseEngine_gMSA = "gMSAsvcQCCATDE"
$QCCAT_MSSQL_SQLAgent_gMSA = "gMSAsvcQCCATAG"
$QCCAT_MSSQL_ReportingServices_gMSA = "gMSAsvcQCCATRS"
$QCCAT_MSSQL_AnalysisServices_gMSA = "gMSAsvcQCCATAS"
$QCCAT_MSSQL_IntergrationServices_gMSA = "gMSAsvcQCCATIS"

# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Testing of the existing KDS root key(s).
cls
Get-KdsRootKey -OutVariable output
For ($i = 0;$i -lt $output.keyid.Count; $i++) {
        $result = Test-KdsRootKey -KeyId $out.Keyid[$i]        
        Write-Output ("Test of KdsRootKey " + $out.Keyid[$i]  + " = " + $result)
        }
Pause
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Create the AD security group, which the servers that are a member of, will be allowed to use the associated gMSA accounts for services.
New-ADGroup -Name $gMSAgroup -Description $gMSAgroup_description -GroupCategory Security -GroupScope Global -WhatIf
Add-ADGroupMember -Identity $gMSAgroup -Members $QCCAT_MSSQL_server_01 -WhatIf
Add-ADGroupMember -Identity $gMSAgroup -Members $QCCAT_MSSQL_server_02 -WhatIf
Add-ADGroupMember -Identity $gMSAgroup -Members $QCCAT_MSSQL_server_03 -WhatIf
Get-ADGroupMember -Identity $gMSAgroup -WhatIf
# NOTE: The servers will need to be cycled in order to take on this change of being added to the gMSA group.

# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Create the gMSA accounts required by QCCAT MSSQL services and assign them to the security group whihc the QCCAT servers will be come a member of.
New-ADServiceAccount -Name $QCCAT_MSSQL_DatabaseEngine_gMSA -PrincipalsAllowedToRetrieveManagedPassword $gMSAgroup -Enabled:$true -DNSHostName $DNShostname -SamAccountName $QCCAT_MSSQL_DatabaseEngine_gMSA -ManagedPasswordIntervalInDays 30 -Whatif
New-ADServiceAccount -Name $QCCAT_MSSQL_SQLAgent_gMSA -PrincipalsAllowedToRetrieveManagedPassword $gMSAgroup -Enabled:$true -DNSHostName $DNShostname -SamAccountName $QCCAT_MSSQL_SQLAgent_gMSA -ManagedPasswordIntervalInDays 30 -Whatif
New-ADServiceAccount -Name $QCCAT_MSSQL_ReportingServices_gMSA -PrincipalsAllowedToRetrieveManagedPassword $gMSAgroup -Enabled:$true -DNSHostName $DNShostname -SamAccountName $QCCAT_MSSQL_ReportingServices_gMSA -ManagedPasswordIntervalInDays 30 -Whatif
New-ADServiceAccount -Name $QCCAT_MSSQL_AnalysisServices_gMSA -PrincipalsAllowedToRetrieveManagedPassword $gMSAgroup -Enabled:$true -DNSHostName $DNShostname -SamAccountName $QCCAT_MSSQL_AnalysisServices_gMSA -ManagedPasswordIntervalInDays 30 -Whatif
New-ADServiceAccount -Name $QCCAT_MSSQL_IntergrationServices_gMSA -PrincipalsAllowedToRetrieveManagedPassword $gMSAgroup -Enabled:$true -DNSHostName $DNShostname -SamAccountName $QCCAT_MSSQL_IntergrationServices_gMSA -ManagedPasswordIntervalInDays 30 -Whatif

# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# NOTE - all gMSA accounts should stay in the OU "sth.health.qld.gov.au/Managed Service Accounts"... this is a Microsoft recommendation..

# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Now this is done (creating the gMSA AD objects), the gMSA accounts now need to be installed on the server(s) themselves.
# There may also be the need to install the AD PowerShell cmdlet.
# Add-WindowsFeature RSAT-AD-PowerShell
# Get-WindowsFeature -Name RSAT-AD-PowerShell
# $QCCAT_MSSQL_DatabaseEngine_gMSA = "gMSAsvcQCCATDE"
# $QCCAT_MSSQL_SQLAgent_gMSA = "gMSAsvcQCCATAG"
# $QCCAT_MSSQL_ReportingServices_gMSA = "gMSAsvcQCCATRS"
# $QCCAT_MSSQL_AnalysisServices_gMSA = "gMSAsvcQCCATAS"
# $QCCAT_MSSQL_IntergrationServices_gMSA = "gMSAsvcQCCATIS"
# Install-ADServiceAccount -Identity $QCCAT_MSSQL_DatabaseEngine_gMSA
# Test-ADServiceAccount -Identity $QCCAT_MSSQL_DatabaseEngine_gMSA
# Install-ADServiceAccount -Identity $QCCAT_MSSQL_SQLAgent_gMSA
# Test-ADServiceAccount -Identity $QCCAT_MSSQL_SQLAgent_gMSA
# Install-ADServiceAccount -Identity $QCCAT_MSSQL_ReportingServices_gMSA
# Test-ADServiceAccount -Identity $QCCAT_MSSQL_ReportingServices_gMSA
# Install-ADServiceAccount -Identity $QCCAT_MSSQL_AnalysisServices_gMSA
# Test-ADServiceAccount -Identity $QCCAT_MSSQL_AnalysisServices_gMSA
# Install-ADServiceAccount -Identity $QCCAT_MSSQL_IntergrationServices_gMSA
# Test-ADServiceAccount -Identity $QCCAT_MSSQL_IntergrationServices_gMSA

# I have used the following website in order to create this script/process.
# https://www.mssqltips.com/sqlservertip/5340/using-group-managed-service-accounts-with-sql-server/

# This script could definately do with some more work, around things like error checking etc... what to do when only one server is required etc, but I will do that as time permits with the next builds, use of this script etc.

# David Shaw
# 17/02/2020

# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Create variables.
$server_01 = “????????”
$server_02 = “????????"
$gMSA_account_name = "gMSA?????????????????"  # in the case of a cluster, this should be the prefix of "gMSA" followed by the cluster name, otherwise it should be the prefix and the server name.
$gMSA_group_name = "gMSA????????????????" # in the case of a cluster, this should be the prefix of "gMSA" followed by the cluster name, otherwise it should be the prefix and the server name.


#************************** *******************************************************************************************************************************************************************************************************************
# *********************************************************************************************************************************************************************************************************************************************
# Nothing below this line should require changing in order for this script to do its intended function.
# *********************************************************************************************************************************************************************************************************************************************
# *********************************************************************************************************************************************************************************************************************************************

# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Quality check variables
cls
if ($gMSA_account_name.length -gt 19 -or $gMSA_group_name.length -gt 19) {
                                                                          cls
                                                                          Write-Output "You have exceeded the max allowed length for the '$gMSA_account_name', please try again."                                       
                                                                          Exit
                                                                          }
If ((Get-ADObject -Filter 'ObjectClass -eq "computer"' | WHERE name -eq $server_01) -eq $null -or (Get-ADObject -Filter 'ObjectClass -eq "computer"' | WHERE name -eq $server_02) -eq $null) {
                                                                                                                                                                                             cls
                                                                                                                                                                                             Write-Output "You declared a server(s) name that do not appear to exist, please try again."                                       
                                                                                                                                                                                             Exit
                                                                                                                                                                                             }
$server_01 = $server_01 + "$" # NOTE: server names require the suffixed of "$" for the remained of this script.
$server_02 = $server_02 + "$" # NOTE: server names require the suffixed of "$" for the remained of this script.

# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Declare fixed variables.
$DNShostname = "METRODC01P.sth.health.qld.gov.au"
$gMSA_account_description = “gMSA used by server(s) listed in the AD group '" + $gMSA_group_name + "'."
$gMSA_group_description = "Servers that are members of this group are entitled to use the Group Managed Service Account '" + $gMSA_account_name +  "'."                          
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
$notes = "This group is intended to provide the members of this group with the rights to use the gMSA '" + $gMSA_account_name + "' to run MSSQL services."
New-ADGroup -Name $gMSA_group_name -Description $gMSA_group_description -GroupCategory Security -GroupScope Global -OtherAttributes @{$notes=$_.info}
Add-ADGroupMember -Identity $gMSA_group_name -Members $server_01
Add-ADGroupMember -Identity $gMSA_group_name -Members $server_02
Get-ADGroupMember -Identity $gMSA_group_name
# NOTE: The servers will need to be cycled in order to take on this change of being added to the gMSA group.

# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Create the gMSA accounts required by MSSQL services and assign them to the security group which the servers will be come a member of.
New-ADServiceAccount -Name $gMSA_account_name -PrincipalsAllowedToRetrieveManagedPassword $gMSA_group_name -Enabled:$true -DNSHostName $DNShostname -SamAccountName $gMSA_account_name -ManagedPasswordIntervalInDays 30 -Description $gMSA_account_description
# NOTE - all gMSA accounts should stay in the OU "sth.health.qld.gov.au/Managed Service Accounts"... this is a Microsoft recommendation..
Write-Oupt "Do NOT forget to reboot server(s) in order for this configuration of the gMSA's to take hold."
$message = "Do NOT forget to move the group '" + $gMSA_group_name + "' you just created, used to house the servers, to the correct OU relating to the system you are deploying."
Write-Oupt $message
Pause

# Histroical notes and obsolete commands... the below should happen as the of the server being rebooted.
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Now this is done (creating the gMSA AD objects), the gMSA accounts now need to be installed on the server(s) themselves.
# There may also be the need to install the AD PowerShell cmdlet.
# Add-WindowsFeature RSAT-AD-PowerShell
# Get-WindowsFeature -Name RSAT-AD-PowerShell
# $gMSA_account_name = "gMSA??????????"
# Install-ADServiceAccount -Identity $gMSA_account_name
# Test-ADServiceAccount -Identity $gMSA_account_name


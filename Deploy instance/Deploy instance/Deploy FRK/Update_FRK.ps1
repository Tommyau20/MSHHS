# This script needs to be executed from a server (e.g. OPSREMOTE01) with the PowerShell modeule DBAtools.io installed.
# It's purpose is to update the below stored procedures relating to the "First Responders Toolkit" on instances where it has been deployed.
function Func_deploy_FRK { 
                    [CmdletBinding()] 
                     param([Parameter(ValueFromPipelineByPropertyName=$true)]$servername                         
                          )                     
                         process {                             
                                  ###try   {
                                  ###      $output_file = "S:\Microsoft\SQL Server\Documentation\Deploy instance\Deploy FRK\Logs\" + $servername  + "_Validate.sql.log"
                                  ###      Invoke-DbaQuery -SqlInstance $servername -Database DBA -File "S:\Microsoft\SQL Server\Documentation\Deploy instance\Deploy FRK\Validate.sql" | Out-File -Append $output_file
                                  ###      } 
                                  ###catch {
                                  ###      $error = "Server '" + $servername + "' had issues... " + $error
                                  ###      Write-Host($error)
                                  ###      }
                                  $output_file = "S:\Microsoft\SQL Server\Documentation\Deploy instance\Deploy FRK\Logs\" + $servername  + "_sp_Blitz.sql.log"
                                  Invoke-DbaQuery -SqlInstance $servername -Database DBA -File "S:\Microsoft\SQL Server\Documentation\Deploy instance\Deploy FRK\sp_Blitz.sql"# | Out-File -Append $output_file
                                  $output_file = "S:\Microsoft\SQL Server\Documentation\Deploy instance\Deploy FRK\Logs\" + $servername  + "_sp_BlitzBackups.sql.log"
                                  Invoke-DbaQuery -SqlInstance $servername -Database DBA -File "S:\Microsoft\SQL Server\Documentation\Deploy instance\Deploy FRK\sp_BlitzBackups.sql"# | Out-File -Append $output_file
                                  $output_file = "S:\Microsoft\SQL Server\Documentation\Deploy instance\Deploy FRK\Logs\" + $servername  + "_sp_BlitzCache.sql.log"
                                  Invoke-DbaQuery -SqlInstance $servername -Database DBA -File "S:\Microsoft\SQL Server\Documentation\Deploy instance\Deploy FRK\sp_BlitzCache.sql"# | Out-File -Append $output_file
                                  $output_file = "S:\Microsoft\SQL Server\Documentation\Deploy instance\Deploy FRK\Logs\" + $servername  + "_sp_BlitzFirst.sql.log"
                                  Invoke-DbaQuery -SqlInstance $servername -Database DBA -File "S:\Microsoft\SQL Server\Documentation\Deploy instance\Deploy FRK\sp_BlitzFirst.sql"# | Out-File -Append $output_file
                                  $output_file = "S:\Microsoft\SQL Server\Documentation\Deploy instance\Deploy FRK\Logs\" + $servername  + "_sp_BlitzIndex.sql.log"
                                  Invoke-DbaQuery -SqlInstance $servername -Database DBA -File "S:\Microsoft\SQL Server\Documentation\Deploy instance\Deploy FRK\sp_BlitzIndex.sql"# | Out-File -Append $output_file
                                  $output_file = "S:\Microsoft\SQL Server\Documentation\Deploy instance\Deploy FRK\Logs\" + $servername  + "_sp_BlitzInMemoryOLTP.sql.log"
                                  Invoke-DbaQuery -SqlInstance $servername -Database DBA -File "S:\Microsoft\SQL Server\Documentation\Deploy instance\Deploy FRK\sp_BlitzInMemoryOLTP.sql"# | Out-File -Append $output_file
                                  $output_file = "S:\Microsoft\SQL Server\Documentation\Deploy instance\Deploy FRK\Logs\" + $servername  + "_sp_BlitzLock.sql.log"
                                  Invoke-DbaQuery -SqlInstance $servername -Database DBA -File "S:\Microsoft\SQL Server\Documentation\Deploy instance\Deploy FRK\sp_BlitzLock.sql"# | Out-File -Append $output_file
                                  $output_file = "S:\Microsoft\SQL Server\Documentation\Deploy instance\Deploy FRK\Logs\" + $servername  + "_sp_BlitzQueryStore.sql.log"
                                  Invoke-DbaQuery -SqlInstance $servername -Database DBA -File "S:\Microsoft\SQL Server\Documentation\Deploy instance\Deploy FRK\sp_BlitzQueryStore.sql"# | Out-File -Append $output_file
                                  $output_file = "S:\Microsoft\SQL Server\Documentation\Deploy instance\Deploy FRK\Logs\" + $servername  + "_sp_BlitzWho.sql.log"
                                  Invoke-DbaQuery -SqlInstance $servername -Database DBA -File "S:\Microsoft\SQL Server\Documentation\Deploy instance\Deploy FRK\sp_BlitzWho.sql"# | Out-File -Append $output_file
                                  $output_file = "S:\Microsoft\SQL Server\Documentation\Deploy instance\Deploy FRK\Logs\" + $servername  + "_Validate.sql.log"
                                  Invoke-DbaQuery -SqlInstance $servername  -Database DBA -File "S:\Microsoft\SQL Server\Documentation\Deploy instance\Deploy FRK\Validate.sql" | Out-File $output_file
                                 }
                          } 
cls
## --------- UAT ---------
Func_deploy_FRK 'SHRDBU01,21433'
Func_deploy_FRK 'SHRCL1-DU01,21433'
Func_deploy_FRK 'SHRCL1-DU02,21433'
Func_deploy_FRK 'SHRCL2DU01.sth.health.qld.gov.au,21433'
Func_deploy_FRK 'SHRCL2DU02.sth.health.qld.gov.au,21433'
Func_deploy_FRK 'SHRCLDU01,21433'
Func_deploy_FRK 'SHRCLDU02,21433'
Func_deploy_FRK 'CAPLAN-DU02'
## ------ PRODUCTION ------
Func_deploy_FRK 'FIRSTQRADB01,21433'
Func_deploy_FRK 'METRO1214'
Func_deploy_FRK 'METRO1215'
Func_deploy_FRK 'PI5DP02,21433'
Func_deploy_FRK 'SHRCL2DP03.sth.health.qld.gov.au,21433'
Func_deploy_FRK 'SHRCL2DP04.sth.health.qld.gov.au,21433'
Func_deploy_FRK 'TWBPFMDP01,21433'
# Load the include file
If ((Test-Path "C:\Admin\Scripts\Includes\include.ps1") -eq $true) 
        {. C:\Admin\Scripts\Includes\include.ps1}
Else
        {. \\PowerShell_include.sth.health.qld.gov.au\PowerShellIncludes$\include.ps1}
# Please refer to the include file at the above location for a current and complete list of its declared constants/settings/functions.
# ------------------------------------------------------------- DO NOT DELETE ANYTHING ABOVE THIS LINE -----------------------------------------------------------------
# --------------------------------------------------- START - REFERENCE RESOURCES ---------------------------------------------------
# https://www.brentozar.com/archive/2019/07/dba-training-plan-2-backups-and-more-importantly-restores/?mc_cid=d91291c723&mc_eid=%5bUNIQID%5d
# https://www.brentozar.com/training/fundamentals-database-administration/dbcc-checkdb-yes-dba-25m/?mc_cid=297233b1a6&mc_eid=%5bUNIQID%5d
# https://www.brentozar.com/archive/2020/08/3-ways-to-run-dbcc-checkdb-faster/
# ---------------------------------------------------- END - REFERENCE RESOURCES ----------------------------------------------------


# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------- START - DECLARE FUNCTIONS -------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Func_delete_old_backups_from_destination {
                                                   # The pruprose of this function is to delete any leftover flat file backups, left from the previous execution.
                                                   Write-Output "Deleting previous copies of backup files from the restore test server destination folder, please wait..." 
                                                   Remove-Item -Path ($target_copy_path + "\*.bak")
                                                   Remove-Item -Path ($target_copy_path + "\*.dif")
                                                   Remove-Item -Path ($target_copy_path + "\*.trn")
                                                   Remove-Item -Path ($target_copy_path + "\*.dmp")
                                                  } # End of -- Func_delete_old_backups_from_destination
function Func_pause_during_standard_backup_window {
                                                  # The pruprose of this function is to pause the script during the Tech\Ops standard SQL agent driven backup window (e.g 19:00 hrs), 
                                                  # so as to prevent an attempt to copy files that are in the process of being created.
                                                  $start_window = Get-Date '17:45'
                                                  $stop_window = Get-Date '20:20'
                                                  $now = Get-Date
                                                  If ($start_window.TimeOfDay -le $now.TimeOfDay -and $stop_window.TimeOfDay -ge $now.TimeOfDay) 
                                                                                {
                                                                                cls
                                                                                $message_now = Get-Date -Format "dddd dd/MM/yyyy HH:mm"
                                                                                Write-Output $message_now
                                                                                $pause_during_standard_backup_window_message = 'Script has been paused, allowing time for standard scheduled full backups (19:00) to be executed and completed, script will resume at 8:30pm, please wait...'
                                                                                Write-Output "---------------------------------------------------------------------------------------------------------------------------------"
                                                                                Write-Output $pause_during_standard_backup_window_message                                           
                                                                                Write-Output "---------------------------------------------------------------------------------------------------------------------------------"                                                                                
                                                                                Start-Sleep ((get-date "8:30pm") - (get-date)).TotalSeconds
                                                                                }
                                                   } # End of -- Func_pause_during_standard_backup_window
function Func_copy_backup_files_to_destination {
                                                # This function simple uses the paramters passed to it, to copy the database backup flat files to a drive on the DBA Centrl server in preperation for restoring.
                                                param($ServerName,$InstanceName,$DatabaseName,$FullBackupLocation)                     
                                                process {                                                         
                                                         Write-Output "Copying source backup file(s) to the restore testing servers destination folder..."                                                        
                                                         If ($FullBackupLocation.StartsWith('\\')) {
                                                                                                    $backup_file_source = $FullBackupLocation
                                                                                                   }
                                                         Else {
                                                              $backup_file_source = ("\\" + $ServerName + "\" + ($FullBackupLocation.replace(":\","$\")))                                                             
                                                              }
                                                         Write-Output $backup_file_source 
                                                         Write-Output "... please wait."                                                                              
                                                         $copy_result = Copy-Item -Path  $backup_file_source -Destination $target_copy_path -PassThru 
                                                         Start-Sleep -s 5                                                        
                                                         $copy_result = test-path $copy_result                                                                                                                                                                           
                                                         # -----------------------------------------------------------
                                                         # This "if" may need to have some additional logic, to check if the "$FullBackupLocation" is also NUll... as I have seen it make inserts when there was no file to copy, while it finished Prod and was waiting for the UAT window.
                                                         # -----------------------------------------------------------                                                         
                                                         If ($copy_result -ne $true) {                                                                     
                                                                                     cls
                                                                                     Write-Output 'File copy of the following source file has failed...'
                                                                                     Write-Output $backup_file_source                                                                                     
                                                                                     Invoke-Sqlcmd -ServerInstance $DBA_Central -Query ("INSERT INTO [DBA_central].[dbo].[DatabaseRestoreTest] ([ServerName],[InstanceName],[DatabaseName],[BackupFileCopyStatus],[FullBackupLocation]) VALUES ('" + $ServerName + "','"  + $InstanceName + "','" + $DatabaseName + "',0 ,'" + $FullBackupLocation + "' )")                                                                     
                                                                                     }
                                                         Else {
                                                              Invoke-Sqlcmd -ServerInstance $DBA_Central -Query ("INSERT INTO [DBA_central].[dbo].[DatabaseRestoreTest] ([ServerName],[InstanceName],[DatabaseName],[BackupFileCopyStatus],[FullBackupLocation]) VALUES ('" + $ServerName + "','"  + $InstanceName + "','" + $DatabaseName + "',1 ,'" + $FullBackupLocation + "' )")
                                                              Func_restore_database $ServerName $InstanceName $DatabaseName  
                                                              }
                                                         }
                                               } # End of -- Func_copy_backup_files_to_destination
function Func_restore_database {
                                # This function will connect to DBA Central and execute a database restore using the previously copied database flat file.
                                param($ServerName,$InstanceName,$DatabaseName)                     
                                process {
                                          cls                                          
                                          $restore_message = "Restoring database '" + $DatabaseName + "', please wait..." 
                                          Write-Output $restore_message
                                          Restore-DbaDatabase -SqlInstance $target_restore_MSSQL_instance -Path $target_copy_path -UseDestinationDefaultDirectories -RestoredDatabaseNamePrefix "ResTest_" -DestinationFilePrefix "ResTest_" #-OutputScriptOnly 
                                          Start-Sleep -s 5
                                          Invoke-Sqlcmd -ServerInstance $DBA_Central -Query ("If EXISTS (SELECT [Name] FROM sys.databases WHERE [Name] = 'ResTest_" + $DatabaseName + "') BEGIN UPDATE [DBA_central].[dbo].[DatabaseRestoreTest] SET [RestoreTestDate] = GetDate() WHERE [ServerName] = '" + $ServerName + "' AND [InstanceName] = '" + $InstanceName + "' AND [DatabaseName] = '" + $DatabaseName + "' END")                                                                             
                                          Func_run_DBCC
                                          }
                                } # End of -- Func_restore_database
function Func_run_DBCC {
                       # This function will be called once the database restore has been complete and will invoke the execution of the SQL agent job 'DBA Central - Database integrity check (restored database check)' on DBA Central".
                       $dbcc_message = "Launching DBCC check on restored database '" + $DatabaseName +  "', please wait..." 
                       Write-Output $dbcc_message
                       # ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
                       #I think I need to write the below invoke-sqlcmd to have and "if statement looking for the ResTest_ database exsiting, before it tries to execute the DBCC check... like I was seeing with the database CPT_PRODCOPY appearing to fail restore.
                       # ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
                       Invoke-Sqlcmd -ServerInstance $DBA_Central -Query ("EXEC msdb.dbo.sp_start_job N'DBA Central - Database integrity check (restored database check)'")
                       Start-Sleep -s 30
                       Func_delete_old_backups_from_destination                       
                       } # End of -- Func_run_DBCC
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------- END - DECLARE FUNCTIONS --------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------------- START - PROCESS -----------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
cls
# ------------------------------------------ START - PAUSE START OF SCRIPT TILL GIVEN DATE ------------------------------------------
$pause_date = ""
$check_datetime = ""
$pause_date = Read-Host -Prompt "Please provide the start date/time e.g. $(Get-Date)... ENTER to start now"
If ($pause_date -ne "") {
                        $check_datetime = (New-TimeSpan –End $pause_date).TotalSeconds
                        If (($check_datetime -eq "" -and $pause_date -ne "") -or $check_datetime -lt 0.0) 
                                    {
                                    cls
                                    Write-Output "Start date/time invalid... please try again."
                                    pause                                      
                                    exit
                                    }
                        Else
                                    {
                                    cls
                                    $pause_message = "This script (database restore testing) is paused till... " + $pause_date + "."
                                    Write-Output $pause_message
                                    (New-TimeSpan –End $pause_date).TotalSeconds | Sleep
                                    }                                                 
                        }
# ------------------------------------------- END - PAUSE START OF SCRIPT TILL GIVEN DATE -------------------------------------------
# ------------------------------------- START - SEND EMAIL NOTIFICATION OF PROCESS STARTING -----------------------------------------
[string[]]$email_recipients = $CI_OPS_DBA_staff_email_addresses.Split(',')
$emailbody = "<p>The process of database restore testing with DBCC has commenced.</p>" + 
             "<p>--------------------------------------------------------------------------------------------------<br>" + 
             "This email has been generated by PowerShell script - '" + $MyInvocation.MyCommand.Source + "' (" + $env:computername +  ")</p>"
Send-MailMessage -SmtpServer $QH_SMTP_Server -To $email_recipients -From "no_reply_address@health.qld.gov.au" -Subject "DBA Central, database restore testing - commencing" -Body $emailbody -Priority normal -BodyAsHtml                            
# -------------------------------------- END - SEND EMAIL NOTIFICATION OF PROCESS STARTING ------------------------------------------
# ---------------------------------------------------- START - DECLARE VARIABLES ----------------------------------------------------
$DBA_Central = "DBA_Central.db.sth.health.qld.gov.au,21433" 
$query_row_count_not_yet_tested = "Select COUNT(*) from [DBA_central].[dbo].[vw_DatabaseRestoreTest_not_yet_tested]"
$target_copy_path = "\\SHRDBU01\P$\RestoreTestBackups"
$target_restore_MSSQL_instance = "DBA_Central.db.sth.health.qld.gov.au,21433" # This is currently the same server hosting DBA Central, but it can be any other server, but it must have the necessary store procedures, SQL agent jobs etc etc.
# ---------------------------------------------------- END - DECLARE VARIABLES ------------------------------------------------------
# ---------------------------------------------------------- START - LOOP -----------------------------------------------------------
$delete_for_retry = "yes" # Create a variable, setting it ot true, in order to have a second bite of the cherry in testing those database restores that failed.
Func_delete_old_backups_from_destination # This function call is in order to do any housekeeping should the script crash and/or it is intensionly re-started.
$query_results_row_count_not_yet_tested = Invoke-Sqlcmd -ServerInstance $DBA_Central -Query $query_row_count_not_yet_tested
Do {
    Func_pause_during_standard_backup_window
    $sql_agent_status_DBCC = Get-DbaRunningJob -SqlInstance $DBA_Central | Where-Object name -like "DBA Central - Database integrity check (restored database check)"
    If ($sql_agent_status_DBCC -ne $null) {
                                           cls                                   
                                           $message_now = Get-Date -Format "dddd dd/MM/yyyy HH:mm"
                                           Write-Output $message_now
                                           $SQLAgent_stillrunning_message = 'SQL agent associated with conducting the DBCC for databases restored by this script, is still running on the server from the prior restore (' + $DatabaseName + ') , please wait...'
                                           Write-Output $SQLAgent_stillrunning_message                                           
                                           Start-Sleep -s 180                            
                                           }
    Else
                                           {                                    
                                           cls                                           
                                           $start_UAT_window = Get-Date '09:15' # a time of day after the Azure UAT servers has started (07:00), allowing time for any Azure UAT backups that have started to finish.
                                           $stop_UAT_window = Get-Date '17:30' # a time of day prior to the Azure UAT servers are scheduled to shut down (19:00), allowing enough time to finish any files copies that have already started.
                                           $now = Get-Date
                                           $query_results_row_count_not_production = Invoke-Sqlcmd -ServerInstance $DBA_Central -Query "Select COUNT(*) from [DBA_central].[dbo].[vw_DatabaseRestoreTest_next_db_to_be_test_NOT_production]"                                          
                                           If ($start_UAT_window.TimeOfDay -le $now.TimeOfDay -and $stop_UAT_window.TimeOfDay -ge $now.TimeOfDay -and $now.DayOfWeek -match 'Monday|Tuesday|Wednesday|Thursday|Friday' -and $query_results_row_count_not_production.Column1 -ne 0) 
                                                                        {                                                                       
                                                                        $query_to_execute = "Select TOP 1 * from [DBA_central].[dbo].[vw_DatabaseRestoreTest_next_db_to_be_test_NOT_production] ORDER BY [RecordedDate] DESC, [ServerName], [InstanceName], [DatabaseName]" # Select the next top NOT production database to restore.
                                                                        $database_environment_message = "Current day and time fits within Azure UAT VM auto-start window... going for a NOT production database..."                                                                                               
                                                                        } 
                                           Else {
                                                $query_to_execute = "Select TOP 1 * from [DBA_central].[dbo].[vw_DatabaseRestoreTest_next_db_to_be_test_production] ORDER BY [RecordedDate] DESC, [ServerName], [InstanceName], [DatabaseName]" # Select the next top production database to restore.                                                
                                                $database_environment_message = "Going for a production database..."
                                                } 
                                           # ---------------- START - used during testing, remove comment out when needed ----------------
                                           #Write-Output "-------------------------------------------------------------------------------------------------------"
                                           #Write-Output $database_environment_message
                                           #Write-Output "-------------------------------------------------------------------------------------------------------"                                                                                                                                                         
                                           #$query_results = Invoke-Sqlcmd -ServerInstance $DBA_Central -Query $query_to_execute                                           
                                           #Write-Output "?????????????????????? query 1 ????????????????????????????"
                                           #Write-Output $query_results
                                           #Write-Output "?????????????????????? query 1 ????????????????????????????"
                                           #$query_results_row_count_not_yet_tested = Invoke-Sqlcmd -ServerInstance $DBA_Central -Query $query_row_count_not_yet_tested
                                           #Write-Output "?????????????????????? query 2 ????????????????????????????"
                                           #Write-Output $query_results_row_count_not_yet_tested
                                           #Write-Output "?????????????????????? query 2 ????????????????????????????"
                                           # ----------------- END - used during testing, remove comment out when needed -----------------
                                           Start-Sleep -s 5                                           
                                           $ServerName =  $query_results.ServerName
                                           $InstanceName =  $query_results.InstanceName
                                           $DatabaseName =  $query_results.DatabaseName
                                           $FullBackupLocation =  $query_results.FullBackupLocation                                           
                                           If ($query_results) 
                                                               {
                                                               Func_copy_backup_files_to_destination $ServerName $InstanceName $DatabaseName $FullBackupLocation
                                                               }
                                           }
   $query_results_row_count_not_yet_tested = Invoke-Sqlcmd -ServerInstance $DBA_Central -Query $query_row_count_not_yet_tested
   If ($query_results_row_count_not_yet_tested.Column1 -eq 0 -and $delete_for_retry -eq "yes") 
                                                                          {
                                                                          Invoke-Sqlcmd -ServerInstance $DBA_Central -Query ("EXEC [DBA_Central].[dbo].[usp_DatabaseRestoreTesting_DeleteForRetry]")                                                                          
                                                                          $query_results_row_count_not_yet_tested = Invoke-Sqlcmd -ServerInstance $DBA_Central -Query $query_row_count_not_yet_tested
                                                                          $delete_for_retry = "done"
                                                                          }                                           
   } Until  ($query_results_row_count_not_yet_tested.Column1 -eq 0)
# --------------------------------------------------------- END - LOOP -------------------------------------------------------------
# --------------------------------- START - SEND EMAIL NOTIFICATION OF PROCESS BEING COMPLETED -------------------------------------
cls
# Prepare email notification advising that this script is complete.
Write-Output "All available listed database backups appear to have gone through this current cycle of restore testing," 
Write-Output "please refer to DBA Central for further outcome results. Don't forget to archive before starting the cycle again."
$emailbody = "<p>Please refer to the process of 'database restore testing' on DBA Central, as this months cycle has finished.</p>" + 
             "<p>Use the following to review the results;<br>" +
             "SELECT * FROM [DBA_central].[dbo].[vw_DatabaseRestoreTest_not_yet_tested] ORDER BY [Environment],[ServerName]<br>" +
             "SELECT * FROM [DBA_central].[dbo].[vw_DatabaseRestoreTest_failed] ORDER BY [ServerName]<br>" +             
             "SELECT * FROM [DBA_central].[dbo].[vw_DatabaseRestoreTest_successful] ORDER BY [RestoreTestDate] <br>" + 
             "SELECT * FROM [DBA_central].[dbo].[vw_DatabaseRestoreTest_wont_be_tested] ORDER BY [DBStatus],[ServerName] <br>" +             
             "<br>" +
             "SELECT * FROM [DBA_central].[dbo].[DatabaseRestoreTest] ORDER BY [ExcludeFromTesting] DESC, [ServerName], [RestoreTestDate] <br>" +
             "SELECT * FROM [DBA_central].[dbo].[vw_database_by_server_USERDATABASES_ONLY] <br>" +
             "SELECT * FROM [DBA_central].[dbo].[vw_Instances_not_seen_for_awhile] <br></p>" +
             "<p>Don't forget to execute <i>usp_DatabaseRestoreTesting_ArchiveData</i> & <i>usp_DatabaseRestoreTesting_DeleteForRetry</i> once the review is complete.</p>" +
             "<p>--------------------------------------------------------------------------------------------------<br>" + 
             "This email has been generated by PowerShell script - '" + $MyInvocation.MyCommand.Source + "' (" + $env:computername +  ")</p>"

# Send email notification.
[string[]]$email_recipients = $CI_OPS_DBA_staff_email_addresses.Split(',')
Send-MailMessage -SmtpServer $QH_SMTP_Server -To $email_recipients -From "no_reply_address@health.qld.gov.au" -Subject "DBA Central, database restore testing - complete" -Body $emailbody -Priority normal -BodyAsHtml                            
# ---------------------------------- END - SEND EMAIL NOTIFICATION OF PROCESS BEING COMPLETED --------------------------------------
Start-Sleep -s 180 
Exit

# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------------------- END - PROCESS ------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
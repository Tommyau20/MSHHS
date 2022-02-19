USE [msdb]
GO

DECLARE @path_string varchar(max)
SET @path_string = N'$'+'(ESCAPE_SQUOTE(SQLLOGDIR))\'+'$'+'(ESCAPE_SQUOTE(JOBNAME))_'+'$'+'(ESCAPE_SQUOTE(STEPID))_'+'$'+'(ESCAPE_SQUOTE(DATE))_'+'$'+'(ESCAPE_SQUOTE(TIME)).txt'

/****** Object:  Job [DBA - Database backup (LOG)]    Script Date: 31/05/2021 11:37:07 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 31/05/2021 11:37:07 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Database backup (LOG)', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Source: https://ola.hallengren.com
Created using version 2020-12-06

This SQL agent job has three parts;
1) Delete previous transactional log backups that has passed the rentention designated period.
2) Carry out a full back using Ola scripts.
3) Execute store procedure for database collector, updating the DBA database.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'CI_OPS', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Delete old LOG backups]    Script Date: 31/05/2021 11:37:07 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Delete old LOG backups', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @Version numeric(18,10) = CAST(LEFT(CAST(SERVERPROPERTY(''ProductVersion'') AS nvarchar(max)),CHARINDEX(''.'',CAST(SERVERPROPERTY(''ProductVersion'') AS nvarchar(max))) - 1) + ''.'' + REPLACE(RIGHT(CAST(SERVERPROPERTY(''ProductVersion'') AS nvarchar(max)), LEN(CAST(SERVERPROPERTY(''ProductVersion'') AS nvarchar(max))) - CHARINDEX(''.'',CAST(SERVERPROPERTY(''ProductVersion'') AS nvarchar(max)))),''.'','''') AS numeric(18,10))
DECLARE @DefaultDirectory nvarchar(4000)
IF @Version >= 15
    BEGIN
    SET @DefaultDirectory = CAST(SERVERPROPERTY(''InstanceDefaultBackupPath'') AS nvarchar(max))
    END
ELSE
    BEGIN
    EXECUTE [master].dbo.xp_instance_regread N''HKEY_LOCAL_MACHINE'', N''SOFTWARE\Microsoft\MSSQLServer\MSSQLServer'', N''BackupDirectory'', @DefaultDirectory OUTPUT
    END
DECLARE @today_minus_1_day datetime
SET @today_minus_1_day = DATEADD(hh, -49, GETDATE())
EXECUTE master.dbo.xp_delete_file 0,@DefaultDirectory,N''trn'',@today_minus_1_day,1', 
		@database_name=N'master', 
		@output_file_name=@path_string, 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DatabaseBackup (LOG)]    Script Date: 31/05/2021 11:37:07 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DatabaseBackup (LOG)', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC [DBA].[dbo].[DatabaseBackup] @Databases = N''ALL_DATABASES'',
			  @BackupType = N''LOG'',							
			  --@CleanupTime = N''24'',
			  --@CleanupMode = N''BEFORE_BACKUP'',
			  @Verify = N''Y'',
			  @CheckSum = N''Y'',							
			  @DirectoryStructure = N''{DatabaseName}'', --@DirectoryStructure = N''{DatabaseName}{DirectorySeparator}{BackupType}'',
			  @AvailabilityGroupDirectoryStructure = N''{DatabaseName}'',			  
			  @FileName = N''{DatabaseName}_{Year}{Month}{Day}_{Hour}{Minute}{Second}.{FileExtension}'',														
			  @AvailabilityGroupFileName = N''{DatabaseName}_{Year}{Month}{Day}_{Hour}{Minute}{Second}.{FileExtension}'',							
			  @LogToTable = N''Y''', 
		@database_name=N'DBA', 
		@output_file_name=@path_string, 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily - every 4 hours (11:00 pm)', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=4, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20201008, 
		@active_end_date=99991231, 
		@active_start_time=230000, 
		@active_end_time=183000
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO



USE [msdb]
GO

DECLARE @path_string varchar(max)
SET @path_string = N'$'+'(ESCAPE_SQUOTE(SQLLOGDIR))\'+'$'+'(ESCAPE_SQUOTE(JOBNAME))_'+'$'+'(ESCAPE_SQUOTE(STEPID))_'+'$'+'(ESCAPE_SQUOTE(DATE))_'+'$'+'(ESCAPE_SQUOTE(TIME)).txt'

/****** Object:  Job [DBA - Database index maintenance]    Script Date: 31/05/2021 11:37:36 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 31/05/2021 11:37:36 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Database index maintenance', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Source: https://ola.hallengren.com

Created using version 2020-12-06', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'CI_OPS', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [IndexOptimize (ALL_DATABASES)]    Script Date: 31/05/2021 11:37:36 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'IndexOptimize (ALL_DATABASES)', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'IF EXISTS (SELECT [role_desc] FROM sys.dm_hadr_availability_replica_states WHERE [role_desc] = ''secondary'' AND [is_local] = 1) -- ***** This may have issues if there were multiple secondaries, would the select fail returning multiple records for the multiple nodes. *****
	BEGIN -- ***** execute on AlwaysOn AG secondary nodes only, only indexing databases NOT in an AG. *****
	EXECUTE [DBA].[dbo].[IndexOptimize] @Databases = ''SYSTEM_DATABASES, USER_DATABASES, -AVAILABILITY_GROUP_DATABASES'', 
				              @FragmentationLow = NULL,
				              @FragmentationMedium = ''INDEX_REORGANIZE'',
				              @FragmentationHigh = ''INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE'',
				              @UpdateStatistics = ''ALL'',
				              --@Execute = ''N'',
				              @LogToTable = ''Y''

	END
ELSE
	BEGIN -- ***** execute on any database, including those databases in on AlwaysOn AG on a primary nodes. *****
	EXECUTE [DBA].[dbo].[IndexOptimize] @Databases = ''ALL_DATABASES'',
				              @FragmentationLow = NULL,
				              @FragmentationMedium = ''INDEX_REORGANIZE'',
				              @FragmentationHigh = ''INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE'',
				              @UpdateStatistics = ''ALL'',
				              --@Execute = ''N'',
				              @LogToTable = ''Y''
	END', 
		@database_name=N'DBA', 
		@output_file_name=@path_string, 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Wed, Sat - 10:00 pm', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=72, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20201223, 
		@active_end_date=99991231, 
		@active_start_time=220000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO



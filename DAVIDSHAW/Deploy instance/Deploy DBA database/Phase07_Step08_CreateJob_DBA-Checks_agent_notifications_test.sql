USE [msdb]
GO

DECLARE @path_string varchar(max)
SET @path_string = N'$'+'(ESCAPE_SQUOTE(SQLLOGDIR))\'+'$'+'(ESCAPE_SQUOTE(JOBNAME))_'+'$'+'(ESCAPE_SQUOTE(STEPID))_'+'$'+'(ESCAPE_SQUOTE(DATE))_'+'$'+'(ESCAPE_SQUOTE(TIME)).txt'

/****** Object:  Job [DBA - checks (agent notifications test)]    Script Date: 1/06/2021 7:38:39 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [System checks]    Script Date: 1/06/2021 7:38:39 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'System checks' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'System checks'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - checks (agent notifications test)', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'The purpose of this job is to FAIL when executed, so as to test that the SQL agent alert system (email notifications) is working correctly.
This job has no schedule but rather is executed on demand (e.g. during the initial build) so as to get a measured test and outcome... or investigate where appropriate (e.g. no notification generated)
The reason behind creating this job is the result of finding some instances where the SQL agent alert system did NOT have "Enable mail profile" turned on.

David Shaw', 
		@category_name=N'System checks', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [failure_test]    Script Date: 1/06/2021 7:38:39 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'failure_test', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- It is intended that the t-sql below will fail, causing the associated SQL agent job to also fail..

USE [DatabaseDoesNotExistAtAll]

GO

Select * FROM [dbo].[TableDoesNotExistAtAll]

', 
		@database_name=N'master', 
		@output_file_name=@path_string, 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO



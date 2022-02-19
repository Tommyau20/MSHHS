-- ********************************* START - CHANGE SQL AGENT JOB OWNER *****************************************************
DECLARE @agent_job_name VARCHAR(100)

DECLARE agent_job_name_cursor CURSOR FOR  
	SELECT [name] FROM msdb.dbo.sysjobs WHERE [name] LIKE 'DBMP_%'

OPEN agent_job_name_cursor
FETCH NEXT FROM agent_job_name_cursor INTO @agent_job_name

WHILE @@FETCH_STATUS = 0   
BEGIN  
	EXEC msdb.dbo.sp_update_job @job_name=@agent_job_name, 
							    @owner_login_name=N'sa'
	FETCH NEXT FROM agent_job_name_cursor INTO @agent_job_name   
END 
CLOSE agent_job_name_cursor
DEALLOCATE agent_job_name_cursor

-- ********************************* END - CHANGE SQL AGENT JOB OWNER *****************************************************

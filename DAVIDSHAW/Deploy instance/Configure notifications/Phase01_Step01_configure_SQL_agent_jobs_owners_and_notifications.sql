-- ****************************************************************
-- ***** Configure all SQL agent jobs, owner and notification *****
-- ****************************************************************
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DECLARE @job_owner varchar(50)
DECLARE @operator varchar(50)
DECLARE @job_id_number varchar(100)
DECLARE @audit_type_jobs_id varchar(50)

SET @job_owner = 'sa' -- at some stage MSHHS had a mix, some database maintenance plan jobs were owned by sa, while some were owned by 'PA-HEALTH\sqlmaintenanceplan'. 
SET @operator = 'CI_OPS' 

DECLARE job_cursor CURSOR FOR  	
	SELECT job_id FROM msdb..sysjobs WHERE [name] LIKE 'DBA - %' OR [name] = 'syspolicy_purge_history'  ORDER BY [name] 
OPEN job_cursor   
FETCH NEXT FROM job_cursor INTO @job_id_number  
WHILE @@FETCH_STATUS = 0   
BEGIN   
	EXEC msdb.dbo.sp_update_job @job_ID = @job_id_number, -- ***** Job ID *****
								@owner_login_name = @job_owner, -- ***** The owner of the SQL agent job. *****	
								@notify_level_email = 2, -- ***** The number 2 denotes, notify on failure. *****
								@notify_email_operator_name = @operator -- ***** The operator to recieve notifications *****
FETCH NEXT FROM job_cursor INTO @job_id_number  
END 
  
CLOSE job_cursor   
DEALLOCATE job_cursor
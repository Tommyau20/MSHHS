-- ********************************* START - CHANGE MAINTENANCE PLAN OWNER *****************************************************
DECLARE @agent_job_name VARCHAR(100)
DECLARE @sqlmaintenanceplan varbinary(85)
SET @sqlmaintenanceplan = SUSER_SID ('sa')  
-- PRINT @sqlmaintenanceplan

DECLARE agent_job_name_cursor CURSOR FOR  
	Select [name] from msdb.dbo.sysmaintplan_plans WHERE [name] LIKE 'DBMP_%'

OPEN agent_job_name_cursor
FETCH NEXT FROM agent_job_name_cursor INTO @agent_job_name

WHILE @@FETCH_STATUS = 0   
BEGIN  
	UPDATE	[msdb].[dbo].[sysssispackages]
		SET	[ownersid] = @sqlmaintenanceplan
			WHERE	[name] = @agent_job_name
	FETCH NEXT FROM agent_job_name_cursor INTO @agent_job_name   
END 
CLOSE agent_job_name_cursor
DEALLOCATE agent_job_name_cursor
-- ********************************* END - CHANGE MAINTENANCE PLAN OWNER *****************************************************

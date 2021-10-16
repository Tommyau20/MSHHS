-- *************************************** START - CONFIRM CHANGES ***********************************************************
DECLARE @sqlmaintenanceplan_check varbinary(85)
SET @sqlmaintenanceplan_check = SUSER_SID ('sa')

SELECT * FROM [msdb].[dbo].[sysjobs]
	WHERE [owner_sid] = @sqlmaintenanceplan_check

SELECT * from [msdb].[dbo].[sysssispackages] 
	WHERE [ownersid] = @sqlmaintenanceplan_check

SELECT * from [msdb].[dbo].[sysmaintplan_plans] 
	WHERE [name] LIKE 'DBMP_%'

SELECT j.[name], p.[name] AS [job_owner] FROM [msdb].[dbo].[sysjobs] j JOIN
	[sys].[server_principals] p ON j.[owner_sid] = P.sid
		WHERE j.[name] LIKE 'DBMP_%'
-- *************************************** END - CONFIRM CHANGES *************************************************************



 




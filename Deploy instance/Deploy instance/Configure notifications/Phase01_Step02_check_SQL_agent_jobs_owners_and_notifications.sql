-- *********************************************************************
-- *********** Confirm SQL agent job owner & notifications  ************
-- *********************************************************************
SELECT a.[name] AS [SQL_agent_job_name], 
      suser_sname(a.[owner_sid]) AS [Job_owner], 
	  sop.[name] AS [Job_notification_operator_for_email]
		FROM [msdb].[dbo].[sysjobs] a LEFT OUTER JOIN
			 [sys].[server_principals] b ON a.[owner_sid] = b.[sid] LEFT OUTER JOIN
			 [msdb].[dbo].[sysoperators] sop ON a.[notify_email_operator_id] = sop.[id]	
			 			ORDER BY a.[name]
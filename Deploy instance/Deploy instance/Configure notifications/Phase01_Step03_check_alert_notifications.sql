-- ******************************************************
-- *********** Confirm alerts notifications  ************
-- ******************************************************
SELECT sa.[name] AS [Alert_name], 
	   sop.[name] As [Operator_name] 
	FROM [msdb].[dbo].[sysnotifications] sn FULL OUTER JOIN
		 [msdb].[dbo].[sysalerts] sa ON sa.[id] = sn.[alert_id] FULL OUTER JOIN
		 [msdb].[dbo].[sysoperators] sop ON sn.[operator_id] = sop.[id]
				ORDER BY sa.[name]
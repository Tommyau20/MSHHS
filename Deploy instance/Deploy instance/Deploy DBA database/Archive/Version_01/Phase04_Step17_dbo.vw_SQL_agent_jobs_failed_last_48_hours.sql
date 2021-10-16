USE [DBA]
GO

/****** Object:  View [dbo].[vw_SQL_agent_jobs_failed_last_48_hours]    Script Date: 14/04/2020 6:39:28 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- ***** Using SSMS local server groups, look to see where I have deployed vw_SQL_agent_jobs_failed_last_48_hours *****
--SELECT OBJECT_SCHEMA_NAME(object_id) schema_name, [name]
--       FROM [DBA].[sys].[views]
--           WHERE [Name] like'%48%'
--              ORDER BY [name]



CREATE VIEW [dbo].[vw_SQL_agent_jobs_failed_last_48_hours]
AS
SELECT j.[name]
      ,js.step_name
      ,jh.sql_severity
      ,jh.[message]
      ,jh.run_date
      ,jh.run_time
FROM msdb.dbo.sysjobs AS j
INNER JOIN msdb.dbo.sysjobsteps AS js
   ON js.job_id = j.job_id
INNER JOIN msdb.dbo.sysjobhistory AS jh
   ON jh.job_id = j.job_id AND jh.step_id = js.step_id
		WHERE jh.run_status = 0 AND jh.run_date > (SELECT REPLACE( CONVERT(varchar, getdate()-2, 23), '-', '' ))
GO
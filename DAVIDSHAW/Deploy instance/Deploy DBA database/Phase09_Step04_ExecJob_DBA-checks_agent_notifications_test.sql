-- ***** START - Enable Operator post testing of the above SQL agent jobs *****
USE [msdb]
GO
EXEC msdb.dbo.sp_update_operator @name=N'DBA', @enabled=1
GO
-- ***** END - Enable Operator post testing of the above SQL agent jobs *****

USE [msdb]
GO

EXEC dbo.sp_start_job N'DBA - checks (agent notifications test)' ;
GO

USE [msdb]
GO

EXEC msdb.dbo.sp_update_job @job_name=N'DBA - checks (agent notifications test)', 
		                    @enabled=0 ;
GO

-- ***** START - Disable Operator post testing of the above SQL agent jobs *****
USE [msdb]
GO
EXEC msdb.dbo.sp_update_operator @name=N'DBA', @enabled=0
GO
-- ***** END - Disable Operator post testing of the above SQL agent jobs *****

USE [msdb]
GO
EXEC msdb.dbo.sp_update_operator @name=N'DBA', 
				 @enabled=1

GO


USE [msdb]
GO
EXEC msdb.dbo.sp_update_operator @name=N'CI_OPS', 
				 @enabled=1

GO
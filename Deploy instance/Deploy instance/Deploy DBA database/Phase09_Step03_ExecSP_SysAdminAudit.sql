-- ***** START - Enable Operator post testing of the above SQL agent jobs *****
USE [msdb]
GO
EXEC msdb.dbo.sp_update_operator @name=N'DBA', @enabled=1
GO
-- ***** END - Enable Operator post testing of the above SQL agent jobs *****


USE [DBA]
GO

EXEC [DBA].[dbo].[sp_SysAdminAudit]
GO


USE [DBA]
GO

UPDATE [dbo].[SysAdminAudit]
   SET [Acknowledged] = 1
 GO


-- ***** START - Disable Operator post testing of the above SQL agent jobs *****
USE [msdb]
GO
EXEC msdb.dbo.sp_update_operator @name=N'DBA', @enabled=0
GO
-- ***** END - Disable Operator post testing of the above SQL agent jobs *****
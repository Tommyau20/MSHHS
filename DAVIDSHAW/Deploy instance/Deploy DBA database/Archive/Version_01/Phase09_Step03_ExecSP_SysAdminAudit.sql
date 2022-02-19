USE [DBA]
GO

EXEC [DBA].[dbo].[sp_SysAdminAudit]
GO


USE [DBA]
GO

UPDATE [dbo].[SysAdminAudit]
   SET [Acknowledged] = 1
 GO

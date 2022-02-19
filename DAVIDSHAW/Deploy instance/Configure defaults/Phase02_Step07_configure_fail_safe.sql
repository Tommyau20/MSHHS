USE [msdb]
GO
EXEC master.dbo.sp_MSsetalertinfo @failsafeoperator=N'CI_OPS', 
				  @notificationmethod=1
GO

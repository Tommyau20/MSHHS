USE [msdb]
GO
EXEC msdb.dbo.sp_add_operator @name=N'DBA', 
			      @enabled=0, 
			      @pager_days=0, 
			      @email_address=N'David.Shaw@health.qld.gov.au'
GO

USE [msdb]
GO
EXEC msdb.dbo.sp_add_operator @name=N'CI_OPS', 
			      @enabled=0, 
			      @pager_days=0,
	  		      @email_address=N'ADM-MSHCIOPSStaff-Full@health.qld.gov.au'			
GO

USE [msdb]
GO
EXEC msdb.dbo.sp_add_operator @name=N'CI_Apps_Services', 
			      @enabled=1, 
			      @pager_days=0,
	  		      @email_address=N'MSHCIApplicationServices@health.qld.gov.au'			
GO

USE [msdb]
GO
EXEC msdb.dbo.sp_add_operator @name=N'CI_Data_and_Analytics', 
			      @enabled=1, 
			      @pager_days=0,
	  		      @email_address=N'ADM-MSH Analytics-Full@health.qld.gov.a'			
GO
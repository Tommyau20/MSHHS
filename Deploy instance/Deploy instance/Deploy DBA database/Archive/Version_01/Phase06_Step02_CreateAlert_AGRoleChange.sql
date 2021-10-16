USE [msdb]
GO

/****** Object:  Alert [AG: Role Change]    Script Date: 31/07/2019 12:50:14 PM ******/
EXEC msdb.dbo.sp_add_alert @name=N'AG: Role Change', 
		@message_id=1480, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1, 
		@notification_message=N'AG role change', 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO

USE [msdb]
GO
EXEC msdb.dbo.sp_update_alert @name=N'AG: Role Change', 
		@message_id=1480, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1, 
		@database_name=N'', 
		@notification_message=N'AG role change', 
		@event_description_keyword=N'', 
		@performance_condition=N'', 
		@wmi_namespace=N'', 
		@wmi_query=N''
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'AG: Role Change', @operator_name=N'DBA', @notification_method = 1
GO


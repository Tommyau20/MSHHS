-- *** http://www.mssqltips.com/tip.asp?tip=939 ***


IF (EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Database: Restore Success'))
BEGIN
EXEC msdb.dbo.sp_delete_alert @name = N'Database: Restore Success' 
END


USE [msdb]
GO

DECLARE @operator VARCHAR(50) 

EXEC msdb.dbo.sp_add_alert @name = N'Database: Restore Success',
						   @message_id = 18267,
						   @severity = 0,
						   @enabled = 1,
						   @delay_between_responses = 60,
						   @include_event_description_in = 1
EXEC msdb.dbo.sp_add_notification @alert_name=N'Database: Restore Success',
                                  @operator_name='DBA',
                                  @notification_method = 1

SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Database: Restore Success'








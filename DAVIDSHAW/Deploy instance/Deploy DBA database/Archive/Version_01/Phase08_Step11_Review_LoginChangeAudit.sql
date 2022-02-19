USE [DBA]
GO

IF EXISTS (SELECT * FROM master.sys.server_triggers where name = 'trig_create_login') AND EXISTS (SELECT * FROM master.sys.server_triggers where name = 'trig_drop_login')
	BEGIN
	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'LoginChangeAudit')
		BEGIN
		PRINT 'Yes - table and both triggers'
		END
	END
ELSE IF EXISTS (SELECT * FROM master.sys.server_triggers where name = 'trig_create_login')
	BEGIN
	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'LoginChangeAudit')
		BEGIN
		PRINT 'Yes - table and create trigger only'
		END
	END	
ELSE IF EXISTS (SELECT * FROM master.sys.server_triggers where name = 'trig_drop_login')
	BEGIN
	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'LoginChangeAudit')
		BEGIN
		PRINT 'Yes - table and drop trigger only'
		END	
	END
ELSE
	BEGIN
	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'LoginChangeAudit')
		BEGIN
		PRINT 'Yes - table only... neither of the trigger'
		END	
	END

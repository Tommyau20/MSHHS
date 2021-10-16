USE [master]
GO

-- ***** create trigger to monitor dropping of SQL logins - version 1.00 *****
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--IF EXISTS (SELECT * FROM sys.server_triggers WHERE name = 'trig_drop_login')
--	DROP TRIGGER trig_drop_login
--	ON ALL SERVER
--GO

CREATE TRIGGER trig_drop_login
ON ALL SERVER 
FOR DROP_LOGIN
AS 
	BEGIN
	DECLARE @UserName VARCHAR(200),
            @servername VARCHAR(50), 
            @emailsubject VARCHAR(200),
	    	@new_login VARCHAR(100),
	    	@emailbody VARCHAR(1000),
			@operator VARCHAR(50) 
	SET @UserName = original_login()
	SET @servername = @@servername 
	SET @new_login = CAST(EVENTDATA().query('/EVENT_INSTANCE/ObjectName/text()') AS VARCHAR(100)) 
	SET @emailsubject = 'MSSQL alert - drop login notification for ' + @servername
	SET @emailbody = @UserName + ', has dropped the login "' + @new_login + '" on the server ' + @servername + CHAR(13) + CHAR(10)	
	EXEC msdb.dbo.sp_notify_operator @name = 'DBA',
									 @subject = @emailsubject,
									 @body = @emailbody
	EXEC [DBA].[dbo].[sp_LoginChangeAudit]
	END
GO


USE [master]
GO
-- ***** Create trigger to monitor the creation of databases *****
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--IF EXISTS (SELECT * FROM sys.server_triggers WHERE name = 'trig_create_database')
--	DROP TRIGGER trig_create_database
--	ON ALL SERVER
--GO

CREATE TRIGGER trig_create_database 
ON ALL SERVER 
FOR CREATE_DATABASE 
AS 
	BEGIN
    DECLARE @UserName VARCHAR(200),
            @servername VARCHAR(50), 
            @emailsubject VARCHAR(200),
	    @TSQL_statement VARCHAR(500),
	    @emailbody VARCHAR(1000),
 	    @operator VARCHAR(50)
	SELECT @UserName = original_login()
	SELECT @servername = @@servername 
	SELECT @TSQL_statement = EVENTDATA().value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]','nvarchar(max)')
	SET @emailsubject = 'MSSQL alert - create database notification for ' + @servername
	SET @emailbody = @UserName + ', has just created the following database on ' + @servername + ' with the following TSQL...' + CHAR(13) + CHAR(10) + @TSQL_statement

	-- ***** Email out alerts *****
    EXEC msdb.dbo.sp_notify_operator @name = 'DBA',
									 @subject = @emailsubject,
									 @body = @emailbody
	END
GO
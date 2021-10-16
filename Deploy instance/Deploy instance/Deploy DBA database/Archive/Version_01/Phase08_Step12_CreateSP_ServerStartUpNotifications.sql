USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_ServerStartUpNotifications]    Script Date: 09/27/2010 11:43:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_ServerStartUpNotifications]

AS

-- ***** Declare variables *****
DECLARE @Today VARCHAR(50)
DECLARE @Instance VARCHAR(100)
DECLARE @Environment VARCHAR(30)
DECLARE @MailSubject VARCHAR(100)
DECLARE @AlertMessage VARCHAR(500)
DECLARE @operator VARCHAR(150)

SET @Instance = CAST(SERVERPROPERTY('InstanceName') AS VARCHAR(100))
IF @Instance is NULL
	BEGIN
	SET @Instance = 'Default instance'
	END

SET @Today = getdate()
SELECT @Environment = [Value] From [DBA].[dbo].[Parameters] WHERE [Parameter] = 'Environment'
SET @MailSubject = 'MSSQL alert (' + @Environment + ') - Server startup ' + @@SERVERNAME
SET @AlertMessage = 'The instance "' + @Instance + '" on server ' + @@SERVERNAME + ', was started at ' + @Today
EXEC msdb.dbo.sp_notify_operator @name = 'DBA',
								 @subject = @MailSubject,
								 @body = @AlertMessage

-- ***** Populate DBA.ServerStartUp table with sent Email details *****
INSERT INTO DBA.dbo.ServerStartUpNotifications (Recipient,
												EmailSubject,
												EmailMessage,
												Date)
												SELECT 'DBA', @MailSubject, @AlertMessage, getdate()
GO

-- ***** configures server to execute this sp at server startup *****
USE [master]
exec sp_procoption N'sp_ServerStartUpNotifications', N'startup', N'true'
GO

-- *****************************************************************************************************************************************************
-- *****************************************************************************************************************************************************

-- ***** list stored procs configured to run at server startup *****
USE [master]
select name from sysobjects where objectproperty(id,'ExecIsStartup')=1
GO
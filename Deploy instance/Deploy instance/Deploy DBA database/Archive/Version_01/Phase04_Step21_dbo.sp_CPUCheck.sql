USE [DBA]
GO
/****** Object:  StoredProcedure [dbo].[sp_CPUCheck]    Script Date: 22/12/2020 7:59:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_CPUCheck] 
AS

-----------------------------------------------------------------------------------------------------------------------
-- Object Type : Stored Procedure  
-- Object Name : sp_CPUCheck
-- Description : Stored Procedure to compare the deployed CPU settings to the current CPU settings, which could have bearing on MAXDOP setting.
-- Author : David Shaw
-- Date : December 2020
DECLARE @sp_version VARCHAR(10)
SET @sp_version = '1.01'
-----------------------------------------------------------------------------------------------------------------------

-- ***** START - Default block of code for all of my SP's to populate the parameter table in DBA database with this SP's information *****
DECLARE @sp_name VARCHAR(100)
SELECT @sp_name = OBJECT_NAME(@@PROCID)
IF EXISTS (SELECT [Value] FROM [DBA].[dbo].[Parameters] WHERE [Parameter] = @sp_name)
	BEGIN
	UPDATE [DBA].[dbo].[Parameters] SET [Value] = @sp_version WHERE [Parameter] = @sp_name
	END
ELSE
	BEGIN
	INSERT INTO [DBA].[dbo].[Parameters] ([Parameter],[Value]) VALUES (@sp_name,@sp_version)
	END
-- ***** END - Default block of code for all of my SP's to populate the parameter table in DBA database with this SP's information *****

BEGIN
	DECLARE @MailSubject VARCHAR(100)
	DECLARE @MailBody VARCHAR(1500)
	DECLARE @environment VARCHAR(50) 
	SELECT @environment = [Value] FROM [DBA].[dbo].[Parameters] WHERE [Parameter] = 'Environment'
	If ((SELECT cpu_count FROM sys.dm_os_sys_info) <> (SELECT [value] FROM [DBA].[dbo].[Parameters] WHERE [Parameter] = 'CPU count at deployment')) OR 
				  ((SELECT hyperthread_ratio FROM sys.dm_os_sys_info) <> (SELECT [value] FROM [DBA].[dbo].[Parameters] WHERE [Parameter] = 'Hyperthread ratio at deployment'))
		   BEGIN       
		   SET @MailBody = 'There appears to have been CPU changes with the CPU count and Hyperthread ratio being different now to that of the time at deployment... hence possible affecting what the MAXDOP should now possible be configured as.' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)
		   SET @MailBody = @MailBody + 'SELECT [value] FROM [DBA].[dbo].[Parameters] WHERE [Parameter] = ''CPU count at deployment''' + CHAR(13) + CHAR(10)
		   SET @MailBody = @MailBody + 'SELECT [value] FROM [DBA].[dbo].[Parameters] WHERE [Parameter] = ''Hyperthread ratio at deployment''' + CHAR(13) + CHAR(10)
		   SET @MailBody = @MailBody + 'SELECT cpu_count FROM sys.dm_os_sys_info' + CHAR(13) + CHAR(10)
		   SET @MailBody = @MailBody + 'SELECT hyperthread_ratio FROM sys.dm_os_sys_info' + CHAR(13) + CHAR(10)
		   SET @MailBody = @MailBody + 'Please ensure you review the MAXDOP setting, as changes to CPU may have a bearing on MAXDOP.'
		   SET @MailSubject = 'MSSQL alert (' + @environment + ') - CPU changes on ' + @@SERVERNAME 
		   EXEC msdb.dbo.sp_notify_operator @name = 'DBA', @subject = @MailSubject, @body = @MailBody
		   END
	ELSE IF (((SELECT [value] FROM [DBA].[dbo].[Parameters] WHERE [Parameter] = 'CPU count at deployment') IS NULL) OR 
						 ((SELECT [value] FROM [DBA].[dbo].[Parameters] WHERE [Parameter] = 'Hyperthread ratio at deployment') IS NULL))
		   BEGIN        
		   SET @MailBody = 'Please look to see that both ''CPU count at deployment'' & ''Hyperthread ratio at deployment'' are configured in the DBA.dbo.Parameters table.' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)
		   SET @MailSubject = 'MSSQL alert (' + @environment + ') - parameters missing on ' + @@SERVERNAME 
		   EXEC msdb.dbo.sp_notify_operator @name = 'DBA', @subject = @MailSubject, @body = @MailBody
		   END
END

USE [DBA]
GO
/****** Object:  StoredProcedure [dbo].[sp_DiskSpaceCheck]    Script Date: 2/10/2020 8:25:25 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_DiskSpaceCheck]
AS
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
-- Object Type : Stored Procedure  
-- Description : Stored Procedure to send an email with low disk space alerts, based on the threshold
--				 values as set in the table db.DiskSpaceThresholds.				
-- Author : David Shaw
-- Date : November 2020
DECLARE @sp_version VARCHAR(10)
SET @sp_version = '2.19'
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------

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

-- **************************************** WARNING ****************************************************
-- If I was to continue to utilize this stored procedure, I will need to work on the code referencing
-- the registry key for the SQL agent "fail safe" where named instances are involved.
-- The other consideration is that, unlike Backup Exec, some software like CommVault may not turn off 
-- the archive attribute on flat files backups... so this stored procedure would be useless.
-- **************************************** WARNING ****************************************************

-- ***** START - Declare variables *****
DECLARE @xp_cmdshell_status INT -- used to determine current setting of xp_cmdshell
DECLARE @ole_auto_pro_status INT -- used to determine current setting of ole automation procedures
DECLARE @hr INT
DECLARE @fso INT
DECLARE @drive CHAR(1)
DECLARE @odrive INT
DECLARE @TotalSize NUMERIC
DECLARE @FreeSpace NUMERIC
DECLARE @MB NUMERIC
SET @MB = 1048576
DECLARE @DriveLetter CHAR(1)
DECLARE @DiskFreeSpacePercent INT
DECLARE @status VARCHAR(25)
DECLARE @UrgentAlertThreshold INT
DECLARE @CriticalAlertThreshold INT
DECLARE @min_free_GB INT
DECLARE @MailSubject VARCHAR(100)
DECLARE @AlertMessage VARCHAR(600)
DECLARE @operator VARCHAR(50)
DECLARE @environment varchar(50) -- used to capture the environment for this instance
SELECT @environment = [Value] FROM [DBA].[dbo].[Parameters] WHERE [Parameter] = 'Environment'

-- ***** START - enable xp_cmdshell for txt file writing *****
SELECT @xp_cmdshell_status = CONVERT(INT,value_in_use) from master.sys.configurations Where [name] = 'xp_cmdshell'
IF @xp_cmdshell_status = 0
	BEGIN
	EXEC master.sys.sp_configure 'xp_cmdshell', 1
	RECONFIGURE
	UPDATE DBA.dbo.cmdshell_state SET step_number = 1 WHERE job_name = 'sp_DiskSpaceCheck_xp'
	UPDATE DBA.dbo.cmdshell_state SET before_step = 0 WHERE job_name = 'sp_DiskSpaceCheck_xp'
	UPDATE DBA.dbo.cmdshell_state SET after_step = 1 WHERE job_name = 'sp_DiskSpaceCheck_xp'
	UPDATE DBA.dbo.cmdshell_state SET [Date_changed] = GETDATE() WHERE job_name = 'sp_DiskSpaceCheck_xp'
	END
SELECT @ole_auto_pro_status = CONVERT(INT,value_in_use) from master.sys.configurations Where [name] = 'Ole Automation Procedures'
IF @ole_auto_pro_status = 0
	BEGIN
	EXEC master.sys.sp_configure 'Ole Automation Procedures', 1
	RECONFIGURE
	UPDATE DBA.dbo.cmdshell_state SET step_number = 1 WHERE job_name = 'sp_DiskSpaceCheck_ole'
	UPDATE DBA.dbo.cmdshell_state SET before_step = 0 WHERE job_name = 'sp_DiskSpaceCheck_ole'
	UPDATE DBA.dbo.cmdshell_state SET after_step = 1 WHERE job_name = 'sp_DiskSpaceCheck_ole'
	UPDATE DBA.dbo.cmdshell_state SET [Date_changed] = GETDATE() WHERE job_name = 'sp_DiskSpaceCheck_ole'
	END
-- ****** END - enable xp_cmdshell for txt file writing *****

SET @status = 'normal'
SET @AlertMessage = 'The following problem(s) has been detected on ' + @@SERVERNAME + ';' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)
-- ***** END - Declare variables *****

-- ***** Start drop/create temporary table *****
IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id = object_id(N'[tempdb]..[#drives]'))
	BEGIN
	DROP TABLE #drives
	END
CREATE TABLE #drives (drive CHAR(1) PRIMARY KEY,
                      TotalSizeMB INT NULL,
					  FreeSpaceMB INT NULL,
					  PercentageFree INT NULL)
-- ***** End drop/create temporary table *****

-- ***** Start populate tempory table #drives with data *****
INSERT #drives(drive,FreeSpaceMB) EXEC xp_fixeddrives 
EXEC @hr=sp_OACreate 'Scripting.FileSystemObject',@fso OUT IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso
DECLARE dcur CURSOR LOCAL FAST_FORWARD FOR SELECT drive FROM #drives 
    ORDER BY drive
OPEN dcur FETCH NEXT FROM dcur INTO @drive
WHILE @@FETCH_STATUS=0
   BEGIN
     EXEC @hr = sp_OAMethod @fso,'GetDrive', @odrive OUT, @drive IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso EXEC @hr = sp_OAGetProperty @odrive,'TotalSize', @TotalSize OUT IF @hr <> 0 EXEC sp_OAGetErrorInfo @odrive 
     UPDATE #drives SET TotalSizeMB = (@TotalSize/@MB) WHERE drive=@drive
	 SELECT @TotalSize = [TotalSizeMB] FROM #drives WHERE drive=@drive
	 SELECT @FreeSpace = [FreeSpaceMB] FROM #drives WHERE drive=@drive
	 UPDATE #drives SET PercentageFree = (@FreeSpace/@TotalSize*100) WHERE drive=@drive
	 FETCH NEXT FROM dcur INTO @drive
   END
CLOSE dcur
DEALLOCATE dcur
-- ***** End populate tempory table #drives with data *****

-- ***** Start cursor build query ***** 
DECLARE DriveSpace CURSOR FAST_FORWARD FOR
	SELECT [drive], [PercentageFree] from #drives

OPEN DriveSpace
FETCH NEXT from DriveSpace into @DriveLetter, @DiskFreeSpacePercent

WHILE (@@FETCH_STATUS = 0)
	BEGIN
	IF NOT EXISTS (SELECT [DriveLetter] FROM [dbo].[DiskSpaceThresholds] WHERE [DriveLetter] = @DriveLetter)
		BEGIN
		IF @status <> 'CRITICAL' AND @status <> 'URGENT'
			BEGIN
			SET @status = 'IMPORTANT INFORMATION'
			END
		SET @AlertMessage = @AlertMessage + @DriveLetter + ' does not appear to have a threshold set.' + CHAR(13) + CHAR(10)
		END


	-- ***************************************** LATEST CHANGE *******************************************************
	-- ********************** START - Changed check of less then 10GB to the below IF statement **********************
	SELECT @FreeSpace = ([FreeSpaceMB]/1024) FROM #drives WHERE drive=@DriveLetter
	SELECT @min_free_GB = [Minimum_FreeGB] FROM [dbo].[DiskSpaceThresholds] WHERE [DriveLetter] = @DriveLetter
	IF @FreeSpace < @min_free_GB OR @min_free_GB IS NULL -- only execute if @FreeSpace is less than @min_free_GB or @min_free_GB is NULL
		BEGIN
		SELECT @CriticalAlertThreshold = (SELECT [Critical_FreePercent] FROM [dbo].[DiskSpaceThresholds] WHERE [DriveLetter] = @DriveLetter)
		IF @DiskFreeSpacePercent < @CriticalAlertThreshold
			BEGIN
			SET @status = 'CRITICAL'
			--SELECT @FreeSpace = ([FreeSpaceMB]/1024) FROM #drives WHERE drive=@DriveLetter
			SET @AlertMessage = @AlertMessage + @DriveLetter + ' drive has only ' + cast(@FreeSpace as varchar) + 'GB (' + cast(@DiskFreeSpacePercent as varchar) + ' %) free disk space.' + CHAR(13) + CHAR(10)
			END	
		SELECT @UrgentAlertThreshold = (SELECT [Urgent_FreePercent] FROM [dbo].[DiskSpaceThresholds] WHERE [DriveLetter] = @DriveLetter)
		IF @DiskFreeSpacePercent < @UrgentAlertThreshold AND @DiskFreeSpacePercent > @CriticalAlertThreshold
			BEGIN
			IF @status <> 'CRITICAL' 
				BEGIN
				SET @status = 'URGENT'
				END
			--SELECT @FreeSpace = ([FreeSpaceMB]/1024) FROM #drives WHERE drive=@DriveLetter	    
			SET @AlertMessage = @AlertMessage + @DriveLetter + ' drive has only ' + cast(@FreeSpace as varchar) + 'GB (' + cast(@DiskFreeSpacePercent as varchar) + ' %) free disk space.' + CHAR(13) + CHAR(10)
			END
		END
	-- ********************** END - Changed check of less then 10GB to the below IF statement **********************
	-- ***************************************************************************************************************
		
			
	FETCH NEXT from DriveSpace into @DriveLetter, @DiskFreeSpacePercent
	END
CLOSE DriveSpace
DEALLOCATE DriveSpace
DROP TABLE #drives
-- ***** End cursor build query *****

-- ***** Start send email, and populate audit tables should there be an disk space issue  *****
IF @status <> 'normal'	
	BEGIN
		
		-- ************************* START - New line, not yet tested ********************************
		SET @AlertMessage = @AlertMessage + CHAR(13) + CHAR(10) + 'If required, please review/configure the current data/settings in the table DBA.dbo.DiskSpaceThresholds on the aforementioned server/instance.' + CHAR(13) + CHAR(10)
		-- ************************* END - New line, not yet tested ********************************

		SET @MailSubject = 'MSSQL alert (' + @environment + ') - ' + @status + ', low disk space on ' + @@SERVERNAME
		-- EXEC sys.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'AlertFailSafeOperator', @param = @operator OUT, @no_output = N'no_output'
		SET @operator = 'DBA'
		EXEC msdb.dbo.sp_notify_operator @name = @operator,
										@subject = @MailSubject,
										@body = @AlertMessage
		 -- ***** Populate DBA.DiskSpaceAlert table with sent Email details *****
		 INSERT INTO DiskSpaceAlerts
				(Recipient,
				EmailSubject,
				EmailMessage,
				Date)
				SELECT @operator,
					   @MailSubject,
					   @AlertMessage,
					   getdate()
		 -- ***** Execute sp_DiskSpaceAudit *****
		 EXECUTE DBA.dbo.sp_DiskSpaceAudit
	 END
-- ***** End send email, and populate audit tables should there be an disk space issue  *****

-- ***** Start reverts xp_cmdshell setting where required *****
SELECT @xp_cmdshell_status = after_step FROM DBA.dbo.cmdshell_state WHERE job_name = 'sp_DiskSpaceCheck_xp'
IF @xp_cmdshell_status = 1
	BEGIN
	EXEC master.sys.sp_configure 'xp_cmdshell', 0
	RECONFIGURE	
	UPDATE DBA.dbo.cmdshell_state SET step_number = 0 WHERE job_name = 'sp_DiskSpaceCheck_xp'
	UPDATE DBA.dbo.cmdshell_state SET before_step = 0 WHERE job_name = 'sp_DiskSpaceCheck_xp'
	UPDATE DBA.dbo.cmdshell_state SET after_step = 0 WHERE job_name = 'sp_DiskSpaceCheck_xp'
	UPDATE DBA.dbo.cmdshell_state SET [Date_reverted] = GETDATE() WHERE job_name = 'sp_DiskSpaceCheck_xp'
	END
SELECT @ole_auto_pro_status = after_step FROM DBA.dbo.cmdshell_state WHERE job_name = 'sp_DiskSpaceCheck_ole'
IF @ole_auto_pro_status = 1
	BEGIN
	EXEC master.sys.sp_configure 'Ole Automation Procedures', 0
	RECONFIGURE	
	UPDATE DBA.dbo.cmdshell_state SET step_number = 0 WHERE job_name = 'sp_DiskSpaceCheck_ole'
	UPDATE DBA.dbo.cmdshell_state SET before_step = 0 WHERE job_name = 'sp_DiskSpaceCheck_ole'
	UPDATE DBA.dbo.cmdshell_state SET after_step = 0 WHERE job_name = 'sp_DiskSpaceCheck_ole'
	UPDATE DBA.dbo.cmdshell_state SET [Date_reverted] = GETDATE() WHERE job_name = 'sp_DiskSpaceCheck_ole'
	END
-- ***** End reverts xp_cmdshell setting where required *****

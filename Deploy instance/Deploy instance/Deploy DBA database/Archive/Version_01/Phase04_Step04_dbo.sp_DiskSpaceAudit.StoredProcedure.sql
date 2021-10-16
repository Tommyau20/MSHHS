USE [DBA]
GO
/****** Object:  StoredProcedure [dbo].[sp_DiskSpaceAudit]    Script Date: 19/11/2018 8:38:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-----------------------------------------------------------------------------------------------------------------------
-- Object Type : Stored Procedure  
-- Object Name : sp_DiskSpaceAudit
-- Description : Stored Procedure to insert disk space audit information into the table DBA.dbo.DiskSpaceAudit
-- Author : David Shaw
-- Date : October 2012
-- Version : 1.06
-----------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[sp_DiskSpaceAudit] AS
SET NOCOUNT ON

CREATE TABLE #drives (drive CHAR(1) PRIMARY KEY,
                      FreeSpace INT NULL,
                      TotalSize INT NULL)
DECLARE @hr INT
DECLARE @fso INT
DECLARE @drive CHAR(1)
DECLARE @odrive INT
DECLARE @TotalSize VARCHAR(20) 
DECLARE @MB NUMERIC
DECLARE @xp_cmdshell_status INT -- used to determine current setting of xp_cmdshell
DECLARE @ole_auto_pro_status INT -- used to determine current setting of ole automation procedures  
SET @MB = 1048576
-- ***** Start enable xp_cmdshell for txt file writing *****
SELECT @xp_cmdshell_status = CONVERT(INT,value_in_use) from master.sys.configurations Where [name] = 'xp_cmdshell'
IF @xp_cmdshell_status = 0
	BEGIN
	EXEC master.sys.sp_configure 'xp_cmdshell', 1
	RECONFIGURE
	UPDATE DBA.dbo.cmdshell_state SET step_number = 1 WHERE job_name = 'sp_DiskSpaceAudit_xp'
	UPDATE DBA.dbo.cmdshell_state SET before_step = 0 WHERE job_name = 'sp_DiskSpaceAudit_xp'
	UPDATE DBA.dbo.cmdshell_state SET after_step = 1 WHERE job_name = 'sp_DiskSpaceAudit_xp'
	UPDATE DBA.dbo.cmdshell_state SET [Date_changed] = GETDATE() WHERE job_name = 'sp_DiskSpaceAudit_xp'
	END
SELECT @ole_auto_pro_status = CONVERT(INT,value_in_use) from master.sys.configurations Where [name] = 'Ole Automation Procedures'
IF @ole_auto_pro_status = 0
	BEGIN
	EXEC master.sys.sp_configure 'Ole Automation Procedures', 1
	RECONFIGURE
	UPDATE DBA.dbo.cmdshell_state SET step_number = 1 WHERE job_name = 'sp_DiskSpaceAudit_ole'
	UPDATE DBA.dbo.cmdshell_state SET before_step = 0 WHERE job_name = 'sp_DiskSpaceAudit_ole'
	UPDATE DBA.dbo.cmdshell_state SET after_step = 1 WHERE job_name = 'sp_DiskSpaceAudit_ole'
	UPDATE DBA.dbo.cmdshell_state SET [Date_changed] = GETDATE() WHERE job_name = 'sp_DiskSpaceAudit_ole'
	END
-- ****** End enable xp_cmdshell for txt file writing *****
INSERT #drives(drive,FreeSpace) EXEC xp_fixeddrives EXEC @hr=sp_OACreate 'Scripting.FileSystemObject',@fso OUT IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso
DECLARE dcur CURSOR LOCAL FAST_FORWARD FOR SELECT drive FROM #drives 
    ORDER BY drive
OPEN dcur FETCH NEXT FROM dcur INTO @drive
WHILE @@FETCH_STATUS=0
   BEGIN
     EXEC @hr = sp_OAMethod @fso,'GetDrive', @odrive OUT, @drive IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso EXEC @hr = sp_OAGetProperty @odrive,'TotalSize', @TotalSize OUT IF @hr <> 0 EXEC sp_OAGetErrorInfo @odrive 
     UPDATE #drives SET TotalSize=@TotalSize/@MB WHERE drive=@drive
	 FETCH NEXT FROM dcur INTO @drive
   END
CLOSE dcur
DEALLOCATE dcur


INSERT INTO DBA.dbo.[DiskSpaceAudit]
	([DriveLetter], [TotalSpaceGB], [FreeSpaceGB], [Date]) SELECT [drive], CAST([TotalSize] AS DECIMAL (11,2))/1024, CAST([FreeSpace] AS DECIMAL (11,2))/1024, (getdate()) FROM #drives
UPDATE DBA.dbo.[DiskSpaceAudit] SET [ServerName]=(@@SERVERNAME) WHERE [ServerName] IS NULL
DECLARE @Instance VARCHAR(25)
SET @Instance = (SELECT (CONVERT (VARCHAR(25), (SERVERPROPERTY('InstanceName')))))
IF @Instance IS NULL 
	BEGIN
	SET @Instance = 'default'
	END
UPDATE DBA.dbo.[DiskSpaceAudit] SET [InstanceName]= @Instance WHERE [InstanceName] IS NULL

DROP TABLE #drives

-- ***** Start reverts xp_cmdshell setting where required *****
SELECT @xp_cmdshell_status = after_step FROM DBA.dbo.cmdshell_state WHERE job_name = 'sp_DiskSpaceAudit_xp'
IF @xp_cmdshell_status = 1
	BEGIN
	EXEC master.sys.sp_configure 'xp_cmdshell', 0
	RECONFIGURE	
	UPDATE DBA.dbo.cmdshell_state SET step_number = 0 WHERE job_name = 'sp_DiskSpaceAudit_xp'
	UPDATE DBA.dbo.cmdshell_state SET before_step = 0 WHERE job_name = 'sp_DiskSpaceAudit_xp'
	UPDATE DBA.dbo.cmdshell_state SET after_step = 0 WHERE job_name = 'sp_DiskSpaceAudit_xp'
	UPDATE DBA.dbo.cmdshell_state SET [Date_reverted] = GETDATE() WHERE job_name = 'sp_DiskSpaceAudit_xp'
	END
SELECT @ole_auto_pro_status = after_step FROM DBA.dbo.cmdshell_state WHERE job_name = 'sp_DiskSpaceAudit_ole'
IF @ole_auto_pro_status = 1
	BEGIN
	EXEC master.sys.sp_configure 'Ole Automation Procedures', 0
	RECONFIGURE	
	UPDATE DBA.dbo.cmdshell_state SET step_number = 0 WHERE job_name = 'sp_DiskSpaceAudit_ole'
	UPDATE DBA.dbo.cmdshell_state SET before_step = 0 WHERE job_name = 'sp_DiskSpaceAudit_ole'
	UPDATE DBA.dbo.cmdshell_state SET after_step = 0 WHERE job_name = 'sp_DiskSpaceAudit_ole'
	UPDATE DBA.dbo.cmdshell_state SET [Date_reverted] = GETDATE() WHERE job_name = 'sp_DiskSpaceAudit_ole'
	END
-- ***** End reverts xp_cmdshell setting where required *****
GO

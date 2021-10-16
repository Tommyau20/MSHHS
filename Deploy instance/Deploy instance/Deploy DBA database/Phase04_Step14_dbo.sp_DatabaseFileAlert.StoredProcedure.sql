USE [DBA]
GO
/****** Object:  StoredProcedure [dbo].[sp_DatabaseFileAlert]    Script Date: 11/05/2021 7:35:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[sp_DatabaseFileAlert]
@ignore_auto_growth_notifications Bit = 0 -- default being, databases with autogrowth enabled will result in notification.

AS

-----------------------------------------------------------------------------------------------------------------------
-- Object Type : Stored Procedure  
-- Object Name : sp_DatabaseFileAlert
-- Description : This stored procedures purpose is to alert if a database has Autogrowth ENABLED or if a database has Autogrowth DISABLED
--				 and its file(s) have exceeded the used capacity alert threshold. 
--				 The orginaly driver for this stored procedure was for the monitoring of databases in an Azure Managed Instance, 
--				 where Azure Managed Instances have a 8TB capacity hard limit... which was an issues for IEMR reporting system, developed by the MSHHS BI team.
-- Concieved after looking at the following - https://www.mssqltips.com/sqlservertip/2359/find-sql-server-data-and-log-files-that-are-almost-out-of-space/
-- Author : David Shaw
-- Date : February 2021
DECLARE @sp_version VARCHAR(10)
SET @sp_version = '1.02'
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
-- ***** START - Declare variables *****
DECLARE @DBID int,
 	    @DB_name varchar (150),
		@DB_name_offline varchar (150),
		@SQL varchar(1000),
		@FileName varchar(500),
        @FileAllocated decimal(11,2),
        @FileUsed decimal(11,2),
		@ID int,
		@AutoGrowth bit,
		--@FILE_DIR AS VARCHAR(250) = 'C:\Windows\Temp\',
		@used_capacity_threshold int = 80, -- this is the max used capacity threshold for database files as a percentage.
		@environment varchar(50),
		@operator VARCHAR(50),
		@emailsubject VARCHAR(100),
		@emailbody VARCHAR(MAX) = '',
		@email_recipients NVARCHAR(250) 
SELECT @environment = [Value] FROM [DBA].[dbo].[Parameters] WHERE [Parameter] = 'Environment'
-- ***** END - Declare variables *****

-- ***** START - Create and populate temporary tables #DataFiles,to hold the datafile stats *****
CREATE TABLE #DataFiles
	(ID int IDENTITY(1,1) NOT NULL,
	 Fileid int,
     [FileGroup] int,
     TotalExtents int,
     UsedExtents int,
	 [Name] varchar(150),
	 [FileName] varchar(1000),
	 DatabaseName varchar(250))
DECLARE cursor_01 CURSOR FOR  
	  SELECT [name] FROM master.sys.databases WHERE [state_desc] = 'ONLINE'	AND [name] NOT IN ('tempdb','ReportServerTempDB')
	  --SELECT [name] FROM master.sys.databases WHERE [state_desc] = 'ONLINE'	AND [name] NOT IN ('master','msdb','model','ReportServer', 'Distribution','tempdb','ReportServerTempDB')
OPEN cursor_01   
FETCH NEXT FROM cursor_01 INTO @DB_name 
WHILE @@FETCH_STATUS = 0   
	BEGIN
	SET @SQL = 'USE ['+@DB_name+'] INSERT INTO #DataFiles (Fileid, [FileGroup], TotalExtents, UsedExtents, [Name], [FileName]) exec (''DBCC SHOWFILESTATS'')'
	EXEC (@SQL)
	UPDATE #DataFiles SET #DataFiles.DatabaseName = @DB_name WHERE DatabaseName IS NULL
	FETCH NEXT FROM cursor_01 INTO @DB_name   
	END
CLOSE cursor_01   
DEALLOCATE cursor_01
-- ***** END - Create and populate temporary tables #DataFiles,to hold the datafile stats *****

-- ***** START - Create and populate temporary tables #LogFiles, to hold the logfile stats *****
CREATE TABLE #LogFiles
	(ID int IDENTITY(1,1) NOT NULL,
	 [Database ID] int,
	 [Database Name] varchar(150),
	 [Log Size(MB)] decimal(11,2),
	 [Log Space Used(%)] decimal(11,2),
	 [Status] int,
	 [FileName] varchar(500))
INSERT INTO #LogFiles ([Database Name], [Log Size(MB)], [Log Space Used(%)], [Status])exec ('DBCC SQLPERF (LOGSPACE)')
UPDATE #LogFiles SET #LogFiles.[Database ID] = 
	(SELECT [dbid] FROM master.dbo.sysdatabases WHERE [name] = #LogFiles.[Database Name])
-- START - Changes I made to cater for more then one ldf file
UPDATE #LogFiles SET #LogFiles.FileName = 
    (SELECT physical_name FROM sys.master_files WHERE [database_id] = #LogFiles.[Database ID] AND [type] = 1 AND [file_id] <= 2)
UPDATE #LogFiles SET #LogFiles.FileName = 'multiple log files'
		WHERE [Database ID] = (SELECT [database_id] FROM sys.master_files where [database_id] = #LogFiles.[Database ID] AND [type] = 1 AND [file_id] > 2)
-- END - Changes I made to cater for more then one ldf file
-- ***** END - Create and populate temporary tables #LogFiles, to hold the logfile stats *****

-- ***** START - Create temp table #CombinedFiles *****
CREATE TABLE #CombinedFiles
	(ID int IDENTITY(1,1) NOT NULL,
	[DatabaseID] int,
	[DatabaseName] varchar(100),
	[FileName] varchar(500),
	[FileAllocated (MB)] decimal(11, 2),
	[FileUsed (%)] decimal(11, 2),
	[AutoGrowth] bit,
	[MaxFileSize] bigint,
	[RecordedDate] datetime)
-- ***** END - Create temp table #CombinedFiles *****

-- ***** START - Insert data from #DataFiles into #CombinedFiles *****
DECLARE cursor_02 CURSOR FOR  
	SELECT [ID] FROM #DataFiles 
OPEN cursor_02   
FETCH NEXT FROM cursor_02 INTO @ID 
WHILE @@FETCH_STATUS = 0   
	BEGIN
    SELECT @DB_name = [DatabaseName] FROM #DataFiles WHERE [ID] = @ID
	SELECT @DBID = [dbid] FROM master.dbo.sysdatabases WHERE [NAME] = @DB_name
	SELECT @FileName = [FileName] FROM #DataFiles WHERE  [ID] = @ID
	SELECT @FileAllocated = TotalExtents * 64.0 / 1024.0 FROM #DataFiles WHERE  [ID] = @ID
    SELECT @FileUsed = (UsedExtents * 64.0 / 1024.0) / (TotalExtents * 64.0 / 1024.0) * 100 FROM #DataFiles WHERE  [ID] = @ID
	INSERT INTO #CombinedFiles ([DatabaseID],[DatabaseName], [FileName], [FileAllocated (MB)], [FileUsed (%)],[RecordedDate])
		VALUES (@DBID,
				@DB_name,
				@FileName,
				@FileAllocated,
				@FileUsed,				
				getdate())
	FETCH NEXT FROM cursor_02 INTO @ID
	END
CLOSE cursor_02   
DEALLOCATE cursor_02
-- ***** END - Insert data from #DataFiles into #CombinedFiles *****

-- ***** START - Insert data from #LogFiles into #CombinedFiles *****
DECLARE cursor_03 CURSOR FOR  
	SELECT [name] FROM master.dbo.sysdatabases WHERE [version] is not NULL
OPEN cursor_03   
FETCH NEXT FROM cursor_03 INTO @DB_name 
WHILE @@FETCH_STATUS = 0   
	BEGIN
    SELECT @DBID = [dbid] FROM master.dbo.sysdatabases WHERE [NAME] = @DB_name
	SELECT @FileName = [FileName] FROM #LogFiles WHERE [Database Name] = @DB_name
	SELECT @FileAllocated = [Log Size(MB)] FROM #LogFiles WHERE [Database Name] = @DB_name
    SELECT @FileUsed = [Log Space Used(%)] FROM #LogFiles WHERE [Database Name] = @DB_name
	INSERT INTO #CombinedFiles ([DatabaseID],[DatabaseName], [FileName], [FileAllocated (MB)], [FileUsed (%)],[RecordedDate])
		VALUES (@DBID,
				@DB_name,
				@FileName,
				@FileAllocated,
				@FileUsed,				
				getdate())
	FETCH NEXT FROM cursor_03 INTO @DB_name   
	END
CLOSE cursor_03   
DEALLOCATE cursor_03
-- ***** END - Insert data from #LogFiles into #CombinedFiles *****

-- ***** START - Update temp table with Autogrowth setting *****
UPDATE #CombinedFiles  
   SET [AutoGrowth] = (SELECT growth FROM sys.master_files WHERE [physical_name] = #CombinedFiles.[FileName])
-- ***** END - Update temp table with Autogrowth setting *****

-- ***** START - Update temp table with MaxFileSize setting *****
UPDATE #CombinedFiles  
   SET [MaxFileSize] = (SELECT [max_size] FROM sys.master_files WHERE [physical_name] = #CombinedFiles.[FileName])
-- ***** END - Update temp table with MaxFileSize setting *****


-- **************************************************************************************************************************************************************************************
-- ************************************************************************* SEND EMAIL NOTIFICATION ************************************************************************************
-- **************************************************************************************************************************************************************************************

-- ***** START - Email notification based on those database(s) with Autogrowth set to true *****
If @ignore_auto_growth_notifications = 0 -- if condition, to ignore sending notification should the paramter to do so be declared on execution.
	BEGIN	
	IF EXISTS(SELECT DatabaseName, [FileName], [FileAllocated (MB)], [FileUsed (%)], AutoGrowth FROM #CombinedFiles WHERE [AutoGrowth] = 1)
		BEGIN
		SET @emailbody = '<p>Below is a list of database(s) (does not include system databases e.g. master, msdb etc) that maybe considered troublesum with AutoGrowth ENABLED, meaning there has been no capacity planning conducted for these databases.</p><p>' + CHAR(10) + CHAR(10)
		DECLARE @04_DatabaseName varchar(100),
				@04_FileName varchar(500)	
		DECLARE cursor_04 CURSOR FOR  
			SELECT ID FROM #CombinedFiles WHERE [AutoGrowth] = 1 AND [DatabaseName] NOT IN ('master','msdb','model','tempdb','ReportServer','ReportServerTempDB')  ORDER BY [DatabaseName]
		OPEN cursor_04   
		FETCH NEXT FROM cursor_04 INTO @ID
		WHILE @@FETCH_STATUS = 0   
			BEGIN
			SELECT @04_DatabaseName = [DatabaseName] FROM #CombinedFiles WHERE [ID] = @ID
			SELECT @04_FileName = [FileName] FROM #CombinedFiles WHERE [ID] = @ID		
			SET @emailbody = @emailbody + 'The database file "<i><b>' + @04_FileName + '</b></i>" belonging to database "<b><i>' +  @04_DatabaseName + '</i></b>", has <i>AutoGrowth</i> enabled.<br>' + CHAR(10)					
			FETCH NEXT FROM cursor_04 INTO @ID   
			END
		CLOSE cursor_04   
		DEALLOCATE cursor_04
		SET @emailbody = @emailbody + '</p>'
		SET @emailsubject = 'MSSQL alert (' + @environment + ') - database(s) with AutoGrowth enabled.'		
		SELECT @email_recipients = ISNULL(email_address, 'David.Shaw@health.qld.gov.au') FROM msdb.dbo.sysoperators WHERE [name] = 'DBA'
		EXEC msdb.dbo.sp_send_dbmail @recipients = @email_recipients,    
									 @subject =  @emailsubject,
									 @body =  @emailbody,    
									 @body_format = 'HTML';
		END
	END
-- ***** END - Email notification based on those database(s) with Autogrowth set to true *****

-- ***** START - Email notification based on those database(s) with no Autogrowth and exceeding the threshold for percentage of file size used *****
IF EXISTS(SELECT DatabaseName, [FileName], [FileAllocated (MB)], [FileUsed (%)], AutoGrowth FROM #CombinedFiles WHERE [AutoGrowth] = 0 AND [FileUsed (%)] > @used_capacity_threshold)
	BEGIN
	SET @emailbody = '<p>Below is a list of database(s) with AutoGrowth DISABLED that have exceeded the threshold for used capacity of ' + CONVERT(varchar,@used_capacity_threshold) + '%.</p><p>' + CHAR(10) + CHAR(10)
	DECLARE @05_DatabaseName varchar(100),
			@05_FileName varchar(500),
			@05_FileAllocated decimal(11, 2),
			@05_FileUsed decimal(11, 2)			
	DECLARE cursor_05 CURSOR FOR  
		SELECT ID FROM #CombinedFiles WHERE [AutoGrowth] = 0 AND [FileUsed (%)] > @used_capacity_threshold ORDER BY [DatabaseName]
	OPEN cursor_05   
	FETCH NEXT FROM cursor_05 INTO @ID
	WHILE @@FETCH_STATUS = 0   
		BEGIN
		SELECT @05_DatabaseName = [DatabaseName] FROM #CombinedFiles WHERE [ID] = @ID
		SELECT @05_FileName = [FileName] FROM #CombinedFiles WHERE [ID] = @ID		
		SELECT @05_FileAllocated = [FileAllocated (MB)] FROM #CombinedFiles WHERE [ID] = @ID
		SELECT @05_FileUsed = [FileUsed (%)] FROM #CombinedFiles WHERE [ID] = @ID		
		SET @emailbody = @emailbody + 'Database "' + @05_DatabaseName + '" with <i>AutoGrowth</i> disabled, has consumed ' + CONVERT(varchar(10),@05_FileUsed) + '% of the allocated ' + CONVERT(varchar(10),@05_FileAllocated) + 'MB for the file "' + @05_FileName + '"<br>' + CHAR(10)					
		FETCH NEXT FROM cursor_05 INTO @ID   
		END
	CLOSE cursor_05   
	DEALLOCATE cursor_05
	SET @emailbody = @emailbody + '</p>'
	SET @emailsubject = 'MSSQL alert (' + @environment + ') - database(s) exceeding used capacity threshold (' + CONVERT(varchar(5),@used_capacity_threshold) + '%)'	
	SELECT @email_recipients = ISNULL(email_address, 'David.Shaw@health.qld.gov.au') FROM msdb.dbo.sysoperators WHERE [name] = 'DBA'
	EXEC msdb.dbo.sp_send_dbmail @recipients = @email_recipients,    
								 @subject =  @emailsubject,
								 @body =  @emailbody,    
								 @body_format = 'HTML';
	END
-- ***** END - Email notification based on those database(s) with no Autogrowth and exceeding the threshold for percentage of file size used *****
	
-- ***** START - Email notification based on those database(s) with Autogrowth enabled and a max size limit configured and exceeding the threshold for percentage of file size used *****
IF EXISTS(SELECT DatabaseName, [FileName], [FileAllocated (MB)], [FileUsed (%)], AutoGrowth FROM #CombinedFiles WHERE [AutoGrowth] = 1 AND [MaxFileSize] <> -1 AND [FileUsed (%)] > @used_capacity_threshold)
	BEGIN
	SET @emailbody = '<p>Below is a list of database(s) with AutoGrowth ENABLED but have a max limit set and have exceeded the threshold for used capacity of ' + CONVERT(varchar,@used_capacity_threshold) + '%.</p><p>' + CHAR(10) + CHAR(10)
	DECLARE @06_DatabaseName varchar(100),
			@06_FileName varchar(500),
			@06_FileAllocated decimal(11, 2),
			@06_FileUsed decimal(11, 2),
			@06_MaxFileSize bigint
	DECLARE cursor_06 CURSOR FOR  
		SELECT ID FROM #CombinedFiles WHERE [AutoGrowth] = 1 AND [MaxFileSize] <> -1 AND [FileUsed (%)] > @used_capacity_threshold ORDER BY [DatabaseName]
	OPEN cursor_06   
	FETCH NEXT FROM cursor_06 INTO @ID
	WHILE @@FETCH_STATUS = 0   
		BEGIN
		SELECT @06_DatabaseName = [DatabaseName] FROM #CombinedFiles WHERE [ID] = @ID
		SELECT @06_FileName = [FileName] FROM #CombinedFiles WHERE [ID] = @ID		
		SELECT @06_FileAllocated = [FileAllocated (MB)] FROM #CombinedFiles WHERE [ID] = @ID
		SELECT @06_FileUsed = [FileUsed (%)] FROM #CombinedFiles WHERE [ID] = @ID		
		SELECT @06_MaxFileSize = [MaxFileSize] FROM #CombinedFiles WHERE [ID] = @ID		
		SET @emailbody = @emailbody + 'Database "' + @06_DatabaseName + '" with AutoGrowth enabled, has consumed ' + CONVERT(varchar(10),@06_FileUsed) + '% of the allocated ' + CONVERT(varchar(10),@06_FileAllocated) + 'MB for the file "' + @06_FileName + '" which has a max size of ' + CONVERT(varchar(10),((CONVERT(bigint,@06_MaxFileSize))*8)/1024) + 'MB configured.<br>' + CHAR(10)					
		FETCH NEXT FROM cursor_06 INTO @ID   
		END
	CLOSE cursor_06   
	DEALLOCATE cursor_06
	SET @emailbody = @emailbody + '</p>'
	SET @emailsubject = 'MSSQL alert (' + @environment + ') - database(s) with max limit configured exceeding used capacity threshold (' + CONVERT(varchar(5),@used_capacity_threshold) + '%)'	
	SELECT @email_recipients = ISNULL(email_address, 'David.Shaw@health.qld.gov.au') FROM msdb.dbo.sysoperators WHERE [name] = 'DBA'
	EXEC msdb.dbo.sp_send_dbmail @recipients = @email_recipients,    
								 @subject =  @emailsubject,
								 @body =  @emailbody,    
								 @body_format = 'HTML';
	END
-- ***** END - Email notification based on those database(s) with Autogrowth enabled and a max size limit configured and exceeding the threshold for percentage of file size used *****

-- ***** START - Drop up temporary tables *****
DROP TABLE #DataFiles
DROP TABLE #LogFiles
DROP TABLE #CombinedFiles
--SELECT * from #CombinedFiles
--SELECT * FROM #CombinedFiles WHERE [AutoGrowth] = 1 AND [MaxFileSize] <> -1
--SELECT * FROM #CombinedFiles WHERE [AutoGrowth] = 1 AND [MaxFileSize] <> -1 AND [FileUsed (%)] > @used_capacity_threshold ORDER BY [DatabaseName]
-- ***** END - Drop up temporary tables *****
END
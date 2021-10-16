USE [DBA]
GO
/****** Object:  StoredProcedure [dbo].[sp_DatabaseFileAudit]    Script Date: 11/22/2019 7:20:59 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-----------------------------------------------------------------------------------------------------------------------
-- Object Type : Stored Procedure  
-- Object Name : sp_DatabaseFileAudit
-- Description : Stored Procedure to insert database audit information into the table DBA.dbo.DatabaseFileAudit
-- Author : David Shaw
-- Date : December 2019
-- Version : 1.15
-----------------------------------------------------------------------------------------------------------------------


CREATE PROCEDURE [dbo].[sp_DatabaseFileAudit]
	@RECORD AS INT = 1, -- *** Changing this value from a 1 to a 0 will result in a select rather than a table insert ***
	@FILE_DIR AS VARCHAR(250) = 'C:\Windows\Temp\'
AS

SET NOCOUNT OFF
-- Declare variables
DECLARE @DBID int,
 	    @DB_name varchar (150),
		@DB_name_offline varchar (150),
		@SQL varchar(1000),
		@FileName varchar(500),
        @FileAllocated decimal(11,2),
        @FileUsed decimal(11,2),
		@ID int,
		@AutoGrowth bit

-- Create and populate temporary tables #DataFiles,to hold the datafile stats
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
	--SELECT [name] FROM master.dbo.sysdatabases
	--SELECT [name] FROM master.sys.databases WHERE [name] NOT IN ('tempdb') AND [state_desc] = 'ONLINE'	 
	--SELECT [name] FROM master.sys.databases WHERE [state_desc] = 'ONLINE'	AND [name] NOT IN ('tempdb') AND [name] NOT IN ('ReportServerTempDB')
	  SELECT [name] FROM master.sys.databases WHERE [state_desc] = 'ONLINE'
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

-- Create and populate temporary tables #LogFiles, to hold the logfile stats
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

-- Create temp table #CombinedFiles
CREATE TABLE #CombinedFiles
	(ID int IDENTITY(1,1) NOT NULL,
	[DatabaseID] int,
	[DatabaseName] varchar(100),
	[FileName] varchar(500),
	[FileAllocated (MB)] decimal(11, 2),
	[FileUsed (%)] decimal(11, 2),
	[AutoGrowth] bit,
	[RecordedDate] datetime)

-- Insert data from #DataFiles into #CombinedFiles
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

-- Insert data from #LogFiles into #CombinedFiles
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

-- Capture those database that are set to offline
DECLARE cursor_04 CURSOR FOR  	
	  SELECT [name] FROM master.sys.databases WHERE [state_desc] = 'OFFLINE'
OPEN cursor_04   
FETCH NEXT FROM cursor_04 INTO @DB_name_offline 
WHILE @@FETCH_STATUS = 0   
	BEGIN
	INSERT INTO DBA.dbo.DatabaseFileAudit
		 ([DatabaseName],
		  [FileName],
		  [RecordedDate])	
		VALUES
		 (@DB_name_offline,
		  'Database offline',
		  GETDATE())
	FETCH NEXT FROM cursor_04 INTO @DB_name_offline   
	END
CLOSE cursor_04   
DEALLOCATE cursor_04

------------------------------------------------------------ START - NEW CODE FOR FILESTREAM DATA ------------------------------------------------------------------------
DECLARE cursor_05 CURSOR FOR  
	SELECT [name] FROM master.sys.databases WHERE [state_desc] = 'ONLINE' AND [name] NOT IN ('master','msdb','model','tempdb','ReportServer','ReportServerTempDB','DBA')
OPEN cursor_05   
FETCH NEXT FROM cursor_05 INTO @DB_name 
WHILE @@FETCH_STATUS = 0   
	BEGIN
	SET @SQL = 'USE ['+@DB_name+'] INSERT INTO #CombinedFiles SELECT d.[Database_id], d.[Name],df.[physical_name], CAST((df.[size]/128.0) AS DECIMAL(18,2)), NULL, NULL, GETDATE() FROM sys.database_files df JOIN
					sys.master_files mf ON df.[file_guid] = mf.[file_guid] JOIN
					sys.databases d ON mf.[database_id] = d.[database_id]
						WHERE df.[type] = 2'
	EXEC (@SQL)	
	FETCH NEXT FROM cursor_05 INTO @DB_name   
	END
CLOSE cursor_05   
DEALLOCATE cursor_05
------------------------------------------------------------ END -  NEW CODE FOR FILESTREAM DATA ------------------------------------------------------------------------

-- Update temp table
UPDATE #CombinedFiles  
   SET [AutoGrowth] = (SELECT growth FROM sys.master_files WHERE [physical_name] = #CombinedFiles.[FileName])

-- If Record option is on, copy the information to the DailyRpt_DatabaseGrowth table, if it is off, return the tabled results
IF @RECORD = 1
	BEGIN
	INSERT INTO DBA.dbo.DatabaseFileAudit
        SELECT DatabaseID, DatabaseName, [FileName], [FileAllocated (MB)], [FileUsed (%)], AutoGrowth, [RecordedDate]
			FROM #CombinedFiles ORDER BY DatabaseID, [FileName]	
	END
ELSE
	BEGIN
	SELECT DatabaseID, DatabaseName, [FileName], [FileAllocated (MB)], [FileUsed (%)], AutoGrowth, [RecordedDate]
		FROM #CombinedFiles ORDER BY DatabaseID, [FileName]
	END

-- Drop up temporary tables 
DROP TABLE #DataFiles
DROP TABLE #LogFiles
DROP TABLE #CombinedFiles

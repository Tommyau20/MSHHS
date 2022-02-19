USE [DBA]
GO
/****** Object:  StoredProcedure [dbo].[sp_DatabaseCollector]    Script Date: 5/8/2020 7:28:45 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[sp_DatabaseCollector] 
AS

-----------------------------------------------------------------------------------------------------------------------
-- Object Type : Stored Procedure  
-- Object Name : sp_DatabaseCollector
-- Description : Stored Procedure to insert database audit information into the table DBA.dbo.DatabaseCollector
-- Author : David Shaw
-- Date : May 2020
DECLARE @sp_version VARCHAR(10)
SET @sp_version = '2.05'
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
	DECLARE @DB_name varchar (150),		
		    @SQL varchar(1000)

	-- DELETE DBA.dbo.DatabaseCollector
	-- PART 1 of 2 -  Trying to cater for databases that are off-line, whereby the record does not delete and we maintain the database size information.
	DELETE FROM [DBA].[dbo].[DatabaseCollector] -- WHERE [DatabaseName] NOT IN (SELECT [Name] FROM sys.databases WHERE [state_desc] <> 'ONLINE')
	UPDATE [DBA].[dbo].[DatabaseCollector] SET [RecordedDate] = getdate()	

	INSERT INTO [DBA].[dbo].[DatabaseCollector]
	   		                 (DatabaseName,
							  DatabaseOwner,							  
							  DBCreatedDate,
							  RecordedDate)
								SELECT d.[name], SUSER_SNAME(d.[owner_sid]),d.[create_date], getdate() FROM sys.databases d LEFT JOIN
																											sys.server_principals p ON d.[owner_sid] = p.[sid]
																												--WHERE d.[name] NOT IN ('tempdb', 'ReportServerTempDB')
																												-- PART 2 of 2 - Trying to cater for databases that are off-line, whereby the record does not delete and we maintain the database size information.
																												WHERE d.[name] NOT IN ('tempdb', 'ReportServerTempDB') --AND d.[name] IN (SELECT [Name] FROM sys.Databases WHERE [state_desc] = 'ONLINE')
																													ORDER BY d.[name]

---------------------------------------------------- START - NEW CODE FOR COMPLETE DATA SIZE, INCLUDING FILESTREAMING -------------------------------------------------
DECLARE cursor_01 CURSOR FOR  
	SELECT [name] FROM master.sys.databases WHERE [state_desc] = 'ONLINE' AND [name] NOT IN ('tempdb','ReportServerTempDB')
OPEN cursor_01   
FETCH NEXT FROM cursor_01 INTO @DB_name 
WHILE @@FETCH_STATUS = 0   
	BEGIN
	SET @SQL = 'UPDATE [DBA].[dbo].[DatabaseCollector] SET [TotalSizeGB] = (Select CAST((sum(size)*8.0/1024.0/1024.0) AS DECIMAL(18,2)) AS [Size(GB)] From ['+@DB_name+'].sys.database_files) 
					WHERE [DatabaseName] = '''+@DB_name+''' AND [TotalSizeGB] IS NULL'	
	EXEC (@SQL)


	-- *********** START - New code to populate AG information ***********
	IF OBJECT_ID('master.sys.availability_groups', 'V') IS NOT NULL
		BEGIN			   	
		-- https://blog.pythian.com/list-of-sql-server-databases-in-an-availability-group/
		UPDATE [DBA].[dbo].[DatabaseCollector] SET [AvailGroupName] = (SELECT AG.name AS [AvailabilityGroupName]
																--,ISNULL(agstates.primary_replica, '') AS [PrimaryReplicaServerName]
																--,ISNULL(arstates.role, 3) AS [LocalReplicaRole]
																--,dbcs.database_name AS [DatabaseName]
																--,ISNULL(dbrs.synchronization_state, 0) AS [SynchronizationState]
																--,ISNULL(dbrs.is_suspended, 0) AS [IsSuspended]
																--,ISNULL(dbcs.is_database_joined, 0) AS [IsJoined]
																FROM master.sys.availability_groups AS AG
																LEFT OUTER JOIN master.sys.dm_hadr_availability_group_states as agstates
																   ON AG.group_id = agstates.group_id
																INNER JOIN master.sys.availability_replicas AS AR
																   ON AG.group_id = AR.group_id
																INNER JOIN master.sys.dm_hadr_availability_replica_states AS arstates
																   ON AR.replica_id = arstates.replica_id AND arstates.is_local = 1
																INNER JOIN master.sys.dm_hadr_database_replica_cluster_states AS dbcs
																   ON arstates.replica_id = dbcs.replica_id
																LEFT OUTER JOIN master.sys.dm_hadr_database_replica_states AS dbrs
																   ON dbcs.replica_id = dbrs.replica_id AND dbcs.group_database_id = dbrs.group_database_id
																WHERE [dbcs].[database_name] = @DB_name
																--ORDER BY AG.name ASC, dbcs.database_name
																)
																WHERE [DatabaseName] = @DB_name
		END
	-- *********** END - New code to populate AG information *********** 
	   	 

	FETCH NEXT FROM cursor_01 INTO @DB_name   
	END
CLOSE cursor_01   
DEALLOCATE cursor_01
---------------------------------------------------- END - NEW CODE FOR COMPLETE DATA SIZE, INCLUDING FILESTREAMING ---------------------------------------------------
	
	UPDATE [DBA].[dbo].[DatabaseCollector] SET [ServerName] = (CONVERT (VARCHAR(25), (SERVERPROPERTY('MachineName')))) WHERE [ServerName] IS NULL
	UPDATE [DBA].[dbo].[DatabaseCollector] SET [DatabaseOwner] = (SELECT SUSER_SNAME(owner_sid) FROM sys.databases WHERE [name] =  [DatabaseName])
	UPDATE [DBA].[dbo].[DatabaseCollector] SET [DBStatus] = convert(sysname,DatabasePropertyEx(DatabaseName,'Status'))
	UPDATE [DBA].[dbo].[DatabaseCollector] SET [RecoveryModel] = convert(sysname,DatabasePropertyEx(DatabaseName,'Recovery'))
	UPDATE a
		SET a.[LastFullBackupDate] = b.backup_start_date,
		FullBackupMediaSet=b.media_set_id
		from [DBA].[dbo].[DatabaseCollector] a,(select database_name,MAX(media_set_id)media_set_id,max(backup_start_date) backup_start_date 
		from msdb..backupset  where type='D' group by database_name)b
			where a.DatabaseName=b.database_name
	UPDATE a
		SET a.[FullBackupLocation] = b.physical_device_name
		from [DBA].[dbo].[DatabaseCollector] a , msdb..backupmediafamily b
			where a.[FullBackupMediaSet] =b.media_set_id	
	UPDATE a
		SET a.[LastDiffBackupDate] = b.backup_start_date,
		[DiffBackupMediaSet] = b.media_set_id
		from [DBA].[dbo].[DatabaseCollector] a,(select database_name,MAX(media_set_id)media_set_id,max(backup_start_date) backup_start_date 
		from msdb..backupset  where type='I' group by database_name)b
			where a.[DatabaseName] = b.database_name 
	UPDATE a
		SET a.[DiffBackupLocation] = b.physical_device_name
		from [DBA].[dbo].[DatabaseCollector] a , msdb..backupmediafamily b
			where a.[DiffBackupMediaSet] =b.media_set_id
	UPDATE a
		SET a.[LastLogBackupDate] = b.backup_start_date,
		LogBackupMediaSet=b.media_set_id
		from [DBA].[dbo].[DatabaseCollector] a,(select database_name,MAX(media_set_id)media_set_id,max(backup_start_date) backup_start_date 
		from msdb..backupset  where type='L' group by database_name)b
			where a.DatabaseName=b.database_name AND a.RecoveryModel != 'SIMPLE'
	UPDATE a
		SET a.LogBackupLocation = b.physical_device_name
		from [DBA].[dbo].[DatabaseCollector] a , msdb..backupmediafamily b
			where a.LogBackupMediaSet =b.media_set_id
	DECLARE @Instance VARCHAR(25)
	SET @Instance = (SELECT (CONVERT (VARCHAR(25), (SERVERPROPERTY('InstanceName')))))
	IF @Instance IS NULL 
		BEGIN
		SET @Instance = 'default'
		END
	UPDATE [DBA].[dbo].[DatabaseCollector] SET [InstanceName] = @Instance WHERE [InstanceName] IS NULL
END

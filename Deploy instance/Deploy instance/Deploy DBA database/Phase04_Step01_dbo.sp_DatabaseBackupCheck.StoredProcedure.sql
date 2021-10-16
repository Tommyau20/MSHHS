USE [DBA]
GO
/****** Object:  StoredProcedure [dbo].[sp_DatabaseBackupCheck]    Script Date: 5/02/2021 7:42:24 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_DatabaseBackupCheck] 
AS
---------------------------------------------------------------------------------------------------------------
-- Object Type : Stored Procedure  
-- Object Name : sp_DatabaseBackupCheck
-- Description : This stored procedures role is to discover those databases that do not have a current 
--               backup and have a status of online.  It will pass these database name to the stored procedure
--				 'DBA.dbo.sp_Databasebackup' in order to carry out a backup in accordance with the standard
--               backup routine/procedure.
-- Author : David Shaw
-- Date : May 2021
DECLARE @sp_version VARCHAR(10)
SET @sp_version = '2.17'
---------------------------------------------------------------------------------------------------------------

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
	-- ***** DECLARE GLOBAL VARIABLES *****
	DECLARE @db_name VARCHAR(100) -- database name  
	DECLARE @backupexists VARCHAR(100) -- value for the backupset within backup file
	DECLARE @instance_name varchar(50) -- used to capture the name of the instance
	DECLARE @environment varchar(50) -- used to capture the enviornment for this instance
	DECLARE @subject_string varchar(100) -- used to build the email subject
	DECLARE @body_string varchar(MAX) -- used to build the email body
	SET @body_string = ''
	SELECT @environment = [Value] FROM [DBA].[dbo].[Parameters] WHERE [Parameter] = 'Environment'
	DECLARE @minus_hours int = 74
	DECLARE @TableHTML_backup_out_of_date NVARCHAR(MAX)   
	SET @TableHTML_backup_out_of_date = '' 
	DECLARE @email_recipients NVARCHAR(250) 	 

	-- ***** CREATE CURSOR OF THOSE DATABASES WITHOUT ANY BACKUP *****
	DECLARE db_cursor CURSOR FOR
		-- This block of code below would need to be revisited, should I ever decide to move database backups for those in Availability Groups, from the primary node to a secondary node.  
		SELECT [name] FROM master.sys.databases WHERE [name] NOT IN ('tempdb', 'ReportServerTempDB') AND 
											  [name] NOT IN (SELECT sd.[Name] from sys.databases as sd left outer join 
															sys.dm_hadr_database_replica_states  as hdrs on hdrs.database_id = sd.database_id
																	WHERE hdrs.is_primary_replica = 0 AND sd.[Name] not in (SELECT sd.[Name] from sys.databases as sd left outer join 
															sys.dm_hadr_database_replica_states  as hdrs on hdrs.database_id = sd.database_id
																	WHERE hdrs.is_primary_replica = 1)) AND [state_desc] = 'ONLINE'
	OPEN db_cursor   
	FETCH NEXT FROM db_cursor INTO @db_name   
	WHILE @@FETCH_STATUS = 0   
	BEGIN  
		SELECT @backupexists = database_name from msdb..backupset 
			WHERE database_name = @db_name and backup_set_id =(select max(backup_set_id) from msdb..backupset where database_name=@db_name)
            -- ****************** START - new code for testing age of last backup ******************
            -- This would come in hardy, telling me if the backup on a secondary AG node is over thirty days, meaning it has not failed over in over thirty days.
			-- but was commented out, after I narrow down the select for the cursor to only provide those database, that are NOT in an AG when the node replica is
			-- secondary.
            --  AND [backup_finish_date] < DATEADD(DAY, -30, GETDATE())
            -- ******************* END - new code for testing age of last backup *******************
		-- ******************* START - Compile email body for those databases that have no backup ******************
		IF @backupexists <> @db_name or @backupexists IS NULL
			BEGIN 
			-- ******************************************************** WARNING ****************************************************************************************
			-- Given this stored procedure passes database names to the stored procedure dbo.sp_DatabaseBackup
			-- means that dbo.sp_DatabaseBackup will need to be fixed first, where I found that it does not cater for 
			-- named instances when I moved to Clinical Informatics at the PAH.
			-- Since moving to MSHHS, I have changed this SP to send an email to the DBA Operator, rather than
			-- launch dbo.sp_DatabaseBackup... well atleast for the time being. 
			-- The passing of those database that do not have a current backup, to the stored procedure "DBA.dbo.sp_DatabaseBackup" has been commented out
			-- since being implimented at Metro South, due to the use of named instances and the fact that the registry reads for the backup location will
			-- fail.  As such I have decided to just email the DBA operator in the time being.
			-- EXEC DBA.dbo.sp_DatabaseBackup @db_name			
			-- ******************************************************** WARNING ****************************************************************************************
			SET @instance_name = CASE   
									WHEN SERVERPROPERTY('InstanceName') IS NULL THEN 'default'  				
									ELSE convert (varchar(50),SERVERPROPERTY('instanceName'))
								 END			
			SET @body_string = @body_string + 'Database (' + @db_name + ') on server (' +  CONVERT(varchar(20),SERVERPROPERTY ('MachineName')) + '\' +  @instance_name + ') appears to have no backup.<br>'
			END
		-- ******************** END - Compile email body for those databases that have no backup *******************
		-- ******************* START - Compile HTML email body  for those databases that have a backup older than @minus_hours *******************
		IF EXISTS (SELECT DISTINCT [DatabaseName] FROM [DBA].[dbo].[DatabaseCollector] WHERE [DatabaseName] = @db_name AND [LastFullBackupDate] <= DATEADD(hh, -@minus_hours, GETDATE()))
			BEGIN
			SELECT @TableHTML_backup_out_of_date = @TableHTML_backup_out_of_date + 
				  '<tr>				  
				  <td><font face="Verdana" size="1">' + [Servername] + '</font></td>
				  <td><font face="Verdana" size="1">' + [InstanceName] + '</font></td>
				  <td><font face="Verdana" size="1">' + [DatabaseName] + '</font></td>            
				  <td><font face="Verdana" size="1">' + [DBStatus] + '</font></td>            
				  <td><font face="Verdana" size="1">' + CONVERT(NVARCHAR(30),[LastFullBackupDate]) + '</font></td>            
				  </tr>'       
						FROM [DBA].[dbo].[DatabaseCollector]
							WHERE [DatabaseName] = @db_name AND [LastFullBackupDate] <= DATEADD(hh, -@minus_hours, GETDATE()) AND [DBStatus] <> 'Offline'
			END
		-- ******************** END - Compile HTML email body for those databases that have a backup older than @minus_hours ********************
		FETCH NEXT FROM db_cursor INTO @db_name   
	END 
	CLOSE db_cursor   
	DEALLOCATE db_cursor

-- ******************************************************************************************************************************************************
-- ******************************************************** START - Send emails if applicable ***********************************************************
	-- ******************* START - Send email for those databases that have no backup *******************
	If @body_string <> '' 
		BEGIN
		SET @subject_string = 'MSSQL alert (' + @environment + ') - database(s) with no backups'
		SELECT @body_string = @body_string +
		'<p><font color=#000080><b>NOTE:</b> Please be aware you may see this alert shortly there after any of the Availability Groups configured instances failing over, indicating a full backup is yet to happen on the instance now doing backups... just something to be mindful of.</font></p>'
		SELECT @email_recipients = ISNULL(email_address, 'David.Shaw@health.qld.gov.au') FROM msdb.dbo.sysoperators WHERE [name] = 'DBA'
		EXEC msdb.dbo.sp_send_dbmail @recipients = @email_recipients,    
									 @subject =  @subject_string,
									 @body = @body_string,    
									 @body_format = 'HTML';
		END
	-- ******************** END - Send email for those databases that have no backup ********************
	-- ******************* START - Compile and send email for those databases that have a backup older than @minus_hours *******************
	-- ***********************************************************************************************************************************************************************************************************
	-- This block was an after thought, added some years later to the original stored procedure, hence it uses sp_send_dbmail for its HTML capability, while the older block above still uses sp_notify_operator.
	-- Time permitting, I will consider changing the old above block of code to use sp_send_dbmail.
	-- ***********************************************************************************************************************************************************************************************************
	If @TableHTML_backup_out_of_date <> '' 
		BEGIN		
		SELECT @TableHTML_backup_out_of_date = '<p><font face="Verdana" size="4">Database(s) with full backups possible <i>out of date</i> (older than ' + CONVERT(NVARCHAR(5),@minus_hours) + ' hours).</font></p>
				  <table width="800" border="1" borderColor="#111111" style="BORDER-COLLAPSE: collapse">
				  <tr>
				  <td width="13%" bgColor="#000080"><b><font face="Verdana" size="1" color="#FFFFFF">ServerName</font></b></td>             
				  <td width="11%" bgColor="#000080"><b><font face="Verdana" size="1" color="#FFFFFF">InstanceName</font></b></td>           
				  <td width="18%" bgColor="#000080"><b><font face="Verdana" size="1" color="#FFFFFF">DatabaseName</font></b></td>           
				  <td width="09%" bgColor="#000080"><b><font face="Verdana" size="1" color="#FFFFFF">DBStatus</font></b></td>                 
				  <td width="15%" bgColor="#000080"><b><font face="Verdana" size="1" color="#FFFFFF">LastFullBackupDate</font></b></td>                 
				  </tr>' + @TableHTML_backup_out_of_date + 
				  '</table>' +
				  '<p>The above list is based on the table DBA.dbo.DatabaseCollector data, all effort should be made to look at current, up to date data, possible using the following t-sql.</p>
				   <p><font color=#000080><b>NOTE:</b> Please be aware you may see this alert shortly there after any of the Availability Groups configured instances failing over, indicating a full backup is yet to happen on the instance now doing backups... just something to be mindful of.</font></p>
				   <p><font color=#000080>DECLARE @minus_hours int = ' + CONVERT(NVARCHAR(5),@minus_hours) + ' -- deduct ' + CONVERT(NVARCHAR(5),@minus_hours) + ' hours, being the default declared in DBA.dbo.sp_DatabaseBackupCheck.<br>
				   SELECT [database_name],<br> 
				   MAX(backup_start_date) as backup_start_date<br>
				   FROM msdb..backupset<br>
				   WHERE [type] = ''D'' -- D means full backups<br>
				   GROUP BY [database_name]<br>
				   HAVING MAX([backup_start_date]) <= DATEADD(hh, -@minus_hours, GETDATE())</font></p>'			
		SET @subject_string = 'MSSQL alert (' + @environment + ') - database(s) with full backups that are out of date'
		SELECT @email_recipients = ISNULL(email_address, 'David.Shaw@health.qld.gov.au') FROM msdb.dbo.sysoperators WHERE [name] = 'DBA'
		EXEC msdb.dbo.sp_send_dbmail @recipients = @email_recipients,    
									 @subject =  @subject_string,
									 @body = @TableHTML_backup_out_of_date,    
									 @body_format = 'HTML';
		END
	-- ******************** END - Compile and send email for those databases that have a backup older than @minus_hours ********************
-- ********************************************************* END - Send emails if applicable ************************************************************
-- ******************************************************************************************************************************************************

END



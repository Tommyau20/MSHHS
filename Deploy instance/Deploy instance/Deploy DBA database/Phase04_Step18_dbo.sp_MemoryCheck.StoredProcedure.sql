USE [DBA]
GO
/****** Object:  StoredProcedure [dbo].[sp_MemoryCheck]    Script Date: 5/28/2020 12:57:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[sp_MemoryCheck] 
AS

-----------------------------------------------------------------------------------------------------------------------
-- Object Type : Stored Procedure  
-- Object Name : sp_MemoryCheck
-- Description : Stored Procedure to compare the deployed memory settings to the current memory settings.
-- Author : David Shaw
-- Date : May 2020
DECLARE @sp_version VARCHAR(10)
SET @sp_version = '1.00'
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
	DECLARE @environment varchar(50) -- used to capture the enviornment for this instance
	DECLARE @instance_name varchar(50) -- used to capture the name of the instance
	SELECT @environment = [Value] FROM [DBA].[dbo].[Parameters] WHERE [Parameter] = 'Environment'
	SET @instance_name = CASE   
							WHEN SERVERPROPERTY('InstanceName') IS NULL THEN 'default'  				
							ELSE 
								convert (varchar(50),SERVERPROPERTY('instanceName'))
							END
	DECLARE @subject_string varchar(100) -- used to build the email subject
	DECLARE @body_string varchar(MAX) -- used to build the email body
	DECLARE @total_os_RAM_at_deployment int
	DECLARE @min_SQL_RAM_at_deployment int
	DECLARE @max_SQL_RAM_at_deployment int
	DECLARE @total_os_RAM_now int
	DECLARE @min_SQL_RAM_now int
	DECLARE @max_SQL_RAM_now int	
	SELECT @total_os_RAM_at_deployment = [Value] from [DBA].[dbo].[Parameters] WHERE [Parameter] = 'Total physical memory (MB) at deployment'
	SELECT @min_SQL_RAM_at_deployment = [Value] from [DBA].[dbo].[Parameters] WHERE [Parameter] = 'Min. server memory (MB) at deployment'
	SELECT @max_SQL_RAM_at_deployment = [Value] from [DBA].[dbo].[Parameters] WHERE [Parameter] = 'Max. server memory (MB) at deployment'
	SELECT @total_os_RAM_now = [total_physical_memory_kb]/(1024^2) from sys.dm_os_sys_memory
	SELECT @min_SQL_RAM_now = CONVERT(int, [value_in_use]) FROM sys.configurations WHERE [NAME] = 'min server memory (MB)'
	SELECT @max_SQL_RAM_now = CONVERT(int, [value_in_use]) FROM sys.configurations WHERE [NAME] = 'max server memory (MB)'
	/*
	PRINT @total_os_RAM_at_deployment
	PRINT @min_SQL_RAM_at_deployment 
	PRINT @max_SQL_RAM_at_deployment 
	PRINT '------------------'
	PRINT @total_os_RAM_now
	PRINT @min_SQL_RAM_now
	PRINT @max_SQL_RAM_now 
	*/
	IF (@total_os_RAM_at_deployment IS NOT NULL) AND (@min_SQL_RAM_at_deployment IS NOT NULL) AND (@max_SQL_RAM_at_deployment IS NOT NULL)
		BEGIN
			IF (@total_os_RAM_at_deployment <>  @total_os_RAM_now) OR (@min_SQL_RAM_at_deployment  <> @min_SQL_RAM_now) OR (@max_SQL_RAM_at_deployment  <> @max_SQL_RAM_now)
				BEGIN								
				SET @subject_string = 'MSSQL alert (' + @environment + ') - memory setting discrepancy'
				SET @body_string = 'There appears to be changes to total physical and/or Min. Max. memory on MSSQL server ' +  CONVERT(varchar(20),SERVERPROPERTY ('MachineName')) + '\' +  @instance_name + ', given the information recorded during deployment and the current detected settings.' + CHAR(13) + CHAR(10)
				SET @body_string = @body_string + CHAR(13) + CHAR(10)
				SET @body_string = @body_string + 'MEMORY SETTINGS AT DEPLOYMENT' + CHAR(13) + CHAR(10)
				SET @body_string = @body_string + 'Total memory (MB): ' +  CONVERT(varchar(100),@total_os_RAM_at_deployment) + CHAR(13) + CHAR(10)
				SET @body_string = @body_string + 'Min. server memory (MB): ' + CONVERT(varchar(100),@min_SQL_RAM_at_deployment) + CHAR(13) + CHAR(10)
				SET @body_string = @body_string + 'Max. server memory (MB): ' + CONVERT(varchar(100),@max_SQL_RAM_at_deployment) + CHAR(13) + CHAR(10)
				SET @body_string = @body_string + CHAR(13) + CHAR(10)
				SET @body_string = @body_string + 'MEMORY SETTINGS NOW' + CHAR(13) + CHAR(10)
				SET @body_string = @body_string + 'Total memory (MB): ' + CONVERT(varchar(100),@total_os_RAM_now) + CHAR(13) + CHAR(10)
				SET @body_string = @body_string + 'Min. server memory (MB): ' + CONVERT(varchar(100),@min_SQL_RAM_now) + CHAR(13) + CHAR(10)
				SET @body_string = @body_string + 'Max. server memory (MB): ' + CONVERT(varchar(100),@max_SQL_RAM_now) + CHAR(13) + CHAR(10)
				EXEC msdb.dbo.sp_notify_operator @name = 'DBA',
												 @subject = @subject_string,
												 @body = @body_string
				END
			ELSE	
				BEGIN
				Print 'No changes to memory settings detected.'				
				END
		END		
	ELSE
		BEGIN
			SET @subject_string = 'MSSQL alert (' + @environment + ') - memory setting discrepancy'
			SET @body_string = 'There is no total physical and/or Min. Max. memory at deployment data, captured on MSSQL server ' +  CONVERT(varchar(20),SERVERPROPERTY ('MachineName')) + '\' +  @instance_name + '.' + CHAR(13) + CHAR(10)
			EXEC msdb.dbo.sp_notify_operator @name = 'DBA',
											 @subject = @subject_string,
											 @body = @body_string 
		END
END

USE [DBA]
GO
/****** Object:  StoredProcedure [dbo].[sp_InstanceCollector]    Script Date: 14/01/2021 8:21:35 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[sp_InstanceCollector]
AS
BEGIN
----------------------------------------------------------------------------------------------------------
-- Object Type : Stored Procedure  
-- Object Name : sp_InstanceCollector
-- Description : Stored Procedure to collect instance related data
-- Author : David Shaw
-- Date : February 2021
DECLARE @sp_version VARCHAR(10)
SET @sp_version = '1.16'
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

DELETE [DBA].[dbo].[Instance]
DECLARE @environment varchar(50)
DECLARE @cpu_count int
SELECT @environment = [Value] From [DBA].[dbo].[Parameters] WHERE [Parameter] = 'Environment'
SELECT @cpu_count = [cpu_count] from sys.dm_os_sys_info

INSERT INTO [DBA].[dbo].[Instance]
						   (ServerName,
							InstanceName,
							Environment,
							ProductVersion,
							Edition,
							ServicePack,
							CPU_count,
							IsClustered,
							IsHadrEnabled,
							DateCollected)
						VALUES (CONVERT(VARCHAR(50),(SERVERPROPERTY('ComputerNamePhysicalNetBIOS'))),
								CONVERT(VARCHAR(50),(SELECT ISNULL(SERVERPROPERTY('InstanceName'), 'default'))),
								@environment,
								CONVERT(VARCHAR(50),(SERVERPROPERTY('ProductVersion'))),				
								CONVERT(VARCHAR(50),(SERVERPROPERTY('Edition'))),
								CONVERT(VARCHAR(50),(SERVERPROPERTY('ProductLevel'))) + '-' + CONVERT(VARCHAR(50),(SELECT ISNULL(SERVERPROPERTY('ProductUpdateLevel'), ''))),
								@cpu_count,
								CONVERT(bit,(SERVERPROPERTY('IsClustered'))),
								CONVERT(bit,(SERVERPROPERTY('IsHadrEnabled'))),
								getdate())

UPDATE [DBA].[dbo].[Instance] SET [Version] = '7' WHERE [ProductVersion] LIKE '7.00%'
UPDATE [DBA].[dbo].[Instance] SET [Version] = '2000' WHERE [ProductVersion] LIKE '8.00%'
UPDATE [DBA].[dbo].[Instance] SET [Version] = '2005' WHERE [ProductVersion] LIKE '9.00%'
UPDATE [DBA].[dbo].[Instance] SET [Version] = '2005' WHERE [ProductVersion] LIKE '9.0.%'
UPDATE [DBA].[dbo].[Instance] SET [Version] = '2008' WHERE [ProductVersion] LIKE '10.0%'
UPDATE [DBA].[dbo].[Instance] SET [Version] = '2008R2' WHERE [ProductVersion] LIKE '10.5%'
UPDATE [DBA].[dbo].[Instance] SET [Version] = '2012' WHERE [ProductVersion] LIKE '11.%'	
UPDATE [DBA].[dbo].[Instance] SET [Version] = '2014' WHERE [ProductVersion] LIKE '12.%'
UPDATE [DBA].[dbo].[Instance] SET [Version] = '2016' WHERE [ProductVersion] LIKE '13.%'
UPDATE [DBA].[dbo].[Instance] SET [Version] = '2017' WHERE [ProductVersion] LIKE '14.%'
UPDATE [DBA].[dbo].[Instance] SET [Version] = '2019' WHERE [ProductVersion] LIKE '15.%'

END

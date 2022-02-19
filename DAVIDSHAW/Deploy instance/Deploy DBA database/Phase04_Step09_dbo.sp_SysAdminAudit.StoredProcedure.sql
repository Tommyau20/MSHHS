USE [DBA]
GO
/****** Object:  StoredProcedure [dbo].[sp_SysAdminAudit]    Script Date: 19/11/2018 8:38:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- NOTE: this stored procedure can be effected when querying AD groups, where the MSSQL service accounts
-- does not have permissions to query the QH domain. On some of the MSSQL builds before my time at MSHHS,
-- this stored procedure would not work when interigating AD group, for exmaple "PA-HEALTH\AppServices-Developers"
-- on server METRO08SQL2008, where I believe the problem is the MSSQL server account that is being used
-- "PA-HEALTH\sqladmin", does not have previleges in the QH domain.

CREATE PROCEDURE [dbo].[sp_SysAdminAudit] 
AS
---------------------------------------------------------------------------------------------------
-- Object Type : Stored Procedure  
-- Object Name : sp_SysAdminAudit
-- Description : Added the current list of SysAdmins to table DBA.dbo.SysAdminAudit
-- Author : David Shaw
-- Date : December 2020
DECLARE @sp_version VARCHAR(10)
SET @sp_version = '1.13'
---------------------------------------------------------------------------------------------------

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
-- *********************** Audit the Win group login objects *************************
--DELETE FROM [DBA].[dbo].[SysAdminAudit] WHERE [Indirect_Win_login_with_sysadmin] =  'indeterminate... xp_logininfo query failed'
DECLARE @winlogins table (acct_name sysname,
						  acct_type varchar(10),
						  acct_priv varchar(10),
						  mapped_login_name sysname,
						  permission_path sysname)
DECLARE @group [sysname]
DECLARE recscan CURSOR FOR 
	SELECT name FROM sys.server_principals WHERE [type] = 'G' and [name] not like 'NT%'
							-- for some reason the following where condition had to be added to the end of the above select
							-- on server METRO08SQL2008 " and [name] not like 'PA-HEALTH\AppServices-Developers'"
OPEN recscan
FETCH NEXT FROM recscan INTO @group
	WHILE @@FETCH_STATUS = 0
	BEGIN	
	BEGIN TRY  
		INSERT INTO @winlogins EXEC xp_logininfo @group,'members'  -- e.g. EXEC xp_logininfo 'builtin\Administrators','members'
	END TRY  
	BEGIN CATCH  
		IF NOT EXISTS (SELECT 1 FROM [DBA].[dbo].[SysAdminAudit] WHERE [Sysadmin_via_SQL_login] = @group)
			INSERT INTO [DBA].[dbo].[SysAdminAudit] ([Sysadmin_via_SQL_login], [Indirect_Win_login_with_sysadmin], [Date]) VALUES (@group, 'indeterminate... xp_logininfo query failed', GETDATE())
	END CATCH  
	FETCH NEXT FROM recscan INTO @group
	END
CLOSE recscan
DEALLOCATE recscan
DELETE FROM [DBA].[dbo].[SysAdminAudit] WHERE [Indirect_Win_login_with_sysadmin] NOT IN (SELECT [acct_name] FROM @winlogins WHERE [acct_priv] = 'admin') AND [Indirect_Win_login_with_sysadmin] <> 'indeterminate... xp_logininfo query failed'
INSERT INTO [DBA].[dbo].[SysAdminAudit] ([Indirect_Win_login_with_sysadmin],
									         [Win_login_type],
									         [Sysadmin_via_SQL_login])
     (SELECT [acct_name], [acct_type], [permission_path] FROM @winlogins WHERE [acct_priv] = 'admin' AND NOT EXISTS (SELECT [Indirect_Win_login_with_sysadmin] FROM [DBA].[dbo].[SysAdminAudit] WHERE [acct_name] = [Indirect_Win_login_with_sysadmin]))
-- *********************** Audit the SQL login objects *************************
DELETE FROM [DBA].[dbo].[SysAdminAudit] WHERE [SQL_login_with_sysadmin] NOT IN
		(SELECT sp.name FROM sys.server_role_members srm 
		JOIN sys.server_principals sp ON srm.member_principal_id = sp.principal_id
		WHERE role_principal_id = (SELECT principal_id FROM sys.server_principals 
		WHERE [Name] = 'sysadmin' AND sp.[type] != 'G'))
INSERT INTO [DBA].[dbo].[SysAdminAudit] ([SQL_login_with_sysadmin]) 
	 (SELECT sp.name FROM sys.server_role_members srm 
	   JOIN sys.server_principals sp ON srm.member_principal_id = sp.principal_id
	   WHERE role_principal_id = (SELECT principal_id FROM sys.server_principals WHERE Name = 'sysadmin' AND sp.[type] != 'G' 
	   AND NOT EXISTS (SELECT [SQL_login_with_sysadmin] FROM [DBA].[dbo].[SysAdminAudit] WHERE [SQL_login_with_sysadmin] = sp.name)))
UPDATE [DBA].[dbo].[SysAdminAudit] SET [ServerName]=(SELECT (CONVERT (VARCHAR(25), (SERVERPROPERTY('MachineName'))))) WHERE [ServerName] IS NULL
DECLARE @Instance VARCHAR(25)
SET @Instance = (SELECT (CONVERT (VARCHAR(25), (SERVERPROPERTY('InstanceName')))))
IF @Instance IS NULL 
	BEGIN
	SET @Instance = 'default'
	END
UPDATE [DBA].[dbo].[SysAdminAudit] SET [InstanceName]= @Instance WHERE [InstanceName] IS NULL

-- ***********************  Send notification of records in table 'SysAdminAudit' that have not been acknowledged. *********************** 
If EXISTS (SELECT * FROM [DBA].[dbo].[SysAdminAudit] WHERE [Acknowledged] = 0)
	BEGIN
	DECLARE @MailSubject VARCHAR(100)
	DECLARE @MailBody VARCHAR(600)
	DECLARE @environment VARCHAR(50) 
	SELECT @environment = [Value] FROM [DBA].[dbo].[Parameters] WHERE [Parameter] = 'Environment'
	SET @MailBody = 'There appears to be new or changes to SQL logins on this instance regarding sysadmin permissions that require investigation and/or acknowledgment.' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)
	SET @MailBody = @MailBody + 'Select * from [DBA].[dbo].[SysAdminAudit] WHERE [Acknowledged] = 0'
	SET @MailSubject = 'MSSQL alert (' + @environment + ') - sysadmin changes on ' + @@SERVERNAME	
	EXEC msdb.dbo.sp_notify_operator @name = 'DBA', @subject = @MailSubject, @body = @MailBody
	END

END
GO


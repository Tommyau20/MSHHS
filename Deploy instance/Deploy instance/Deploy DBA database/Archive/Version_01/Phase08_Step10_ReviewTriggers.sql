SELECT * FROM msdb.dbo.sysobjects where name = 'trig_sysjobs_altered'
SELECT * FROM master.sys.server_triggers where name = 'trig_create_database'
SELECT * FROM master.sys.server_triggers where name = 'trig_drop_database'
-- SELECT * FROM master.sys.server_triggers where name = 'trig_alter_database'
SELECT * FROM master.sys.server_triggers where name = 'trig_create_login'
SELECT * FROM master.sys.server_triggers where name = 'trig_drop_login'
-- SELECT * FROM msdb.dbo.sysobjects where name = 'trig_operator_email'
-- SELECT * FROM msdb.dbo.sysobjects where name = 'trig_operator_pager'
-- SELECT * FROM msdb.dbo.sysobjects where name = 'trig_operator_altered'
SELECT * FROM sys.server_sql_modules -- SHOULD RETURN 4 ROWS
SELECT * FROM master.sys.server_triggers -- SHOULD RETURN 4 ROWS
SELECT * FROM msdb.dbo.sysobjects WHERE [xtype] = 'TR' and [crdate] > (getdate()-2)  -- SHOULD RETURN 1 ROWS




-- *********************************************************************************************************
-- ********* START - review that public server role has permission to execute sp_notify_operator ***********
-- *********************************************************************************************************
USE [msdb]
GO

SELECT [name]
FROM sys.objects obj
INNER JOIN sys.database_permissions dp ON dp.major_id = obj.object_id
WHERE obj.[type] = 'P' -- stored procedure
AND dp.permission_name = 'EXECUTE'
AND dp.state IN ('G', 'W') -- GRANT or GRANT WITH GRANT
AND dp.grantee_principal_id =
(SELECT principal_id FROM sys.database_principals WHERE [name] = 'public')
-- *********************************************************************************************************
-- ********** END - review that public server role has permission to execute sp_notify_operator ************
-- *********************************************************************************************************


-- *****************************************************************************
-- ************************* START - DROP TRIGGERS *****************************
-- *****************************************************************************
-- USE [MSDB]
-- DROP TRIGGER dbo.trig_sysjobs_altered

-- USE [Master]
-- DROP TRIGGER trig_create_database
-- ON ALL SERVER
-- GO
-- DROP TRIGGER trig_drop_database
-- ON ALL SERVER
-- GO
-- DROP TRIGGER trig_alter_database
-- ON ALL SERVER
-- GO
-- DROP TRIGGER trig_create_login
-- ON ALL SERVER
-- GO
-- DROP TRIGGER trig_drop_login
-- ON ALL SERVER
-- GO

-- USE [MSDB]
-- DROP TRIGGER dbo.trig_operator_email
-- DROP TRIGGER dbo.trig_operator_pager
-- DROP TRIGGER dbo.trig_operator_altered
-- *****************************************************************************
-- ************************** END - DROP TRIGGERS ******************************
-- *****************************************************************************


-- *****************************************************************************
-- ***************** START - DROP OPTIONAL TRIGGER SERIES **********************
-- *****************************************************************************
-- USE master
-- SELECT * FROM sys.server_triggers

-- USE master
-- DROP TRIGGER trig_LoginAudit_??? -- **** Provide the login name to be monitored ****
-- ON ALL SERVER

-- USE master
-- DROP TRIGGER trig_LoginNotification_??? -- **** Provide the login name to be monitored ****
-- ON ALL SERVER

-- USE master
-- DROP TRIGGER trig_LoginNotification_sysadmins
-- ON ALL SERVER

-- USE master
-- DROP TRIGGER trig_LoginNotify_sysadmins_sql
-- ON ALL SERVER

-- USE master
-- DROP TRIGGER trig_LoginNotify_sysadmins_windows
-- ON ALL SERVER
-- *****************************************************************************
-- ******************* END - DROP OPTIONAL TRIGGER SERIES **********************
-- *****************************************************************************





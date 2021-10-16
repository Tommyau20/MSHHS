USE [DBA]
GO
/****** Object:  StoredProcedure [dbo].[sp_LoginChangeAudit]    Script Date: 6/12/2019 8:36:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

---------------------------------------------------------------------------------------------------
-- Object Type : Stored Procedure  
-- Object Name : sp_LoginChangeAudit
-- Description : Captures trace data relating to login changes to table DBA.dbo.SysAdminAudit
--               This stored procedure will most likely be called by the login change triggers.
-- Author : David Shaw
-- Date : December 2019
-- Version : 1.01
-- https://social.msdn.microsoft.com/Forums/sqlserver/en-US/8c190713-231f-42d1-83cf-9b0cdb3b712b/how-to-find-who-created-logins-on-sql-server-for-compliance-request?forum=sqldataaccess
---------------------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[sp_LoginChangeAudit] 
AS
BEGIN
INSERT INTO [dbo].[LoginChangeAudit] ([TransactionID]
										  ,[EventName]
										  ,[subclass_name]
										  ,[DatabaseName]           
										  ,[NTDomainName]
										  ,[HostName]
										  ,[ApplicationName]
										  ,[LoginName]
										  ,[SPID]           
										  ,[TargetLoginName]
										  ,[TargetUserName]
										  ,[TargetRoleName]						
										  ,[SessionLoginName]
										  ,[StartTime])

											   (SELECT t.TransactionID ,
                                                       te.name AS [EventName] ,
                                                       v.subclass_name ,
                                                       t.DatabaseName ,        
                                                       t.NTDomainName ,
                                                       t.HostName ,
                                                       t.ApplicationName ,
                                                       t.LoginName ,
                                                       t.SPID ,                                                      
                                                       t.TargetLoginName ,
                                                       t.TargetUserName ,
                                                       t.RoleName AS [TargetRoleName] ,
                                                       t.SessionLoginName , 
                                                       t.StartTime  --INTO [LoginCreateAudit]
                                         FROM    sys.fn_trace_gettable(CONVERT(VARCHAR(150), (SELECT TOP 1 f.[value] FROM sys.fn_trace_getinfo(NULL) f WHERE f.property = 2)), DEFAULT) t
                                                       JOIN sys.trace_events te ON t.EventClass = te.trace_event_id
                                                       JOIN sys.trace_subclass_values v ON v.trace_event_id = te.trace_event_id AND v.subclass_value = t.EventSubClass
                                         WHERE te.[name] IN ( 'Audit Addlogin Event', 'Audit Add DB User Event', 'Audit Add Member to DB Role Event', 'Audit Add Login to Server Role Event' , 'Audit Login GDR Event' )
                                                       AND v.subclass_name IN ( 'Add', 'Grant', 'Grant database access', 'Drop', 'Revoke', 'Revoke database access') 
													   AND NOT EXISTS (Select [TransactionID] FROM [DBA].[dbo].[LoginChangeAudit] WHERE [TransactionID] = t.TransactionID))         

END

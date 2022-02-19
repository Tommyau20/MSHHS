USE [msdb]
GO  
CREATE TRIGGER trig_sysjobs_altered  
ON sysjobs  
FOR UPDATE AS  
-----------------------------------------------------------------------------------------  
-- Object Type : Trigger  
-- Object Name : msdb..trig_sysjobs_altered  
-- Description : Trigger to email a given operator team when a job is enabled or disabled
-- Trigger location : msdb.dbo.sysjobs triggers  
-- Author : www.mssqltips.com  
-- Date : July 2009
-- Altered Date: September 2014
-- Version: 1.12  
-----------------------------------------------------------------------------------------  
SET NOCOUNT ON  

DECLARE @username VARCHAR(50),  
	@hostname VARCHAR(50),  
	@jobname VARCHAR(100),  
	@DeletedJobName VARCHAR(100),  
	@New_Enabled INT,  
	@Old_Enabled INT,  
	@emailsubject VARCHAR(200),
	@emailbody VARCHAR(200),  
 	@Servername VARCHAR(50),
	@operator VARCHAR(50) 

SELECT @username = SYSTEM_USER, @hostname = HOST_NAME()  
SELECT @New_Enabled = [enabled] FROM Inserted  
SELECT @Old_Enabled =  [enabled] FROM Deleted  
SELECT @jobname = [name] FROM Inserted  
SELECT @Servername = @@servername 

-- Check if the enabled flag has been changed. 
IF @New_Enabled <> @Old_Enabled  
BEGIN  
  IF @New_Enabled = 1  
  BEGIN  
    SET @emailsubject = 'MSSQL alert - server job ['+@jobname+'] on '+@Servername+' has been ENABLED'
    SET @emailbody = 'User: '+@username+' on '+@hostname+' has ENABLED SQL server job ['+@jobname+'] at '+CONVERT(VARCHAR(20),GETDATE(),100)  
  END  

  IF @New_Enabled = 0  
  BEGIN  
    SET @emailsubject = 'MSSQL alert - server job ['+@jobname+'] on '+@Servername+' has been DISABLED'
    SET @emailbody = 'User: '+@username+' on '+@hostname+' has DISABLED SQL server job ['+@jobname+'] at '+CONVERT(VARCHAR(20),GETDATE(),100)  
  END  

-- ***** Email out alerts *****   
   EXEC msdb.dbo.sp_notify_operator @name = 'DBA',
 				    @subject = @emailsubject,
				    @body = @emailbody

END 
GO


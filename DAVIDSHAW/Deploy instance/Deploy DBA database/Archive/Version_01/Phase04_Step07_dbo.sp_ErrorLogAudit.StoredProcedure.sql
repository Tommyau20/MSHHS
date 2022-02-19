USE [DBA]
GO
/****** Object:  StoredProcedure [dbo].[sp_ErrorLogAudit]    Script Date: 19/11/2018 8:38:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

------------------------------------------------------------------------------------------------------------------
-- Object Type : Stored Procedure  
-- Object Name : sp_ErrorLogAudit
-- Description : Stored Procedure to email the declared reciepiant a HTML formatted email with error log information.
-- Author : David Shaw
-- Date : November 2018
-- Version : 1.13
------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[sp_ErrorLogAudit]
@days_prior int,	  
@email_address VARCHAR(150) 

AS
BEGIN
-- ***** Variable declaration *****
DECLARE @Server_name VARCHAR(100),
		@instance_name VARCHAR(100),		
		@Version VARCHAR(250),
		@Edition VARCHAR(100),
		@Service_pack VARCHAR(100),
		@MailProfile VARCHAR(100),
		@TableHTML  VARCHAR(MAX),    
		@StrSubject VARCHAR(100),    
		@URL varchar(1000),
		@environment varchar(50) -- used to capture the enviornment for this instance


-- ***** Variable Assignment *****
SELECT @environment = [Value] FROM [DBA].[dbo].[Parameters] WHERE [Parameter] = 'Environment'
SET @MailProfile = (SELECT name FROM msdb.dbo.sysmail_profile WHERE profile_id = (SELECT profile_id FROM msdb.dbo.sysmail_Principalprofile WHERE is_default = '1'))

SET @instance_name = (SELECT (CONVERT (VARCHAR(25), (SERVERPROPERTY('InstanceName')))))
IF @instance_name IS NULL 
	BEGIN
	SET @instance_name = 'default'
	END
SELECT @Server_name = CONVERT(VARCHAR(50), SERVERPROPERTY('servername'))  
SELECT @Version = CONVERT(VARCHAR(100), SERVERPROPERTY('productversion'))
SELECT @Edition = CONVERT(VARCHAR(100), serverproperty('Edition'))
SELECT @Service_pack = CONVERT(VARCHAR(100), SERVERPROPERTY ('productlevel'))
SELECT @StrSubject = 'MSSQL alert (' + @environment + ') - Error log audit ('+ @Server_name + '\' + @instance_name + ')'    


-- ***** START OF THE COMPILING OF HTML CODE *****
-- ***** START OF SERVER INFORMATION TABLE *****
SET @TableHTML =    
	'<font face="Verdana" size="4">Server Information</font>  
	 <table width="200" border="1" borderColor="#111111" style="BORDER-COLLAPSE: collapse">  
	 <tr>  
	 <td width="20%" bgcolor="#000080"><b><font face="Verdana" size="1" color="#ffffff">Server Name</font></b></td>  
	 </tr>  
	 <tr>  
	 <td align="center"><font face="Verdana" size="1">'+@Server_name+'\'+@instance_name+'</font></td>  
	 </tr>
	 </table>
	 </p>'

-- ***** END OF SERVER INFORMATION TABLE *****
-- ***** START OF SERVER LOG TABLE *****
IF EXISTS (SELECT NAME FROM sysobjects WHERE name = '#server_log')    
	BEGIN    
	DROP TABLE #server_log
	END
IF EXISTS (SELECT NAME FROM sysobjects WHERE name = '#agent_log')    
	BEGIN    
	DROP TABLE #agent_log
	END

SELECT 
	@TableHTML =  @TableHTML + 
	'<font face="Verdana" size="4">Server Log</font>
	 <table width="933" border="1" borderColor="#111111" style="BORDER-COLLAPSE: collapse">
	 <tr>
	 <td width="15%" bgColor="#000080"><b><font face="Verdana" size="1" color="#ffffff">Date</font></b></td>
	 <td width="10%" bgColor="#000080"><b><font face="Verdana" size="1" color="#ffffff">Error Level</font></b></td>
	 <td width="75%" bgColor="#000080"><b><font face="Verdana" size="1" color="#ffffff">Text (first 50 charactors)</font></b></td>
	 </tr>'

DECLARE	@StartDate_server_log DATETIME
DECLARE	@EndDate_server_log DATETIME

CREATE TABLE #server_log (LogDate DATETIME,
                          ProcessInfo VARCHAR(20),
                          [Text]  VARCHAR(MAX)) 
SELECT @StartDate_server_log = GETDATE()-+@days_prior
SELECT @EndDate_server_log = GETDATE()
INSERT #server_log(LogDate, ProcessInfo, [Text]) EXEC sys.xp_readerrorlog 0,            -- Value of error log file you want to read: 0 = current, 1 = Archive #1, 2 = Archive #2, etc... 
																	  1,            -- Log file type: 1 or NULL = error log, 2 = SQL Agent log 
																	  NULL,         -- Search string 1: String one you want to search for 
																	  NULL,         -- Search string 2: String two you want to search for to further refine the results
																	  @StartDate_server_log,   -- Search from start time  ('yyyy-mm-dd') 
																	  @EndDate_server_log,     -- Search to end time ('yyyy-mm-dd')
																	  N'desc'       -- Sort order for results: N'asc' = ascending, N'desc' = descending

DECLARE @cur_server_log_var1 DATETIME
DECLARE @cur_server_log_var2 VARCHAR(20)
DECLARE @cur_server_log_var3 VARCHAR(MAX)
DECLARE cur_server_log CURSOR FOR
	SELECT LogDate, ProcessInfo, (SELECT SUBSTRING([Text], 0, 100)) FROM #server_log

OPEN cur_server_log

FETCH NEXT FROM cur_server_log
           INTO @cur_server_log_var1, @cur_server_log_var2, @cur_server_log_var3

WHILE @@FETCH_STATUS = 0
    BEGIN  
	  SET @TableHTML =  @TableHTML +   
	      '<tr>
           <td><font face="Verdana" size="1">'+ CAST(@cur_server_log_var1 AS VARCHAR(50)) +'</font></td>' + '
           <td><font face="Verdana" size="1">'+ @cur_server_log_var2 +'</font></td>' + '
           <td><font face="Verdana" size="1">'+ @cur_server_log_var3 +'</font></td>
		   </tr>' 	
      FETCH NEXT FROM cur_server_log
          INTO @cur_server_log_var1, @cur_server_log_var2, @cur_server_log_var3		
    END
CLOSE cur_server_log
DEALLOCATE cur_server_log
DROP TABLE #server_log

SET @TableHTML = @TableHTML +
	'</table></p>'
-- ***** END OF SERVER LOG TABLE ***** 
-- ***** START OF SQL AGENT LOG TABLE *****
SELECT 
	@TableHTML =  @TableHTML + 
	'<font face="Verdana" size="4">SQL Agent Log</font>
	 <table width="933" border="1" borderColor="#111111" style="BORDER-COLLAPSE: collapse">
	 <tr>
	 <td width="15%" bgColor="#000080"><b><font face="Verdana" size="1" color="#ffffff">Date</font></b></td>
	 <td width="10%" bgColor="#000080"><b><font face="Verdana" size="1" color="#ffffff">Error Level</font></b></td>
	 <td width="75%" bgColor="#000080"><b><font face="Verdana" size="1" color="#ffffff">Text (first 50 charactors)</font></b></td>
	 </tr>'

DECLARE	@StartDate_agent_log DATETIME
DECLARE	@EndDate_agent_log DATETIME

CREATE TABLE #agent_log (LogDate DATETIME,
                          ErrorLevel VARCHAR(20),
                          [Text]  VARCHAR(MAX)) 
SELECT @StartDate_agent_log = GETDATE()-+@days_prior
SELECT @EndDate_agent_log = GETDATE()
INSERT #agent_log(LogDate, ErrorLevel, [Text]) EXEC sys.xp_readerrorlog 0,            -- Value of error log file you want to read: 0 = current, 1 = Archive #1, 2 = Archive #2, etc... 
																	  2,            -- Log file type: 1 or NULL = error log, 2 = SQL Agent log 
																	  NULL,         -- Search string 1: String one you want to search for 
																	  NULL,         -- Search string 2: String two you want to search for to further refine the results
																	  @StartDate_agent_log,   -- Search from start time  ('yyyy-mm-dd') 
																	  @EndDate_agent_log,     -- Search to end time ('yyyy-mm-dd')
																	  N'desc'       -- Sort order for results: N'asc' = ascending, N'desc' = descending

UPDATE #agent_log SET ErrorLevel = 'High' WHERE ErrorLevel = '1'
UPDATE #agent_log SET ErrorLevel = 'Warning' WHERE ErrorLevel = '2'
UPDATE #agent_log SET ErrorLevel = 'Information' WHERE ErrorLevel = '3'

DECLARE @cur_agent_log_var1 DATETIME
DECLARE @cur_agent_log_var2 VARCHAR(20)
DECLARE @cur_agent_log_var3 VARCHAR(MAX)
DECLARE cur_agent_log CURSOR FOR
	SELECT LogDate, ErrorLevel, (SELECT SUBSTRING([Text], 0, 100)) FROM #agent_log

OPEN cur_agent_log

FETCH NEXT FROM cur_agent_log
           INTO @cur_agent_log_var1, @cur_agent_log_var2, @cur_agent_log_var3

WHILE @@FETCH_STATUS = 0
	BEGIN
    IF @cur_agent_log_var2 = 'High'
		BEGIN   
		  SET @TableHTML =  @TableHTML +   
	      '<tr>
           <td><font face="Verdana" size="1">'+ CAST(@cur_agent_log_var1 AS VARCHAR(50)) +'</font></td>' + '
           <td bgColor="#ff0000"><font face="Verdana" size="1">'+ @cur_agent_log_var2 +'</font></td>' + '
           <td><font face="Verdana" size="1">'+ @cur_agent_log_var3  +'</font></td>
		   </tr>' 
        END		
    ELSE IF @cur_agent_log_var2 = 'Warning'
        BEGIN   
		  SET @TableHTML =  @TableHTML +   
	      '<tr>
           <td><font face="Verdana" size="1">'+ CAST(@cur_agent_log_var1 AS VARCHAR(50)) +'</font></td>' + '
           <td bgColor="#FFC10A"><font face="Verdana" size="1">'+ @cur_agent_log_var2 +'</font></td>' + '
           <td><font face="Verdana" size="1">'+ @cur_agent_log_var3 +'</font></td>
		   </tr>' 
        END		
    ELSE
        BEGIN  
		  SET @TableHTML =  @TableHTML +   
	      '<tr>
           <td><font face="Verdana" size="1">'+ CAST(@cur_agent_log_var1 AS VARCHAR(50)) +'</font></td>' + '
           <td><font face="Verdana" size="1">'+ @cur_agent_log_var2 +'</font></td>' + '
           <td><font face="Verdana" size="1">'+ @cur_agent_log_var3 +'</font></td>
		   </tr>' 	
        END 
    FETCH NEXT FROM cur_agent_log
          INTO @cur_agent_log_var1, @cur_agent_log_var2, @cur_agent_log_var3		
    END
CLOSE cur_agent_log
DEALLOCATE cur_agent_log
DROP TABLE #agent_log

SET @TableHTML = @TableHTML +
	'</table>'
-- ***** END OF SQL AGENT LOG TABLE *****
-- ***** END OF THE COMPILING OF HTML CODE *****
 
-- ***** SEND EMAIL *****
EXEC msdb.dbo.sp_send_dbmail  
	@profile_name = @MailProfile,    
	@recipients = @email_address,    
	@subject = @StrSubject,    
	@body = @TableHTML,    
	@body_format = 'HTML' ;    
SET NOCOUNT OFF
END
GO

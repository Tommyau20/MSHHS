USE [DBA]
GO
/****** Object:  StoredProcedure [dbo].[sp_WhatIsExecuting_email]    Script Date: 19/11/2018 8:38:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---------------------------------------------------------------------------------------------------
-- Object Type : Stored Procedure  
-- Object Name : sp_WhatIsExecuting_email
-- Description : Stored Procedure to send an email with information on what is currently executing.
-- Author : David Shaw
-- Date : November 2018
-- Version : 1.11
---------------------------------------------------------------------------------------------------
CREATE PROC [dbo].[sp_WhatIsExecuting_email]
@email_address VARCHAR(150)

AS
BEGIN
	-- ***** Start Do not lock anything, and do not get held up by any locks *****
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	-- ***** End Do not lock anything, and do not get held up by any locks *****
	-- ***** Start Variable declaration *****
	DECLARE @Server_name VARCHAR(100)	
	DECLARE	@MailProfile VARCHAR(100)
	DECLARE	@StrSubject VARCHAR(100)    
	DECLARE	@TableHTML  VARCHAR(MAX) 
	DECLARE @environment varchar(50) -- used to capture the enviornment for this instance

	SELECT @environment = [Value] FROM [DBA].[dbo].[Parameters] WHERE [Parameter] = 'Environment'
	-- ***** End Variable declaration *****
	-- ***** Start collect current execution data *****
	IF EXISTS (SELECT NAME FROM sysobjects WHERE name = '#WhatsExecuting')    
		BEGIN    
		DROP TABLE #WhatsExecuting
		END
	CREATE TABLE #WhatsExecuting (SPID int NULL,
								  ECID int NULL,
								  [Database] VARCHAR(50) NULL,
								  [User] VARCHAR(50) NULL,
								  [Status] VARCHAR(100) NULL,
								  [Wait] VARCHAR(50) NULL,
								  [IndividualQuery] VARCHAR(MAX) NULL,
								  [ParentQuery] VARCHAR(MAX) NULL,
								  [Program] VARCHAR(250) NULL,
								  [StartTime] Datetime) 

	INSERT #WhatsExecuting SELECT [Spid] = session_Id,
								  ecid,
								  [Database] = DB_NAME(sp.dbid),
								  [User] = nt_username,
								  [Status] = er.status,
								  [Wait] = wait_type,
								  [Individual Query] = SUBSTRING (qt.text, er.statement_start_offset/2,
								  (CASE WHEN er.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2
										ELSE er.statement_end_offset END - er.statement_start_offset)/2),
								  [Parent Query] = qt.text,
								  Program = program_name,
								  start_time
							FROM sys.dm_exec_requests er
								INNER JOIN sys.sysprocesses sp ON er.session_id = sp.spid
								CROSS APPLY sys.dm_exec_sql_text(er.sql_handle)as qt
							WHERE session_Id > 50              -- Ignore system spids.
								AND session_Id NOT IN (@@SPID)     -- Ignore this current statement.
							ORDER BY 1, 2
	-- ***** End collect current execution data *****
	-- ***** Start compiling email *****
	SET @MailProfile = (SELECT name FROM msdb.dbo.sysmail_profile WHERE profile_id = (SELECT profile_id FROM msdb.dbo.sysmail_Principalprofile WHERE is_default = '1'))
	SELECT @StrSubject = 'MSSQL alert (' + @environment + ') - Executing information ('+ CONVERT(VARCHAR(50), SERVERPROPERTY('servername')) + ')'    
	SELECT @Server_name = CONVERT(VARCHAR(50), SERVERPROPERTY('servername')) 
	SET @TableHTML =    
		'<font face="Verdana" size="4">Executing Information</font>  
		<table width="840" border="1" borderColor="#111111" style="BORDER-COLLAPSE: collapse">  
		<tr>  
		<td width="10%" bgcolor="#000080"><b><font face="Verdana" size="1" color="#ffffff">Database</font></b></td>  
		<td width="10%" bgcolor="#000080"><b><font face="Verdana" size="1" color="#ffffff">User</font></b></td>  
		<td width="5%" bgColor="#000080"><b><font face="Verdana" size="1" color="#ffffff">SPID</font></b></td>
		<td width="30%" bgColor="#000080"><b><font face="Verdana" size="1" color="#ffffff">Individual query</font></b></td>
		<td width="30%" bgColor="#000080"><b><font face="Verdana" size="1" color="#ffffff">Parent query</font></b></td>
		<td width="15%" bgColor="#000080"><b><font face="Verdana" size="1" color="#ffffff">Program</font></b></td>
		<td width="10%" bgColor="#000080"><b><font face="Verdana" size="1" color="#ffffff">Start time</font></b></td>
		</tr>'  
	DECLARE @cur_Database VARCHAR(50)
	DECLARE @cur_User VARCHAR(50)
	DECLARE @cur_SPID int
	DECLARE @cur_IndividualQuery VARCHAR(MAX)
	DECLARE @cur_ParentQuery VARCHAR(MAX)
	DECLARE @cur_Program VARCHAR(250)
	DECLARE @cur_StartTime Datetime
	DECLARE cur_executing CURSOR FOR
		SELECT [Database], [User], [SPID], [IndividualQuery], [ParentQuery], [Program], [StartTime] FROM #WhatsExecuting
	OPEN cur_executing
	FETCH NEXT FROM cur_executing
          INTO @cur_Database, @cur_User, @cur_SPID, @cur_IndividualQuery, @cur_ParentQuery, @cur_Program, @cur_StartTime
	WHILE @@FETCH_STATUS = 0
		BEGIN
		SET @TableHTML =  @TableHTML +   
	       '<tr>
           <td valign=top><font face="Verdana" size="1">'+ CAST(@cur_Database AS VARCHAR(50)) +'</font></td>' + '
           <td valign=top><font face="Verdana" size="1">'+ CAST(@cur_User AS VARCHAR(50)) +'</font></td>' + '
		   <td valign=top><font face="Verdana" size="1">'+ CAST(@cur_SPID AS VARCHAR(10)) +'</font></td>' + '
		   <td valign=top><font face="Verdana" size="1">'+ CAST(@cur_IndividualQuery AS VARCHAR(MAX)) +'</font></td>' + '
		   <td valign=top><font face="Verdana" size="1">'+ CAST(@cur_ParentQuery AS VARCHAR(200)) +'</font></td>' + '
		   <td valign=top><font face="Verdana" size="1">'+ CAST(@cur_Program AS VARCHAR(100)) +'</font></td>' + '
           <td valign=top><font face="Verdana" size="1">'+ CAST(@cur_StartTime AS VARCHAR(25)) +'</font></td>
		   </tr>'
		INSERT [DBA].[dbo].[WhatIsExecuting_email] VALUES (@cur_Database,
														   @cur_User,
														   @cur_SPID,
														   @cur_IndividualQuery, 
														   @cur_ParentQuery,
														   @cur_Program,
														   @cur_StartTime,
														   getdate())
		FETCH NEXT FROM cur_executing
          INTO @cur_Database, @cur_User, @cur_SPID, @cur_IndividualQuery, @cur_ParentQuery, @cur_Program, @cur_StartTime
 		END
	CLOSE cur_executing
	DEALLOCATE cur_executing
	DROP TABLE #WhatsExecuting
	SELECT @TableHTML =  @TableHTML + '</table></p>'
	-- ***** End compiling email *****
	-- ***** Start send HTML email *****
	EXEC msdb.dbo.sp_send_dbmail @profile_name = @MailProfile,    
								 @recipients=@email_address,    
								 @subject = @StrSubject,    
								 @body = @TableHTML,    
								 @body_format = 'HTML' ;    
	-- ***** End send HTML email *****
END
GO

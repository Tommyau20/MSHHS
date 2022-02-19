USE [DBA]
GO
/****** Object:  StoredProcedure [dbo].[sp_BlockTracer]    Script Date: 03/05/2010 11:37:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[sp_BlockTracer]
AS
/*--------------------------------------------------
 
Purpose: Shows details of the root blocking process, together with details of any blocked processed

----------------------------------------------------

Parameters: None.

Revision History:
      19/07/2007   Ian_Stirk@yahoo.com Initial version

Example Usage:
   1. exec YourServerName.master.dbo.dba_BlockTracer

--------------------------------------------------*/

BEGIN
   -- Do not lock anything, and do not get held up by any locks. 
   SET TRANSACTION ISOLATION LEVEL READ 
      UNCOMMITTED

   -- If there are blocked processes...
   IF EXISTS(SELECT 1 FROM sys.sysprocesses WHERE 
      blocked != 0) 
   BEGIN

      -- Identify the root-blocking spid(s)
      SELECT  distinct t1.spid  AS [Root blocking spids]
         , t1.[loginame] AS [Owner]
         , DBA.dbo.fn_GetSQLForSpid(t1.spid) AS 
            'SQL Text' 
         , t1.[cpu]
         , t1.[physical_io]
         , DatabaseName = DB_NAME(t1.[dbid])
         , t1.[program_name]
         , t1.[hostname]
         , t1.[status]
         , t1.[cmd]
         , t1.[blocked]
         , t1.[ecid] 
      FROM  sys.sysprocesses t1, sys.sysprocesses t2
      WHERE t1.spid = t2.blocked
        AND t1.ecid = t2.ecid
        AND t1.blocked = 0 
      ORDER BY t1.spid, t1.ecid

      -- Identify the spids being blocked.
      SELECT t2.spid AS 'Blocked spid'
         , t2.blocked AS 'Blocked By'
         , t2.[loginame] AS [Owner]
         , DBA.dbo.fn_GetSQLForSpid(t2.spid) AS 
            'SQL Text' 
         , t2.[cpu]
         , t2.[physical_io]
         , DatabaseName = DB_NAME(t2.[dbid])
         , t2.[program_name]
         , t2.[hostname]
         , t2.[status]
         , t2.[cmd]
         , t2.ecid
      FROM sys.sysprocesses t1, sys.sysprocesses t2 
      WHERE t1.spid = t2.blocked
        AND t1.ecid = t2.ecid
      ORDER BY t2.blocked, t2.spid, t2.ecid
   END

   ELSE -- No blocked processes.
      PRINT 'There is currently no processes being blocked.' 
END

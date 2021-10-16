
-- Script to create new schedule on start-up of SQL agent, for the SQL agent job that conducts daily full database backups.
-- The reason being, to conduct a full database backup on those instances that are on Azure servers that are configured for auto shutdown
-- and as such are shutdown, when their normal schedule for full database backup would normally execute (i.e. 7:00 pm - 09:00 pm) but cannot.

-- ************************************************************************************************************************************************
-- ******************************************** Create new schedule for Full Backup job ***********************************************************
-- ************************************************************************************************************************************************
EXEC master.sys.sp_configure 'xp_cmdshell', 1
RECONFIGURE
DECLARE @ip varchar(40)
DECLARE @ipLine varchar(200)
DECLARE @pos int
SET @ip = NULL
CREATE TABLE #IP_temp (ipLine VARCHAR(200))
INSERT #IP_temp exec master..xp_cmdshell 'ipconfig'
SELECT @ipLine = ipLine FROM #IP_temp WHERE (ipLine) like '%IPv4 Address%10.%'          
IF (isnull (@ipLine,'***') != '***')
       BEGIN 
    SET @pos = CharIndex (':',@ipLine,1);
    SET @ip = rtrim(ltrim(substring (@ipLine , 
    @pos + 1 ,
    len (@ipLine) - @pos)))
    END 
       --PRINT @ip
DROP TABLE #IP_temp
EXEC master.sys.sp_configure 'xp_cmdshell', 0
RECONFIGURE

IF @ip LIKE '10.4.%' 
       BEGIN
       DECLARE @Daily_job_id uniqueidentifier
       DECLARE @Daily_job_name VARCHAR (100)
       DECLARE @name_for_new_schedule VARCHAR (100)
       IF (SELECT COUNT(Job_id) FROM msdb.dbo.sysjobs WHERE [name] LIKE 'DBA - Database backup (FULL)%') = 1
              BEGIN
              SELECT @Daily_job_id = [job_id] FROM msdb.dbo.sysjobs WHERE [name] LIKE 'DBA - Database backup (FULL)%'
              SELECT @Daily_job_name = [name] FROM msdb.dbo.sysjobs WHERE [name] LIKE 'DBA - Database backup (FULL)%'
              SET @name_for_new_schedule = @Daily_job_name + ' (on startup)'
              --PRINT @Daily_job_id –- enable for testing purposes.
              --PRINT @Daily_job_name –- enable for testing purposes.
              --PRINT @name_for_new_schedule –- enable for testing purposes.
              IF NOT EXISTS (SELECT [schedule_id] FROM msdb.dbo.sysschedules WHERE [NAME] = @name_for_new_schedule) 
                     BEGIN
                     USE [msdb]
                     DECLARE @schedule_id int
                     EXEC msdb.dbo.sp_add_jobschedule @job_id=@Daily_job_id, 
                                                      @name=@name_for_new_schedule, 
                                                      @enabled=1, 
                                                      @freq_type=64, 
                                                      @freq_interval=1, 
                                                      @freq_subday_type=0, 
                                                      @freq_subday_interval=0, 
                                                      @freq_relative_interval=0, 
                                                      @freq_recurrence_factor=1, 
                                                      @active_start_date=20200320, 
                                                      @active_end_date=99991231, 
                                                      @active_start_time=0, 
                                                      @active_end_time=235959, 
                                                      @schedule_id = @schedule_id                      
                     EXEC msdb.dbo.sp_attach_schedule @job_id=@Daily_job_id, @schedule_name=@name_for_new_schedule                  
                     END
              ELSE
                     BEGIN
                     PRINT @name_for_new_schedule + ' already exists...'
                     END
              END
       ELSE
              BEGIN
              PRINT 'SQL agent job using the naming standard DBMP%Daily% not found...'
              END
       END    
ELSE
       BEGIN
       PRINT 'IP address (' + @ip + '... not Azure) means the new schedule was not deployed.'
       END


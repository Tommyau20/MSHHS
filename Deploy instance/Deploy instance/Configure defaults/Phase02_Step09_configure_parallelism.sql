-- *********************** SET PARALLELISM *****************************
EXEC sys.sp_configure N'cost threshold for parallelism', N'50'
GO
RECONFIGURE WITH OVERRIDE
GO


-- ************************** SET MAXDOP *******************************
-- http://support.microsoft.com/kb/2806535
-- https://www.brentozar.com/archive/2019/12/microsofts-guidance-on-how-to-set-maxdop-has-changed/
-- https://dba.stackexchange.com/questions/186364/script-to-setup-maxdop
-- https://www.brentozar.com/training/diagnosing-slow-sql-servers-wait-stats/5-wait-types-cxpacket-part-1-demonstrating-7-minutes/ (28:45 min mark)
-- https://dba.stackexchange.com/questions/186364/script-to-setup-maxdop
-- https://dba.stackexchange.com/questions/36522/maxdop-setting-algorithm-for-sql-server

SET NOCOUNT ON
DECLARE @maxdop varchar(5)
DECLARE @cmd nvarchar(200)
SELECT @maxdop = convert(varchar(5),CASE 
									WHEN cpu_count / hyperthread_ratio > 8
										THEN 8
									ELSE cpu_count / hyperthread_ratio
									END)
	FROM sys.dm_os_sys_info
SET @cmd = 'EXEC master.sys.sp_configure ''max degree of parallelism'',' + @maxdop + ';'   + CHAR(13) + CHAR(10)
SET @cmd = @cmd + 'RECONFIGURE WITH OVERRIDE;'
--PRINT @cmd
EXECUTE sp_executesql @cmd

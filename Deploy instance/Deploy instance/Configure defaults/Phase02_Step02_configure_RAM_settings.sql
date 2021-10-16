-- This script will configure the max. memory at the total memory minus 4GB or total memory minus 10%, which ever is the greater.
-- While Min. memory will be set to 50% of the Max. memory.


-- ************************** START - Set Max. memory ****************************************************
DECLARE @total_os_RAM int
DECLARE @max_SQL_RAM int
DECLARE @min_SQL_RAM int
SELECT @total_os_RAM = [total_physical_memory_kb] from sys.dm_os_sys_memory

If 4194304 > (@total_os_RAM / 10) -- Is 4GB (min. amount for Windows) greater than 10% of the total memory.
	BEGIN
	SET @max_SQL_RAM = (@total_os_RAM - 4194304)/(1024^2) -- Declare Max. memory to be total memory minus 4GB to be left for Windows.
	SET @min_SQL_RAM = (@max_SQL_RAM / 2) -- Declare Min. memory to be 50% of the Max. memory.
	END
ELSE
	BEGIN
	SET @max_SQL_RAM = (@total_os_RAM - (@total_os_RAM / 10))/(1024^2) -- Declare Max. memory to be total memory minus 10% to be left for Windows.
	SET @min_SQL_RAM = (@max_SQL_RAM / 2) -- Declare Min. memory to be 50% of the Max. memory. 
	END

EXEC master.sys.sp_configure N'max server memory (MB)', @max_SQL_RAM
EXEC master.sys.sp_configure N'min server memory (MB)', @min_SQL_RAM
GO
RECONFIGURE WITH OVERRIDE
GO






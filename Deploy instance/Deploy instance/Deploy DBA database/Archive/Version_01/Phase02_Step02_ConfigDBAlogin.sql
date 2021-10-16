USE [DBA]
GO
CREATE USER [DBA] FOR LOGIN [DBA]
GO
USE [DBA]
GO
ALTER ROLE [db_datareader] ADD MEMBER [DBA]
GO
USE [DBA]
GO
ALTER ROLE [db_datawriter] ADD MEMBER [DBA]
GO



-- This will provide DBA login with the necessary permissions for SP [DBA_Central].[dbo].[sp_HaDrEnabledServersCollector] & [InstanceCollector] to run across the linked server from the DBA Central server/instance.
use [master]
GO
GRANT VIEW SERVER STATE TO [DBA]
GO

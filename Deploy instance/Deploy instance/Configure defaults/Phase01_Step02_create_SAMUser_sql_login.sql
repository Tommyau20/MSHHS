-- https://documentation.solarwinds.com/en/Success_Center/SAM/Content/SAM-AppInsight-for-SQL-Requirements-and-Permissions-sw1273.htm

-- Create login PA-Health\SAMUser
USE [master]
GO
CREATE LOGIN [PA-HEALTH\SAMUser] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
GO

-- Grant connect to any database to login PA-Health\SAMUser
use [master]
GO
GRANT CONNECT ANY DATABASE TO [PA-HEALTH\SAMUser]
GO

-- Grant specific system database permissions to login PA-Health\SAMUser 
USE [master]
GO
EXEC sp_adduser @loginame = 'PA-Health\SAMUser' ,@name_in_db = 'PA-Health\SAMUser'
GRANT VIEW SERVER STATE TO "PA-Health\SAMUser"
GRANT VIEW ANY DEFINITION TO "PA-Health\SAMUser"
GRANT EXECUTE ON xp_readerrorlog TO "PA-Health\SAMUser"
USE [msdb]
GO
EXEC sp_adduser @loginame = 'PA-Health\SAMUser' ,@name_in_db = 'PA-Health\SAMUser'
EXEC sp_addrolemember N'db_datareader', N'PA-Health\SAMUser'
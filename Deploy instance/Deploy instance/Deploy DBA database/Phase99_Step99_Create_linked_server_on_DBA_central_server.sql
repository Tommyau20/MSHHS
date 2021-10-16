USE [master]
GO

DECLARE @ServerName VARCHAR(50)
DECLARE @DBAPassWord VARCHAR(50)
SET @ServerName = '$(var_server)'
SET @DBAPassWord = '$(var_password)' -- This marries with the password in the script to create DBA SQL login on the source server

EXEC master.dbo.sp_addlinkedserver @server = @ServerName, @srvproduct=N'SQL Server'
EXEC master.dbo.sp_serveroption @server=@ServerName, @optname=N'collation compatible', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=@ServerName, @optname=N'data access', @optvalue=N'true'
EXEC master.dbo.sp_serveroption @server=@ServerName, @optname=N'dist', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=@ServerName, @optname=N'pub', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=@ServerName, @optname=N'rpc', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=@ServerName, @optname=N'rpc out', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=@ServerName, @optname=N'sub', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=@ServerName, @optname=N'connect timeout', @optvalue=N'0'
EXEC master.dbo.sp_serveroption @server=@ServerName, @optname=N'collation name', @optvalue=null
EXEC master.dbo.sp_serveroption @server=@ServerName, @optname=N'lazy schema validation', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=@ServerName, @optname=N'query timeout', @optvalue=N'0'
EXEC master.dbo.sp_serveroption @server=@ServerName, @optname=N'use remote collation', @optvalue=N'true'
EXEC master.dbo.sp_serveroption @server=@ServerName, @optname=N'remote proc transaction promotion', @optvalue=N'true'


USE [master]
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname = @ServerName,
				     @locallogin = NULL ,
				     @useself = N'False', 
                                     @rmtuser = N'DBA', 
				     @rmtpassword = @DBAPassWord
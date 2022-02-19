USE [DBA]
GO

INSERT INTO [DBA].[dbo].[Parameters]
           ([Parameter]
  	   ,[Value])
     VALUES
           ('Deployment date'
	   ,(SELECT CONVERT(VARCHAR,GETDATE(), 20)))
GO

INSERT INTO [DBA].[dbo].[Parameters]
           ([Parameter]
  	   ,[Value])
     VALUES
           ('Environment'
	   ,'$(var_environment)')
GO

INSERT INTO [DBA].[dbo].[Parameters]
           ([Parameter]
  	   ,[Value])
     VALUES
           ('SharedInstance'
	   ,'$(var_shared)')
GO


-- ********************************************************************************
-- The below inserts do not need configuring. They will be populated as required.
-- ********************************************************************************
INSERT INTO [DBA].[dbo].[Parameters]
	  ([Parameter]
  	  ,[Value])
     VALUES
	  ('CPU count at deployment'
	  ,(SELECT cpu_count FROM sys.dm_os_sys_info))
GO

INSERT INTO [DBA].[dbo].[Parameters]
	  ([Parameter]
  	  ,[Value])
     VALUES
	  ('Hyperthread ratio at deployment'
	  ,(SELECT hyperthread_ratio FROM sys.dm_os_sys_info))
GO

INSERT INTO [DBA].[dbo].[Parameters]
           ([Parameter]
  	   ,[Value])
     VALUES
           ('MAXDOP at deployment'
	   ,(SELECT cpu_count / hyperthread_ratio FROM sys.dm_os_sys_info))
GO

INSERT INTO [DBA].[dbo].[Parameters]
           ([Parameter]
  	   ,[Value])
     VALUES
           ('Cost threshold for parallelism at deployment'
	   ,(SELECT CONVERT(VARCHAR(MAX), [value_in_use]) FROM sys.configurations WHERE [NAME] = 'cost threshold for parallelism'))
GO

INSERT INTO [DBA].[dbo].[Parameters]
	   ([Parameter]
	   ,[Value])
     VALUES
	   ('Total physical memory (MB) at deployment'
	   ,(SELECT [total_physical_memory_kb]/(1024^2) from sys.dm_os_sys_memory))
GO

INSERT INTO [DBA].[dbo].[Parameters]
	   ([Parameter]
	   ,[Value])
     VALUES
	   ('Min. server memory (MB) at deployment'
	   ,(SELECT CONVERT(VARCHAR(MAX), [value_in_use]) FROM sys.configurations WHERE [NAME] = 'min server memory (MB)'))
GO

INSERT INTO [DBA].[dbo].[Parameters]
	   ([Parameter]
	   ,[Value])
     VALUES
	   ('Max. server memory (MB) at deployment'
	   ,(SELECT CONVERT(VARCHAR(MAX), [value_in_use]) FROM sys.configurations WHERE [NAME] = 'max server memory (MB)'))
GO

INSERT INTO [DBA].[dbo].[Parameters]
           ([Parameter]
  	   ,[Value])
     VALUES
           ('DBA Central last connection'
	   ,NULL)
GO

-- ******************************************************************************
-- Select * from [DBA].[dbo].[Parameters]

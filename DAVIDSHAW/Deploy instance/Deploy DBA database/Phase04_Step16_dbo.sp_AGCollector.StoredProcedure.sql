USE [DBA]
GO

/****** Object:  StoredProcedure [dbo].[sp_AGCollector]    Script Date: 3/27/2020 11:58:46 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




-----------------------------------------------------------------------------------------------------------------------
-- Object Type : Stored Procedure  
-- Object Name : sp_AGCollector
-- Description : Stored Procedure to insert Availability Group information into the table DBA.dbo.AGCollector
-- Author : David Shaw
-- Date : March 2020
-- Version : 0.01
------------------------------------------------------------------------------------------------------------------------


CREATE PROCEDURE [dbo].[sp_AGCollector]
AS
BEGIN
	DELETE FROM [DBA].[dbo].[AGCollector]	

	INSERT INTO [DBA].[dbo].[AGCollector]
									([Availability_group_name],
									 [Primary_server],
									 [AG_role_desc],
									 [Listener_name],
									 [RecordedDate]) 
										SELECT AGC.name AS [Availability_group_name], RCS.replica_server_name AS [Primary_server], ARS.role_desc AS [AG_role_desc], AGL.dns_name AS [Listener_name], GETDATE()
											FROM [master].sys.availability_groups_cluster AS AGC INNER JOIN 
												 [master].sys.dm_hadr_availability_replica_cluster_states AS RCS ON RCS.group_id = AGC.group_id INNER JOIN 
												 [master].sys.dm_hadr_availability_replica_states AS ARS ON ARS.replica_id = RCS.replica_id INNER JOIN 
												 [master].sys.availability_group_listeners AS AGL ON AGL.group_id = ARS.group_id	
													WHERE RCS.replica_server_name = (SELECT SERVERPROPERTY('ComputerNamePhysicalNetBIOS'))

END


GO



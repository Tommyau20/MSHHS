USE [DBA]
GO
SELECT name, modify_date 
	FROM sys.objects
		WHERE type = 'P' AND [name] LIKE 'sp_blitz%'
			ORDER BY modify_date DESC
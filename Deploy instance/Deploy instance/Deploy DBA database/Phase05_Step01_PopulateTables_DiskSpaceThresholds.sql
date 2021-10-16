USE [DBA]
GO

INSERT [DiskSpaceThresholds]([DriveLetter],[Urgent_FreePercent]) EXEC master.dbo.xp_fixeddrives
UPDATE [DiskSpaceThresholds] SET [Urgent_FreePercent] = 10 , [Critical_FreePercent] = 5 , [Minimum_FreeGB] = 10
SELECT * FROM [DBA].[dbo].[DiskSpaceThresholds]

GO


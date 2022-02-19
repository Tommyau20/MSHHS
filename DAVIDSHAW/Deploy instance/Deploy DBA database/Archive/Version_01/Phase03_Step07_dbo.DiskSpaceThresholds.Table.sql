USE [DBA]
GO
/****** Object:  Table [dbo].[DiskSpaceThresholds]    Script Date: 19/11/2018 8:37:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DBA].[dbo].[DiskSpaceThresholds](
	[DriveLetter] [varchar](5) NULL,
	[Urgent_FreePercent] [int] NULL,
	[Critical_FreePercent] [int] NULL,
	[Minimum_FreeGB] [int] NULL
) ON [PRIMARY]
GO

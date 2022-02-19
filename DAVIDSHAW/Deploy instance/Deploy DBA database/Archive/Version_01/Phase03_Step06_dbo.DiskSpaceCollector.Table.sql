USE [DBA]
GO
/****** Object:  Table [dbo].[DiskSpaceCollector]    Script Date: 19/11/2018 8:37:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DBA].[dbo].[DiskSpaceCollector](
	[ServerName] [varchar](25) NULL,
	[InstanceName] [varchar](50) NULL,
	[DriveLetter] [char](1) NULL,
	[TotalSpaceGB] [decimal](11, 2) NULL,
	[FreeSpaceGB] [decimal](11, 2) NULL,
	[Date] [smalldatetime] NULL
) ON [PRIMARY]
GO

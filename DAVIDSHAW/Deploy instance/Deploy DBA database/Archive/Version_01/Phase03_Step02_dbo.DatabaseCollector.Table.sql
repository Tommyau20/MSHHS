USE [DBA]
GO


IF OBJECT_ID('dbo.DatabaseCollector', 'U') IS NOT NULL
	DROP TABLE [dbo].[DatabaseCollector]
GO


/****** Object:  Table [dbo].[DatabaseCollector]    Script Date: 19/11/2018 8:37:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DBA].[dbo].[DatabaseCollector](
	[ServerName] [varchar](25) NULL,
	[InstanceName] [varchar](50) NULL,
	[DatabaseName] [varchar](100) NULL,
	[DatabaseOwner] [varchar](50) NULL,
	[TotalSizeGB] [decimal](15, 2) NULL,
	[DBCreatedDate] [smalldatetime] NULL,
	[DBStatus] [varchar](100) NULL,
	[AvailGroupName] [varchar](25) NULL,
	[RecoveryModel] [varchar](50) NULL,
	[LastFullBackupDate] [datetime] NULL,
	[FullBackupMediaSet] [int] NULL,
	[FullBackupLocation] [varchar](1000) NULL,
	[LastDiffBackupDate] [datetime] NULL,
	[DiffBackupMediaSet] [int] NULL,
	[DiffBackupLocation] [varchar](1000) NULL,
	[LastLogBackupDate] [datetime] NULL,
	[LogBackupMediaSet] [int] NULL,
	[LogBackupLocation] [varchar](1000) NULL,
	[RecordedDate] [smalldatetime] NULL
) ON [PRIMARY]
GO

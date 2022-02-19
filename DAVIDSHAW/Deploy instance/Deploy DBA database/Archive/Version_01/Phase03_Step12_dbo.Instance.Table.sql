USE [DBA]
GO

/****** Object:  Table [dbo].[Instance]    Script Date: 21/12/2018 3:24:32 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Instance](
	[ServerName] [varchar](25) NULL,
	[InstanceName] [varchar](50) NULL,
	[IPAddress] [varchar](48) NULL,
	[Environment] [varchar](50) NULL,
	[ProductVersion] [varchar](50) NULL,
	[Version] [varchar](8) NULL,
	[Edition] [varchar](50) NULL,
	[ServicePack] [varchar](10) NULL,
	[CPU_count] [int] NULL,
	[IsClustered] [bit] NULL,
	[IsHadrEnabled] [bit] NULL,
	[DateCollected] [smalldatetime] NULL
) ON [PRIMARY]
GO



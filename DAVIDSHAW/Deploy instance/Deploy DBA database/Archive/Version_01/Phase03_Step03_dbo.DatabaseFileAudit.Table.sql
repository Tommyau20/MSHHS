USE [DBA]
GO
/****** Object:  Table [dbo].[DatabaseFileAudit]    Script Date: 19/11/2018 8:37:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DBA].[dbo].[DatabaseFileAudit](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[DatabaseID] [smallint] NULL,
	[DatabaseName] [varchar](100) NULL,
	[FileName] [varchar](500) NULL,
	[SpaceAllocated (MB)] [decimal](11, 2) NULL,
	[PercentageUsed (%)] [decimal](11, 2) NULL,
	[AutoGrowth] [bit] NULL,
	[RecordedDate] [datetime] NULL,
 CONSTRAINT [PK_DatabaseFileAudit] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

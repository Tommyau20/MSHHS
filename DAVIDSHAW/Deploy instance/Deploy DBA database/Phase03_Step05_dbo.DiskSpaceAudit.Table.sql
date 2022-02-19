USE [DBA]
GO
/****** Object:  Table [dbo].[DiskSpaceAudit]    Script Date: 19/11/2018 8:37:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DBA].[dbo].[DiskSpaceAudit](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ServerName] [varchar](25) NULL,
	[InstanceName] [varchar](50) NULL,
	[DriveLetter] [char](1) NULL,
	[TotalSpaceGB] [decimal](11, 2) NULL,
	[FreeSpaceGB] [decimal](11, 2) NULL,
	[Date] [smalldatetime] NULL,
 CONSTRAINT [PK_DiskSpaceAudit] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

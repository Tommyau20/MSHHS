USE [DBA]
GO

/****** Object:  Table [dbo].[AGCollector]    Script Date: 3/27/2020 11:58:29 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[AGCollector](
	[Availability_group_name] [sysname] NULL,
	[Primary_server] [nvarchar](256) NOT NULL,
	[AG_role_desc] [nvarchar](60) NULL,
	[Listener_name] [nvarchar](63) NULL,
	[RecordedDate] [smalldatetime] NULL
) ON [PRIMARY]
GO



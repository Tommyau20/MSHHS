USE [DBA]
GO

/****** Object:  Table [dbo].[LoginChangeAudit]    Script Date: 6/12/2019 8:31:50 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[LoginChangeAudit](
	[TransactionID] [bigint] NULL,
	[EventName] [nvarchar](128) NULL,
	[subclass_name] [nvarchar](128) NULL,
	[DatabaseName] [nvarchar](256) NULL,
	[NTDomainName] [nvarchar](256) NULL,
	[HostName] [nvarchar](256) NULL,
	[ApplicationName] [nvarchar](256) NULL,
	[LoginName] [nvarchar](256) NULL,
	[SPID] [int] NULL,
	[TargetLoginName] [nvarchar](256) NULL,
	[TargetUserName] [nvarchar](256) NULL,
	[TargetRoleName] [nvarchar](256) NULL,
	[SessionLoginName] [nvarchar](256) NULL,
	[StartTime] [datetime] NULL
) ON [PRIMARY]
GO



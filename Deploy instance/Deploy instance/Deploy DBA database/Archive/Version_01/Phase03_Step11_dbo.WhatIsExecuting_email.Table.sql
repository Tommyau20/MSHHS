USE [DBA]
GO
/****** Object:  Table [dbo].[WhatIsExecuting_email]    Script Date: 19/11/2018 8:37:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DBA].[dbo].[WhatIsExecuting_email](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Database] [varchar](50) NULL,
	[User] [varchar](50) NULL,
	[SPID] [int] NULL,
	[IndividualQuery] [varchar](max) NULL,
	[ParentQuery] [varchar](max) NULL,
	[Program] [varchar](250) NULL,
	[StartTime] [datetime] NULL,
	[Date] [smalldatetime] NULL,
 CONSTRAINT [PK_WhatsIsExecutingEmail] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

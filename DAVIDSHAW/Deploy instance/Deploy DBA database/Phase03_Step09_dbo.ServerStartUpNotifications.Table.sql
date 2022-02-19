USE [DBA]
GO
/****** Object:  Table [dbo].[ServerStartUpNotifications]    Script Date: 19/11/2018 8:37:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DBA].[dbo].[ServerStartUpNotifications](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Recipient] [varchar](50) NULL,
	[EmailSubject] [varchar](100) NULL,
	[EmailMessage] [varchar](150) NULL,
	[Date] [datetime] NULL,
 CONSTRAINT [PK_ServerStartUpNotifications] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

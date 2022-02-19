USE [DBA]
GO
/****** Object:  Table [dbo].[cmdshell_state]    Script Date: 19/11/2018 8:37:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DBA].[dbo].[cmdshell_state](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[job_name] [varchar](100) NULL,
	[step_number] [int] NULL,
	[before_step] [int] NULL,
	[after_step] [int] NULL,
	[Date_changed] [smalldatetime] NULL,
	[Date_reverted] [smalldatetime] NULL,
 CONSTRAINT [PK_xp_cmd_status] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

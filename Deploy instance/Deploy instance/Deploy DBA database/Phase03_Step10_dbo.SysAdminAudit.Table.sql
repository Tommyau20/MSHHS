USE [DBA]
GO
/****** Object:  Table [dbo].[SysAdminAudit]    Script Date: 19/11/2018 8:37:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DBA].[dbo].[SysAdminAudit](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ServerName] [varchar](25) NULL,
	[InstanceName] [varchar](50) NULL,
	[SQL_login_with_sysadmin] [varchar](100) NULL,
	[Indirect_Win_login_with_sysadmin] [varchar](100) NULL,
	[Win_login_type] [varchar](100) NULL,
	[Sysadmin_via_SQL_login] [varchar](100) NULL,
	[Date] [datetime] NOT NULL,
	[Acknowledged] [bit] NULL,
 CONSTRAINT [PK_SysAdminAudit] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[SysAdminAudit] ADD  CONSTRAINT [DF_SysAdminAudit_Date]  DEFAULT (getdate()) FOR [Date]
GO
ALTER TABLE [dbo].[SysAdminAudit] ADD  CONSTRAINT [DF_SysAdminAudit_Acknowledged]  DEFAULT ((0)) FOR [Acknowledged]
GO

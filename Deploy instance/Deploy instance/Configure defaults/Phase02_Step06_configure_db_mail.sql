USE [master]
GO

IF NOT EXISTS(SELECT * from msdb.dbo.sysmail_profile)
	BEGIN
		
		/******	Global Variable declaration ******/
		DECLARE @DBMailProfileNameDescription VARCHAR(100)
		DECLARE @DBMailProfileName VARCHAR(100)
		DECLARE @SMTPServer VARCHAR(100)
		DECLARE @TestEmail VARCHAR(100)
		DECLARE @EmailDomain VARCHAR(100)
		DECLARE @replyToEmail  VARCHAR(100)

		/******	Variables requiring configuration to suit ******/
		SET @DBMailProfileName = 'DatabaseMail'
		SET @DBMailProfileNameDescription ='Default database mail profile'
		SET @SMTPServer = 'qhsmtp.health.qld.gov.au'
		SET @TestEmail = 'ADM-MSHCIOPSStaff-Full@health.qld.gov.au'
		SET @EmailDomain = '@health.qld.gov.au'
		SET @replyToEmail = ''
		
		/****** Set Up Database Mail ******/
		exec sp_configure 'show advanced options', 1
		RECONFIGURE
		exec sp_configure 'Database Mail XPs', 1
		RECONFIGURE
		exec sp_configure 'Agent XPs',1
		RECONFIGURE
		RECONFIGURE WITH OVERRIDE

		DECLARE @servername varchar(100)
		DECLARE @email_address varchar(100)
		DECLARE @display_name varchar(100)
		DECLARE @testmsg varchar(100)

		SET @servername = (SELECT (CONVERT (VARCHAR(25), (SERVERPROPERTY('MachineName')))))
		SET @email_address = @servername + @EmailDomain
		SET @display_name = @servername
		SET @testmsg = 'Test email from ' + @servername + ' to confirm configuration of MSSQL database mail.'

		/****** Create database mail account ******/
		EXEC msdb.dbo.sysmail_add_account_sp @Account_name = @servername,
											 @description = '',
											 @email_address = @email_address,
											 @replyto_address = @replyToEmail,
											 @display_name = @display_name,
											 @mailserver_name = @SMTPServer

		/****** Create global mail profile ******/
		EXEC msdb.dbo.sysmail_add_profile_sp @profile_name = @DBMailProfileName,
											 @description = @DBMailProfileNameDescription

		/****** Add the account to the profile ******/
		EXEC msdb.dbo.sysmail_add_profileaccount_sp	@profile_name = @DBMailProfileName,
													@Account_name = @servername,
													@sequence_number=1

		/****** Grant access to the profile to all users in the msdb database ******/
		EXEC msdb.dbo.sysmail_add_principalprofile_sp @profile_name = @DBMailProfileName,
													  @principal_name = 'public',
													  @is_default = 1

		/****** Enabling SQL Agent notification ******/
		/****** IMPORTANT, THIS COMMAND HAS PROBLEMS ON OLDER VERSIONS OF MSSQL ******/
		EXEC msdb.dbo.sp_set_sqlagent_properties @email_save_in_sent_folder=1, 
												 @databasemail_profile=N'DatabaseMail'
		
		/****** Send test email ******/
		EXEC msdb..sp_send_dbmail @profile_name = @DBMailProfileName, 
								  @recipients = @TestEmail,
								  @subject = @testmsg,
								  @body = @testmsg

		/******  SQL Agent reminder ******/
		PRINT '**************************************************************************'
		PRINT 'Please restart the SQL server agent in order to enable agent notifications'
		PRINT '**************************************************************************'
	END
ELSE
	BEGIN
		DECLARE @ExistingDBMailProfileName VARCHAR(100)
		SET @ExistingDBMailProfileName = (SELECT NAME from msdb.dbo.sysmail_profile)
		PRINT '*****************************************'
		PRINT 'Database mail has already been configured'
		PRINT '*****************************************'
		PRINT ''
		PRINT 'Existing database mail profile name = ' + @ExistingDBMailProfileName
	END
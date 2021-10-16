-- ***********************************************************************
-- *********** Confirm the configuration of the notifications ************
-- ***********************************************************************
SELECT SJ.[name] as [Job name],SC.[name] as [Category name], SJ.category_id as [Catergory ID] 
	FROM msdb..sysjobs SJ JOIN msdb..syscategories SC
	  ON SJ.category_id = SC.category_id ORDER BY SC.[name]
SELECT [name] AS 'DBA email notification' FROM msdb..sysjobs WHERE notify_email_operator_id = (SELECT id FROM msdb..sysoperators WHERE [name] = 'DBA') ORDER by [name]
SELECT [name] AS 'DBA pager notification' FROM msdb..sysjobs WHERE notify_page_operator_id = (SELECT id FROM msdb..sysoperators WHERE [name] = 'DBA') ORDER by [name]
SELECT [name] AS 'CI_OPS email notification' FROM msdb..sysjobs WHERE notify_email_operator_id = (SELECT id FROM msdb..sysoperators WHERE [name] = 'CI_OPS') ORDER by [name]
SELECT [name] AS 'CI_OPS pager notification' FROM msdb..sysjobs WHERE notify_page_operator_id = (SELECT id FROM msdb..sysoperators WHERE [name] = 'CI_OPS') ORDER by [name]
SELECT [name] AS 'Email notifications not configured' FROM msdb..sysjobs WHERE notify_email_operator_id = 0 ORDER by [name]
SELECT [name] AS 'Pager notifications not configured' FROM msdb..sysjobs WHERE notify_page_operator_id = 0 ORDER by [name]


-- ***************************************************************************
-- *********** Confirm all SQL agent job owners and notifications ************
-- ***************************************************************************
SELECT a.name AS [JobName], suser_sname( a.owner_sid ) AS [OwnerName], sop.name AS [Email operator]
 FROM msdb.dbo.sysjobs a LEFT OUTER JOIN
		sys.server_principals b ON a.owner_sid = b.sid LEFT OUTER JOIN
        msdb.dbo.sysoperators sop ON a.notify_email_operator_id = sop.id			
			ORDER BY a.name

-- ******************************************************
-- *********** Confirm alerts notifications  ************
-- ******************************************************
SELECT sa.name AS [Alert name], sop.name As [Operator name] 
	FROM msdb.dbo.sysnotifications sn FULL OUTER JOIN
	msdb.dbo.sysalerts sa ON sa.id = sn.alert_id FULL OUTER JOIN
	msdb.dbo.sysoperators sop ON sn.operator_id = sop.id
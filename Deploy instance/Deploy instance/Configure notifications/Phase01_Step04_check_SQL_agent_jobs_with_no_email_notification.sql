-- ********************************************************************************
-- *********** SQL agent jobs with no notification operator confgiured ************
-- *********** ideally this should return no records ******************************
-- ********************************************************************************
SELECT [name] AS 'Jobs_with_no_email_notifications_configured' FROM msdb..sysjobs WHERE notify_email_operator_id = 0 ORDER by [name]
--SELECT [name] AS 'Jobs_with_no_pager_notifications_configured' FROM msdb..sysjobs WHERE notify_page_operator_id = 0 ORDER by [name]
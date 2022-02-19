USE [DBA]
GO

DELETE FROM [DBA].[dbo].[cmdshell_state] 

--DBCC CHECKIDENT ('[DBA].[dbo].[cmdshell_state]', RESEED, 1)


INSERT INTO [dbo].[cmdshell_state] 
	([job_name]
	,[step_number]
	,[before_step]
	,[after_step])
VALUES 
	('sp_DiskSpaceCheck_xp', 0, 0, 0)

INSERT INTO [dbo].[cmdshell_state] 
	([job_name]
	,[step_number]
	,[before_step]
	,[after_step])
VALUES 
	('sp_DiskSpaceCheck_ole', 0, 0, 0)

INSERT INTO [DBA].[dbo].[cmdshell_state]
        ([job_name],
        [step_number],
        [before_step],
        [after_step])
VALUES
        ('sp_DiskSpaceAudit_xp', 0, 0, 0)

INSERT INTO [DBA].[dbo].[cmdshell_state]
        ([job_name],
        [step_number],
        [before_step],
        [after_step])
    VALUES
        ('sp_DiskSpaceAudit_ole', 0, 0, 0)

INSERT INTO [DBA].[dbo].[cmdshell_state]
        ([job_name],
        [step_number],
        [before_step],
        [after_step])
    VALUES
        ('sp_DiskSpaceCollector_xp', 0, 0, 0)

INSERT INTO [DBA].[dbo].[cmdshell_state]
        ([job_name],
        [step_number],
        [before_step],
        [after_step])
    VALUES
        ('sp_DiskSpaceCollector_ole', 0, 0, 0)

INSERT INTO [DBA].[dbo].[cmdshell_state]
        ([job_name],
        [step_number],
        [before_step],
        [after_step])
    VALUES
        ('sp_ServerHealthAudit_xp', 0, 0, 0)

INSERT INTO [DBA].[dbo].[cmdshell_state]
        ([job_name],
        [step_number],
        [before_step],
        [after_step])
    VALUES
        ('sp_ServerHealthAudit_ole', 0, 0, 0)


	


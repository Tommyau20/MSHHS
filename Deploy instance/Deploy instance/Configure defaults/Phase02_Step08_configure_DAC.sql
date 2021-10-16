EXEC master.sys.sp_configure 'remote admin connections', 1; 
GO 
RECONFIGURE; 
GO


-- ********************** NOTES **********************
-- *** SSMS ***
-- <Servername>,1434

-- *** SQLCMD ***
-- sqlcmd -S admin:<ServerName> -E


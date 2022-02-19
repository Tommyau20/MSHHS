-- This change addressed the problem experienced by DSMU applications team, when transactional replication was trying to move tables with PDF's in BLOB's

EXEC master.sys.sp_configure 'max text repl size (b)', 2147483647;
GO
RECONFIGURE;
GO
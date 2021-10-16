-- The below code is purely to query the current setting, at this point I am not playing to change it,
-- it should be correct as long as Windows is set correctly with regional setting etc.

-- English = 0
-- British English = 23

EXEC master.sys.sp_configure 'default language'

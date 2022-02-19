@echo off
SET /p SERVER="Please provide <Server name\instance,port> (leave instance and port blank if defaults): "
SET /p DBA_PASSWORD="Please provide password for SQL login 'DBA' (available in KeePass): "

REM ****************** None of the code below should need altering ***********************************
SET DATABASE=master
REM **** Create SQL login DBA... using a variable so that the password is never saved in plain text ****
sqlcmd -S %SERVER% -d %DATABASE% -v var_password=%DBA_PASSWORD% -i Phase01_Step01_create_DBA_sql_login.sql -o Phase01_Step01_create_DBA_sql_login.log
timeout /t 10 /nobreak > NUL
Notepad.exe Phase01_Step01_create_DBA_sql_login.log

SET DATABASE=master
REM **** Run all of Phase 01 t-sql scripts ****
for %%v in (Phase02*.sql) do sqlcmd -S %SERVER% -d %DATABASE% -i %%v -o %%v.log
for %%v in (Phase02*.sql) do %%v.log

REM ************** Del *.log
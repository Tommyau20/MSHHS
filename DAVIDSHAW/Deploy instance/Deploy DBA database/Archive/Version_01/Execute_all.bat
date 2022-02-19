@echo off
SET /p SERVER="Please provide <Server name\instance,port> (leave instance and port blank if defaults): "
SET /p DBA_PASSWORD="Please provide password for SQL login 'DBA' (available in KeePass): "
SET /p ENVIRONMENT="What environment is this server joining (e.g. UAT, Production): "
SET /p SHARED="Is this a shared server (yes=1 or no=0): "

REM ****************** None of the code below should need altering ***********************************
SET DATABASE=master
REM **** Run all of Phase 01 t-sql scripts ****
for %%v in (Phase01*.sql) do sqlcmd -S %SERVER% -d %DATABASE% -i %%v -o %%v.log
for %%v in (Phase01*.sql) do %%v.log

REM **** Run all of Phase 02 t-sql scripts ****
for %%v in (Phase02*.sql) do sqlcmd -S %SERVER% -d %DATABASE% -i %%v -o %%v.log
for %%v in (Phase02*.sql) do %%v.log

REM **** Run all of Phase 03 t-sql scripts ****
for %%v in (Phase03*.sql) do sqlcmd -S %SERVER% -d %DATABASE% -i %%v -o %%v.log
for %%v in (Phase03*.sql) do %%v.log

REM **** Run all of Phase 04 t-sql scripts ****
for %%v in (Phase04*.sql) do sqlcmd -S %SERVER% -d %DATABASE% -i %%v -o %%v.log
for %%v in (Phase04*.sql) do %%v.log

REM **** Run all of Phase 05 t-sql scripts ****
for %%v in (Phase05*.sql) do sqlcmd -S %SERVER% -d %DATABASE% -i %%v -o %%v.log
for %%v in (Phase05*.sql) do %%v.log

REM **** Run all of Phase 06 t-sql scripts ****
for %%v in (Phase06*.sql) do sqlcmd -S %SERVER% -d %DATABASE% -i %%v -o %%v.log
for %%v in (Phase06*.sql) do %%v.log

REM **** Run all of Phase 07 t-sql scripts ****
for %%v in (Phase07*.sql) do sqlcmd -S %SERVER% -d %DATABASE% -i %%v -o %%v.log
for %%v in (Phase07*.sql) do %%v.log

REM **** Run all of Phase 08 t-sql scripts ****
for %%v in (Phase08*.sql) do sqlcmd -S %SERVER% -d %DATABASE% -i %%v -o %%v.log
for %%v in (Phase08*.sql) do %%v.log

REM **** Run all of Phase 09 t-sql scripts ****
for %%v in (Phase09*.sql) do sqlcmd -S %SERVER% -d %DATABASE% -i %%v -o %%v.log
for %%v in (Phase09*.sql) do %%v.log

REM **** Populate DBA parameters table ****
sqlcmd -S %SERVER% -d DBA -v var_environment=%ENVIRONMENT% var_shared=%SHARED% -i Phase99_Step98_PopulateTables_Parameters_table.sql -o Phase99_Step98_PopulateTables_Parameters_table.log
timeout /t 10 /nobreak > NUL
Notepad.exe Phase99_Step98_PopulateTables_Parameters_table.log

REM **** Create linked server in DBA Central ****
sqlcmd -S "DBA_Central.db.sth.health.qld.gov.au,21433" -d DBA -v var_server=%SERVER% var_password=%DBA_PASSWORD% -i Phase99_Step99_Create_linked_server_on_DBA_central_server.sql -o Phase99_Step99_Create_linked_server_on_DBA_central_server.log
timeout /t 10 /nobreak > NUL
Notepad.exe Phase99_Step99_Create_linked_server_on_DBA_central_server.log

REM ************** Del *.log
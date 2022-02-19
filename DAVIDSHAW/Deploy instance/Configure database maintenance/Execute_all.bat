@echo off
SET /p SERVER="Please provide <Server name\instance,port> (leave instance and port blank if defaults): "

REM ****************** None of the code below should need altering ***********************************

SET DATABASE=Master
REM **** Run all of Phase 01 t-sql scripts ****
for %%v in (Phase00*.sql) do sqlcmd -S %SERVER% -d %DATABASE% -i %%v -o %%v.log
for %%v in (Phase00*.sql) do %%v.log

SET DATABASE=DBA
REM **** Run all of Phase 01 t-sql scripts ****
for %%v in (Phase01*.sql) do sqlcmd -S %SERVER% -d %DATABASE% -i %%v -o %%v.log
for %%v in (Phase01*.sql) do %%v.log

REM **** Run all of Phase 02 t-sql scripts ****
for %%v in (Phase02*.sql) do sqlcmd -S %SERVER% -d %DATABASE% -i %%v -o %%v.log
for %%v in (Phase02*.sql) do %%v.log

mspaint.exe "%~dp0\Image01.jpg"

REM ************** Del *.log
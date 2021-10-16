@echo off
SET /p SERVER="Please provide <Server name\instance,port> (leave instance and port blank if defaults): "

REM ****************** None of the code below should need altering ***********************************

SET DATABASE=master
REM **** Run all of Phase 01 t-sql scripts ****
for %%v in (Phase01*.sql) do sqlcmd -S %SERVER% -d %DATABASE% -i %%v -o %%v.log
for %%v in (Phase01*.sql) do %%v.log

REM ************** Del *.log
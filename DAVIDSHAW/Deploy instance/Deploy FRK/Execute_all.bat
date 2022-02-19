@echo off
SET /p SERVER="Please provide <Server name\instance,port> (leave instance and port blank if defaults): "

REM ****************** None of the code below should need altering ***********************************

REM **** Run all of sp_Blitz (Brent Ozar) t-sql scripts ****
SET DATABASE=DBA
for %%v in (sp_Blitz*.sql) do sqlcmd -S %SERVER% -d %DATABASE% -i %%v -o %SERVER%_%%v.log
for %%v in (sp_Blitz*.sql) do %SERVER%_%%v.log

REM ************** Del *.log
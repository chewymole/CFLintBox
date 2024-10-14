@ECHO OFF
SETLOCAL

set fn=%~dp0results\%~n2.json
set jf=%~dp0CFLint-1.5.0-all.jar

java -jar %jf% -file %1 -q -e -json -jsonfile %fn%

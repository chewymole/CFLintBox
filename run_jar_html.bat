@ECHO OFF
SETLOCAL

set fn=%~dp0results\html\%~n2.html
set jf=%~dp0CFLint-1.5.0-all.jar

java -jar %jf% -file %1 -q -e -html -htmlfile %fn%
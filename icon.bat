set WORKSHOP_ID=2605363456

cd /d "%~dp0"
cd ..\..\..\bin\

gmpublish update -icon "%~dp0icon.jpg" -id "%WORKSHOP_ID%"

pause

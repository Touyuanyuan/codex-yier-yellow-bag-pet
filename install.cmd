@echo off
chcp 65001 >nul
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
set "PET_EXIT=%ERRORLEVEL%"
echo.
pause
exit /b %PET_EXIT%

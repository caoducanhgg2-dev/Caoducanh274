@echo off
setlocal EnableExtensions
chcp 65001 >nul

title Restore Comedy Host Studio before 5.5.4
set "APPDIR=%LOCALAPPDATA%\Programs\ComedyHostStudio"
set "ENGINE=%APPDIR%\engine.py"

echo ============================================================
echo   RESTORE ENGINE - BEFORE 5.5.4

echo ============================================================
echo.

if not exist "%APPDIR%" (
  echo [ERROR] Khong tim thay thu muc app:
  echo %APPDIR%
  pause
  exit /b 1
)

for /f "delims=" %%F in ('dir /b /a-d /o-d "%APPDIR%\engine.py.before_5.5.4_*" 2^>nul') do (
  set "BACKUP=%APPDIR%\%%F"
  goto :found
)

echo [ERROR] Khong tim thay engine.py.before_5.5.4_*
echo Khong co gi de restore.
pause
exit /b 2

:found
echo Backup se restore:
echo %BACKUP%
echo.
copy /y "%ENGINE%" "%ENGINE%.failed_5.5.4" >nul 2>&1
copy /y "%BACKUP%" "%ENGINE%" >nul
if errorlevel 1 (
  echo [FAILED] Khong restore duoc engine.py
  pause
  exit /b 3
)

echo [PASS] Da restore engine.py ve trang thai ngay truoc 5.5.4.
echo Dong cua so nay va mo lai Comedy Host Studio.
pause
exit /b 0

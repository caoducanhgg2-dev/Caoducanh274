@echo off
setlocal EnableExtensions
chcp 65001 >nul

title Comedy Host Studio 5.5.3f Final Repair

set "APPDIR=%LOCALAPPDATA%\Programs\ComedyHostStudio"
set "ENGINE=%APPDIR%\engine.py"
set "PATCHER=%~dp0patch_5_5_3f.ps1"

echo ============================================================
echo   COMEDY HOST STUDIO 5.5.3f - FINAL REPAIR HOTFIX
echo ============================================================
echo.

if not exist "%ENGINE%" (
  echo [ERROR] Khong tim thay: %ENGINE%
  echo Hay cai dung Comedy Host Studio Beta 5.1 truoc.
  pause
  exit /b 1
)

if not exist "%PATCHER%" (
  echo [ERROR] Thieu patch_5_5_3f.ps1 trong cung thu muc.
  pause
  exit /b 1
)

echo [1/2] Dang sao luu va cap nhat engine.py...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PATCHER%" -EnginePath "%ENGINE%"
if errorlevel 1 (
  echo.
  echo [FAILED] Khong the cai 5.5.3f.
  echo Engine goc van duoc giu trong file backup neu patch da bat dau.
  pause
  exit /b 1
)

echo [2/2] Hoan tat.
echo.
echo 5.5.3f da duoc cai de sua loi:
echo - 1 hard-repeat cuoi lam huy ca SRT
echo - AI tao cau moi nhung bi reject vi khong dung 10 tu
echo - Final fallback se dung cau factual-safe 10 tu, khong lap
echo.
echo Mo lai Comedy Host Studio va chay lai video.
pause
exit /b 0

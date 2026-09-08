@echo off
setlocal EnableExtensions
chcp 65001 >nul

title Comedy Host Studio 5.5.3h Helper Order Fix

set "APPDIR=%LOCALAPPDATA%\Programs\ComedyHostStudio"
set "ENGINE=%APPDIR%\engine.py"
set "PATCHF=%~dp0patch_5_5_3f.ps1"
set "PATCHH=%~dp0patch_5_5_3h_fix.ps1"

echo ============================================================
echo   COMEDY HOST STUDIO 5.5.3h - HELPER BEFORE MAIN DEF FIX
echo ============================================================
echo.

if not exist "%ENGINE%" (
  echo [ERROR] Khong tim thay: %ENGINE%
  echo Hay cai dung Comedy Host Studio Beta 5.1 truoc.
  pause
  exit /b 1
)

if not exist "%PATCHF%" (
  echo [ERROR] Thieu patch_5_5_3f.ps1
  pause
  exit /b 1
)
if not exist "%PATCHH%" (
  echo [ERROR] Thieu patch_5_5_3h_fix.ps1
  pause
  exit /b 1
)

echo [1/3] Dam bao Final Repair 5.5.3f da duoc cai...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PATCHF%" -EnginePath "%ENGINE%"
if errorlevel 1 (
  echo.
  echo [FAILED] Khong the ap dung nen Final Repair 5.5.3f.
  pause
  exit /b 1
)

echo [2/3] Dat helper Final Repair truoc def main()...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PATCHH%" -EnginePath "%ENGINE%"
if errorlevel 1 (
  echo.
  echo [FAILED] Khong the cai 5.5.3h.
  echo Engine backup da duoc khoi phuc neu patch bat dau.
  pause
  exit /b 1
)

echo [3/3] Hoan tat.
echo.
echo 5.5.3h da sua truc tiep:
echo - Loi 5.5.3g khong tim thay Python entry point
echo - Loi NameError cua _antirepeat_last_resort_553f
echo - Helper duoc dat TRUOC top-level def main()
echo - Khong thay doi GPU Recovery, StoryFlow, GoldStyle, Anti-Repeat, timing

echo.
echo Dong cua so nay, mo lai Comedy Host Studio va chay lai video.
pause
exit /b 0

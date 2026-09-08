@echo off
setlocal EnableExtensions
chcp 65001 >nul

title Comedy Host Studio 5.5.3g NameError Fix

set "APPDIR=%LOCALAPPDATA%\Programs\ComedyHostStudio"
set "ENGINE=%APPDIR%\engine.py"
set "PATCHF=%~dp0patch_5_5_3f.ps1"
set "PATCHG=%~dp0patch_5_5_3g_fix.ps1"

echo ============================================================
echo   COMEDY HOST STUDIO 5.5.3g - FINAL REPAIR NAMEERROR FIX
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
if not exist "%PATCHG%" (
  echo [ERROR] Thieu patch_5_5_3g_fix.ps1
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

echo [2/3] Sua loi helper khai bao sau main()...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PATCHG%" -EnginePath "%ENGINE%"
if errorlevel 1 (
  echo.
  echo [FAILED] Khong the cai 5.5.3g.
  echo Engine backup duoc tao truoc khi sua.
  pause
  exit /b 1
)

echo [3/3] Hoan tat.
echo.
echo 5.5.3g da sua truc tiep loi:
echo - name '_antirepeat_last_resort_553f' is not defined
echo - Final Repair helper duoc dat TRUOC Python main entry point
echo - Giu nguyen Anti-Repeat, GPU Recovery, GoldStyle va timing

echo.
echo Dong cua so nay, mo lai Comedy Host Studio va chay lai video.
pause
exit /b 0

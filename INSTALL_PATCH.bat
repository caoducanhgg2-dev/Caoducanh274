@echo off
setlocal EnableExtensions
chcp 65001 >nul

title Comedy Host Studio 5.5.4 Clean Stability

set "APPDIR=%LOCALAPPDATA%\Programs\ComedyHostStudio"
set "ENGINE=%APPDIR%\engine.py"
set "PATCHER=%~dp0patch_5_5_4_clean.ps1"

echo ============================================================
echo   COMEDY HOST STUDIO 5.5.4 - CLEAN STABILITY
echo ============================================================
echo.
echo Ban nay KHONG stack len 5.5.3f / g / h.
echo Installer se tim backup engine.py 5.5.3e sach, khoi phuc lam base,
echo sau do chi sua Final Gate de mot caption loi khong huy ca SRT.
echo.

if not exist "%ENGINE%" (
  echo [ERROR] Khong tim thay:
  echo %ENGINE%
  echo Hay cai dung Comedy Host Studio Beta 5.1 truoc.
  pause
  exit /b 1
)

if not exist "%PATCHER%" (
  echo [ERROR] Thieu patch_5_5_4_clean.ps1 trong cung thu muc.
  pause
  exit /b 1
)

echo [1/3] Tim va xac minh clean base 5.5.3e...
echo [2/3] Khoi phuc clean base va ap dung 5.5.4 Stability...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PATCHER%" -EnginePath "%ENGINE%"
if errorlevel 1 (
  echo.
  echo [FAILED] Khong the cai 5.5.4 Clean.
  echo Engine hien tai da duoc backup truoc khi patch.
  echo Neu thong bao noi khong co backup 5.5.3e, hay cai lai 5.5.3e AntiRepeatV3 mot lan,
  echo dong app, sau do chay lai file INSTALL_PATCH.bat nay.
  echo.
  pause
  exit /b 1
)

echo [3/3] HOAN TAT.
echo.
echo 5.5.4 Clean Stability da san sang.
echo - Khong dung helper _antirepeat_last_resort_553f
echo - Khong sua / di chuyen main()
echo - Khong stack patch f-g-h
echo - Khoi phuc tu source 5.5.3e sach truoc khi sua
echo - Giu GPU Recovery, StoryFlow, GoldStyle, 10 tu, 4.08s, gap 0.10s
echo - Residual repeat cuoi chi la QA warning, khong huy toan bo SRT
echo.
echo Dong cua so nay, mo Comedy Host Studio va chay lai video.
pause
exit /b 0

@echo off
:: ============================================================
::  QuickInstall.bat - Post-Install Software Setup
::  Edit URLs below to customize without rebuilding ISO
::  Run as Administrator!
:: ============================================================
title QuickInstall - Software Setup
color 0B
setlocal EnableExtensions EnableDelayedExpansion

echo.
echo  =============================================
echo   QuickInstall - Software Setup
echo  =============================================
echo.

:: ---- Admin check ----
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Run as Administrator!
    pause
    exit /b 1
)

:: ============================================================
:: EDIT THESE URLs TO CUSTOMIZE
:: Set to SKIP to skip a particular install
:: ============================================================

:: --- Browsers ---
set "CHROME_URL=https://dl.google.com/chrome/install/googlechromestandaloneenterprise64.msi"

:: --- Development ---
set "NODE_URL=https://nodejs.org/dist/v20.18.0/node-v20.18.0-x64.msi"
set "GIT_URL=https://github.com/git-for-windows/git/releases/download/v2.49.0.windows.1/Git-2.49.0-64-bit.exe"
set "VSCODE_URL=https://update.code.visualstudio.com/latest/win32-x64/stable"

:: --- Utilities ---
set "SEVENZIP_URL=https://www.7-zip.org/a/7z2408-x64.exe"
set "NOTEPADPP_URL=https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.7.6/npp.8.7.6.Installer.x64.exe"

:: --- Communication ---
set "TELEGRAM_URL=SKIP"

:: --- Virtualization ---
set "VMTOOLS_URL=https://packages.vmware.com/tools/releases/latest/windows/x64/VMware-tools-windows-x64.exe"

:: --- Runtime ---
set "VCREDIST_URL=https://aka.ms/vs/17/release/vc_redist.x64.exe"
set "DOTNET_URL=SKIP"

:: ============================================================
:: DO NOT EDIT BELOW (unless you know what you're doing)
:: ============================================================

set "DL_DIR=%SystemRoot%\Temp\QuickInstall"
if not exist "%DL_DIR%" mkdir "%DL_DIR%"

:: Function-like installer
:: Usage: call :install "Name" "URL" "type" "extra_args"
:: type: msi | exe | exe-silent

echo ---- Starting installations ----
echo.

:: --- Chrome ---
if /i not "%CHROME_URL%"=="SKIP" (
    echo [1] Installing Google Chrome...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "Invoke-WebRequest -Uri '%CHROME_URL%' -OutFile '%DL_DIR%\chrome.msi'"
    msiexec /i "%DL_DIR%\chrome.msi" /qn /norestart
    del /f /q "%DL_DIR%\chrome.msi" >nul 2>&1
    echo     Done.
) else echo [1] Chrome: SKIPPED
echo.

:: --- Node.js ---
if /i not "%NODE_URL%"=="SKIP" (
    echo [2] Installing Node.js...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "Invoke-WebRequest -Uri '%NODE_URL%' -OutFile '%DL_DIR%\nodejs.msi'"
    msiexec /i "%DL_DIR%\nodejs.msi" /qn /norestart
    del /f /q "%DL_DIR%\nodejs.msi" >nul 2>&1
    echo     Done.
) else echo [2] Node.js: SKIPPED
echo.

:: --- Git ---
if /i not "%GIT_URL%"=="SKIP" (
    echo [3] Installing Git...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "Invoke-WebRequest -Uri '%GIT_URL%' -OutFile '%DL_DIR%\git.exe'"
    start /wait "" "%DL_DIR%\git.exe" /VERYSILENT /NORESTART /SP-
    del /f /q "%DL_DIR%\git.exe" >nul 2>&1
    echo     Done.
) else echo [3] Git: SKIPPED
echo.

:: --- VS Code ---
if /i not "%VSCODE_URL%"=="SKIP" (
    echo [4] Installing Visual Studio Code...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "Invoke-WebRequest -Uri '%VSCODE_URL%' -OutFile '%DL_DIR%\vscode.exe'"
    start /wait "" "%DL_DIR%\vscode.exe" /VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,addtopath
    del /f /q "%DL_DIR%\vscode.exe" >nul 2>&1
    echo     Done.
) else echo [4] VS Code: SKIPPED
echo.

:: --- 7-Zip ---
if /i not "%SEVENZIP_URL%"=="SKIP" (
    echo [5] Installing 7-Zip...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "Invoke-WebRequest -Uri '%SEVENZIP_URL%' -OutFile '%DL_DIR%\7zip.exe'"
    start /wait "" "%DL_DIR%\7zip.exe" /S
    del /f /q "%DL_DIR%\7zip.exe" >nul 2>&1
    echo     Done.
) else echo [5] 7-Zip: SKIPPED
echo.

:: --- Notepad++ ---
if /i not "%NOTEPADPP_URL%"=="SKIP" (
    echo [6] Installing Notepad++...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "Invoke-WebRequest -Uri '%NOTEPADPP_URL%' -OutFile '%DL_DIR%\npp.exe'"
    start /wait "" "%DL_DIR%\npp.exe" /S
    del /f /q "%DL_DIR%\npp.exe" >nul 2>&1
    echo     Done.
) else echo [6] Notepad++: SKIPPED
echo.

:: --- Telegram ---
if /i not "%TELEGRAM_URL%"=="SKIP" (
    echo [7] Installing Telegram...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "Invoke-WebRequest -Uri '%TELEGRAM_URL%' -OutFile '%DL_DIR%\telegram.exe'"
    start /wait "" "%DL_DIR%\telegram.exe" /VERYSILENT /NORESTART
    del /f /q "%DL_DIR%\telegram.exe" >nul 2>&1
    echo     Done.
) else echo [7] Telegram: SKIPPED
echo.

:: --- VC++ Redistributable ---
if /i not "%VCREDIST_URL%"=="SKIP" (
    echo [8] Installing VC++ Redistributable...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "Invoke-WebRequest -Uri '%VCREDIST_URL%' -OutFile '%DL_DIR%\vcredist.exe'"
    start /wait "" "%DL_DIR%\vcredist.exe" /install /quiet /norestart
    del /f /q "%DL_DIR%\vcredist.exe" >nul 2>&1
    echo     Done.
) else echo [8] VC++ Redist: SKIPPED
echo.

:: --- .NET Runtime ---
if /i not "%DOTNET_URL%"=="SKIP" (
    echo [9] Installing .NET Runtime...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "Invoke-WebRequest -Uri '%DOTNET_URL%' -OutFile '%DL_DIR%\dotnet.exe'"
    start /wait "" "%DL_DIR%\dotnet.exe" /install /quiet /norestart
    del /f /q "%DL_DIR%\dotnet.exe" >nul 2>&1
    echo     Done.
) else echo [9] .NET Runtime: SKIPPED
echo.

:: --- VMware Tools ---
if /i not "%VMTOOLS_URL%"=="SKIP" (
    echo [10] Installing VMware Tools...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "Invoke-WebRequest -Uri '%VMTOOLS_URL%' -OutFile '%DL_DIR%\vmtools.exe'"
    start /wait "" "%DL_DIR%\vmtools.exe" /S /v"/qn REBOOT=R"
    del /f /q "%DL_DIR%\vmtools.exe" >nul 2>&1
    echo     Done.
) else echo [10] VMware Tools: SKIPPED
echo.

:: --- Cleanup ---
rmdir /s /q "%DL_DIR%" >nul 2>&1

echo.
echo  =============================================
echo   All installations complete!
echo  =============================================
echo.
echo   To customize: edit the URLs at the top
echo   Set any URL to SKIP to skip that install
echo.
pause
endlocal

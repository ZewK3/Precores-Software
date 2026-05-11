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

:: --- Vietnamese Input ---
set "UNIKEY_URL=https://www.unikey.org/assets/release/unikey46RC2-230919-win64.zip"

:: --- Remote Desktop ---
set "RUSTDESK_URL=https://github.com/rustdesk/rustdesk/releases/download/1.4.6/rustdesk-1.4.6-x86_64.exe"

:: --- Virtualization (auto-detect) ---
set "VIRTIO_URL=https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win-guest-tools.exe"
set "VMTOOLS_URL=https://packages.vmware.com/tools/releases/latest/windows/x64/VMware-tools-13.0.10-25056151-x64.exe"

:: --- Runtime ---
set "VCREDIST_URL=https://aka.ms/vs/17/release/vc_redist.x64.exe"
set "DOTNET_URL=SKIP"

:: ============================================================
:: DO NOT EDIT BELOW (unless you know what you're doing)
:: ============================================================

set "DL_DIR=%SystemRoot%\Temp\QuickInstall"
if not exist "%DL_DIR%" mkdir "%DL_DIR%"

:: Common PowerShell download command (silent, no progress bar, fast)
set "PS_DL=powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue';"

echo ---- Starting installations ----
echo.

:: --- Chrome ---
if /i not "%CHROME_URL%"=="SKIP" (
    echo [1/10] Installing Google Chrome...
    %PS_DL% Invoke-WebRequest -Uri '%CHROME_URL%' -OutFile '%DL_DIR%\chrome.msi' -UseBasicParsing"
    msiexec /i "%DL_DIR%\chrome.msi" /qn /norestart
    del /f /q "%DL_DIR%\chrome.msi" >nul 2>&1
    echo        Done.
) else echo [1/10] Chrome: SKIPPED

:: --- Node.js ---
if /i not "%NODE_URL%"=="SKIP" (
    echo [2/10] Installing Node.js...
    %PS_DL% Invoke-WebRequest -Uri '%NODE_URL%' -OutFile '%DL_DIR%\nodejs.msi' -UseBasicParsing"
    msiexec /i "%DL_DIR%\nodejs.msi" /qn /norestart
    del /f /q "%DL_DIR%\nodejs.msi" >nul 2>&1
    echo        Done.
) else echo [2/10] Node.js: SKIPPED

:: --- Git ---
if /i not "%GIT_URL%"=="SKIP" (
    echo [3/10] Installing Git...
    %PS_DL% Invoke-WebRequest -Uri '%GIT_URL%' -OutFile '%DL_DIR%\git.exe' -UseBasicParsing"
    start /wait "" "%DL_DIR%\git.exe" /VERYSILENT /NORESTART /SP-
    del /f /q "%DL_DIR%\git.exe" >nul 2>&1
    echo        Done.
) else echo [3/10] Git: SKIPPED

:: --- VS Code ---
if /i not "%VSCODE_URL%"=="SKIP" (
    echo [4/10] Installing Visual Studio Code...
    %PS_DL% Invoke-WebRequest -Uri '%VSCODE_URL%' -OutFile '%DL_DIR%\vscode.exe' -UseBasicParsing"
    start /wait "" "%DL_DIR%\vscode.exe" /VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,addtopath
    del /f /q "%DL_DIR%\vscode.exe" >nul 2>&1
    echo        Done.
) else echo [4/10] VS Code: SKIPPED

:: --- 7-Zip ---
if /i not "%SEVENZIP_URL%"=="SKIP" (
    echo [5/10] Installing 7-Zip...
    %PS_DL% Invoke-WebRequest -Uri '%SEVENZIP_URL%' -OutFile '%DL_DIR%\7zip.exe' -UseBasicParsing"
    start /wait "" "%DL_DIR%\7zip.exe" /S
    del /f /q "%DL_DIR%\7zip.exe" >nul 2>&1
    echo        Done.
) else echo [5/10] 7-Zip: SKIPPED

:: --- Notepad++ ---
if /i not "%NOTEPADPP_URL%"=="SKIP" (
    echo [6/10] Installing Notepad++...
    %PS_DL% Invoke-WebRequest -Uri '%NOTEPADPP_URL%' -OutFile '%DL_DIR%\npp.exe' -UseBasicParsing"
    start /wait "" "%DL_DIR%\npp.exe" /S
    del /f /q "%DL_DIR%\npp.exe" >nul 2>&1
    echo        Done.
) else echo [6/10] Notepad++: SKIPPED

:: --- Telegram ---
if /i not "%TELEGRAM_URL%"=="SKIP" (
    echo [7/10] Installing Telegram...
    %PS_DL% Invoke-WebRequest -Uri '%TELEGRAM_URL%' -OutFile '%DL_DIR%\telegram.exe' -UseBasicParsing"
    start /wait "" "%DL_DIR%\telegram.exe" /VERYSILENT /NORESTART
    del /f /q "%DL_DIR%\telegram.exe" >nul 2>&1
    echo        Done.
) else echo [7/10] Telegram: SKIPPED

:: --- VC++ Redistributable ---
if /i not "%VCREDIST_URL%"=="SKIP" (
    echo [8/10] Installing VC++ Redistributable...
    %PS_DL% Invoke-WebRequest -Uri '%VCREDIST_URL%' -OutFile '%DL_DIR%\vcredist.exe' -UseBasicParsing"
    start /wait "" "%DL_DIR%\vcredist.exe" /install /quiet /norestart
    del /f /q "%DL_DIR%\vcredist.exe" >nul 2>&1
    echo        Done.
) else echo [8/10] VC++ Redist: SKIPPED

:: --- .NET Runtime ---
if /i not "%DOTNET_URL%"=="SKIP" (
    echo [9/10] Installing .NET Runtime...
    %PS_DL% Invoke-WebRequest -Uri '%DOTNET_URL%' -OutFile '%DL_DIR%\dotnet.exe' -UseBasicParsing"
    start /wait "" "%DL_DIR%\dotnet.exe" /install /quiet /norestart
    del /f /q "%DL_DIR%\dotnet.exe" >nul 2>&1
    echo        Done.
) else echo [9/10] .NET Runtime: SKIPPED

:: --- Virtualization Tools (auto-detect Proxmox/QEMU vs VMware) ---
set "IS_QEMU=0"
set "IS_VMWARE=0"
for /f "tokens=*" %%M in ('wmic computersystem get manufacturer /value 2^>nul ^| findstr /i "QEMU"') do set "IS_QEMU=1"
for /f "tokens=*" %%M in ('wmic computersystem get manufacturer /value 2^>nul ^| findstr /i "VMware"') do set "IS_VMWARE=1"

if "%IS_QEMU%"=="1" (
    echo [10/11] Installing VirtIO Guest Tools (Proxmox/QEMU detected)...
    %PS_DL% Invoke-WebRequest -Uri '%VIRTIO_URL%' -OutFile '%DL_DIR%\virtio-win-guest-tools.exe' -UseBasicParsing"
    start /wait "" "%DL_DIR%\virtio-win-guest-tools.exe" /install /quiet /norestart
    del /f /q "%DL_DIR%\virtio-win-guest-tools.exe" >nul 2>&1
    echo        Done.
) else if "%IS_VMWARE%"=="1" (
    echo [10/11] Installing VMware Tools (VMware detected)...
    %PS_DL% Invoke-WebRequest -Uri '%VMTOOLS_URL%' -OutFile '%DL_DIR%\vmtools.exe' -UseBasicParsing"
    start /wait "" "%DL_DIR%\vmtools.exe" /S /v"/qn REBOOT=R"
    del /f /q "%DL_DIR%\vmtools.exe" >nul 2>&1
    echo        Done.
) else echo [10/11] VM Tools: SKIPPED (physical machine)

:: --- RustDesk ---
if /i not "%RUSTDESK_URL%"=="SKIP" (
    echo [11/12] Installing RustDesk (Remote Desktop)...
    %PS_DL% Invoke-WebRequest -Uri '%RUSTDESK_URL%' -OutFile '%DL_DIR%\rustdesk.exe' -UseBasicParsing"
    start /wait "" "%DL_DIR%\rustdesk.exe" --silent-install
    del /f /q "%DL_DIR%\rustdesk.exe" >nul 2>&1
    echo        Done.
) else echo [11/12] RustDesk: SKIPPED

:: --- UniKey (Vietnamese input method) ---
if /i not "%UNIKEY_URL%"=="SKIP" (
    echo [12/12] Installing UniKey...
    set "UNIKEY_DIR=%ProgramFiles%\UniKey"
    %PS_DL% Invoke-WebRequest -Uri '%UNIKEY_URL%' -OutFile '%DL_DIR%\unikey.zip' -UseBasicParsing"
    if exist "%DL_DIR%\unikey.zip" (
        if not exist "%ProgramFiles%\UniKey" mkdir "%ProgramFiles%\UniKey" >nul 2>&1
        powershell -NoProfile -Command "Expand-Archive -Path '%DL_DIR%\unikey.zip' -DestinationPath '%ProgramFiles%\UniKey' -Force"
        del /f /q "%DL_DIR%\unikey.zip" >nul 2>&1

        :: Locate UniKeyNT.exe (zip may contain a subfolder)
        set "UNIKEY_EXE="
        for /r "%ProgramFiles%\UniKey" %%F in (UniKeyNT.exe) do if not defined UNIKEY_EXE set "UNIKEY_EXE=%%F"

        if defined UNIKEY_EXE (
            :: Desktop shortcut (all users)
            powershell -NoProfile -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut('%PUBLIC%\Desktop\UniKey.lnk');$s.TargetPath='!UNIKEY_EXE!';$s.WorkingDirectory=(Split-Path '!UNIKEY_EXE!');$s.Save()"
            :: Auto-run on every user login (all-users Startup)
            powershell -NoProfile -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut([Environment]::GetFolderPath('CommonStartup')+'\UniKey.lnk');$s.TargetPath='!UNIKEY_EXE!';$s.WorkingDirectory=(Split-Path '!UNIKEY_EXE!');$s.Save()"
            :: Launch immediately
            start "" "!UNIKEY_EXE!"
            echo        Done. UniKey installed to "%ProgramFiles%\UniKey".
        ) else (
            echo        WARNING: UniKeyNT.exe not found after extract.
        )
    ) else echo        ERROR: Download failed.
) else echo [12/12] UniKey: SKIPPED

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

:: Self-delete
del /f /q "C:\QuickInstall.bat" >nul 2>&1

endlocal

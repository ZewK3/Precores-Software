@echo off
:: ============================================================
::  BUILD ISO - LIGHTWEIGHT
::  Windows 10 Tiny ISO Builder (Post-Boot Optimization)
::  No offline WIM modification - scripts run after boot
::  Run as Administrator!
:: ============================================================
title BUILD ISO - Lightweight
color 0A
setlocal EnableExtensions EnableDelayedExpansion

:: Auto-detect base directory from script location
set "SCRIPTS_DIR=%~dp0"
if "%SCRIPTS_DIR:~-1%"=="\" set "SCRIPTS_DIR=%SCRIPTS_DIR:~0,-1%"
for %%I in ("%SCRIPTS_DIR%\..") do set "BASE_DIR=%%~fI"
set "ISO_SRC=%BASE_DIR%\tiny10 x64 23h.iso"
set "ISO_FILES=%BASE_DIR%\ISO_FILES"
set "OUTPUT_ISO=%BASE_DIR%\tiny10_optimized_ldplayer.iso"
set "OSCDIMG=C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"

echo.
echo  =============================================
echo   WINDOWS 10 TINY - LIGHTWEIGHT ISO BUILDER
echo  =============================================
echo   User: PCL / Pass: PCL@1231233 / AutoLogin
echo  =============================================
echo   Optimization runs AFTER boot:
echo   - QuickOptimize.bat (system tweaks)
echo   - QuickInstall.bat  (software install)
echo  =============================================
echo.

:: ---- Admin check ----
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Script requires Administrator privileges!
    echo         Right-click and select "Run as administrator"
    pause
    exit /b 1
)

:: ---- Check oscdimg ----
if not exist "%OSCDIMG%" (
    echo [ERROR] oscdimg.exe not found!
    echo         Install Windows ADK - Deployment Tools only
    echo         https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install
    pause
    exit /b 1
)

:: ---- Check source ISO ----
if not exist "%ISO_SRC%" (
    echo [ERROR] Source ISO not found: %ISO_SRC%
    pause
    exit /b 1
)

echo Press any key to start building, or Ctrl+C to cancel...
pause >nul

:: ============================================================
:: PHASE 1/3: EXTRACT ISO
:: ============================================================
echo.
echo ============================================================
echo  PHASE 1/3: Extract ISO
echo ============================================================

:: Clean previous
if exist "%ISO_FILES%" (
    echo [CLEAN] Removing previous ISO_FILES...
    rmdir /s /q "%ISO_FILES%" 2>nul
)

mkdir "%ISO_FILES%" 2>nul

echo [*] Dismounting any previous ISO mounts...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Dismount-DiskImage -ImagePath '%ISO_SRC%' -ErrorAction SilentlyContinue" >nul 2>&1
timeout /t 2 /nobreak >nul

echo [*] Mounting ISO...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Mount-DiskImage -ImagePath '%ISO_SRC%'"
timeout /t 3 /nobreak >nul

:: Find the mounted ISO drive letter
set "ISO_DRIVE="
for %%D in (D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%D:\sources\boot.wim" if not defined ISO_DRIVE (
        set "ISO_DRIVE=%%D"
    )
)

if not defined ISO_DRIVE (
    echo [ERROR] Could not find mounted ISO on any drive!
    pause
    exit /b 1
)

echo   ISO mounted at !ISO_DRIVE!:
echo [*] Copying ISO contents to ISO_FILES...
echo     This may take several minutes...
xcopy "!ISO_DRIVE!:\*" "%ISO_FILES%\" /E /H /R /Y /Q

if !errorlevel! neq 0 (
    echo [ERROR] Failed to copy ISO contents!
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Dismount-DiskImage -ImagePath '%ISO_SRC%'" >nul 2>&1
    pause
    exit /b 1
)

echo [*] Dismounting ISO...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Dismount-DiskImage -ImagePath '%ISO_SRC%'" >nul 2>&1
echo [OK] Phase 1 complete.

:: ============================================================
:: PHASE 2/3: ADD AUTOUNATTEND.XML
:: ============================================================
echo.
echo ============================================================
echo  PHASE 2/3: Add autounattend.xml + scripts
echo ============================================================

echo [*] Copying autounattend.xml...
copy /y "%SCRIPTS_DIR%\autounattend.xml" "%ISO_FILES%\autounattend.xml" >nul
if !errorlevel! neq 0 (
    echo [ERROR] Failed to copy autounattend.xml!
    pause
    exit /b 1
)

echo [*] Copying scripts to $OEM$ folder for offline installation...
mkdir "%ISO_FILES%\sources\$OEM$\$1\InstallScripts" 2>nul
copy /y "%SCRIPTS_DIR%\RunAll.bat" "%ISO_FILES%\sources\$OEM$\$1\InstallScripts\RunAll.bat" >nul
copy /y "%SCRIPTS_DIR%\QuickOptimize.bat" "%ISO_FILES%\sources\$OEM$\$1\InstallScripts\QuickOptimize.bat" >nul
copy /y "%SCRIPTS_DIR%\QuickInstall.bat" "%ISO_FILES%\sources\$OEM$\$1\InstallScripts\QuickInstall.bat" >nul
if exist "%SCRIPTS_DIR%\gdrive_folder_dl.ps1" (
    copy /y "%SCRIPTS_DIR%\gdrive_folder_dl.ps1" "%ISO_FILES%\sources\$OEM$\$1\InstallScripts\gdrive_folder_dl.ps1" >nul
    echo [*] Google Drive folder download script included.
)
if exist "%SCRIPTS_DIR%\logo-nen.png" (
    copy /y "%SCRIPTS_DIR%\logo-nen.png" "%ISO_FILES%\sources\$OEM$\$1\InstallScripts\logo-nen.png" >nul
    echo [*] Wallpaper logo-nen.png included.
)
if exist "%SCRIPTS_DIR%\avt.png" (
    copy /y "%SCRIPTS_DIR%\avt.png" "%ISO_FILES%\sources\$OEM$\$1\InstallScripts\avt.png" >nul
    echo [*] User avatar avt.png included.
)
if exist "%SCRIPTS_DIR%\nen.png" (
    copy /y "%SCRIPTS_DIR%\nen.png" "%ISO_FILES%\sources\$OEM$\$1\InstallScripts\nen.png" >nul
    echo [*] Chrome background nen.png included.
)
if exist "%SCRIPTS_DIR%\precore-pc.bat" (
    copy /y "%SCRIPTS_DIR%\precore-pc.bat" "%ISO_FILES%\sources\$OEM$\$1\InstallScripts\precore-pc.bat" >nul
    echo [*] PreCore PC maintenance tool included.
)

:: --- Create SetupComplete.cmd fallback ---
:: This runs AFTER Windows Setup finishes, BEFORE any user logon
:: Write to temp first, then copy (avoids $$ path issues with redirect)
echo [*] Creating SetupComplete.cmd fallback...
set "SC_TEMP=%TEMP%\SetupComplete.cmd"
> "%SC_TEMP%" echo @echo off
>> "%SC_TEMP%" echo :: SetupComplete.cmd - Fallback: register RunOnce for post-install
>> "%SC_TEMP%" echo if not exist "C:\InstallScripts\RunAll.bat" exit /b 0
>> "%SC_TEMP%" echo if exist "C:\InstallScripts\.completed" exit /b 0
>> "%SC_TEMP%" echo reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v PostInstall /t REG_SZ /d "cmd /c \"C:\InstallScripts\RunAll.bat\"" /f

set "SC_DST=%ISO_FILES%\sources\$OEM$"
mkdir "%SC_DST%\$$\Setup\Scripts" 2>nul
copy /y "%SC_TEMP%" "%SC_DST%\$$\Setup\Scripts\SetupComplete.cmd" >nul 2>&1
del /f /q "%SC_TEMP%" >nul 2>&1

if exist "%SC_DST%\$$\Setup\Scripts\SetupComplete.cmd" (
    echo [*] SetupComplete.cmd fallback created.
) else (
    echo [WARN] SetupComplete.cmd could not be created - trying alternate method...
    :: Alternate: create via PowerShell to avoid all batch escaping
    powershell -NoProfile -Command "$d='%ISO_FILES%\sources\$OEM$\$$\Setup\Scripts';New-Item -ItemType Directory -Path $d -Force|Out-Null;'@echo off','if not exist \"C:\InstallScripts\RunAll.bat\" exit /b 0','if exist \"C:\InstallScripts\.completed\" exit /b 0','start \"PostInstall\" /wait cmd /c \"C:\InstallScripts\RunAll.bat\"'|Set-Content (Join-Path $d 'SetupComplete.cmd') -Encoding ASCII"
    if exist "%SC_DST%\$$\Setup\Scripts\SetupComplete.cmd" (
        echo [*] SetupComplete.cmd created via PowerShell fallback.
    ) else (
        echo [WARN] SetupComplete.cmd creation failed - FirstLogonCommands will be used instead.
    )
)

:: --- Verify critical files exist ---
echo [*] Verifying file copy...
set "VERIFY_OK=1"
for %%F in (RunAll.bat QuickOptimize.bat QuickInstall.bat gdrive_folder_dl.ps1) do (
    if not exist "%ISO_FILES%\sources\$OEM$\$1\InstallScripts\%%F" (
        echo [ERROR] MISSING: %%F - copy failed!
        set "VERIFY_OK=0"
    )
)
if "!VERIFY_OK!"=="0" (
    echo [ERROR] Critical files missing! ISO build aborted.
    pause
    exit /b 1
)
echo [OK] All critical files verified.

echo [OK] Phase 2 complete.

:: ============================================================
:: PHASE 3/3: BUILD ISO
:: ============================================================
echo.
echo ============================================================
echo  PHASE 3/3: Build ISO
echo ============================================================

:: Remove read-only, hidden, and system attributes
attrib -r -h -s "%ISO_FILES%\*" /s /d >nul 2>&1

set "BIOS_BOOT=%ISO_FILES%\boot\etfsboot.com"
set "UEFI_BOOT=%ISO_FILES%\efi\microsoft\boot\efisys_noprompt.bin"

if not exist "%UEFI_BOOT%" set "UEFI_BOOT=%ISO_FILES%\efi\microsoft\boot\efisys.bin"

if not exist "!BIOS_BOOT!" (
    echo [ERROR] BIOS boot file not found: !BIOS_BOOT!
    pause
    exit /b 1
)

if not exist "!UEFI_BOOT!" goto :bios_only

echo [*] Building dual-boot ISO (BIOS + UEFI)...
"!OSCDIMG!" -m -h -u2 -udfver102 -bootdata:2#p0,e,b"!BIOS_BOOT!"#pEF,e,b"!UEFI_BOOT!" "!ISO_FILES!" "!OUTPUT_ISO!"
goto :check_iso

:bios_only
echo [*] Building BIOS-only ISO...
"!OSCDIMG!" -m -h -u2 -udfver102 -b"!BIOS_BOOT!" "!ISO_FILES!" "!OUTPUT_ISO!"

:check_iso
if !errorlevel! neq 0 (
    echo [ERROR] ISO creation failed!
    pause
    exit /b 1
)

:: --- Summary ---
echo.
echo  =============================================
echo   BUILD COMPLETE!
echo  =============================================
for %%F in ("%OUTPUT_ISO%") do echo   ISO: %%~nxF (%%~zF bytes)
echo.
echo   User:       PCL
echo   Password:   PCL@1231233
echo   AutoLogin:  YES
echo   OOBE:       Skipped
echo   Boot:       BIOS + UEFI
echo.
echo   After first login, scripts run automatically:
echo   1. QuickOptimize.bat - system optimization
echo   2. QuickInstall.bat  - software installation
echo  =============================================
echo.
pause
endlocal

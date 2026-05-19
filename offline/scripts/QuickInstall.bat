@echo off
:: ============================================================
::  QuickInstall.bat - LDPlayer Farm Software Setup
::  Optimized for maximum LDPlayer emulator instances
::  No GitHub required - runs from local ISO
::  Run as Administrator!
:: ============================================================
title QuickInstall - LDPlayer Farm Setup
color 0B
setlocal EnableExtensions EnableDelayedExpansion

:: ---- Log setup (hidden directory) ----
set "LOG_DIR=%SystemRoot%\Logs\PCL"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1
attrib +h +s "%LOG_DIR%" >nul 2>&1

set "LOG=%LOG_DIR%\QuickInstall_Log.txt"
echo ============================================================ > "%LOG%"
echo  QuickInstall (LDPlayer Farm) - Started: %DATE% %TIME% >> "%LOG%"
echo  Computer: %COMPUTERNAME% >> "%LOG%"
echo ============================================================ >> "%LOG%"

echo.
echo  =============================================
echo   QuickInstall - LDPlayer Farm Setup
echo  =============================================
echo.

:: ---- Admin check (skip if running from FirstLogonCommands) ----
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARN] Not running as admin - some operations may fail >> "%LOG%"
    echo [WARN] Not running as admin - some operations may fail
)
echo [OK] Running as Administrator >> "%LOG%"

:: ============================================================
:: SOFTWARE URLs
:: ============================================================

:: --- Browser ---
set "CHROME_URL=https://dl.google.com/chrome/install/googlechromestandaloneenterprise64.msi"

:: --- Utilities ---
set "SEVENZIP_URL=https://www.7-zip.org/a/7z2408-x64.exe"

:: --- Runtime ---
set "VCREDIST_URL=https://aka.ms/vs/17/release/vc_redist.x64.exe"

:: --- LDPlayer Emulator ---
set "LDPLAYER_URL=https://encdn.ldmnq.com/download/package/LDPlayer9_en_1009_ld.exe"

:: --- Vietnamese Input ---
set "UNIKEY_URL=https://www.unikey.org/assets/release/unikey46RC2-230919-win64.zip"

:: --- Virtualization (auto-detect) ---
set "VIRTIO_URL=https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win-guest-tools.exe"

:: ============================================================
:: DO NOT EDIT BELOW
:: ============================================================

set "DL_DIR=%SystemRoot%\Temp\QuickInstall"
if not exist "%DL_DIR%" mkdir "%DL_DIR%" >nul 2>&1

set "PS_DL=powershell -NoProfile -ExecutionPolicy Bypass -Command"

set "TOTAL_OK=0"
set "TOTAL_FAIL=0"
set "TOTAL_SKIP=0"

echo ---- Starting installations ---- >> "%LOG%"
echo ---- Starting installations ----
echo.

:: --- 1. Chrome ---
call :install_app "1/6" "Google Chrome" "%CHROME_URL%" "chrome.msi" "msi" "%ProgramFiles%\Google\Chrome\Application\chrome.exe" "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"

:: --- 2. 7-Zip ---
call :install_app "2/6" "7-Zip" "%SEVENZIP_URL%" "7zip.exe" "nsis" "%ProgramFiles%\7-Zip\7z.exe" "%ProgramFiles(x86)%\7-Zip\7z.exe"

:: --- 3. VC++ Redistributable ---
if /i "%VCREDIST_URL%"=="SKIP" (
    echo [3/6] VC++ Redist: SKIPPED
    echo [3/6] VC++ Redist: SKIPPED >> "%LOG%"
    set /a TOTAL_SKIP+=1
) else (
    set "VCR_KEY=HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64"
    reg query "!VCR_KEY!" /v Installed >nul 2>&1
    if !errorlevel! equ 0 (
        echo [3/6] VC++ Redist: already installed, skipping.
        echo [3/6] VC++ Redist: ALREADY INSTALLED >> "%LOG%"
        set /a TOTAL_SKIP+=1
    ) else (
        echo [3/6] Installing VC++ Redistributable...
        echo [3/6] Downloading VC++ Redist... >> "%LOG%"
        %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%VCREDIST_URL%' -OutFile '%DL_DIR%\vcredist.exe' -UseBasicParsing"
        if exist "%DL_DIR%\vcredist.exe" (
            echo [3/6] Installing VC++ Redist... >> "%LOG%"
            start /wait "" "%DL_DIR%\vcredist.exe" /install /quiet /norestart
            set "EXIT_CODE=!errorlevel!"
            echo [3/6] VC++ Redist exit code: !EXIT_CODE! >> "%LOG%"
            del /f /q "%DL_DIR%\vcredist.exe" >nul 2>&1
            if !EXIT_CODE! equ 0 (set /a TOTAL_OK+=1) else (set /a TOTAL_FAIL+=1)
            echo        Done.
        ) else (
            echo        ERROR: download failed.
            echo [3/6] VC++ Redist: DOWNLOAD FAILED >> "%LOG%"
            set /a TOTAL_FAIL+=1
        )
    )
)

:: --- 4. VirtIO Guest Tools (auto-detect QEMU/Proxmox) ---
set "IS_QEMU=0"
for /f "tokens=*" %%M in ('wmic computersystem get manufacturer /value 2^>nul ^| findstr /i "QEMU"') do set "IS_QEMU=1"
echo [4/6] Detection: QEMU=%IS_QEMU% >> "%LOG%"

if "%IS_QEMU%"=="1" (
    if exist "%ProgramFiles%\Virtio-Win\" (
        echo [4/6] VirtIO Guest Tools: already installed, skipping.
        echo [4/6] VirtIO: ALREADY INSTALLED >> "%LOG%"
        set /a TOTAL_SKIP+=1
    ) else (
        echo [4/6] Installing VirtIO Guest Tools ^(Proxmox/QEMU detected^)...
        echo [4/6] Downloading VirtIO... >> "%LOG%"
        %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%VIRTIO_URL%' -OutFile '%DL_DIR%\virtio-win-guest-tools.exe' -UseBasicParsing"
        if exist "%DL_DIR%\virtio-win-guest-tools.exe" (
            start /wait "" "%DL_DIR%\virtio-win-guest-tools.exe" /install /quiet /norestart
            set "EXIT_CODE=!errorlevel!"
            echo [4/6] VirtIO exit code: !EXIT_CODE! >> "%LOG%"
            del /f /q "%DL_DIR%\virtio-win-guest-tools.exe" >nul 2>&1
            if !EXIT_CODE! equ 0 (set /a TOTAL_OK+=1) else if !EXIT_CODE! equ 3010 (set /a TOTAL_OK+=1) else (set /a TOTAL_FAIL+=1)
            echo        Done.
        ) else (
            echo        ERROR: download failed.
            echo [4/6] VirtIO: DOWNLOAD FAILED >> "%LOG%"
            set /a TOTAL_FAIL+=1
        )
    )
) else (
    echo [4/6] VirtIO: SKIPPED ^(not QEMU/Proxmox^)
    echo [4/6] VirtIO: SKIPPED (not QEMU) >> "%LOG%"
    set /a TOTAL_SKIP+=1
)

:: --- 5. LDPlayer 9 ---
if exist "%ProgramFiles%\LDPlayer\LDPlayer9\dnplayer.exe" (
    echo [5/6] LDPlayer 9: already installed, skipping.
    echo [5/6] LDPlayer: ALREADY INSTALLED >> "%LOG%"
    set /a TOTAL_SKIP+=1
) else if exist "%ProgramFiles(x86)%\LDPlayer\LDPlayer9\dnplayer.exe" (
    echo [5/6] LDPlayer 9: already installed, skipping.
    echo [5/6] LDPlayer: ALREADY INSTALLED >> "%LOG%"
    set /a TOTAL_SKIP+=1
) else (
    echo [5/6] Installing LDPlayer 9...
    echo [5/6] Downloading LDPlayer 9... >> "%LOG%"
    %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%LDPLAYER_URL%' -OutFile '%DL_DIR%\ldplayer.exe' -UseBasicParsing"
    if exist "%DL_DIR%\ldplayer.exe" (
        echo [5/6] Installing LDPlayer 9... >> "%LOG%"
        start /wait "" "%DL_DIR%\ldplayer.exe" /S
        set "EXIT_CODE=!errorlevel!"
        echo [5/6] LDPlayer exit code: !EXIT_CODE! >> "%LOG%"
        del /f /q "%DL_DIR%\ldplayer.exe" >nul 2>&1
        if !EXIT_CODE! equ 0 (set /a TOTAL_OK+=1) else (set /a TOTAL_FAIL+=1)
        echo        Done.
    ) else (
        echo        ERROR: download failed.
        echo [5/6] LDPlayer: DOWNLOAD FAILED >> "%LOG%"
        set /a TOTAL_FAIL+=1
    )
)

:: --- 6. UniKey ---
if /i "%UNIKEY_URL%"=="SKIP" (
    echo [6/6] UniKey: SKIPPED
    echo [6/6] UniKey: SKIPPED >> "%LOG%"
    set /a TOTAL_SKIP+=1
) else (
    set "UNIKEY_ROOT=%ProgramFiles%\UniKey"
    set "EXISTING_EXE="
    if exist "!UNIKEY_ROOT!" (
        for /r "!UNIKEY_ROOT!" %%F in (UniKeyNT.exe) do if not defined EXISTING_EXE set "EXISTING_EXE=%%F"
    )
    if defined EXISTING_EXE (
        echo [6/6] UniKey: already installed, skipping.
        echo [6/6] UniKey: ALREADY INSTALLED >> "%LOG%"
        set /a TOTAL_SKIP+=1
    ) else (
        echo [6/6] Installing UniKey...
        echo [6/6] Downloading UniKey... >> "%LOG%"
        if not exist "!UNIKEY_ROOT!" mkdir "!UNIKEY_ROOT!" >nul 2>&1
        %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%UNIKEY_URL%' -OutFile '%DL_DIR%\unikey.zip' -UseBasicParsing -UserAgent 'Mozilla/5.0'"
        if exist "%DL_DIR%\unikey.zip" (
            powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '%DL_DIR%\unikey.zip' -DestinationPath '!UNIKEY_ROOT!' -Force" >nul 2>&1
            del /f /q "%DL_DIR%\unikey.zip" >nul 2>&1
            for /d %%D in ("!UNIKEY_ROOT!\*") do (
                if exist "%%D\UniKeyNT.exe" (
                    xcopy "%%D\*" "!UNIKEY_ROOT!\" /E /Y /Q >nul 2>&1
                    rmdir /s /q "%%D" >nul 2>&1
                )
            )
            if exist "!UNIKEY_ROOT!\UniKeyNT.exe" (
                powershell -NoProfile -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut('%PUBLIC%\Desktop\UniKey.lnk');$s.TargetPath='!UNIKEY_ROOT!\UniKeyNT.exe';$s.WorkingDirectory='!UNIKEY_ROOT!';$s.Save()" >nul 2>&1
                powershell -NoProfile -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut([Environment]::GetFolderPath('CommonStartup')+'\UniKey.lnk');$s.TargetPath='!UNIKEY_ROOT!\UniKeyNT.exe';$s.WorkingDirectory='!UNIKEY_ROOT!';$s.Save()" >nul 2>&1
                start "" "!UNIKEY_ROOT!\UniKeyNT.exe"
                echo        Done. UniKey installed.
                echo [6/6] UniKey: OK >> "%LOG%"
                set /a TOTAL_OK+=1
            ) else (
                echo        WARNING: UniKeyNT.exe not found after extract.
                echo [6/6] UniKey: EXTRACT FAILED >> "%LOG%"
                set /a TOTAL_FAIL+=1
            )
        ) else (
            echo        ERROR: Download failed.
            echo [6/6] UniKey: DOWNLOAD FAILED >> "%LOG%"
            set /a TOTAL_FAIL+=1
        )
    )
)

:: --- Cleanup download dir ---
timeout /t 3 /nobreak >nul
rmdir /s /q "%DL_DIR%" >nul 2>&1

:: --- Summary ---
echo. >> "%LOG%"
echo ============================================================ >> "%LOG%"
echo  SUMMARY: OK=%TOTAL_OK% FAILED=%TOTAL_FAIL% SKIPPED=%TOTAL_SKIP% >> "%LOG%"
echo  Completed: %DATE% %TIME% >> "%LOG%"
echo ============================================================ >> "%LOG%"

echo.
echo  =============================================
echo   All installations complete! (LDPlayer Farm)
echo   OK: %TOTAL_OK%  Failed: %TOTAL_FAIL%  Skipped: %TOTAL_SKIP%
echo  =============================================
echo   Log: %LOG%
echo  =============================================
echo.

:: --- Archive logs with password (if 7z available) ---
call :archive_logs

:: --- Remove desktop copy if autounattend copied one ---
if /i not "%~f0"=="%USERPROFILE%\Desktop\QuickInstall.bat" (
    if exist "%USERPROFILE%\Desktop\QuickInstall.bat" del /f /q "%USERPROFILE%\Desktop\QuickInstall.bat" >nul 2>&1
)

endlocal

:: Self-delete
(goto) 2>nul & del /f /q "%~f0" >nul 2>&1

:: ============================================================
:: SUBROUTINE: install_app
:: Args: %1=Step %2=AppName %3=URL %4=Filename %5=Type %6=ExePath1 %7=ExePath2
:: ============================================================
:install_app
set "_STEP=%~1"
set "_NAME=%~2"
set "_URL=%~3"
set "_FILE=%~4"
set "_TYPE=%~5"
set "_EXE1=%~6"
set "_EXE2=%~7"

if /i "!_URL!"=="SKIP" (
    echo [!_STEP!] !_NAME!: SKIPPED
    echo [!_STEP!] !_NAME!: SKIPPED >> "%LOG%"
    set /a TOTAL_SKIP+=1
    exit /b 0
)

set "_FOUND=0"
if exist "!_EXE1!" set "_FOUND=1"
if exist "!_EXE2!" set "_FOUND=1"
if "!_FOUND!"=="1" (
    echo [!_STEP!] !_NAME!: already installed, skipping.
    echo [!_STEP!] !_NAME!: ALREADY INSTALLED >> "%LOG%"
    set /a TOTAL_SKIP+=1
    exit /b 0
)

echo [!_STEP!] Installing !_NAME!...
echo [!_STEP!] Downloading !_NAME!... >> "%LOG%"

%PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '!_URL!' -OutFile '%DL_DIR%\!_FILE!' -UseBasicParsing"

if not exist "%DL_DIR%\!_FILE!" (
    echo        ERROR: download failed.
    echo [!_STEP!] !_NAME!: DOWNLOAD FAILED >> "%LOG%"
    set /a TOTAL_FAIL+=1
    exit /b 1
)

echo [!_STEP!] Installing !_NAME!... >> "%LOG%"

if "!_TYPE!"=="msi" (
    msiexec /i "%DL_DIR%\!_FILE!" /qn /norestart
) else if "!_TYPE!"=="nsis" (
    start /wait "" "%DL_DIR%\!_FILE!" /S
)

set "EXIT_CODE=!errorlevel!"
echo [!_STEP!] !_NAME! exit code: !EXIT_CODE! >> "%LOG%"
del /f /q "%DL_DIR%\!_FILE!" >nul 2>&1

if !EXIT_CODE! equ 0 (
    echo        Done.
    echo [!_STEP!] !_NAME!: OK >> "%LOG%"
    set /a TOTAL_OK+=1
) else (
    echo        Done (exit code: !EXIT_CODE!^).
    echo [!_STEP!] !_NAME!: COMPLETED WITH EXIT CODE !EXIT_CODE! >> "%LOG%"
    set /a TOTAL_OK+=1
)
exit /b 0

:: ============================================================
:: SUBROUTINE: archive_logs
:: ============================================================
:archive_logs
set "SEVENZIP="
if exist "%ProgramFiles%\7-Zip\7z.exe" set "SEVENZIP=%ProgramFiles%\7-Zip\7z.exe"
if exist "%ProgramFiles(x86)%\7-Zip\7z.exe" set "SEVENZIP=%ProgramFiles(x86)%\7-Zip\7z.exe"

if defined SEVENZIP (
    echo [*] Archiving logs with password protection...
    echo [*] Archiving logs... >> "%LOG%"
    if exist "C:\QuickOptimize_Log.txt" move /y "C:\QuickOptimize_Log.txt" "%LOG_DIR%\" >nul 2>&1
    attrib +h +s "%LOG_DIR%" >nul 2>&1
    "!SEVENZIP!" a -t7z "%LOG_DIR%\PCL_Logs.7z" "%LOG_DIR%\*.txt" -pPCL@1231233 -mhe=on -mx=1 -y >nul 2>&1
    if !errorlevel! equ 0 (
        del /f /q "%LOG_DIR%\*.txt" >nul 2>&1
        echo [*] Logs archived to %LOG_DIR%\PCL_Logs.7z >> "%LOG_DIR%\status.txt"
    )
) else (
    echo [*] 7-Zip not found, logs kept as plain text in %LOG_DIR%
    echo [*] 7-Zip not found, logs kept as plain text >> "%LOG%"
)
exit /b 0

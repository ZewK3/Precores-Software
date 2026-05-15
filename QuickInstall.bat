@echo off
:: ============================================================
::  QuickInstall.bat - Post-Install Software Setup
::  Logs to: C:\Windows\Logs\PCL\QuickInstall_Log.txt
::  Run as Administrator!
:: ============================================================
title QuickInstall - Software Setup
color 0B
setlocal EnableExtensions EnableDelayedExpansion

:: ---- Log setup (hidden directory) ----
set "LOG_DIR=%SystemRoot%\Logs\PCL"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1
attrib +h +s "%LOG_DIR%" >nul 2>&1

set "LOG=%LOG_DIR%\QuickInstall_Log.txt"
echo ============================================================ > "%LOG%"
echo  QuickInstall - Started: %DATE% %TIME% >> "%LOG%"
echo  Computer: %COMPUTERNAME% >> "%LOG%"
echo ============================================================ >> "%LOG%"

echo.
echo  =============================================
echo   QuickInstall - Software Setup
echo  =============================================
echo.

:: ---- Admin check ----
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Run as Administrator! >> "%LOG%"
    echo [ERROR] Run as Administrator!
    pause
    exit /b 1
)
echo [OK] Running as Administrator >> "%LOG%"

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

:: --- RustDesk Remote Control ---
set "RUSTDESK_URL=https://github.com/rustdesk/rustdesk/releases/download/1.4.6/rustdesk-1.4.6-x86_64.exe"

:: --- Virtualization (auto-detect) ---
set "VIRTIO_URL=https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win-guest-tools.exe"
set "VMTOOLS_URL=https://packages.vmware.com/tools/releases/latest/windows/x64/VMware-tools-13.1.0-25218885-x64.exe"

:: --- Runtime ---
set "VCREDIST_URL=https://aka.ms/vs/17/release/vc_redist.x64.exe"
set "DOTNET_URL=SKIP"

:: ============================================================
:: DO NOT EDIT BELOW (unless you know what you're doing)
:: ============================================================

set "DL_DIR=%SystemRoot%\Temp\QuickInstall"
if not exist "%DL_DIR%" mkdir "%DL_DIR%" >nul 2>&1

:: Common PowerShell download command
set "PS_DL=powershell -NoProfile -ExecutionPolicy Bypass -Command"

set "TOTAL_OK=0"
set "TOTAL_FAIL=0"
set "TOTAL_SKIP=0"

echo ---- Starting installations ---- >> "%LOG%"
echo ---- Starting installations ----
echo.

:: --- Chrome ---
call :install_app "1/12" "Google Chrome" "%CHROME_URL%" "chrome.msi" "msi" "%ProgramFiles%\Google\Chrome\Application\chrome.exe" "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"

:: --- Node.js ---
call :install_app "2/12" "Node.js" "%NODE_URL%" "nodejs.msi" "msi" "%ProgramFiles%\nodejs\node.exe" "%ProgramFiles(x86)%\nodejs\node.exe"

:: --- Git ---
call :install_app "3/12" "Git" "%GIT_URL%" "git.exe" "inno" "%ProgramFiles%\Git\cmd\git.exe" "%ProgramFiles(x86)%\Git\cmd\git.exe"

:: --- VS Code ---
call :install_app "4/12" "VS Code" "%VSCODE_URL%" "vscode.exe" "inno_vscode" "%ProgramFiles%\Microsoft VS Code\Code.exe" "%LOCALAPPDATA%\Programs\Microsoft VS Code\Code.exe"

:: --- 7-Zip ---
call :install_app "5/12" "7-Zip" "%SEVENZIP_URL%" "7zip.exe" "nsis" "%ProgramFiles%\7-Zip\7z.exe" "%ProgramFiles(x86)%\7-Zip\7z.exe"

:: --- Notepad++ ---
call :install_app "6/12" "Notepad++" "%NOTEPADPP_URL%" "npp.exe" "nsis" "%ProgramFiles%\Notepad++\notepad++.exe" "%ProgramFiles(x86)%\Notepad++\notepad++.exe"

:: --- Telegram ---
call :install_app "7/12" "Telegram" "%TELEGRAM_URL%" "telegram.exe" "inno" "%ProgramFiles%\Telegram Desktop\Telegram.exe" "%LOCALAPPDATA%\Telegram Desktop\Telegram.exe"

:: --- VC++ Redistributable ---
if /i "%VCREDIST_URL%"=="SKIP" (
    echo [8/12] VC++ Redist: SKIPPED
    echo [8/12] VC++ Redist: SKIPPED >> "%LOG%"
    set /a TOTAL_SKIP+=1
) else (
    set "VCR_KEY=HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64"
    reg query "!VCR_KEY!" /v Installed >nul 2>&1
    if !errorlevel! equ 0 (
        echo [8/12] VC++ Redist: already installed, skipping.
        echo [8/12] VC++ Redist: ALREADY INSTALLED >> "%LOG%"
        set /a TOTAL_SKIP+=1
    ) else (
        echo [8/12] Installing VC++ Redistributable...
        echo [8/12] Downloading VC++ Redist... >> "%LOG%"
        %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%VCREDIST_URL%' -OutFile '%DL_DIR%\vcredist.exe' -UseBasicParsing"
        if exist "%DL_DIR%\vcredist.exe" (
            echo [8/12] Installing VC++ Redist... >> "%LOG%"
            start /wait "" "%DL_DIR%\vcredist.exe" /install /quiet /norestart
            set "EXIT_CODE=!errorlevel!"
            echo [8/12] VC++ Redist exit code: !EXIT_CODE! >> "%LOG%"
            del /f /q "%DL_DIR%\vcredist.exe" >nul 2>&1
            if !EXIT_CODE! equ 0 (set /a TOTAL_OK+=1) else (set /a TOTAL_FAIL+=1)
            echo        Done.
        ) else (
            echo        ERROR: download failed.
            echo [8/12] VC++ Redist: DOWNLOAD FAILED >> "%LOG%"
            set /a TOTAL_FAIL+=1
        )
    )
)

:: --- .NET Runtime ---
if /i "%DOTNET_URL%"=="SKIP" (
    echo [9/12] .NET Runtime: SKIPPED
    echo [9/12] .NET Runtime: SKIPPED >> "%LOG%"
    set /a TOTAL_SKIP+=1
) else (
    echo [9/12] Installing .NET Runtime...
    echo [9/12] Downloading .NET Runtime... >> "%LOG%"
    %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%DOTNET_URL%' -OutFile '%DL_DIR%\dotnet.exe' -UseBasicParsing"
    if exist "%DL_DIR%\dotnet.exe" (
        start /wait "" "%DL_DIR%\dotnet.exe" /install /quiet /norestart
        set "EXIT_CODE=!errorlevel!"
        echo [9/12] .NET exit code: !EXIT_CODE! >> "%LOG%"
        del /f /q "%DL_DIR%\dotnet.exe" >nul 2>&1
        if !EXIT_CODE! equ 0 (set /a TOTAL_OK+=1) else (set /a TOTAL_FAIL+=1)
        echo        Done.
    ) else (
        echo        ERROR: download failed.
        echo [9/12] .NET: DOWNLOAD FAILED >> "%LOG%"
        set /a TOTAL_FAIL+=1
    )
)

:: --- Virtualization Tools (auto-detect) ---
set "IS_QEMU=0"
set "IS_VMWARE=0"
for /f "tokens=*" %%M in ('wmic computersystem get manufacturer /value 2^>nul ^| findstr /i "QEMU"') do set "IS_QEMU=1"
for /f "tokens=*" %%M in ('wmic computersystem get manufacturer /value 2^>nul ^| findstr /i "VMware"') do set "IS_VMWARE=1"
echo [10/12] Detection: QEMU=%IS_QEMU% VMware=%IS_VMWARE% >> "%LOG%"

if "%IS_QEMU%"=="1" (
    if exist "%ProgramFiles%\Virtio-Win\" (
        echo [10/12] VirtIO Guest Tools: already installed, skipping.
        echo [10/12] VirtIO: ALREADY INSTALLED >> "%LOG%"
        set /a TOTAL_SKIP+=1
    ) else (
        echo [10/12] Installing VirtIO Guest Tools ^(Proxmox/QEMU detected^)...
        echo [10/12] Downloading VirtIO... >> "%LOG%"
        %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%VIRTIO_URL%' -OutFile '%DL_DIR%\virtio-win-guest-tools.exe' -UseBasicParsing"
        if exist "%DL_DIR%\virtio-win-guest-tools.exe" (
            start /wait "" "%DL_DIR%\virtio-win-guest-tools.exe" /install /quiet /norestart
            set "EXIT_CODE=!errorlevel!"
            echo [10/12] VirtIO exit code: !EXIT_CODE! >> "%LOG%"
            del /f /q "%DL_DIR%\virtio-win-guest-tools.exe" >nul 2>&1
            if !EXIT_CODE! equ 0 (
                set /a TOTAL_OK+=1
            ) else if !EXIT_CODE! equ 3010 (
                echo [10/12] VirtIO: OK - reboot required >> "%LOG%"
                set /a TOTAL_OK+=1
            ) else (
                set /a TOTAL_FAIL+=1
            )
            echo        Done.
        ) else (
            echo        ERROR: download failed.
            echo [10/12] VirtIO: DOWNLOAD FAILED >> "%LOG%"
            set /a TOTAL_FAIL+=1
        )
    )
) else if "%IS_VMWARE%"=="1" (
    if exist "%ProgramFiles%\VMware\VMware Tools\vmtoolsd.exe" (
        echo [10/12] VMware Tools: already installed, skipping.
        echo [10/12] VMware Tools: ALREADY INSTALLED >> "%LOG%"
        set /a TOTAL_SKIP+=1
    ) else (
        echo [10/12] Installing VMware Tools ^(VMware detected^)...
        echo [10/12] Downloading VMware Tools... >> "%LOG%"
        %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%VMTOOLS_URL%' -OutFile '%DL_DIR%\vmtools.exe' -UseBasicParsing"
        if exist "%DL_DIR%\vmtools.exe" (
            start /wait "" "%DL_DIR%\vmtools.exe" /S /v"/qn REBOOT=R"
            set "EXIT_CODE=!errorlevel!"
            echo [10/12] VMware Tools exit code: !EXIT_CODE! >> "%LOG%"
            del /f /q "%DL_DIR%\vmtools.exe" >nul 2>&1
            if !EXIT_CODE! equ 0 (
                set /a TOTAL_OK+=1
            ) else if !EXIT_CODE! equ 3010 (
                echo [10/12] VMware Tools: OK - reboot required >> "%LOG%"
                set /a TOTAL_OK+=1
            ) else (
                set /a TOTAL_FAIL+=1
            )
            echo        Done.
        ) else (
            echo        ERROR: download failed.
            echo [10/12] VMware Tools: DOWNLOAD FAILED >> "%LOG%"
            set /a TOTAL_FAIL+=1
        )
    )
) else (
    echo [10/12] VM Tools: SKIPPED ^(physical machine^)
    echo [10/12] VM Tools: SKIPPED (physical) >> "%LOG%"
    set /a TOTAL_SKIP+=1
)

:: --- RustDesk ---
call :install_app "11/12" "RustDesk" "%RUSTDESK_URL%" "rustdesk.exe" "rustdesk" "%ProgramFiles%\RustDesk\rustdesk.exe" "%ProgramFiles(x86)%\RustDesk\rustdesk.exe"

:: --- UniKey ---
if /i "%UNIKEY_URL%"=="SKIP" (
    echo [12/12] UniKey: SKIPPED
    echo [12/12] UniKey: SKIPPED >> "%LOG%"
    set /a TOTAL_SKIP+=1
) else (
    set "UNIKEY_ROOT=%ProgramFiles%\UniKey"
    set "EXISTING_EXE="
    if exist "!UNIKEY_ROOT!" (
        for /r "!UNIKEY_ROOT!" %%F in (UniKeyNT.exe) do if not defined EXISTING_EXE set "EXISTING_EXE=%%F"
    )
    if defined EXISTING_EXE (
        echo [12/12] UniKey: already installed, skipping.
        echo [12/12] UniKey: ALREADY INSTALLED >> "%LOG%"
        set /a TOTAL_SKIP+=1
    ) else (
        echo [12/12] Installing UniKey...
        echo [12/12] Downloading UniKey... >> "%LOG%"
        if not exist "!UNIKEY_ROOT!" mkdir "!UNIKEY_ROOT!" >nul 2>&1
        %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%UNIKEY_URL%' -OutFile '%DL_DIR%\unikey.zip' -UseBasicParsing -UserAgent 'Mozilla/5.0'"
        if exist "%DL_DIR%\unikey.zip" (
            powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '%DL_DIR%\unikey.zip' -DestinationPath '!UNIKEY_ROOT!' -Force" >nul 2>&1
            del /f /q "%DL_DIR%\unikey.zip" >nul 2>&1

            REM Flatten: if zip created a subfolder, move everything up
            for /d %%D in ("!UNIKEY_ROOT!\*") do (
                if exist "%%D\UniKeyNT.exe" (
                    xcopy "%%D\*" "!UNIKEY_ROOT!\" /E /Y /Q >nul 2>&1
                    rmdir /s /q "%%D" >nul 2>&1
                )
            )

            if exist "!UNIKEY_ROOT!\UniKeyNT.exe" (
                set "UNIKEY_EXE=!UNIKEY_ROOT!\UniKeyNT.exe"
                powershell -NoProfile -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut('%PUBLIC%\Desktop\UniKey.lnk');$s.TargetPath='!UNIKEY_ROOT!\UniKeyNT.exe';$s.WorkingDirectory='!UNIKEY_ROOT!';$s.Save()" >nul 2>&1
                powershell -NoProfile -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut([Environment]::GetFolderPath('CommonStartup')+'\UniKey.lnk');$s.TargetPath='!UNIKEY_ROOT!\UniKeyNT.exe';$s.WorkingDirectory='!UNIKEY_ROOT!';$s.Save()" >nul 2>&1
                start "" "!UNIKEY_ROOT!\UniKeyNT.exe"
                echo        Done. UniKey installed to "!UNIKEY_ROOT!".
                echo [12/12] UniKey: OK >> "%LOG%"
                set /a TOTAL_OK+=1
            ) else (
                echo        WARNING: UniKeyNT.exe not found after extract.
                echo [12/12] UniKey: EXTRACT FAILED - UniKeyNT.exe not found >> "%LOG%"
                set /a TOTAL_FAIL+=1
            )
        ) else (
            echo        ERROR: Download failed.
            echo [12/12] UniKey: DOWNLOAD FAILED >> "%LOG%"
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
echo   All installations complete!
echo   OK: %TOTAL_OK%  Failed: %TOTAL_FAIL%  Skipped: %TOTAL_SKIP%
echo  =============================================
echo   Log: %LOG%
echo  =============================================
echo.

:: --- Archive logs with password (if 7z available) ---
call :archive_logs

:: --- Remove desktop copy if autounattend copied one for manual debugging ---
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

:: Check if already installed
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
) else if "!_TYPE!"=="inno" (
    start /wait "" "%DL_DIR%\!_FILE!" /VERYSILENT /NORESTART /SP-
) else if "!_TYPE!"=="inno_vscode" (
    start /wait "" "%DL_DIR%\!_FILE!" /VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,addtopath
) else if "!_TYPE!"=="nsis" (
    start /wait "" "%DL_DIR%\!_FILE!" /S
) else if "!_TYPE!"=="rustdesk" (
    start /wait "" "%DL_DIR%\!_FILE!" --silent-install
    timeout /t 5 /nobreak >nul
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
:: Archive all PCL logs into password-protected 7z
:: ============================================================
:archive_logs
set "SEVENZIP="
if exist "%ProgramFiles%\7-Zip\7z.exe" set "SEVENZIP=%ProgramFiles%\7-Zip\7z.exe"
if exist "%ProgramFiles(x86)%\7-Zip\7z.exe" set "SEVENZIP=%ProgramFiles(x86)%\7-Zip\7z.exe"

if defined SEVENZIP (
    echo [*] Archiving logs with password protection...
    echo [*] Archiving logs... >> "%LOG%"
    :: Move any root-level logs into PCL dir first
    if exist "C:\QuickOptimize_Log.txt" move /y "C:\QuickOptimize_Log.txt" "%LOG_DIR%\" >nul 2>&1
    if exist "C:\vm_heartbeat.ps1" del /f /q "C:\vm_heartbeat.ps1" >nul 2>&1
    attrib +h +s "%LOG_DIR%" "%LOG_DIR%\vm_heartbeat.ps1" >nul 2>&1
    :: Create password-protected archive
    "!SEVENZIP!" a -t7z "%LOG_DIR%\PCL_Logs.7z" "%LOG_DIR%\*.txt" -pPCL@1231233 -mhe=on -mx=1 -y >nul 2>&1
    if !errorlevel! equ 0 (
        :: Delete plain text logs, keep only archive
        del /f /q "%LOG_DIR%\*.txt" >nul 2>&1
        echo [*] Logs archived to %LOG_DIR%\PCL_Logs.7z >> "%LOG_DIR%\status.txt"
    )
) else (
    echo [*] 7-Zip not found, logs kept as plain text in %LOG_DIR%
    echo [*] 7-Zip not found, logs kept as plain text >> "%LOG%"
)
exit /b 0

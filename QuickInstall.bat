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

:: --- NoMachine Remote Control ---
set "NOMACHINE_URL=https://download.nomachine.com/download/8.14/Windows/nomachine_8.14.2_1_x64.exe"

:: --- Virtual Display (For GPU Passthrough) ---
set "VIRTUAL_DISPLAY_URL=https://www.amyuni.com/downloads/usbmmidd_v2.zip"

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
call :install_app "1/13" "Google Chrome" "%CHROME_URL%" "chrome.msi" "msi" "%ProgramFiles%\Google\Chrome\Application\chrome.exe" "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"

:: --- Node.js ---
call :install_app "2/13" "Node.js" "%NODE_URL%" "nodejs.msi" "msi" "%ProgramFiles%\nodejs\node.exe" "%ProgramFiles(x86)%\nodejs\node.exe"

:: --- Git ---
call :install_app "3/13" "Git" "%GIT_URL%" "git.exe" "inno" "%ProgramFiles%\Git\cmd\git.exe" "%ProgramFiles(x86)%\Git\cmd\git.exe"

:: --- VS Code ---
call :install_app "4/13" "VS Code" "%VSCODE_URL%" "vscode.exe" "inno_vscode" "%ProgramFiles%\Microsoft VS Code\Code.exe" "%LOCALAPPDATA%\Programs\Microsoft VS Code\Code.exe"

:: --- 7-Zip ---
call :install_app "5/13" "7-Zip" "%SEVENZIP_URL%" "7zip.exe" "nsis" "%ProgramFiles%\7-Zip\7z.exe" "%ProgramFiles(x86)%\7-Zip\7z.exe"

:: --- Notepad++ ---
call :install_app "6/13" "Notepad++" "%NOTEPADPP_URL%" "npp.exe" "nsis" "%ProgramFiles%\Notepad++\notepad++.exe" "%ProgramFiles(x86)%\Notepad++\notepad++.exe"

:: --- Telegram ---
call :install_app "7/13" "Telegram" "%TELEGRAM_URL%" "telegram.exe" "inno" "%ProgramFiles%\Telegram Desktop\Telegram.exe" "%LOCALAPPDATA%\Telegram Desktop\Telegram.exe"

:: --- VC++ Redistributable ---
if /i "%VCREDIST_URL%"=="SKIP" (
    echo [8/13] VC++ Redist: SKIPPED
    echo [8/13] VC++ Redist: SKIPPED >> "%LOG%"
    set /a TOTAL_SKIP+=1
) else (
    set "VCR_KEY=HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64"
    reg query "!VCR_KEY!" /v Installed >nul 2>&1
    if !errorlevel! equ 0 (
        echo [8/13] VC++ Redist: already installed, skipping.
        echo [8/13] VC++ Redist: ALREADY INSTALLED >> "%LOG%"
        set /a TOTAL_SKIP+=1
    ) else (
        echo [8/13] Installing VC++ Redistributable...
        echo [8/13] Downloading VC++ Redist... >> "%LOG%"
        %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%VCREDIST_URL%' -OutFile '%DL_DIR%\vcredist.exe' -UseBasicParsing"
        if exist "%DL_DIR%\vcredist.exe" (
            echo [8/13] Installing VC++ Redist... >> "%LOG%"
            start /wait "" "%DL_DIR%\vcredist.exe" /install /quiet /norestart
            set "EXIT_CODE=!errorlevel!"
            echo [8/13] VC++ Redist exit code: !EXIT_CODE! >> "%LOG%"
            del /f /q "%DL_DIR%\vcredist.exe" >nul 2>&1
            if !EXIT_CODE! equ 0 (set /a TOTAL_OK+=1) else (set /a TOTAL_FAIL+=1)
            echo        Done.
        ) else (
            echo        ERROR: download failed.
            echo [8/13] VC++ Redist: DOWNLOAD FAILED >> "%LOG%"
            set /a TOTAL_FAIL+=1
        )
    )
)

:: --- .NET Runtime ---
if /i "%DOTNET_URL%"=="SKIP" (
    echo [9/13] .NET Runtime: SKIPPED
    echo [9/13] .NET Runtime: SKIPPED >> "%LOG%"
    set /a TOTAL_SKIP+=1
) else (
    echo [9/13] Installing .NET Runtime...
    echo [9/13] Downloading .NET Runtime... >> "%LOG%"
    %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%DOTNET_URL%' -OutFile '%DL_DIR%\dotnet.exe' -UseBasicParsing"
    if exist "%DL_DIR%\dotnet.exe" (
        start /wait "" "%DL_DIR%\dotnet.exe" /install /quiet /norestart
        set "EXIT_CODE=!errorlevel!"
        echo [9/13] .NET exit code: !EXIT_CODE! >> "%LOG%"
        del /f /q "%DL_DIR%\dotnet.exe" >nul 2>&1
        if !EXIT_CODE! equ 0 (set /a TOTAL_OK+=1) else (set /a TOTAL_FAIL+=1)
        echo        Done.
    ) else (
        echo        ERROR: download failed.
        echo [9/13] .NET: DOWNLOAD FAILED >> "%LOG%"
        set /a TOTAL_FAIL+=1
    )
)

:: --- Virtualization Tools (auto-detect) ---
set "IS_QEMU=0"
set "IS_VMWARE=0"
for /f "tokens=*" %%M in ('wmic computersystem get manufacturer /value 2^>nul ^| findstr /i "QEMU"') do set "IS_QEMU=1"
for /f "tokens=*" %%M in ('wmic computersystem get manufacturer /value 2^>nul ^| findstr /i "VMware"') do set "IS_VMWARE=1"
echo [10/13] Detection: QEMU=%IS_QEMU% VMware=%IS_VMWARE% >> "%LOG%"

if "%IS_QEMU%"=="1" (
    if exist "%ProgramFiles%\Virtio-Win\" (
        echo [10/13] VirtIO Guest Tools: already installed, skipping.
        echo [10/13] VirtIO: ALREADY INSTALLED >> "%LOG%"
        set /a TOTAL_SKIP+=1
    ) else (
        echo [10/13] Installing VirtIO Guest Tools ^(Proxmox/QEMU detected^)...
        echo [10/13] Downloading VirtIO... >> "%LOG%"
        %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%VIRTIO_URL%' -OutFile '%DL_DIR%\virtio-win-guest-tools.exe' -UseBasicParsing"
        if exist "%DL_DIR%\virtio-win-guest-tools.exe" (
            start /wait "" "%DL_DIR%\virtio-win-guest-tools.exe" /install /quiet /norestart
            set "EXIT_CODE=!errorlevel!"
            echo [10/13] VirtIO exit code: !EXIT_CODE! >> "%LOG%"
            del /f /q "%DL_DIR%\virtio-win-guest-tools.exe" >nul 2>&1
            if !EXIT_CODE! equ 0 (
                set /a TOTAL_OK+=1
            ) else if !EXIT_CODE! equ 3010 (
                echo [10/13] VirtIO: OK - reboot required >> "%LOG%"
                set /a TOTAL_OK+=1
            ) else (
                set /a TOTAL_FAIL+=1
            )
            echo        Done.
        ) else (
            echo        ERROR: download failed.
            echo [10/13] VirtIO: DOWNLOAD FAILED >> "%LOG%"
            set /a TOTAL_FAIL+=1
        )
    )
) else if "%IS_VMWARE%"=="1" (
    if exist "%ProgramFiles%\VMware\VMware Tools\vmtoolsd.exe" (
        echo [10/13] VMware Tools: already installed, skipping.
        echo [10/13] VMware Tools: ALREADY INSTALLED >> "%LOG%"
        set /a TOTAL_SKIP+=1
    ) else (
        echo [10/13] Installing VMware Tools ^(VMware detected^)...
        echo [10/13] Downloading VMware Tools... >> "%LOG%"
        %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%VMTOOLS_URL%' -OutFile '%DL_DIR%\vmtools.exe' -UseBasicParsing"
        if exist "%DL_DIR%\vmtools.exe" (
            start /wait "" "%DL_DIR%\vmtools.exe" /S /v"/qn REBOOT=R"
            set "EXIT_CODE=!errorlevel!"
            echo [10/13] VMware Tools exit code: !EXIT_CODE! >> "%LOG%"
            del /f /q "%DL_DIR%\vmtools.exe" >nul 2>&1
            if !EXIT_CODE! equ 0 (
                set /a TOTAL_OK+=1
            ) else if !EXIT_CODE! equ 3010 (
                echo [10/13] VMware Tools: OK - reboot required >> "%LOG%"
                set /a TOTAL_OK+=1
            ) else (
                set /a TOTAL_FAIL+=1
            )
            echo        Done.
        ) else (
            echo        ERROR: download failed.
            echo [10/13] VMware Tools: DOWNLOAD FAILED >> "%LOG%"
            set /a TOTAL_FAIL+=1
        )
    )
) else (
    echo [10/13] VM Tools: SKIPPED ^(physical machine^)
    echo [10/13] VM Tools: SKIPPED (physical) >> "%LOG%"
    set /a TOTAL_SKIP+=1
)

:: --- Virtual Display (Amyuni USBMMIDD) ---
if /i "%VIRTUAL_DISPLAY_URL%"=="SKIP" (
    echo [11/13] Virtual Display: SKIPPED
    echo [11/13] Virtual Display: SKIPPED >> "%LOG%"
    set /a TOTAL_SKIP+=1
) else (
    if exist "%ProgramFiles%\VirtualDisplay\deviceinstaller64.exe" (
        echo [11/13] Virtual Display: already installed, skipping.
        echo [11/13] Virtual Display: ALREADY INSTALLED >> "%LOG%"
        set /a TOTAL_SKIP+=1
    ) else (
        echo [11/13] Installing Virtual Display Driver...
        echo [11/13] Downloading Virtual Display Driver... >> "%LOG%"
        if not exist "%ProgramFiles%\VirtualDisplay" mkdir "%ProgramFiles%\VirtualDisplay" >nul 2>&1
        %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%VIRTUAL_DISPLAY_URL%' -OutFile '%DL_DIR%\usbmmidd.zip' -UseBasicParsing"
        if exist "%DL_DIR%\usbmmidd.zip" (
            powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '%DL_DIR%\usbmmidd.zip' -DestinationPath '%ProgramFiles%\VirtualDisplay' -Force" >nul 2>&1
            del /f /q "%DL_DIR%\usbmmidd.zip" >nul 2>&1
            if exist "%ProgramFiles%\VirtualDisplay\deviceinstaller64.exe" (
                pushd "%ProgramFiles%\VirtualDisplay"
                deviceinstaller64.exe install usbmmidd.inf usbmmidd >nul 2>&1
                deviceinstaller64.exe enableidd 1 >nul 2>&1
                popd
                echo        Done. Virtual Display enabled.
                echo [11/13] Virtual Display: OK >> "%LOG%"
                set /a TOTAL_OK+=1
            ) else (
                echo        WARNING: deviceinstaller64.exe not found after extract.
                echo [11/13] Virtual Display: EXTRACT FAILED >> "%LOG%"
                set /a TOTAL_FAIL+=1
            )
        ) else (
            echo        ERROR: Download failed.
            echo [11/13] Virtual Display: DOWNLOAD FAILED >> "%LOG%"
            set /a TOTAL_FAIL+=1
        )
    )
)

:: --- NoMachine ---
call :install_app "12/13" "NoMachine" "%NOMACHINE_URL%" "nomachine.exe" "nomachine" "%ProgramFiles%\NoMachine\bin\nxserver.exe" "%ProgramFiles(x86)%\NoMachine\bin\nxserver.exe"
call :configure_nomachine

:: --- UniKey ---
if /i "%UNIKEY_URL%"=="SKIP" (
    echo [13/13] UniKey: SKIPPED
    echo [13/13] UniKey: SKIPPED >> "%LOG%"
    set /a TOTAL_SKIP+=1
) else (
    set "UNIKEY_ROOT=%ProgramFiles%\UniKey"
    set "EXISTING_EXE="
    if exist "!UNIKEY_ROOT!" (
        for /r "!UNIKEY_ROOT!" %%F in (UniKeyNT.exe) do if not defined EXISTING_EXE set "EXISTING_EXE=%%F"
    )
    if defined EXISTING_EXE (
        echo [13/13] UniKey: already installed, skipping.
        echo [13/13] UniKey: ALREADY INSTALLED >> "%LOG%"
        set /a TOTAL_SKIP+=1
    ) else (
        echo [13/13] Installing UniKey...
        echo [13/13] Downloading UniKey... >> "%LOG%"
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
                echo [13/13] UniKey: OK >> "%LOG%"
                set /a TOTAL_OK+=1
            ) else (
                echo        WARNING: UniKeyNT.exe not found after extract.
                echo [13/13] UniKey: EXTRACT FAILED - UniKeyNT.exe not found >> "%LOG%"
                set /a TOTAL_FAIL+=1
            )
        ) else (
            echo        ERROR: Download failed.
            echo [13/13] UniKey: DOWNLOAD FAILED >> "%LOG%"
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
) else if "!_TYPE!"=="nomachine" (
    start /wait "" "%DL_DIR%\!_FILE!" /VERYSILENT /NORESTART /SUPPRESSMSGBOXES
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
:: SUBROUTINE: configure_nomachine
:: Optimize NoMachine config and publish VM to dashboard.
:: ============================================================
:configure_nomachine
echo [12/13] NoMachine: configuring unattended access and optimizing...
echo [12/13] NoMachine: configuring unattended access and optimizing >> "%LOG%"

set "NM_CFG_DIR=%ProgramFiles%\NoMachine\etc"
if not exist "%NM_CFG_DIR%\server.cfg" set "NM_CFG_DIR=%ProgramFiles(x86)%\NoMachine\etc"

if exist "!NM_CFG_DIR!\server.cfg" (
    echo [*] Applying NoMachine optimizations for VM Farm... >> "%LOG%"
    :: Disable UPnP (faster startup, no router port mapping)
    :: Disable Auto-Updates (prevents popups)
    powershell -NoProfile -Command "$f='!NM_CFG_DIR!\server.cfg'; (Get-Content $f) -replace '(?i)^#?EnableUPnP\b.*', 'EnableUPnP none' -replace '(?i)^#?UpdateFrequency\b.*', 'UpdateFrequency 0' | Set-Content $f"
    
    :: Disable Audio injection (saves bandwidth)
    :: Disable USB sharing (saves CPU and driver load)
    powershell -NoProfile -Command "$f='!NM_CFG_DIR!\node.cfg'; (Get-Content $f) -replace '(?i)^#?AudioInterface\b.*', 'AudioInterface disabled' -replace '(?i)^#?EnableAudio\b.*', 'EnableAudio 0' -replace '(?i)^#?EnableUSBSharing\b.*', 'EnableUSBSharing 0' | Set-Content $f"

    :: Restart NoMachine services to apply changes
    net stop nxserver >nul 2>&1
    net start nxserver >nul 2>&1
)

set "VM_REGISTRY_URL=https://vm-registry.zewk.workers.dev"
set "PS_NM=%TEMP%\nomachine_register.ps1"
(
echo $ProgressPreference = 'SilentlyContinue'
echo [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

echo $nic = Get-CimInstance Win32_NetworkAdapter -Filter 'NetEnabled=True AND PhysicalAdapter=True' ^| Select-Object -First 1
echo $mac = if ^($nic^) { $nic.MACAddress } else { '' }
echo $ip = ^(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue ^| Where-Object {$_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.*'} ^| Select-Object -First 1^).IPAddress
echo $hostname = $env:COMPUTERNAME
echo if ^($hostname -like 'PCLPCL*'^) { $hostname = 'PCL' + $hostname.Substring^(6^) }
echo $body = @{ mac = $mac; hostname = $hostname; ip = $ip; nomachine = 'READY'; user = 'PCL'; password = 'PCL@1231233'; os = ^(Get-CimInstance Win32_OperatingSystem^).Caption } ^| ConvertTo-Json -Depth 3
echo try { Invoke-RestMethod -Uri '%VM_REGISTRY_URL%/register' -Method POST -Body $body -ContentType 'application/json' -TimeoutSec 15 ^| Out-Null; Write-Output ^('NOMACHINE_REGISTER_OK ' + $hostname + ' ' + $ip^) } catch { Write-Output ^('NOMACHINE_REGISTER_ERROR ' + $_.Exception.Message^); exit 1 }
) > "%PS_NM%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_NM%" >> "%LOG%" 2>&1
del /f /q "%PS_NM%" >nul 2>&1
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

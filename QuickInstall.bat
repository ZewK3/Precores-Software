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
set "VMTOOLS_URL=https://packages.vmware.com/tools/releases/latest/windows/x64/VMware-tools-13.1.0-25218885-x64.exe"

:: --- Runtime ---
set "VCREDIST_URL=https://aka.ms/vs/17/release/vc_redist.x64.exe"
set "DOTNET_URL=SKIP"

:: ============================================================
:: DO NOT EDIT BELOW (unless you know what you're doing)
:: ============================================================

set "DL_DIR=%SystemRoot%\Temp\QuickInstall"
if not exist "%DL_DIR%" mkdir "%DL_DIR%" >nul 2>&1

:: Common PowerShell download command (TLS 1.2, silent, no progress bar, fast)
set "PS_DL=powershell -NoProfile -ExecutionPolicy Bypass -Command"

echo ---- Starting installations ----
echo.

:: --- Chrome ---
if /i "%CHROME_URL%"=="SKIP" (
    echo [1/12] Chrome: SKIPPED
) else (
    call :check_installed "Google Chrome" "%ProgramFiles%\Google\Chrome\Application\chrome.exe" "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
    if "!ALREADY!"=="1" (
        echo [1/12] Chrome: already installed, skipping.
    ) else (
        echo [1/12] Installing Google Chrome...
        %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%CHROME_URL%' -OutFile '%DL_DIR%\chrome.msi' -UseBasicParsing"
        if exist "%DL_DIR%\chrome.msi" (
            msiexec /i "%DL_DIR%\chrome.msi" /qn /norestart
            del /f /q "%DL_DIR%\chrome.msi" >nul 2>&1
            echo        Done.
        ) else echo        ERROR: download failed.
    )
)

:: --- Node.js ---
if /i "%NODE_URL%"=="SKIP" (
    echo [2/12] Node.js: SKIPPED
) else (
    call :check_installed "Node.js" "%ProgramFiles%\nodejs\node.exe" "%ProgramFiles(x86)%\nodejs\node.exe"
    if "!ALREADY!"=="1" (
        echo [2/12] Node.js: already installed, skipping.
    ) else (
        echo [2/12] Installing Node.js...
        %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%NODE_URL%' -OutFile '%DL_DIR%\nodejs.msi' -UseBasicParsing"
        if exist "%DL_DIR%\nodejs.msi" (
            msiexec /i "%DL_DIR%\nodejs.msi" /qn /norestart
            del /f /q "%DL_DIR%\nodejs.msi" >nul 2>&1
            echo        Done.
        ) else echo        ERROR: download failed.
    )
)

:: --- Git ---
if /i "%GIT_URL%"=="SKIP" (
    echo [3/12] Git: SKIPPED
) else (
    call :check_installed "Git" "%ProgramFiles%\Git\cmd\git.exe" "%ProgramFiles(x86)%\Git\cmd\git.exe"
    if "!ALREADY!"=="1" (
        echo [3/12] Git: already installed, skipping.
    ) else (
        echo [3/12] Installing Git...
        %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%GIT_URL%' -OutFile '%DL_DIR%\git.exe' -UseBasicParsing"
        if exist "%DL_DIR%\git.exe" (
            start /wait "" "%DL_DIR%\git.exe" /VERYSILENT /NORESTART /SP-
            del /f /q "%DL_DIR%\git.exe" >nul 2>&1
            echo        Done.
        ) else echo        ERROR: download failed.
    )
)

:: --- VS Code ---
if /i "%VSCODE_URL%"=="SKIP" (
    echo [4/12] VS Code: SKIPPED
) else (
    call :check_installed "VS Code" "%ProgramFiles%\Microsoft VS Code\Code.exe" "%LOCALAPPDATA%\Programs\Microsoft VS Code\Code.exe"
    if "!ALREADY!"=="1" (
        echo [4/12] VS Code: already installed, skipping.
    ) else (
        echo [4/12] Installing Visual Studio Code...
        %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%VSCODE_URL%' -OutFile '%DL_DIR%\vscode.exe' -UseBasicParsing"
        if exist "%DL_DIR%\vscode.exe" (
            start /wait "" "%DL_DIR%\vscode.exe" /VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,addtopath
            del /f /q "%DL_DIR%\vscode.exe" >nul 2>&1
            echo        Done.
        ) else echo        ERROR: download failed.
    )
)

:: --- 7-Zip ---
if /i "%SEVENZIP_URL%"=="SKIP" (
    echo [5/12] 7-Zip: SKIPPED
) else (
    call :check_installed "7-Zip" "%ProgramFiles%\7-Zip\7z.exe" "%ProgramFiles(x86)%\7-Zip\7z.exe"
    if "!ALREADY!"=="1" (
        echo [5/12] 7-Zip: already installed, skipping.
    ) else (
        echo [5/12] Installing 7-Zip...
        %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%SEVENZIP_URL%' -OutFile '%DL_DIR%\7zip.exe' -UseBasicParsing"
        if exist "%DL_DIR%\7zip.exe" (
            start /wait "" "%DL_DIR%\7zip.exe" /S
            del /f /q "%DL_DIR%\7zip.exe" >nul 2>&1
            echo        Done.
        ) else echo        ERROR: download failed.
    )
)

:: --- Notepad++ ---
if /i "%NOTEPADPP_URL%"=="SKIP" (
    echo [6/12] Notepad++: SKIPPED
) else (
    call :check_installed "Notepad++" "%ProgramFiles%\Notepad++\notepad++.exe" "%ProgramFiles(x86)%\Notepad++\notepad++.exe"
    if "!ALREADY!"=="1" (
        echo [6/12] Notepad++: already installed, skipping.
    ) else (
        echo [6/12] Installing Notepad++...
        %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%NOTEPADPP_URL%' -OutFile '%DL_DIR%\npp.exe' -UseBasicParsing"
        if exist "%DL_DIR%\npp.exe" (
            start /wait "" "%DL_DIR%\npp.exe" /S
            del /f /q "%DL_DIR%\npp.exe" >nul 2>&1
            echo        Done.
        ) else echo        ERROR: download failed.
    )
)

:: --- Telegram ---
if /i "%TELEGRAM_URL%"=="SKIP" (
    echo [7/12] Telegram: SKIPPED
) else (
    call :check_installed "Telegram" "%ProgramFiles%\Telegram Desktop\Telegram.exe" "%LOCALAPPDATA%\Telegram Desktop\Telegram.exe"
    if "!ALREADY!"=="1" (
        echo [7/12] Telegram: already installed, skipping.
    ) else (
        echo [7/12] Installing Telegram...
        %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%TELEGRAM_URL%' -OutFile '%DL_DIR%\telegram.exe' -UseBasicParsing"
        if exist "%DL_DIR%\telegram.exe" (
            start /wait "" "%DL_DIR%\telegram.exe" /VERYSILENT /NORESTART
            del /f /q "%DL_DIR%\telegram.exe" >nul 2>&1
            echo        Done.
        ) else echo        ERROR: download failed.
    )
)

:: --- VC++ Redistributable ---
if /i "%VCREDIST_URL%"=="SKIP" (
    echo [8/12] VC++ Redist: SKIPPED
) else (
    set "VCR_KEY=HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64"
    reg query "!VCR_KEY!" /v Installed >nul 2>&1
    if !errorlevel! equ 0 (
        echo [8/12] VC++ Redist: already installed, skipping.
    ) else (
        echo [8/12] Installing VC++ Redistributable...
        %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%VCREDIST_URL%' -OutFile '%DL_DIR%\vcredist.exe' -UseBasicParsing"
        if exist "%DL_DIR%\vcredist.exe" (
            start /wait "" "%DL_DIR%\vcredist.exe" /install /quiet /norestart
            del /f /q "%DL_DIR%\vcredist.exe" >nul 2>&1
            echo        Done.
        ) else echo        ERROR: download failed.
    )
)

:: --- .NET Runtime ---
if /i "%DOTNET_URL%"=="SKIP" (
    echo [9/12] .NET Runtime: SKIPPED
) else (
    echo [9/12] Installing .NET Runtime...
    %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%DOTNET_URL%' -OutFile '%DL_DIR%\dotnet.exe' -UseBasicParsing"
    if exist "%DL_DIR%\dotnet.exe" (
        start /wait "" "%DL_DIR%\dotnet.exe" /install /quiet /norestart
        del /f /q "%DL_DIR%\dotnet.exe" >nul 2>&1
        echo        Done.
    ) else echo        ERROR: download failed.
)

:: --- Virtualization Tools (auto-detect Proxmox/QEMU vs VMware) ---
set "IS_QEMU=0"
set "IS_VMWARE=0"
for /f "tokens=*" %%M in ('wmic computersystem get manufacturer /value 2^>nul ^| findstr /i "QEMU"') do set "IS_QEMU=1"
for /f "tokens=*" %%M in ('wmic computersystem get manufacturer /value 2^>nul ^| findstr /i "VMware"') do set "IS_VMWARE=1"

if "%IS_QEMU%"=="1" (
    if exist "%ProgramFiles%\Virtio-Win\" (
        echo [10/12] VirtIO Guest Tools: already installed, skipping.
    ) else (
        echo [10/12] Installing VirtIO Guest Tools ^(Proxmox/QEMU detected^)...
        %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%VIRTIO_URL%' -OutFile '%DL_DIR%\virtio-win-guest-tools.exe' -UseBasicParsing"
        if exist "%DL_DIR%\virtio-win-guest-tools.exe" (
            start /wait "" "%DL_DIR%\virtio-win-guest-tools.exe" /install /quiet /norestart
            del /f /q "%DL_DIR%\virtio-win-guest-tools.exe" >nul 2>&1
            echo        Done.
        ) else echo        ERROR: download failed.
    )
) else if "%IS_VMWARE%"=="1" (
    if exist "%ProgramFiles%\VMware\VMware Tools\vmtoolsd.exe" (
        echo [10/12] VMware Tools: already installed, skipping.
    ) else (
        echo [10/12] Installing VMware Tools ^(VMware detected^)...
        %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%VMTOOLS_URL%' -OutFile '%DL_DIR%\vmtools.exe' -UseBasicParsing"
        if exist "%DL_DIR%\vmtools.exe" (
            start /wait "" "%DL_DIR%\vmtools.exe" /S /v"/qn REBOOT=R"
            del /f /q "%DL_DIR%\vmtools.exe" >nul 2>&1
            echo        Done.
        ) else echo        ERROR: download failed.
    )
) else (
    echo [10/12] VM Tools: SKIPPED ^(physical machine^)
)

:: --- RustDesk ---
if /i "%RUSTDESK_URL%"=="SKIP" (
    echo [11/12] RustDesk: SKIPPED
) else (
    call :check_installed "RustDesk" "%ProgramFiles%\RustDesk\rustdesk.exe" "%ProgramFiles(x86)%\RustDesk\rustdesk.exe"
    if "!ALREADY!"=="1" (
        echo [11/12] RustDesk: already installed, skipping.
    ) else (
        echo [11/12] Installing RustDesk ^(Remote Desktop^)...
        %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%RUSTDESK_URL%' -OutFile '%DL_DIR%\rustdesk.exe' -UseBasicParsing"
        if exist "%DL_DIR%\rustdesk.exe" (
            start /wait "" "%DL_DIR%\rustdesk.exe" --silent-install
            del /f /q "%DL_DIR%\rustdesk.exe" >nul 2>&1
            echo        Done.
        ) else echo        ERROR: download failed.
    )
)

:: --- UniKey (Vietnamese input method) ---
if /i "%UNIKEY_URL%"=="SKIP" (
    echo [12/12] UniKey: SKIPPED
) else (
    set "UNIKEY_ROOT=%ProgramFiles%\UniKey"
    set "EXISTING_EXE="
    if exist "!UNIKEY_ROOT!" (
        for /r "!UNIKEY_ROOT!" %%F in (UniKeyNT.exe) do if not defined EXISTING_EXE set "EXISTING_EXE=%%F"
    )
    if defined EXISTING_EXE (
        echo [12/12] UniKey: already installed, skipping.
    ) else (
        echo [12/12] Installing UniKey...
        if not exist "!UNIKEY_ROOT!" mkdir "!UNIKEY_ROOT!" >nul 2>&1
        %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%UNIKEY_URL%' -OutFile '%DL_DIR%\unikey.zip' -UseBasicParsing -UserAgent 'Mozilla/5.0'"
        if exist "%DL_DIR%\unikey.zip" (
            powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '%DL_DIR%\unikey.zip' -DestinationPath '!UNIKEY_ROOT!' -Force" >nul 2>&1
            del /f /q "%DL_DIR%\unikey.zip" >nul 2>&1

            REM Flatten: if zip created a subfolder, move everything up to UNIKEY_ROOT
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
            ) else (
                echo        WARNING: UniKeyNT.exe not found after extract.
            )
        ) else echo        ERROR: Download failed.
    )
)

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

:: Self-delete (works from any location)
(goto) 2>nul & del /f /q "%~f0" >nul 2>&1

endlocal
exit /b 0

:: ============================================================
:: SUBROUTINE: check_installed
:: Args: %1=AppName (for log), %2..%n = candidate exe paths
:: Sets ALREADY=1 if any candidate file exists, else 0
:: ============================================================
:check_installed
set "ALREADY=0"
set "_APP=%~1"
shift
:_ci_loop
if "%~1"=="" goto :_ci_end
if exist "%~1" set "ALREADY=1"
shift
goto :_ci_loop
:_ci_end
exit /b 0

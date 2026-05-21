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
cd /d "%SystemRoot%"

:: ---- Log setup ----
set "LOG_DIR=%SystemRoot%\Logs\PCL"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1

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
) else (
    echo [OK] Running as Administrator >> "%LOG%"
)

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
set "LDPLAYER_URL=https://res.ldrescdn.com/download/LDPlayer9.exe?n=LDPlayer9_vi_1254_ld.exe"

:: --- Vietnamese Input ---
set "UNIKEY_URL=https://www.unikey.org/assets/release/unikey46RC2-230919-win64.zip"

:: --- Virtualization (auto-detect) ---
set "VIRTIO_URL=https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win-guest-tools.exe"

:: --- .NET 10 Desktop Runtime ---
set "DOTNET10_URL=https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/10.0.8/windowsdesktop-runtime-10.0.8-win-x64.exe"

:: --- Google Drive Software Folder (all extra software lives here) ---
:: Update files on Drive WITHOUT rebuilding ISO!
set "GDRIVE_FOLDER_ID=1-AOvLBDWO0ALzGpeJzVxuDkwLgqZWbAy"

:: ============================================================
:: DO NOT EDIT BELOW
:: ============================================================

set "DL_DIR=%SystemRoot%\Temp\QuickInstall"
if not exist "%DL_DIR%" mkdir "%DL_DIR%" >nul 2>&1

:: Software download folder on Desktop (for manual-install apps)
set "SOFTWARE_DIR=%PUBLIC%\Desktop\Software"
if not exist "%SOFTWARE_DIR%" mkdir "%SOFTWARE_DIR%" >nul 2>&1

set "PS_DL=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -Command"

set "TOTAL_OK=0"
set "TOTAL_FAIL=0"
set "TOTAL_SKIP=0"

echo ---- Starting installations ---- >> "%LOG%"
echo ---- Starting installations ----
echo.

:: ---- Check Internet Connection (wait up to 60 seconds) ----
echo [*] Checking internet connectivity...
echo [*] Checking internet connectivity... >> "%LOG%"
set "INTERNET_OK=0"
for /l %%I in (1,1,12) do (
    ping -n 1 8.8.8.8 >nul 2>&1
    if !errorlevel! equ 0 (
        set "INTERNET_OK=1"
        goto :internet_connected
    )
    echo      Offline, waiting for network connection... (Attempt %%I/12)
    echo      Offline, waiting for network connection... (Attempt %%I/12) >> "%LOG%"
    timeout /t 5 /nobreak >nul
)

:internet_connected
if "%INTERNET_OK%"=="0" (
    echo [WARN] No internet connection detected! Downloading software files may fail.
    echo [WARN] No internet connection detected! >> "%LOG%"
) else (
    echo [OK] Internet connection is active.
    echo [OK] Internet connection is active. >> "%LOG%"
)
echo.

:: --- 1. Chrome ---
call :install_app "1/8" "Google Chrome" "%CHROME_URL%" "chrome.msi" "msi" "%ProgramFiles%\Google\Chrome\Application\chrome.exe" "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"

:: --- Chrome Optimization (skip first-run + RAM optimization + custom background) ---
echo [*] Applying Chrome optimizations...
echo [*] Chrome optimizations... >> "%LOG%"

:: ---- SKIP FIRST RUN / WELCOME ----
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v SuppressUnsupportedOSWarning /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v MetricsReportingEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v DefaultBrowserSettingEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v PromotionalTabsEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v CommandLineFlagSecurityWarningsEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v WelcomePageOnOSUpgradeEnabled /t REG_DWORD /d 0 /f >nul 2>&1
:: Set first run tabs to blank (no welcome page)
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\RestoreOnStartupURLs" /v 1 /t REG_SZ /d "about:blank" /f >nul 2>&1
:: Disable sign-in prompt, sync prompt
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v BrowserSignin /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v SyncDisabled /t REG_DWORD /d 1 /f >nul 2>&1
:: Mark first run done for all profiles
set "CHROME_MASTER=%ProgramFiles%\Google\Chrome\Application\master_preferences"
if not exist "%CHROME_MASTER%" set "CHROME_MASTER=%ProgramFiles(x86)%\Google\Chrome\Application\master_preferences"
(
echo {
echo   "distribution": {
echo     "skip_first_run_ui": true,
echo     "suppress_first_run_default_browser_prompt": true,
echo     "suppress_first_run_bubble": true,
echo     "make_chrome_default": false,
echo     "make_chrome_default_for_user": false,
echo     "import_bookmarks": false,
echo     "import_history": false,
echo     "import_search_engine": false,
echo     "do_not_create_desktop_shortcut": false,
echo     "do_not_create_quick_launch_shortcut": true,
echo     "do_not_create_taskbar_shortcut": false,
echo     "do_not_launch_chrome": true
echo   },
echo   "first_run_tabs": ["chrome://newtab"],
echo   "browser": {
echo     "show_home_button": false,
echo     "check_default_browser": false
echo   },
echo   "session": {
echo     "restore_on_startup": 5
echo   }
echo }
) > "%ProgramFiles%\Google\Chrome\Application\master_preferences" 2>nul
if !errorlevel! neq 0 (
    (
    echo {
    echo   "distribution": {
    echo     "skip_first_run_ui": true,
    echo     "suppress_first_run_default_browser_prompt": true,
    echo     "suppress_first_run_bubble": true,
    echo     "make_chrome_default": false,
    echo     "import_bookmarks": false,
    echo     "import_history": false,
    echo     "do_not_launch_chrome": true
    echo   },
    echo   "first_run_tabs": ["chrome://newtab"],
    echo   "browser": {
    echo     "check_default_browser": false
    echo   }
    echo }
    ) > "%ProgramFiles(x86)%\Google\Chrome\Application\master_preferences" 2>nul
)
echo   - First-run/welcome skipped

:: ---- RAM OPTIMIZATION (via GPO registry) ----
:: Enable Memory Saver (High Efficiency Mode)
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v HighEfficiencyModeEnabled /t REG_DWORD /d 1 /f >nul 2>&1
:: Reduce renderer process limit (default is unlimited, limit to 4 saves ~200MB)
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v RendererProcessLimit /t REG_DWORD /d 4 /f >nul 2>&1
:: Disable background mode (Chrome stays in memory after closing)
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v BackgroundModeEnabled /t REG_DWORD /d 0 /f >nul 2>&1
:: Disable preloading pages (saves RAM + bandwidth)
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v NetworkPredictionOptions /t REG_DWORD /d 2 /f >nul 2>&1
:: Disable translation service (saves ~30MB per tab)
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v TranslateEnabled /t REG_DWORD /d 0 /f >nul 2>&1
:: Disable spell check
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v SpellCheckServiceEnabled /t REG_DWORD /d 0 /f >nul 2>&1
:: Disable media router (Chromecast discovery)
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v EnableMediaRouter /t REG_DWORD /d 0 /f >nul 2>&1
:: Disable cloud print
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v CloudPrintSubmitEnabled /t REG_DWORD /d 0 /f >nul 2>&1
:: Disable Safe Browsing extended reporting (less background network)
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v SafeBrowsingExtendedReportingEnabled /t REG_DWORD /d 0 /f >nul 2>&1
:: Disable search suggestions (less network calls)
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v SearchSuggestEnabled /t REG_DWORD /d 0 /f >nul 2>&1
:: Disable component updates for unused components
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v ComponentUpdatesEnabled /t REG_DWORD /d 0 /f >nul 2>&1
:: Disable Chrome auto-update (saves RAM from update service)
reg add "HKLM\SOFTWARE\Policies\Google\Update" /v UpdateDefault /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Update" /v AutoUpdateCheckPeriodMinutes /t REG_DWORD /d 0 /f >nul 2>&1
echo   - RAM optimizations applied (Memory Saver ON, preload OFF, renderer limit=4)

:: ---- SET CUSTOM NTP BACKGROUND (nen.png) ----
set "NEN_SRC=C:\InstallScripts\nen.png"
set "CHROME_THEME_DIR=%ProgramData%\PCL\chrome-theme"
if exist "%NEN_SRC%" (
    if not exist "%CHROME_THEME_DIR%" mkdir "%CHROME_THEME_DIR%" >nul 2>&1
    copy /y "%NEN_SRC%" "%CHROME_THEME_DIR%\nen.png" >nul 2>&1
    :: Create Chrome theme extension folder
    set "EXT_DIR=%CHROME_THEME_DIR%\pcl-theme"
    if not exist "!EXT_DIR!\images" mkdir "!EXT_DIR!\images" >nul 2>&1
    copy /y "%NEN_SRC%" "!EXT_DIR!\images\theme_ntp_background.png" >nul 2>&1
    (
    echo {
    echo   "manifest_version": 3,
    echo   "version": "1.0",
    echo   "name": "PCL Theme",
    echo   "theme": {
    echo     "images": {
    echo       "theme_ntp_background": "images/theme_ntp_background.png"
    echo     },
    echo     "properties": {
    echo       "ntp_background_alignment": "center",
    echo       "ntp_background_repeat": "no-repeat"
    echo     },
    echo     "colors": {
    echo       "ntp_background": [30, 30, 30],
    echo       "ntp_text": [255, 255, 255],
    echo       "frame": [30, 30, 30],
    echo       "toolbar": [40, 40, 40]
    echo     }
    echo   }
    echo }
    ) > "!EXT_DIR!\manifest.json"
    :: Add --load-extension to Chrome launch args via registry
    set "CHROME_EXE="
    if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" set "CHROME_EXE=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
    if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" set "CHROME_EXE=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
    if defined CHROME_EXE (
        :: Update all Chrome shortcuts on Public Desktop to load the theme extension
        %SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -Command "$d=[Environment]::GetFolderPath('CommonDesktopDirectory');Get-ChildItem $d -Filter '*Chrome*' -ErrorAction SilentlyContinue|ForEach-Object{$s=(New-Object -ComObject WScript.Shell).CreateShortcut($_.FullName);$s.Arguments='--load-extension=\"!EXT_DIR!\"';$s.Save()}" >nul 2>&1
        %SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -Command "$d=[Environment]::GetFolderPath('Desktop');Get-ChildItem $d -Filter '*Chrome*' -ErrorAction SilentlyContinue|ForEach-Object{$s=(New-Object -ComObject WScript.Shell).CreateShortcut($_.FullName);$s.Arguments='--load-extension=\"!EXT_DIR!\"';$s.Save()}" >nul 2>&1
    )
    echo   - Custom NTP background set (nen.png as Chrome theme)
) else (
    echo   - nen.png not found, skipping Chrome background
)
echo [*] Chrome optimizations done >> "%LOG%"

:: --- 2. 7-Zip ---
call :install_app "2/8" "7-Zip" "%SEVENZIP_URL%" "7zip.exe" "nsis" "%ProgramFiles%\7-Zip\7z.exe" "%ProgramFiles(x86)%\7-Zip\7z.exe"

:: --- 3. VC++ Redistributable ---
if /i "%VCREDIST_URL%"=="SKIP" (
    echo [3/8] VC++ Redist: SKIPPED
    echo [3/8] VC++ Redist: SKIPPED >> "%LOG%"
    set /a TOTAL_SKIP+=1
) else (
    set "VCR_KEY=HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64"
    reg query "!VCR_KEY!" /v Installed >nul 2>&1
    if !errorlevel! equ 0 (
        echo [3/8] VC++ Redist: already installed, skipping.
        echo [3/8] VC++ Redist: ALREADY INSTALLED >> "%LOG%"
        set /a TOTAL_SKIP+=1
    ) else (
        echo [3/8] Installing VC++ Redistributable...
        echo [3/8] Downloading VC++ Redist... >> "%LOG%"
        %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%VCREDIST_URL%' -OutFile '%DL_DIR%\vcredist.exe' -UseBasicParsing"
        if exist "%DL_DIR%\vcredist.exe" (
            echo [3/8] Installing VC++ Redist... >> "%LOG%"
            start /wait "" "%DL_DIR%\vcredist.exe" /install /quiet /norestart
            set "EXIT_CODE=!errorlevel!"
            echo [3/8] VC++ Redist exit code: !EXIT_CODE! >> "%LOG%"
            del /f /q "%DL_DIR%\vcredist.exe" >nul 2>&1
            if !EXIT_CODE! equ 0 (set /a TOTAL_OK+=1) else (set /a TOTAL_FAIL+=1)
            echo        Done.
        ) else (
            echo        ERROR: download failed.
            echo [3/8] VC++ Redist: DOWNLOAD FAILED >> "%LOG%"
            set /a TOTAL_FAIL+=1
        )
    )
)

:: --- 4. VirtIO Guest Tools (auto-detect QEMU/Proxmox) ---
set "IS_QEMU=0"
for /f "tokens=*" %%M in ('wmic computersystem get manufacturer /value 2^>nul ^| findstr /i "QEMU"') do set "IS_QEMU=1"
echo [4/8] Detection: QEMU=%IS_QEMU% >> "%LOG%"

if "%IS_QEMU%"=="1" (
    if exist "%ProgramFiles%\Virtio-Win\" (
        echo [4/8] VirtIO Guest Tools: already installed, skipping.
        echo [4/8] VirtIO: ALREADY INSTALLED >> "%LOG%"
        set /a TOTAL_SKIP+=1
    ) else (
        echo [4/8] Installing VirtIO Guest Tools ^(Proxmox/QEMU detected^)...
        echo [4/8] Downloading VirtIO... >> "%LOG%"
        %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%VIRTIO_URL%' -OutFile '%DL_DIR%\virtio-win-guest-tools.exe' -UseBasicParsing"
        if exist "%DL_DIR%\virtio-win-guest-tools.exe" (
            start /wait "" "%DL_DIR%\virtio-win-guest-tools.exe" /install /quiet /norestart
            set "EXIT_CODE=!errorlevel!"
            echo [4/8] VirtIO exit code: !EXIT_CODE! >> "%LOG%"
            del /f /q "%DL_DIR%\virtio-win-guest-tools.exe" >nul 2>&1
            if !EXIT_CODE! equ 0 (set /a TOTAL_OK+=1) else if !EXIT_CODE! equ 3010 (set /a TOTAL_OK+=1) else (set /a TOTAL_FAIL+=1)
            echo        Done.
        ) else (
            echo        ERROR: download failed.
            echo [4/8] VirtIO: DOWNLOAD FAILED >> "%LOG%"
            set /a TOTAL_FAIL+=1
        )
    )
) else (
    echo [4/8] VirtIO: SKIPPED ^(not QEMU/Proxmox^)
    echo [4/8] VirtIO: SKIPPED (not QEMU) >> "%LOG%"
    set /a TOTAL_SKIP+=1
)

:: --- 5. LDPlayer 9 (download to Software folder) ---
echo [5/8] Downloading LDPlayer 9 to Software folder...
echo [5/8] Downloading LDPlayer 9... >> "%LOG%"
if exist "%SOFTWARE_DIR%\LDPlayer9_Installer.exe" (
    echo [5/8] LDPlayer: already downloaded, skipping.
    echo [5/8] LDPlayer: ALREADY EXISTS >> "%LOG%"
    set /a TOTAL_SKIP+=1
) else (
    %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%LDPLAYER_URL%' -OutFile '%SOFTWARE_DIR%\LDPlayer9_Installer.exe' -UseBasicParsing"
    if exist "%SOFTWARE_DIR%\LDPlayer9_Installer.exe" (
        echo        Done. Saved to Software\LDPlayer9_Installer.exe
        echo [5/8] LDPlayer: DOWNLOADED >> "%LOG%"
        set /a TOTAL_OK+=1
    ) else (
        echo        ERROR: download failed.
        echo [5/8] LDPlayer: DOWNLOAD FAILED >> "%LOG%"
        set /a TOTAL_FAIL+=1
    )
)

:: --- 6. UniKey ---
if /i "%UNIKEY_URL%"=="SKIP" (
    echo [6/8] UniKey: SKIPPED
    echo [6/8] UniKey: SKIPPED >> "%LOG%"
    set /a TOTAL_SKIP+=1
) else (
    set "UNIKEY_ROOT=%ProgramFiles%\UniKey"
    set "EXISTING_EXE="
    if exist "!UNIKEY_ROOT!" (
        for /r "!UNIKEY_ROOT!" %%F in (UniKeyNT.exe) do if not defined EXISTING_EXE set "EXISTING_EXE=%%F"
    )
    if defined EXISTING_EXE (
        echo [6/8] UniKey: already installed, skipping.
        echo [6/8] UniKey: ALREADY INSTALLED >> "%LOG%"
        set /a TOTAL_SKIP+=1
    ) else (
        echo [6/8] Installing UniKey...
        echo [6/8] Downloading UniKey... >> "%LOG%"
        if not exist "!UNIKEY_ROOT!" mkdir "!UNIKEY_ROOT!" >nul 2>&1
        %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%UNIKEY_URL%' -OutFile '%DL_DIR%\unikey.zip' -UseBasicParsing -UserAgent 'Mozilla/5.0'"
        if exist "%DL_DIR%\unikey.zip" (
            %SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '%DL_DIR%\unikey.zip' -DestinationPath '!UNIKEY_ROOT!' -Force" >nul 2>&1
            del /f /q "%DL_DIR%\unikey.zip" >nul 2>&1
            for /d %%D in ("!UNIKEY_ROOT!\*") do (
                if exist "%%D\UniKeyNT.exe" (
                    xcopy "%%D\*" "!UNIKEY_ROOT!\" /E /Y /Q >nul 2>&1
                    rmdir /s /q "%%D" >nul 2>&1
                )
            )
            if exist "!UNIKEY_ROOT!\UniKeyNT.exe" (
                %SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut('%PUBLIC%\Desktop\UniKey.lnk');$s.TargetPath='!UNIKEY_ROOT!\UniKeyNT.exe';$s.WorkingDirectory='!UNIKEY_ROOT!';$s.Save()" >nul 2>&1
                %SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut([Environment]::GetFolderPath('CommonStartup')+'\UniKey.lnk');$s.TargetPath='!UNIKEY_ROOT!\UniKeyNT.exe';$s.WorkingDirectory='!UNIKEY_ROOT!';$s.Save()" >nul 2>&1
                start "" "!UNIKEY_ROOT!\UniKeyNT.exe"
                echo        Done. UniKey installed.
                echo [6/8] UniKey: OK >> "%LOG%"
                set /a TOTAL_OK+=1
            ) else (
                echo        WARNING: UniKeyNT.exe not found after extract.
                echo [6/8] UniKey: EXTRACT FAILED >> "%LOG%"
                set /a TOTAL_FAIL+=1
            )
        ) else (
            echo        ERROR: Download failed.
            echo [6/8] UniKey: DOWNLOAD FAILED >> "%LOG%"
            set /a TOTAL_FAIL+=1
        )
    )
)

:: --- 7. .NET 10 Desktop Runtime ---
echo [7/8] Checking .NET 10 Desktop Runtime...
set "DOTNET10_FOUND=0"
%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -Command "if(Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall' -ErrorAction SilentlyContinue | Get-ItemProperty | Where-Object {$_.DisplayName -match 'Microsoft Windows Desktop Runtime.*10\.0'}){exit 0}else{exit 1}" >nul 2>&1
if !errorlevel! equ 0 (
    echo [7/8] .NET 10 Desktop Runtime: already installed, skipping.
    echo [7/8] .NET 10: ALREADY INSTALLED >> "%LOG%"
    set /a TOTAL_SKIP+=1
) else (
    echo [7/8] Installing .NET 10 Desktop Runtime...
    echo [7/8] Downloading .NET 10... >> "%LOG%"
    %PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%DOTNET10_URL%' -OutFile '%DL_DIR%\dotnet10-desktop.exe' -UseBasicParsing"
    if exist "%DL_DIR%\dotnet10-desktop.exe" (
        echo [7/8] Installing .NET 10... >> "%LOG%"
        start /wait "" "%DL_DIR%\dotnet10-desktop.exe" /install /quiet /norestart
        set "EXIT_CODE=!errorlevel!"
        echo [7/8] .NET 10 exit code: !EXIT_CODE! >> "%LOG%"
        del /f /q "%DL_DIR%\dotnet10-desktop.exe" >nul 2>&1
        if !EXIT_CODE! equ 0 (set /a TOTAL_OK+=1) else if !EXIT_CODE! equ 3010 (set /a TOTAL_OK+=1) else (set /a TOTAL_FAIL+=1)
        echo        Done.
    ) else (
        echo        ERROR: download failed.
        echo [7/8] .NET 10: DOWNLOAD FAILED >> "%LOG%"
        set /a TOTAL_FAIL+=1
    )
)

:: --- 8. Download Software from Google Drive folder ---
:: All extra software (VMware, MSI Afterburner, FanControl, etc.) lives in one Drive folder.
:: Add/remove/update files on Drive WITHOUT rebuilding ISO!
echo [8/8] Downloading Software from Google Drive folder...
echo [8/8] Downloading Software folder from Google Drive... >> "%LOG%"
set "GDRIVE_SCRIPT=C:\InstallScripts\gdrive_folder_dl.ps1"
if exist "%GDRIVE_SCRIPT%" (
    %SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '%GDRIVE_SCRIPT%' '%GDRIVE_FOLDER_ID%' '%SOFTWARE_DIR%' 2>&1 | Tee-Object -FilePath '%LOG%' -Append"
    if !errorlevel! equ 0 (
        echo [8/8] Software folder: ALL OK >> "%LOG%"
        set /a TOTAL_OK+=1
    ) else (
        echo [8/8] Software folder: SOME DOWNLOADS FAILED >> "%LOG%"
        set /a TOTAL_FAIL+=1
    )
) else (
    echo        ERROR: gdrive_folder_dl.ps1 not found.
    echo [8/8] Software folder: SCRIPT MISSING >> "%LOG%"
    set /a TOTAL_FAIL+=1
)

:: --- Cleanup download dir ---
timeout /t 3 /nobreak >nul
rmdir /s /q "%DL_DIR%" >nul 2>&1

:: --- Deploy PreCores PC maintenance tool to Desktop ---
set "PRECORE_SRC=C:\InstallScripts\precore-pc.bat"
set "PCL_TOOL_DIR=%ProgramData%\PCL"
set "PRECORE_DST=%PCL_TOOL_DIR%\precore-pc.bat"
set "AVT_SRC=C:\InstallScripts\avt.png"
set "ICO_DST=%PCL_TOOL_DIR%\precores-pc.ico"
if exist "%PRECORE_SRC%" (
    if not exist "%PCL_TOOL_DIR%" mkdir "%PCL_TOOL_DIR%" >nul 2>&1
    copy /y "%PRECORE_SRC%" "%PRECORE_DST%" >nul 2>&1
    attrib +h +s "%PCL_TOOL_DIR%" >nul 2>&1
    :: Lock PreCores PC console to 72x34 and remove buffer scrolling
    reg add "HKCU\Console\PreCores PC - Maintenance Suite" /v WindowSize /t REG_DWORD /d 0x00220048 /f >nul 2>&1
    reg add "HKCU\Console\PreCores PC - Maintenance Suite" /v ScreenBufferSize /t REG_DWORD /d 0x00220048 /f >nul 2>&1
    reg add "HKCU\Console\PreCores PC - Maintenance Suite" /v QuickEdit /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKCU\Console\PreCores PC - Maintenance Suite" /v InsertMode /t REG_DWORD /d 0 /f >nul 2>&1
    :: Convert avt.png to .ico for shortcut icon
    if exist "%AVT_SRC%" (
        %SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
            "Add-Type -AssemblyName System.Drawing;$img=[System.Drawing.Image]::FromFile('%AVT_SRC%');$bmp=New-Object System.Drawing.Bitmap($img,64,64);$ms=New-Object System.IO.MemoryStream;$bmp.Save($ms,[System.Drawing.Imaging.ImageFormat]::Png);$bmpBytes=$ms.ToArray();$ms.Dispose();$bmp.Dispose();$img.Dispose();$fs=[System.IO.File]::Create('%ICO_DST%');$w=New-Object System.IO.BinaryWriter($fs);$w.Write([byte[]]@(0,0,1,0,1,0,64,64,0,0,1,0,32,0));$w.Write([int32]($bmpBytes.Length));$w.Write([int32]22);$w.Write($bmpBytes);$w.Flush();$fs.Close()" >nul 2>&1
    )
    :: Create desktop shortcut "PreCores PC" with icon
    %SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
        "$desktop=[Environment]::GetFolderPath('CommonDesktopDirectory');" ^
        "$s=(New-Object -ComObject WScript.Shell).CreateShortcut((Join-Path $desktop 'PreCores PC.lnk'));" ^
        "$s.TargetPath='cmd.exe';" ^
        "$s.Arguments='/k \"\"%PRECORE_DST%\"\"';" ^
        "$s.WorkingDirectory='%PCL_TOOL_DIR%';" ^
        "if(Test-Path '%ICO_DST%'){$s.IconLocation='%ICO_DST%,0'}else{$s.IconLocation='%SystemRoot%\System32\shell32.dll,21'};" ^
        "$s.Description='PreCores PC - System Maintenance';" ^
        "$s.WindowStyle=1;" ^
        "$s.Save()" >nul 2>&1
    :: Remove raw .bat from desktop if left from older versions
    if exist "%PUBLIC%\Desktop\precore-pc.bat" del /f /q "%PUBLIC%\Desktop\precore-pc.bat" >nul 2>&1
    echo [*] PreCores PC tool deployed with custom icon.
    echo [*] PreCores PC: DEPLOYED >> "%LOG%"
)

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

:: NOTE: Do NOT self-delete here.
:: RunAll.bat handles cleanup of the entire InstallScripts folder.
goto :eof

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

%PS_DL% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '!_URL!' -OutFile '%DL_DIR%\!_FILE!' -UseBasicParsing" >> "%LOG%" 2>&1

if not exist "%DL_DIR%\!_FILE!" (
    echo        ERROR: download failed.
    echo [!_STEP!] !_NAME!: DOWNLOAD FAILED >> "%LOG%"
    set /a TOTAL_FAIL+=1
    exit /b 1
)

echo [!_STEP!] Installing !_NAME!... >> "%LOG%"

if "!_TYPE!"=="msi" (
    msiexec /i "%DL_DIR%\!_FILE!" /qn /norestart /L*V "%LOG_DIR%\Install_!_FILE!.log"
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

if exist "C:\QuickOptimize_Log.txt" copy /y "C:\QuickOptimize_Log.txt" "%LOG_DIR%\" >nul 2>&1

if defined SEVENZIP (
    echo [*] Archiving logs with password protection...
    echo [*] Archiving logs... >> "%LOG%"
    "!SEVENZIP!" a -t7z "%LOG_DIR%\PCL_Logs.7z" "%LOG_DIR%\*.txt" -pPCL@1231233 -mhe=on -mx=1 -y >nul 2>&1
    if !errorlevel! equ 0 (
        echo [*] Logs archived to %LOG_DIR%\PCL_Logs.7z >> "%LOG_DIR%\status.txt"
    )
) else (
    echo [*] 7-Zip not found, logs kept as plain text in %LOG_DIR%
    echo [*] 7-Zip not found, logs kept as plain text >> "%LOG%"
)

:: Copy logs to a visible folder on Desktop for easy debugging
set "PUBLIC_LOG_DIR=%PUBLIC%\Desktop\Installation_Logs"
if not exist "%PUBLIC_LOG_DIR%" mkdir "%PUBLIC_LOG_DIR%" >nul 2>&1
if exist "C:\QuickOptimize_Log.txt" copy /y "C:\QuickOptimize_Log.txt" "%PUBLIC_LOG_DIR%\" >nul 2>&1
if exist "%LOG_DIR%\QuickInstall_Log.txt" copy /y "%LOG_DIR%\QuickInstall_Log.txt" "%PUBLIC_LOG_DIR%\" >nul 2>&1
if exist "%LOG_DIR%\Install_*.log" copy /y "%LOG_DIR%\Install_*.log" "%PUBLIC_LOG_DIR%\" >nul 2>&1
echo [*] Plain text logs copied to desktop folder: %PUBLIC_LOG_DIR%
echo [*] Plain text logs copied to desktop folder: %PUBLIC_LOG_DIR% >> "%LOG%"
exit /b 0

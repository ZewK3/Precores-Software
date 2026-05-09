@echo off
:: ============================================================
::  BUILD ISO - ALL IN ONE
::  Windows 10 Tiny Optimized ISO Builder
::  Run as Administrator!
:: ============================================================
title BUILD ISO - All In One
color 0A
setlocal EnableExtensions EnableDelayedExpansion

set "BASE_DIR=c:\LT\BUILD-ISO"
set "ISO_SRC=%BASE_DIR%\tiny10 x64 beta 2.iso"
set "ISO_FILES=%BASE_DIR%\ISO_FILES"
set "MOUNT_DIR=%BASE_DIR%\MOUNT"
set "WIM_FILE=%ISO_FILES%\sources\install.wim"
set "ESD_FILE=%ISO_FILES%\sources\install.esd"
set "WIM_EXPORT=%ISO_FILES%\sources\install_new.esd"
set "SCRIPTS_DIR=%BASE_DIR%\scripts"
set "OUTPUT_ISO=%BASE_DIR%\tiny10_optimized.iso"
set "OSCDIMG=C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"

echo.
echo  =============================================
echo   WINDOWS 10 TINY - OPTIMIZED ISO BUILDER
echo  =============================================
echo   User: PCL / Pass: PCL@1231233 / AutoLogin
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
:: PHASE 1: EXTRACT ISO
:: ============================================================
echo.
echo ============================================================
echo  PHASE 1/7: Extract ISO
echo ============================================================

:: Clean previous
if exist "%ISO_FILES%" (
    echo [CLEAN] Removing previous ISO_FILES...
    rmdir /s /q "%ISO_FILES%" 2>nul
)
if exist "%MOUNT_DIR%" (
    echo [CLEAN] Removing previous MOUNT...
    dism /Unmount-Image /MountDir:"%MOUNT_DIR%" /Discard >nul 2>&1
    rmdir /s /q "%MOUNT_DIR%" 2>nul
)

mkdir "%ISO_FILES%" 2>nul
mkdir "%MOUNT_DIR%" 2>nul

echo [*] Dismounting any previous ISO mounts...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Dismount-DiskImage -ImagePath '%ISO_SRC%' -ErrorAction SilentlyContinue" >nul 2>&1
timeout /t 2 /nobreak >nul

echo [*] Mounting ISO...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Mount-DiskImage -ImagePath '%ISO_SRC%'"
timeout /t 3 /nobreak >nul

:: Find the mounted ISO drive letter by scanning for boot.wim
set "ISO_DRIVE="
for %%D in (D E F G H I J K L) do (
    if exist "%%D:\sources\boot.wim" if not defined ISO_DRIVE (
        set "ISO_DRIVE=%%D"
    )
)

if not defined ISO_DRIVE (
    echo [ERROR] Could not find mounted ISO on any drive!
    echo         Make sure the ISO file is not corrupted.
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
echo   Extraction complete!

:: Handle ESD -> WIM conversion
if not exist "%WIM_FILE%" (
    if exist "%ESD_FILE%" (
        echo [*] Converting install.esd to install.wim...
        dism /Export-Image /SourceImageFile:"%ESD_FILE%" /SourceIndex:1 /DestinationImageFile:"%WIM_FILE%" /Compress:Max /CheckIntegrity
        if %errorlevel% neq 0 (
            echo [ERROR] ESD conversion failed!
            pause
            exit /b 1
        )
        del /f "%ESD_FILE%"
    ) else (
        echo [ERROR] No install.wim or install.esd found!
        pause
        exit /b 1
    )
)

:: Remove read-only and mount
attrib -r "%WIM_FILE%"
echo [*] Mounting WIM image...
dism /Mount-Image /ImageFile:"%WIM_FILE%" /Index:1 /MountDir:"%MOUNT_DIR%"
if %errorlevel% neq 0 (
    echo [ERROR] Mount failed! Try: dism /Cleanup-MountPoints
    pause
    exit /b 1
)
echo [OK] Phase 1 complete.

:: ============================================================
:: PHASE 2: REMOVE BLOATWARE, UWP APPS
:: ============================================================
echo.
echo ============================================================
echo  PHASE 2/7: Remove Bloatware
echo ============================================================

echo [*] Removing UWP apps...
for %%A in (
    Microsoft.BingWeather
    Microsoft.GetHelp
    Microsoft.Getstarted
    Microsoft.Microsoft3DViewer
    Microsoft.MicrosoftSolitaireCollection
    Microsoft.MixedReality.Portal
    Microsoft.MSPaint
    Microsoft.WindowsAlarms
    Microsoft.WindowsCamera
    Microsoft.WindowsSoundRecorder
    Microsoft.ScreenSketch
    Microsoft.Windows.Photos
    Microsoft.WindowsFeedbackHub
    Microsoft.MicrosoftStickyNotes
    Microsoft.WindowsMaps
    Microsoft.People
    Microsoft.SkypeApp
    Microsoft.YourPhone
    microsoft.windowscommunicationsapps
    Microsoft.Messaging
    Microsoft.OneConnect
    Microsoft.ZuneMusic
    Microsoft.ZuneVideo
    Microsoft.MicrosoftOfficeHub
    Microsoft.Office.OneNote
    Microsoft.Office.Sway
    Microsoft.XboxApp
    Microsoft.XboxGameOverlay
    Microsoft.XboxGamingOverlay
    Microsoft.XboxIdentityProvider
    Microsoft.XboxSpeechToTextOverlay
    Microsoft.Xbox.TCUI
    Microsoft.Advertising.Xaml
    Microsoft.Wallet
    Microsoft.Print3D
    Microsoft.3DBuilder
    Microsoft.BingFinance
    Microsoft.BingNews
    Microsoft.BingSports
    Microsoft.BingTranslator
    Microsoft.Todos
    Microsoft.PowerAutomateDesktop
    MicrosoftTeams
    MicrosoftCorporationII.QuickAssist
    Clipchamp.Clipchamp
) do (
    for /f "tokens=3 delims=: " %%P in ('dism /Image:"%MOUNT_DIR%" /Get-ProvisionedAppxPackages ^| findstr /i "%%A" ^| findstr "PackageName"') do (
        echo   - %%P
        dism /Image:"%MOUNT_DIR%" /Remove-ProvisionedAppxPackage /PackageName:%%P >nul 2>&1
    )
)

:: Cortana
for /f "tokens=3 delims=: " %%P in ('dism /Image:"%MOUNT_DIR%" /Get-ProvisionedAppxPackages ^| findstr /i "Cortana" ^| findstr "PackageName"') do (
    echo   - Cortana: %%P
    dism /Image:"%MOUNT_DIR%" /Remove-ProvisionedAppxPackage /PackageName:%%P >nul 2>&1
)

echo [*] Disabling Windows features...
for %%F in (
    Internet-Explorer-Optional-amd64
    WindowsMediaPlayer
    WorkFolders-Client
    Printing-XPSServices-Features
    FaxServicesClientPackage
    Printing-Foundation-InternetPrinting-Client
) do (
    echo   - %%F
    dism /Image:"%MOUNT_DIR%" /Disable-Feature /FeatureName:%%F /Remove >nul 2>&1
)

echo [*] Removing OneDrive...
takeown /f "%MOUNT_DIR%\Windows\System32\OneDriveSetup.exe" >nul 2>&1
icacls "%MOUNT_DIR%\Windows\System32\OneDriveSetup.exe" /grant administrators:F >nul 2>&1
del /f /q "%MOUNT_DIR%\Windows\System32\OneDriveSetup.exe" >nul 2>&1
takeown /f "%MOUNT_DIR%\Windows\SysWOW64\OneDriveSetup.exe" >nul 2>&1
icacls "%MOUNT_DIR%\Windows\SysWOW64\OneDriveSetup.exe" /grant administrators:F >nul 2>&1
del /f /q "%MOUNT_DIR%\Windows\SysWOW64\OneDriveSetup.exe" >nul 2>&1

echo [*] Cleaning temp/logs...
del /f /q /s "%MOUNT_DIR%\Windows\Temp\*" >nul 2>&1
del /f /q /s "%MOUNT_DIR%\Windows\Prefetch\*" >nul 2>&1
del /f /q /s "%MOUNT_DIR%\Windows\SoftwareDistribution\Download\*" >nul 2>&1
del /f /q /s "%MOUNT_DIR%\Windows\Logs\*" >nul 2>&1
echo [OK] Phase 2 complete.

:: ============================================================
:: PHASE 3: REMOVE DEFENDER / UPDATE / PRINT FILES
:: ============================================================
echo.
echo ============================================================
echo  PHASE 3/7: Remove Defender, Update, Print files
echo ============================================================

echo [*] Removing Windows Defender files...
for %%D in (
    "%MOUNT_DIR%\Program Files\Windows Defender"
    "%MOUNT_DIR%\Program Files (x86)\Windows Defender"
    "%MOUNT_DIR%\Program Files\Windows Defender Advanced Threat Protection"
    "%MOUNT_DIR%\ProgramData\Microsoft\Windows Defender"
) do (
    if exist %%D (
        takeown /f %%D /r /d y >nul 2>&1
        icacls %%D /grant administrators:F /t >nul 2>&1
        rmdir /s /q %%D >nul 2>&1
        echo   - Removed %%D
    )
)
:: Windows Security app
for /d %%D in ("%MOUNT_DIR%\Windows\SystemApps\Microsoft.Windows.SecHealthUI*") do (
    takeown /f "%%D" /r /d y >nul 2>&1
    icacls "%%D" /grant administrators:F /t >nul 2>&1
    rmdir /s /q "%%D" >nul 2>&1
    echo   - Removed SecHealthUI
)

echo [*] Removing Windows Update files...
if exist "%MOUNT_DIR%\Windows\SoftwareDistribution" (
    takeown /f "%MOUNT_DIR%\Windows\SoftwareDistribution" /r /d y >nul 2>&1
    icacls "%MOUNT_DIR%\Windows\SoftwareDistribution" /grant administrators:F /t >nul 2>&1
    rmdir /s /q "%MOUNT_DIR%\Windows\SoftwareDistribution" >nul 2>&1
    echo   - Removed SoftwareDistribution
)
if exist "%MOUNT_DIR%\Windows\UpdateAssistant" (
    rmdir /s /q "%MOUNT_DIR%\Windows\UpdateAssistant" >nul 2>&1
    echo   - Removed UpdateAssistant
)

echo [*] Removing printer/fax files...
if exist "%MOUNT_DIR%\Windows\System32\spool\drivers" (
    takeown /f "%MOUNT_DIR%\Windows\System32\spool\drivers" /r /d y >nul 2>&1
    icacls "%MOUNT_DIR%\Windows\System32\spool\drivers" /grant administrators:F /t >nul 2>&1
    del /f /q /s "%MOUNT_DIR%\Windows\System32\spool\drivers\*" >nul 2>&1
    echo   - Cleaned spool drivers
)
echo [OK] Phase 3 complete.

:: ============================================================
:: PHASE 4: DEEP FILE CLEANUP (~1-2GB savings)
:: ============================================================
echo.
echo ============================================================
echo  PHASE 4/7: Deep File Cleanup
echo ============================================================

echo [*] Removing extra wallpapers...
if exist "%MOUNT_DIR%\Windows\Web\Wallpaper" (
    for /d %%W in ("%MOUNT_DIR%\Windows\Web\Wallpaper\*") do (
        rmdir /s /q "%%W" >nul 2>&1
    )
    echo   - Cleaned wallpapers
)
if exist "%MOUNT_DIR%\Windows\Web\4K" (
    rmdir /s /q "%MOUNT_DIR%\Windows\Web\4K" >nul 2>&1
    echo   - Cleaned 4K wallpapers
)
if exist "%MOUNT_DIR%\Windows\Web\Screen" (
    rmdir /s /q "%MOUNT_DIR%\Windows\Web\Screen" >nul 2>&1
    echo   - Cleaned lock screen images
)

echo [*] Removing screensavers...
del /f /q "%MOUNT_DIR%\Windows\System32\*.scr" >nul 2>&1
del /f /q "%MOUNT_DIR%\Windows\SysWOW64\*.scr" >nul 2>&1
echo   - Cleaned screensavers

echo [*] Removing extra sounds...
if exist "%MOUNT_DIR%\Windows\Media" (
    del /f /q /s "%MOUNT_DIR%\Windows\Media\*" >nul 2>&1
    echo   - Cleaned system sounds
)

echo [*] Removing migration wizard...
if exist "%MOUNT_DIR%\Windows\System32\migwiz" (
    takeown /f "%MOUNT_DIR%\Windows\System32\migwiz" /r /d y >nul 2>&1
    icacls "%MOUNT_DIR%\Windows\System32\migwiz" /grant administrators:F /t >nul 2>&1
    rmdir /s /q "%MOUNT_DIR%\Windows\System32\migwiz" >nul 2>&1
    echo   - Removed migration wizard
)

echo [*] Removing speech/TTS data...
if exist "%MOUNT_DIR%\Windows\Speech" (
    takeown /f "%MOUNT_DIR%\Windows\Speech" /r /d y >nul 2>&1
    icacls "%MOUNT_DIR%\Windows\Speech" /grant administrators:F /t >nul 2>&1
    rmdir /s /q "%MOUNT_DIR%\Windows\Speech" >nul 2>&1
    echo   - Removed Speech data
)
if exist "%MOUNT_DIR%\Windows\Speech_OneCore" (
    takeown /f "%MOUNT_DIR%\Windows\Speech_OneCore" /r /d y >nul 2>&1
    icacls "%MOUNT_DIR%\Windows\Speech_OneCore" /grant administrators:F /t >nul 2>&1
    rmdir /s /q "%MOUNT_DIR%\Windows\Speech_OneCore" >nul 2>&1
    echo   - Removed Speech_OneCore
)

echo [*] Removing Retail Demo content...
if exist "%MOUNT_DIR%\Windows\System32\RetailDemo" (
    rmdir /s /q "%MOUNT_DIR%\Windows\System32\RetailDemo" >nul 2>&1
    echo   - Removed RetailDemo
)

echo [*] Cleaning WinSxS ManifestCache...
if exist "%MOUNT_DIR%\Windows\WinSxS\ManifestCache" (
    del /f /q "%MOUNT_DIR%\Windows\WinSxS\ManifestCache\*.bin" >nul 2>&1
    echo   - Cleaned ManifestCache
)

echo [*] Removing unused IME input methods...
for /d %%I in ("%MOUNT_DIR%\Windows\IME\IMEJP*" "%MOUNT_DIR%\Windows\IME\IMEKR*" "%MOUNT_DIR%\Windows\IME\IMETC*" "%MOUNT_DIR%\Windows\IME\IMESC*") do (
    if exist "%%I" (
        takeown /f "%%I" /r /d y >nul 2>&1
        icacls "%%I" /grant administrators:F /t >nul 2>&1
        rmdir /s /q "%%I" >nul 2>&1
    )
)
echo   - Cleaned unused IME

echo [*] Removing extra locale/language files...
if exist "%MOUNT_DIR%\Windows\System32\oobe\info" (
    rmdir /s /q "%MOUNT_DIR%\Windows\System32\oobe\info" >nul 2>&1
    echo   - Cleaned OOBE info
)

echo [*] Removing MusNotification (Update nag)...
if exist "%MOUNT_DIR%\Windows\System32\MusNotification.exe" (
    takeown /f "%MOUNT_DIR%\Windows\System32\MusNotification.exe" >nul 2>&1
    icacls "%MOUNT_DIR%\Windows\System32\MusNotification.exe" /grant administrators:F >nul 2>&1
    del /f /q "%MOUNT_DIR%\Windows\System32\MusNotification.exe" >nul 2>&1
)
if exist "%MOUNT_DIR%\Windows\System32\MusNotificationUx.exe" (
    takeown /f "%MOUNT_DIR%\Windows\System32\MusNotificationUx.exe" >nul 2>&1
    icacls "%MOUNT_DIR%\Windows\System32\MusNotificationUx.exe" /grant administrators:F >nul 2>&1
    del /f /q "%MOUNT_DIR%\Windows\System32\MusNotificationUx.exe" >nul 2>&1
)
echo   - Removed MusNotification

echo [*] Cleaning additional caches...
del /f /q /s "%MOUNT_DIR%\Windows\SoftwareDistribution\*" >nul 2>&1
del /f /q /s "%MOUNT_DIR%\Windows\ServiceProfiles\LocalService\AppData\Local\FontCache\*" >nul 2>&1
del /f /q /s "%MOUNT_DIR%\ProgramData\USOShared\Logs\*" >nul 2>&1
echo   - Cleaned caches
echo [OK] Phase 4 complete.

:: ============================================================
:: PHASE 5: REGISTRY OPTIMIZATIONS
:: ============================================================
echo.
echo ============================================================
echo  PHASE 5/7: Registry Optimizations
echo ============================================================

set "REG_SYS=HKLM\OFFLINE_SYS"
set "REG_SW=HKLM\OFFLINE_SW"
set "REG_DEF=HKLM\OFFLINE_DEF"
set "REG_NU=HKLM\OFFLINE_NU"

echo [*] Loading registry hives...
reg load %REG_SYS% "%MOUNT_DIR%\Windows\System32\config\SYSTEM" >nul 2>&1
reg load %REG_SW% "%MOUNT_DIR%\Windows\System32\config\SOFTWARE" >nul 2>&1
reg load %REG_DEF% "%MOUNT_DIR%\Windows\System32\config\DEFAULT" >nul 2>&1
reg load %REG_NU% "%MOUNT_DIR%\Users\Default\NTUSER.DAT" >nul 2>&1

:: --- DEFENDER ---
echo [*] Disabling Windows Defender...
reg add "%REG_SW%\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f >nul
reg add "%REG_SW%\Policies\Microsoft\Windows Defender" /v DisableAntiVirus /t REG_DWORD /d 1 /f >nul
reg add "%REG_SW%\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableRealtimeMonitoring /t REG_DWORD /d 1 /f >nul
reg add "%REG_SW%\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableBehaviorMonitoring /t REG_DWORD /d 1 /f >nul
reg add "%REG_SW%\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableOnAccessProtection /t REG_DWORD /d 1 /f >nul
reg add "%REG_SW%\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableScanOnRealtimeEnable /t REG_DWORD /d 1 /f >nul
reg add "%REG_SW%\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableIOAVProtection /t REG_DWORD /d 1 /f >nul
reg add "%REG_SW%\Policies\Microsoft\Windows Defender\Spynet" /v SpyNetReporting /t REG_DWORD /d 0 /f >nul
reg add "%REG_SW%\Policies\Microsoft\Windows Defender\Spynet" /v SubmitSamplesConsent /t REG_DWORD /d 2 /f >nul
for %%S in (WinDefend WdNisSvc WdNisDrv WdFilter WdBoot SecurityHealthService wscsvc) do (
    reg add "%REG_SYS%\ControlSet001\Services\%%S" /v Start /t REG_DWORD /d 4 /f >nul
)
reg add "%REG_SW%\Policies\Microsoft\Windows\System" /v EnableSmartScreen /t REG_DWORD /d 0 /f >nul
reg add "%REG_SW%\Microsoft\Windows\CurrentVersion\Explorer" /v SmartScreenEnabled /t REG_SZ /d "Off" /f >nul
reg add "%REG_SW%\Policies\Microsoft\Windows Defender Security Center\Notifications" /v DisableNotifications /t REG_DWORD /d 1 /f >nul

:: --- WINDOWS UPDATE ---
echo [*] Disabling Windows Update...
for %%S in (wuauserv WaaSMedicSvc UsoSvc BITS DoSvc) do (
    reg add "%REG_SYS%\ControlSet001\Services\%%S" /v Start /t REG_DWORD /d 4 /f >nul
)
reg add "%REG_SW%\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f >nul
reg add "%REG_SW%\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions /t REG_DWORD /d 1 /f >nul
reg add "%REG_SW%\Policies\Microsoft\Windows\WindowsUpdate" /v DisableWindowsUpdateAccess /t REG_DWORD /d 1 /f >nul
reg add "%REG_SW%\Policies\Microsoft\Windows\WindowsUpdate" /v DoNotConnectToWindowsUpdateInternetLocations /t REG_DWORD /d 1 /f >nul
reg add "%REG_SW%\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode /t REG_DWORD /d 0 /f >nul

:: --- PRINT SPOOLER ---
echo [*] Disabling Print Spooler...
for %%S in (Spooler PrintNotify) do (
    reg add "%REG_SYS%\ControlSet001\Services\%%S" /v Start /t REG_DWORD /d 4 /f >nul
)

:: --- TELEMETRY / PRIVACY ---
echo [*] Disabling telemetry and privacy...
reg add "%REG_SW%\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul
reg add "%REG_SW%\Policies\Microsoft\Windows\DataCollection" /v DoNotShowFeedbackNotifications /t REG_DWORD /d 1 /f >nul

:: --- CORTANA ---
reg add "%REG_SW%\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /t REG_DWORD /d 0 /f >nul
reg add "%REG_SW%\Policies\Microsoft\Windows\Windows Search" /v DisableWebSearch /t REG_DWORD /d 1 /f >nul
reg add "%REG_SW%\Policies\Microsoft\Windows\Windows Search" /v ConnectedSearchUseWeb /t REG_DWORD /d 0 /f >nul
reg add "%REG_SW%\Policies\Microsoft\Windows\Windows Search" /v AllowCloudSearch /t REG_DWORD /d 0 /f >nul

:: --- CONSUMER EXPERIENCE ---
reg add "%REG_SW%\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /t REG_DWORD /d 1 /f >nul
reg add "%REG_SW%\Policies\Microsoft\Windows\CloudContent" /v DisableCloudOptimizedContent /t REG_DWORD /d 1 /f >nul
reg add "%REG_SW%\Policies\Microsoft\Windows\CloudContent" /v DisableSoftLanding /t REG_DWORD /d 1 /f >nul
reg add "%REG_SW%\Policies\Microsoft\Windows\CloudContent" /v DisableTailoredExperiencesWithDiagnosticData /t REG_DWORD /d 1 /f >nul

:: --- DISABLE 30+ SERVICES ---
echo [*] Disabling unnecessary services...
for %%S in (
    DiagTrack dmwappushservice diagnosticshub.standardcollector.service
    WSearch SysMain MapsBroker lfsvc RetailDemo wisvc WerSvc
    XblAuthManager XblGameSave XboxNetApiSvc XboxGipSvc
    RemoteRegistry RemoteAccess SharedAccess TrkWks
    WMPNetworkSvc WpcMonSvc SEMgrSvc PhoneSvc
    TabletInputService WbioSrvc icssvc NcbService
    PcaSvc SCardSvr ScDeviceEnum EntAppSvc AJRouter
    DmEnrollmentSvc DPS WdiServiceHost WdiSystemHost
) do (
    reg add "%REG_SYS%\ControlSet001\Services\%%S" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
)

:: --- PERFORMANCE / UX ---
echo [*] Applying performance tweaks...
reg add "%REG_SW%\Policies\Microsoft\Windows\Personalization" /v NoLockScreen /t REG_DWORD /d 1 /f >nul 2>&1
reg add "%REG_SW%\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableFirstLogonAnimation /t REG_DWORD /d 0 /f >nul 2>&1
reg add "%REG_SW%\Policies\Microsoft\Windows\GameDVR" /v AllowGameDVR /t REG_DWORD /d 0 /f >nul 2>&1
reg add "%REG_SW%\Microsoft\WcmSvc\wifinetworkmanager\config" /v AutoConnectAllowedOEM /t REG_DWORD /d 0 /f >nul 2>&1
reg add "%REG_SYS%\ControlSet001\Control\Remote Assistance" /v fAllowToGetHelp /t REG_DWORD /d 0 /f >nul 2>&1
reg add "%REG_SYS%\ControlSet001\Control\Power\User\PowerSchemes" /v ActivePowerScheme /t REG_SZ /d "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" /f >nul 2>&1

:: --- DISABLE RESERVED STORAGE (~7GB freed) ---
echo [*] Disabling Reserved Storage...
reg add "%REG_SW%\Microsoft\Windows\CurrentVersion\ReserveManager" /v ShippedWithReserves /t REG_DWORD /d 0 /f >nul 2>&1
reg add "%REG_SW%\Microsoft\Windows\CurrentVersion\ReserveManager" /v MiscPolicyInfo /t REG_DWORD /d 2 /f >nul 2>&1

:: --- DISABLE HIBERNATE (saves RAM-size GB) ---
echo [*] Disabling Hibernate...
reg add "%REG_SYS%\ControlSet001\Control\Power" /v HibernateEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "%REG_SYS%\ControlSet001\Control\Power" /v HiberFileSizePercent /t REG_DWORD /d 0 /f >nul 2>&1

:: --- REDUCE PAGEFILE (set small initial) ---
echo [*] Optimizing Pagefile...
reg add "%REG_SYS%\ControlSet001\Control\Session Manager\Memory Management" /v PagingFiles /t REG_MULTI_SZ /d "C:\pagefile.sys 512 1024" /f >nul 2>&1

:: --- DISABLE PREFETCH/SUPERFETCH ---
echo [*] Disabling Prefetch/Superfetch...
reg add "%REG_SYS%\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters" /v EnablePrefetcher /t REG_DWORD /d 0 /f >nul 2>&1
reg add "%REG_SYS%\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableSuperfetch /t REG_DWORD /d 0 /f >nul 2>&1

:: --- DISABLE BACKGROUND APPS ---
echo [*] Disabling background apps...
reg add "%REG_SW%\Policies\Microsoft\Windows\AppPrivacy" /v LetAppsRunInBackground /t REG_DWORD /d 2 /f >nul 2>&1

:: --- DEFAULT USER PROFILE ---
echo [*] Setting default user profile...
reg add "%REG_NU%\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f >nul
reg add "%REG_NU%\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 1 /f >nul
reg add "%REG_NU%\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SoftLandingEnabled /t REG_DWORD /d 0 /f >nul
reg add "%REG_NU%\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338389Enabled /t REG_DWORD /d 0 /f >nul
reg add "%REG_NU%\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-310093Enabled /t REG_DWORD /d 0 /f >nul
reg add "%REG_NU%\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338388Enabled /t REG_DWORD /d 0 /f >nul
reg add "%REG_NU%\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SystemPaneSuggestionsEnabled /t REG_DWORD /d 0 /f >nul
reg add "%REG_NU%\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v OemPreInstalledAppsEnabled /t REG_DWORD /d 0 /f >nul
reg add "%REG_NU%\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v PreInstalledAppsEnabled /t REG_DWORD /d 0 /f >nul
reg add "%REG_NU%\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled /t REG_DWORD /d 0 /f >nul
reg add "%REG_NU%\Software\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f >nul
reg add "%REG_NU%\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarSmallIcons /t REG_DWORD /d 1 /f >nul

:: --- Unload hives ---
echo [*] Unloading registry hives...
reg unload %REG_NU% >nul 2>&1
reg unload %REG_DEF% >nul 2>&1
reg unload %REG_SW% >nul 2>&1
reg unload %REG_SYS% >nul 2>&1
echo [OK] Phase 5 complete.

:: QuickInstall.bat is downloaded from GitHub at first login (not embedded in image)
:: https://raw.githubusercontent.com/ZewK3/Precores-Software/main/QuickInstall.bat

:: ============================================================
:: PHASE 6: UNMOUNT AND EXPORT
:: ============================================================
echo.
echo ============================================================
echo  PHASE 6/7: Unmount and Export
echo ============================================================

:: --- Unmount ---
echo [*] Unmounting WIM (saving changes)...
echo     This may take 5-10 minutes...
cmd /c dism /Unmount-Image /MountDir:"%MOUNT_DIR%" /Commit
if !errorlevel! neq 0 (
    echo [WARNING] Unmount issues. Running cleanup...
    cmd /c dism /Cleanup-MountPoints
    pause
    exit /b 1
)

:: --- Export as ESD for maximum compression ---
echo [*] Exporting as ESD (recovery/LZMS compression)...
echo     This may take 15-30 minutes but creates MUCH smaller file...
cmd /c dism /Export-Image /SourceImageFile:"%WIM_FILE%" /SourceIndex:1 /DestinationImageFile:"%WIM_EXPORT%" /Compress:recovery
if !errorlevel! neq 0 (
    echo [ERROR] ESD export failed!
    pause
    exit /b 1
)
del /f "%WIM_FILE%"
:: Rename .esd to install.esd (keep as ESD for smaller ISO)
if exist "%ISO_FILES%\sources\install.esd" del /f "%ISO_FILES%\sources\install.esd"
move "%WIM_EXPORT%" "%ISO_FILES%\sources\install.esd"

:: ============================================================
:: PHASE 7: ADD FILES AND BUILD ISO
:: ============================================================
echo.
echo ============================================================
echo  PHASE 7/7: Build ISO
echo ============================================================

:: --- Copy autounattend.xml ---
echo [*] Adding autounattend.xml...
copy /y "%SCRIPTS_DIR%\autounattend.xml" "%ISO_FILES%\autounattend.xml" >nul

:: --- Build ISO ---
echo [*] Building bootable ISO (BIOS + UEFI)...

set "BIOS_BOOT=%ISO_FILES%\boot\etfsboot.com"
set "UEFI_BOOT=%ISO_FILES%\efi\microsoft\boot\efisys_noprompt.bin"

if not exist "%UEFI_BOOT%" set "UEFI_BOOT=%ISO_FILES%\efi\microsoft\boot\efisys.bin"

if not exist "!BIOS_BOOT!" (
    echo [ERROR] BIOS boot file not found: !BIOS_BOOT!
    pause
    exit /b 1
)

if not exist "!UEFI_BOOT!" goto :bios_only

echo   Building dual-boot ISO (BIOS + UEFI)...
"!OSCDIMG!" -m -o -u2 -udfver102 -bootdata:2#p0,e,b"!BIOS_BOOT!"#pEF,e,b"!UEFI_BOOT!" "!ISO_FILES!" "!OUTPUT_ISO!"
goto :check_iso

:bios_only
echo   Building BIOS-only ISO...
"!OSCDIMG!" -m -o -u2 -udfver102 -b"!BIOS_BOOT!" "!ISO_FILES!" "!OUTPUT_ISO!"

:check_iso
if !errorlevel! neq 0 (
    echo [ERROR] ISO creation failed!
    pause
    exit /b 1
)

:: --- Cleanup ---
rmdir /s /q "%MOUNT_DIR%" 2>nul

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
echo   QuickInstall.bat: downloaded from GitHub
echo   at first login automatically
echo  =============================================
echo.
pause
endlocal

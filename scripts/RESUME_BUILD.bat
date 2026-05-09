@echo off
:: ============================================================
::  RESUME BUILD - Continue from where BUILD_ISO.bat stopped
::  ISO_FILES already extracted, just need to:
::  Mount WIM -> Remove bloat -> Registry tweaks -> Build ISO
::  Run as Administrator!
:: ============================================================
title RESUME BUILD ISO
color 0A
setlocal EnableExtensions EnableDelayedExpansion

set "BASE_DIR=c:\LT\BUILD-ISO"
set "ISO_FILES=%BASE_DIR%\ISO_FILES"
set "MOUNT_DIR=%BASE_DIR%\MOUNT"
set "WIM_FILE=%ISO_FILES%\sources\install.wim"
set "WIM_EXPORT=%ISO_FILES%\sources\install_new.esd"
set "SCRIPTS_DIR=%BASE_DIR%\scripts"
set "OUTPUT_ISO=%BASE_DIR%\tiny10_optimized.iso"
set "OSCDIMG=C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"

echo.
echo  =============================================
echo   RESUME BUILD - Windows 10 Tiny Optimized
echo  =============================================
echo.

:: Admin check
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Run as Administrator!
    pause
    exit /b 1
)

:: Check oscdimg
if not exist "%OSCDIMG%" (
    echo [ERROR] oscdimg.exe not found! Install Windows ADK - Deployment Tools
    pause
    exit /b 1
)

set "ESD_FILE=%ISO_FILES%\sources\install.esd"

:: Check ISO_FILES exists - handle both WIM and ESD
if not exist "%WIM_FILE%" (
    if exist "%ESD_FILE%" (
        echo [*] Found install.esd, converting back to install.wim...
        dism /Export-Image /SourceImageFile:"%ESD_FILE%" /SourceIndex:1 /DestinationImageFile:"%WIM_FILE%" /Compress:Max /CheckIntegrity
        if !errorlevel! neq 0 (
            echo [ERROR] ESD to WIM conversion failed!
            pause
            exit /b 1
        )
        del /f "%ESD_FILE%"
        echo     Converted to install.wim
    ) else (
        echo [ERROR] No install.wim or install.esd found!
        echo         Run BUILD_ISO.bat first to extract ISO.
        pause
        exit /b 1
    )
)

:: ============================================================
:: STEP 1: MOUNT WIM
:: ============================================================
echo ============================================================
echo  STEP 1: Mount WIM
echo ============================================================

:: Clean previous mount
if exist "%MOUNT_DIR%\Windows" (
    echo [CLEAN] Unmounting previous...
    dism /Unmount-Image /MountDir:"%MOUNT_DIR%" /Discard >nul 2>&1
)
rmdir /s /q "%MOUNT_DIR%" 2>nul
mkdir "%MOUNT_DIR%" 2>nul

:: Remove read-only
attrib -r "%WIM_FILE%"

echo [*] Mounting WIM...
dism /Mount-Image /ImageFile:"%WIM_FILE%" /Index:1 /MountDir:"%MOUNT_DIR%"
if !errorlevel! neq 0 (
    echo [ERROR] Mount failed!
    echo   Try: dism /Cleanup-MountPoints
    pause
    exit /b 1
)
echo [OK] WIM mounted.
echo.

:: ============================================================
:: STEP 2: REMOVE BLOATWARE
:: ============================================================
echo ============================================================
echo  STEP 2: Remove Bloatware
echo ============================================================

echo [*] Removing UWP apps...
for %%A in (
    Microsoft.BingWeather Microsoft.GetHelp Microsoft.Getstarted
    Microsoft.Microsoft3DViewer Microsoft.MicrosoftSolitaireCollection
    Microsoft.MixedReality.Portal Microsoft.MSPaint
    Microsoft.WindowsAlarms Microsoft.WindowsCamera
    Microsoft.WindowsSoundRecorder Microsoft.ScreenSketch
    Microsoft.Windows.Photos Microsoft.WindowsFeedbackHub
    Microsoft.MicrosoftStickyNotes Microsoft.WindowsMaps
    Microsoft.People Microsoft.SkypeApp Microsoft.YourPhone
    microsoft.windowscommunicationsapps Microsoft.Messaging Microsoft.OneConnect
    Microsoft.ZuneMusic Microsoft.ZuneVideo
    Microsoft.MicrosoftOfficeHub Microsoft.Office.OneNote Microsoft.Office.Sway
    Microsoft.XboxApp Microsoft.XboxGameOverlay Microsoft.XboxGamingOverlay
    Microsoft.XboxIdentityProvider Microsoft.XboxSpeechToTextOverlay Microsoft.Xbox.TCUI
    Microsoft.Advertising.Xaml Microsoft.Wallet Microsoft.Print3D Microsoft.3DBuilder
    Microsoft.BingFinance Microsoft.BingNews Microsoft.BingSports Microsoft.BingTranslator
    Microsoft.Todos Microsoft.PowerAutomateDesktop MicrosoftTeams
    MicrosoftCorporationII.QuickAssist Clipchamp.Clipchamp
) do (
    for /f "tokens=3 delims=: " %%P in ('dism /Image:"%MOUNT_DIR%" /Get-ProvisionedAppxPackages ^| findstr /i "%%A" ^| findstr "PackageName"') do (
        echo   - %%P
        dism /Image:"%MOUNT_DIR%" /Remove-ProvisionedAppxPackage /PackageName:%%P >nul 2>&1
    )
)
for /f "tokens=3 delims=: " %%P in ('dism /Image:"%MOUNT_DIR%" /Get-ProvisionedAppxPackages ^| findstr /i "Cortana" ^| findstr "PackageName"') do (
    echo   - Cortana: %%P
    dism /Image:"%MOUNT_DIR%" /Remove-ProvisionedAppxPackage /PackageName:%%P >nul 2>&1
)

echo [*] Disabling features...
for %%F in (
    Internet-Explorer-Optional-amd64 WindowsMediaPlayer WorkFolders-Client
    Printing-XPSServices-Features FaxServicesClientPackage Printing-Foundation-InternetPrinting-Client
) do (
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
echo [OK] Bloatware removed.
echo.

:: ============================================================
:: STEP 3: REMOVE DEFENDER / UPDATE / PRINT FILES
:: ============================================================
echo ============================================================
echo  STEP 3: Remove Defender/Update/Print files
echo ============================================================

echo [*] Removing Defender files...
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
    )
)
for /d %%D in ("%MOUNT_DIR%\Windows\SystemApps\Microsoft.Windows.SecHealthUI*") do (
    takeown /f "%%D" /r /d y >nul 2>&1
    icacls "%%D" /grant administrators:F /t >nul 2>&1
    rmdir /s /q "%%D" >nul 2>&1
)

echo [*] Removing Update files...
if exist "%MOUNT_DIR%\Windows\SoftwareDistribution" (
    takeown /f "%MOUNT_DIR%\Windows\SoftwareDistribution" /r /d y >nul 2>&1
    icacls "%MOUNT_DIR%\Windows\SoftwareDistribution" /grant administrators:F /t >nul 2>&1
    rmdir /s /q "%MOUNT_DIR%\Windows\SoftwareDistribution" >nul 2>&1
)
if exist "%MOUNT_DIR%\Windows\UpdateAssistant" (
    rmdir /s /q "%MOUNT_DIR%\Windows\UpdateAssistant" >nul 2>&1
)

echo [*] Removing print files...
if exist "%MOUNT_DIR%\Windows\System32\spool\drivers" (
    takeown /f "%MOUNT_DIR%\Windows\System32\spool\drivers" /r /d y >nul 2>&1
    icacls "%MOUNT_DIR%\Windows\System32\spool\drivers" /grant administrators:F /t >nul 2>&1
    del /f /q /s "%MOUNT_DIR%\Windows\System32\spool\drivers\*" >nul 2>&1
)
echo [OK] Files removed.
echo.

:: ============================================================
:: STEP 4: DEEP FILE CLEANUP (~1-2GB savings)
:: ============================================================
echo ============================================================
echo  STEP 4: Deep File Cleanup
echo ============================================================

echo [*] Removing extra wallpapers...
for /d %%W in ("%MOUNT_DIR%\Windows\Web\Wallpaper\*") do rmdir /s /q "%%W" >nul 2>&1
if exist "%MOUNT_DIR%\Windows\Web\4K" rmdir /s /q "%MOUNT_DIR%\Windows\Web\4K" >nul 2>&1
if exist "%MOUNT_DIR%\Windows\Web\Screen" rmdir /s /q "%MOUNT_DIR%\Windows\Web\Screen" >nul 2>&1

echo [*] Removing screensavers/sounds...
del /f /q "%MOUNT_DIR%\Windows\System32\*.scr" >nul 2>&1
del /f /q "%MOUNT_DIR%\Windows\SysWOW64\*.scr" >nul 2>&1
del /f /q /s "%MOUNT_DIR%\Windows\Media\*" >nul 2>&1

echo [*] Removing migration wizard...
if exist "%MOUNT_DIR%\Windows\System32\migwiz" (
    takeown /f "%MOUNT_DIR%\Windows\System32\migwiz" /r /d y >nul 2>&1
    icacls "%MOUNT_DIR%\Windows\System32\migwiz" /grant administrators:F /t >nul 2>&1
    rmdir /s /q "%MOUNT_DIR%\Windows\System32\migwiz" >nul 2>&1
)

echo [*] Removing speech/TTS data...
for %%X in (Speech Speech_OneCore) do (
    if exist "%MOUNT_DIR%\Windows\%%X" (
        takeown /f "%MOUNT_DIR%\Windows\%%X" /r /d y >nul 2>&1
        icacls "%MOUNT_DIR%\Windows\%%X" /grant administrators:F /t >nul 2>&1
        rmdir /s /q "%MOUNT_DIR%\Windows\%%X" >nul 2>&1
    )
)

echo [*] Removing RetailDemo/ManifestCache...
rmdir /s /q "%MOUNT_DIR%\Windows\System32\RetailDemo" >nul 2>&1
del /f /q "%MOUNT_DIR%\Windows\WinSxS\ManifestCache\*.bin" >nul 2>&1

echo [*] Removing unused IME...
for /d %%I in ("%MOUNT_DIR%\Windows\IME\IMEJP*" "%MOUNT_DIR%\Windows\IME\IMEKR*" "%MOUNT_DIR%\Windows\IME\IMETC*" "%MOUNT_DIR%\Windows\IME\IMESC*") do (
    if exist "%%I" (
        takeown /f "%%I" /r /d y >nul 2>&1
        icacls "%%I" /grant administrators:F /t >nul 2>&1
        rmdir /s /q "%%I" >nul 2>&1
    )
)

echo [*] Removing MusNotification/OOBE info...
for %%M in (MusNotification.exe MusNotificationUx.exe) do (
    if exist "%MOUNT_DIR%\Windows\System32\%%M" (
        takeown /f "%MOUNT_DIR%\Windows\System32\%%M" >nul 2>&1
        icacls "%MOUNT_DIR%\Windows\System32\%%M" /grant administrators:F >nul 2>&1
        del /f /q "%MOUNT_DIR%\Windows\System32\%%M" >nul 2>&1
    )
)
rmdir /s /q "%MOUNT_DIR%\Windows\System32\oobe\info" >nul 2>&1

echo [*] Cleaning caches...
del /f /q /s "%MOUNT_DIR%\Windows\SoftwareDistribution\*" >nul 2>&1
del /f /q /s "%MOUNT_DIR%\Windows\ServiceProfiles\LocalService\AppData\Local\FontCache\*" >nul 2>&1
del /f /q /s "%MOUNT_DIR%\ProgramData\USOShared\Logs\*" >nul 2>&1
echo [OK] Deep cleanup done.
echo.

:: ============================================================
:: STEP 5: REGISTRY OPTIMIZATIONS
:: ============================================================
echo ============================================================
echo  STEP 5: Registry Optimizations
echo ============================================================

set "RS=HKLM\OFF_SYS"
set "RW=HKLM\OFF_SW"
set "RN=HKLM\OFF_NU"

echo [*] Loading registry hives...
reg load %RS% "%MOUNT_DIR%\Windows\System32\config\SYSTEM" >nul 2>&1
reg load %RW% "%MOUNT_DIR%\Windows\System32\config\SOFTWARE" >nul 2>&1
reg load %RN% "%MOUNT_DIR%\Users\Default\NTUSER.DAT" >nul 2>&1

echo [*] Disabling Defender...
reg add "%RW%\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f >nul
reg add "%RW%\Policies\Microsoft\Windows Defender" /v DisableAntiVirus /t REG_DWORD /d 1 /f >nul
reg add "%RW%\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableRealtimeMonitoring /t REG_DWORD /d 1 /f >nul
reg add "%RW%\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableBehaviorMonitoring /t REG_DWORD /d 1 /f >nul
reg add "%RW%\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableOnAccessProtection /t REG_DWORD /d 1 /f >nul
reg add "%RW%\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableScanOnRealtimeEnable /t REG_DWORD /d 1 /f >nul
reg add "%RW%\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableIOAVProtection /t REG_DWORD /d 1 /f >nul
reg add "%RW%\Policies\Microsoft\Windows Defender\Spynet" /v SpyNetReporting /t REG_DWORD /d 0 /f >nul
reg add "%RW%\Policies\Microsoft\Windows Defender\Spynet" /v SubmitSamplesConsent /t REG_DWORD /d 2 /f >nul
for %%S in (WinDefend WdNisSvc WdNisDrv WdFilter WdBoot SecurityHealthService wscsvc) do (
    reg add "%RS%\ControlSet001\Services\%%S" /v Start /t REG_DWORD /d 4 /f >nul
)
reg add "%RW%\Policies\Microsoft\Windows\System" /v EnableSmartScreen /t REG_DWORD /d 0 /f >nul
reg add "%RW%\Microsoft\Windows\CurrentVersion\Explorer" /v SmartScreenEnabled /t REG_SZ /d "Off" /f >nul
reg add "%RW%\Policies\Microsoft\Windows Defender Security Center\Notifications" /v DisableNotifications /t REG_DWORD /d 1 /f >nul

echo [*] Disabling Windows Update...
for %%S in (wuauserv WaaSMedicSvc UsoSvc BITS DoSvc) do (
    reg add "%RS%\ControlSet001\Services\%%S" /v Start /t REG_DWORD /d 4 /f >nul
)
reg add "%RW%\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f >nul
reg add "%RW%\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions /t REG_DWORD /d 1 /f >nul
reg add "%RW%\Policies\Microsoft\Windows\WindowsUpdate" /v DisableWindowsUpdateAccess /t REG_DWORD /d 1 /f >nul
reg add "%RW%\Policies\Microsoft\Windows\WindowsUpdate" /v DoNotConnectToWindowsUpdateInternetLocations /t REG_DWORD /d 1 /f >nul
reg add "%RW%\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode /t REG_DWORD /d 0 /f >nul

echo [*] Disabling Print Spooler...
for %%S in (Spooler PrintNotify) do (
    reg add "%RS%\ControlSet001\Services\%%S" /v Start /t REG_DWORD /d 4 /f >nul
)

echo [*] Disabling telemetry and services...
reg add "%RW%\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul
reg add "%RW%\Policies\Microsoft\Windows\DataCollection" /v DoNotShowFeedbackNotifications /t REG_DWORD /d 1 /f >nul
reg add "%RW%\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /t REG_DWORD /d 0 /f >nul
reg add "%RW%\Policies\Microsoft\Windows\Windows Search" /v DisableWebSearch /t REG_DWORD /d 1 /f >nul
reg add "%RW%\Policies\Microsoft\Windows\Windows Search" /v AllowCloudSearch /t REG_DWORD /d 0 /f >nul
reg add "%RW%\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /t REG_DWORD /d 1 /f >nul
reg add "%RW%\Policies\Microsoft\Windows\CloudContent" /v DisableCloudOptimizedContent /t REG_DWORD /d 1 /f >nul
reg add "%RW%\Policies\Microsoft\Windows\CloudContent" /v DisableSoftLanding /t REG_DWORD /d 1 /f >nul

for %%S in (
    DiagTrack dmwappushservice diagnosticshub.standardcollector.service
    WSearch SysMain MapsBroker lfsvc RetailDemo wisvc WerSvc
    XblAuthManager XblGameSave XboxNetApiSvc XboxGipSvc
    RemoteRegistry RemoteAccess TrkWks WMPNetworkSvc SEMgrSvc PhoneSvc
    TabletInputService WbioSrvc icssvc PcaSvc AJRouter DPS
) do (
    reg add "%RS%\ControlSet001\Services\%%S" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
)

echo [*] Performance tweaks...
reg add "%RW%\Policies\Microsoft\Windows\Personalization" /v NoLockScreen /t REG_DWORD /d 1 /f >nul 2>&1
reg add "%RW%\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableFirstLogonAnimation /t REG_DWORD /d 0 /f >nul 2>&1
reg add "%RW%\Policies\Microsoft\Windows\GameDVR" /v AllowGameDVR /t REG_DWORD /d 0 /f >nul 2>&1
reg add "%RS%\ControlSet001\Control\Power\User\PowerSchemes" /v ActivePowerScheme /t REG_SZ /d "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" /f >nul 2>&1

:: --- NEW: DISK OPTIMIZATION ---
echo [*] Disabling Reserved Storage...
reg add "%RW%\Microsoft\Windows\CurrentVersion\ReserveManager" /v ShippedWithReserves /t REG_DWORD /d 0 /f >nul 2>&1
reg add "%RW%\Microsoft\Windows\CurrentVersion\ReserveManager" /v MiscPolicyInfo /t REG_DWORD /d 2 /f >nul 2>&1

echo [*] Disabling Hibernate...
reg add "%RS%\ControlSet001\Control\Power" /v HibernateEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "%RS%\ControlSet001\Control\Power" /v HiberFileSizePercent /t REG_DWORD /d 0 /f >nul 2>&1

echo [*] Optimizing Pagefile...
reg add "%RS%\ControlSet001\Control\Session Manager\Memory Management" /v PagingFiles /t REG_MULTI_SZ /d "C:\pagefile.sys 512 1024" /f >nul 2>&1

echo [*] Disabling Prefetch/Superfetch...
reg add "%RS%\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters" /v EnablePrefetcher /t REG_DWORD /d 0 /f >nul 2>&1
reg add "%RS%\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableSuperfetch /t REG_DWORD /d 0 /f >nul 2>&1

echo [*] Disabling background apps...
reg add "%RW%\Policies\Microsoft\Windows\AppPrivacy" /v LetAppsRunInBackground /t REG_DWORD /d 2 /f >nul 2>&1

echo [*] User profile defaults...
reg add "%RN%\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f >nul
reg add "%RN%\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 1 /f >nul
reg add "%RN%\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SoftLandingEnabled /t REG_DWORD /d 0 /f >nul
reg add "%RN%\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SystemPaneSuggestionsEnabled /t REG_DWORD /d 0 /f >nul
reg add "%RN%\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v OemPreInstalledAppsEnabled /t REG_DWORD /d 0 /f >nul
reg add "%RN%\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v PreInstalledAppsEnabled /t REG_DWORD /d 0 /f >nul
reg add "%RN%\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled /t REG_DWORD /d 0 /f >nul
reg add "%RN%\Software\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f >nul

echo [*] Unloading hives...
reg unload %RN% >nul 2>&1
reg unload %RW% >nul 2>&1
reg unload %RS% >nul 2>&1
echo [OK] Registry optimized.
echo.

:: QuickInstall.bat is downloaded from GitHub at first login (not embedded in image)
:: https://raw.githubusercontent.com/ZewK3/Precores-Software/main/QuickInstall.bat

:: ============================================================
:: STEP 6: UNMOUNT, EXPORT, BUILD ISO
:: ============================================================
echo ============================================================
echo  STEP 6: Build ISO
echo ============================================================

echo [*] Unmounting WIM (saving changes)...
echo     This may take 5-10 minutes...
dism /Unmount-Image /MountDir:"%MOUNT_DIR%" /Commit
if !errorlevel! neq 0 (
    echo [ERROR] Unmount failed!
    dism /Cleanup-MountPoints
    pause
    exit /b 1
)

echo [*] Exporting as ESD (recovery/LZMS compression)...
echo     This may take 15-30 minutes but creates MUCH smaller file...
dism /Export-Image /SourceImageFile:"%WIM_FILE%" /SourceIndex:1 /DestinationImageFile:"%WIM_EXPORT%" /Compress:recovery
if !errorlevel! neq 0 (
    echo [ERROR] ESD export failed!
    pause
    exit /b 1
)
del /f "%WIM_FILE%"
if exist "%ISO_FILES%\sources\install.esd" del /f "%ISO_FILES%\sources\install.esd"
move "%WIM_EXPORT%" "%ISO_FILES%\sources\install.esd"

echo [*] Copying autounattend.xml...
copy /y "%SCRIPTS_DIR%\autounattend.xml" "%ISO_FILES%\autounattend.xml" >nul

echo [*] Building ISO (BIOS + UEFI)...
set "BIOS_BOOT=%ISO_FILES%\boot\etfsboot.com"
set "UEFI_BOOT=%ISO_FILES%\efi\microsoft\boot\efisys_noprompt.bin"
if not exist "!UEFI_BOOT!" set "UEFI_BOOT=%ISO_FILES%\efi\microsoft\boot\efisys.bin"

if not exist "!BIOS_BOOT!" (
    echo [ERROR] BIOS boot file not found: !BIOS_BOOT!
    pause
    exit /b 1
)

if not exist "!UEFI_BOOT!" goto :r_bios_only

echo   Building dual-boot ISO (BIOS + UEFI)...
"!OSCDIMG!" -m -o -u2 -udfver102 -bootdata:2#p0,e,b"!BIOS_BOOT!"#pEF,e,b"!UEFI_BOOT!" "!ISO_FILES!" "!OUTPUT_ISO!"
goto :r_check_iso

:r_bios_only
echo   Building BIOS-only ISO...
"!OSCDIMG!" -m -o -u2 -udfver102 -b"!BIOS_BOOT!" "!ISO_FILES!" "!OUTPUT_ISO!"

:r_check_iso
if !errorlevel! neq 0 (
    echo [ERROR] ISO build failed!
    pause
    exit /b 1
)

rmdir /s /q "%MOUNT_DIR%" 2>nul

echo.
echo  =============================================
echo   BUILD COMPLETE!
echo  =============================================
for %%F in ("%OUTPUT_ISO%") do echo   ISO: %%~nxF (%%~zF bytes)
echo   User: PCL / Pass: PCL@1231233 / AutoLogin
echo   QuickInstall: downloaded from GitHub at first login
echo  =============================================
pause
endlocal

@echo off
:: ============================================================
::  QuickOptimize.bat - Windows 10 Post-Install Optimization
::  Runs ONLINE after first boot (via autounattend.xml)
::  Edit on GitHub: ZewK3/Precores-Software/QuickOptimize.bat
::  Run as Administrator!
:: ============================================================
title QuickOptimize - Windows Optimization
color 0E
setlocal EnableExtensions EnableDelayedExpansion

set "LOG=C:\QuickOptimize_Log.txt"
echo ============================================================ > "%LOG%"
echo  QuickOptimize - Started: %DATE% %TIME% >> "%LOG%"
echo ============================================================ >> "%LOG%"

echo.
echo  =============================================
echo   QuickOptimize - Windows 10 Optimization
echo  =============================================
echo   This may take 10-15 minutes...
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
:: PHASE 1: REMOVE UWP BLOATWARE
:: ============================================================
echo.
echo ============================================================
echo  [1/11] Removing UWP Bloatware...
echo ============================================================
echo [1/11] Removing UWP Bloatware... >> "%LOG%"

:: Write PowerShell script to temp file to avoid batch escaping issues
set "PS_SCRIPT=%TEMP%\remove_bloatware.ps1"
(
echo $ProgressPreference = 'SilentlyContinue'
echo $apps = @(
echo     'Microsoft.BingWeather',
echo     'Microsoft.GetHelp',
echo     'Microsoft.Getstarted',
echo     'Microsoft.Microsoft3DViewer',
echo     'Microsoft.MicrosoftSolitaireCollection',
echo     'Microsoft.MixedReality.Portal',
echo     'Microsoft.MSPaint',
echo     'Microsoft.WindowsAlarms',
echo     'Microsoft.WindowsCamera',
echo     'Microsoft.WindowsSoundRecorder',
echo     'Microsoft.ScreenSketch',
echo     'Microsoft.Windows.Photos',
echo     'Microsoft.WindowsFeedbackHub',
echo     'Microsoft.MicrosoftStickyNotes',
echo     'Microsoft.WindowsMaps',
echo     'Microsoft.People',
echo     'Microsoft.SkypeApp',
echo     'Microsoft.YourPhone',
echo     'microsoft.windowscommunicationsapps',
echo     'Microsoft.Messaging',
echo     'Microsoft.OneConnect',
echo     'Microsoft.ZuneMusic',
echo     'Microsoft.ZuneVideo',
echo     'Microsoft.MicrosoftOfficeHub',
echo     'Microsoft.Office.OneNote',
echo     'Microsoft.Office.Sway',
echo     'Microsoft.XboxApp',
echo     'Microsoft.XboxGameOverlay',
echo     'Microsoft.XboxGamingOverlay',
echo     'Microsoft.XboxIdentityProvider',
echo     'Microsoft.XboxSpeechToTextOverlay',
echo     'Microsoft.Xbox.TCUI',
echo     'Microsoft.Advertising.Xaml',
echo     'Microsoft.Wallet',
echo     'Microsoft.Print3D',
echo     'Microsoft.3DBuilder',
echo     'Microsoft.BingFinance',
echo     'Microsoft.BingNews',
echo     'Microsoft.BingSports',
echo     'Microsoft.BingTranslator',
echo     'Microsoft.Todos',
echo     'Microsoft.PowerAutomateDesktop',
echo     'MicrosoftTeams',
echo     'MicrosoftCorporationII.QuickAssist',
echo     'Clipchamp.Clipchamp',
echo     'Microsoft.Services.Store.Engagement'
echo ^)
echo foreach ^($app in $apps^) {
echo     Get-AppxPackage -AllUsers -Name $app 2^>$null ^| Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
echo     Get-AppxProvisionedPackage -Online 2^>$null ^| Where-Object {$_.DisplayName -like $app} ^| Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
echo     Write-Host "  - $app"
echo }
) > "%PS_SCRIPT%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
del /f /q "%PS_SCRIPT%" >nul 2>&1
echo   Done.
echo   UWP apps removed >> "%LOG%"

:: ============================================================
:: PHASE 2: DISABLE WINDOWS FEATURES
:: ============================================================
echo.
echo ============================================================
echo  [2/11] Disabling Windows Features...
echo ============================================================
echo [2/11] Disabling Windows Features... >> "%LOG%"

for %%F in (
    Internet-Explorer-Optional-amd64
    WindowsMediaPlayer
    WorkFolders-Client
    Printing-XPSServices-Features
    FaxServicesClientPackage
    Printing-Foundation-InternetPrinting-Client
) do (
    echo   - %%F
    dism /Online /Disable-Feature /FeatureName:%%F /Remove /NoRestart >nul 2>&1
)
echo   Done.

:: Remove OneDrive
echo [*] Removing OneDrive...
taskkill /f /im OneDrive.exe >nul 2>&1
timeout /t 2 /nobreak >nul
if exist "%SystemRoot%\SysWOW64\OneDriveSetup.exe" (
    "%SystemRoot%\SysWOW64\OneDriveSetup.exe" /uninstall >nul 2>&1
) else if exist "%SystemRoot%\System32\OneDriveSetup.exe" (
    "%SystemRoot%\System32\OneDriveSetup.exe" /uninstall >nul 2>&1
)
rd /s /q "%USERPROFILE%\OneDrive" >nul 2>&1
rd /s /q "%LOCALAPPDATA%\Microsoft\OneDrive" >nul 2>&1
rd /s /q "%ProgramData%\Microsoft OneDrive" >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v OneDrive /f >nul 2>&1
echo   OneDrive removed.
echo   Features disabled + OneDrive removed >> "%LOG%"

:: ============================================================
:: PHASE 3: DISABLE WINDOWS DEFENDER
:: ============================================================
echo.
echo ============================================================
echo  [3/11] Disabling Windows Defender...
echo ============================================================
echo [3/11] Disabling Windows Defender... >> "%LOG%"

:: Registry policies
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiVirus /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableRealtimeMonitoring /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableBehaviorMonitoring /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableOnAccessProtection /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableScanOnRealtimeEnable /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableIOAVProtection /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v SpyNetReporting /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v SubmitSamplesConsent /t REG_DWORD /d 2 /f >nul

:: Disable Defender services
for %%S in (WinDefend WdNisSvc WdNisDrv WdFilter WdBoot SecurityHealthService wscsvc) do (
    sc config %%S start= disabled >nul 2>&1
    sc stop %%S >nul 2>&1
)

:: Disable SmartScreen
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableSmartScreen /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v SmartScreenEnabled /t REG_SZ /d "Off" /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" /v DisableNotifications /t REG_DWORD /d 1 /f >nul

:: Remove Defender scheduled tasks
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cleanup" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Verification" /Disable >nul 2>&1

:: Physically delete Defender files (~500MB)
echo   - Removing Defender files from disk...
for %%D in (
    "%ProgramFiles%\Windows Defender"
    "%ProgramFiles(x86)%\Windows Defender"
    "%ProgramFiles%\Windows Defender Advanced Threat Protection"
    "%ProgramData%\Microsoft\Windows Defender"
) do (
    if exist %%D (
        takeown /f %%D /r /d y >nul 2>&1
        icacls %%D /grant administrators:F /t >nul 2>&1
        rmdir /s /q %%D >nul 2>&1
    )
)
:: Windows Security app
for /d %%D in ("%SystemRoot%\SystemApps\Microsoft.Windows.SecHealthUI*") do (
    takeown /f "%%D" /r /d y >nul 2>&1
    icacls "%%D" /grant administrators:F /t >nul 2>&1
    rmdir /s /q "%%D" >nul 2>&1
)
echo   Defender disabled + files removed.
echo   Defender disabled + files removed >> "%LOG%"

:: ============================================================
:: PHASE 4: DISABLE WINDOWS UPDATE + SERVICES
:: ============================================================
echo.
echo ============================================================
echo  [4/11] Disabling Windows Update + Services...
echo ============================================================
echo [4/11] Disabling Windows Update + Services... >> "%LOG%"

:: Windows Update services
for %%S in (wuauserv WaaSMedicSvc UsoSvc BITS DoSvc) do (
    sc stop %%S >nul 2>&1
    sc config %%S start= disabled >nul 2>&1
)

:: Windows Update registry
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DisableWindowsUpdateAccess /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DoNotConnectToWindowsUpdateInternetLocations /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode /t REG_DWORD /d 0 /f >nul

:: Print Spooler
for %%S in (Spooler PrintNotify) do (
    sc stop %%S >nul 2>&1
    sc config %%S start= disabled >nul 2>&1
)
:: Delete print spool drivers
if exist "%SystemRoot%\System32\spool\drivers" (
    takeown /f "%SystemRoot%\System32\spool\drivers" /r /d y >nul 2>&1
    icacls "%SystemRoot%\System32\spool\drivers" /grant administrators:F /t >nul 2>&1
    del /f /q /s "%SystemRoot%\System32\spool\drivers\*" >nul 2>&1
)

:: Delete Windows Update files
if exist "%SystemRoot%\SoftwareDistribution" (
    takeown /f "%SystemRoot%\SoftwareDistribution" /r /d y >nul 2>&1
    icacls "%SystemRoot%\SoftwareDistribution" /grant administrators:F /t >nul 2>&1
    rmdir /s /q "%SystemRoot%\SoftwareDistribution" >nul 2>&1
)
if exist "%SystemRoot%\UpdateAssistant" (
    rmdir /s /q "%SystemRoot%\UpdateAssistant" >nul 2>&1
)

:: Disable 45+ unnecessary services (keep dev-critical: WSearch, TokenBroker, InstallService, StorSvc)
for %%S in (
    DiagTrack dmwappushservice diagnosticshub.standardcollector.service
    SysMain MapsBroker lfsvc RetailDemo wisvc WerSvc
    XblAuthManager XblGameSave XboxNetApiSvc XboxGipSvc
    RemoteRegistry RemoteAccess SharedAccess TrkWks
    WMPNetworkSvc WpcMonSvc SEMgrSvc PhoneSvc
    TabletInputService WbioSrvc icssvc NcbService
    PcaSvc SCardSvr ScDeviceEnum EntAppSvc AJRouter
    DmEnrollmentSvc DPS WdiServiceHost WdiSystemHost
    WpnService WpnUserService_* CDPSvc CDPUserSvc_*
    FrameServer stisvc edgeupdate edgeupdatem
    lmhosts NetTcpPortSharing SmsRouter
    OneSyncSvc_* MessagingService_*
    PimIndexMaintenanceSvc_* UnistoreSvc_* UserDataSvc_*
    BcastDVRUserService_* BluetoothUserService_*
    Fax PrintWorkflowUserSvc_*
) do (
    sc stop %%S >nul 2>&1
    sc config %%S start= disabled >nul 2>&1
)

echo   Services disabled + files removed.
echo   Services disabled + files removed >> "%LOG%"

:: ============================================================
:: PHASE 5: REGISTRY OPTIMIZATIONS
:: ============================================================
echo.
echo ============================================================
echo  [5/11] Applying Registry Tweaks...
echo ============================================================
echo [5/11] Applying Registry Tweaks... >> "%LOG%"

:: Telemetry
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v DoNotShowFeedbackNotifications /t REG_DWORD /d 1 /f >nul

:: Cortana
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v DisableWebSearch /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v ConnectedSearchUseWeb /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCloudSearch /t REG_DWORD /d 0 /f >nul

:: Consumer Experience
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableCloudOptimizedContent /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableSoftLanding /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableTailoredExperiencesWithDiagnosticData /t REG_DWORD /d 1 /f >nul

:: Performance / UX
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" /v NoLockScreen /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableFirstLogonAnimation /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v AllowGameDVR /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" /v AutoConnectAllowedOEM /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Remote Assistance" /v fAllowToGetHelp /t REG_DWORD /d 0 /f >nul

:: Disable Reserved Storage
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager" /v ShippedWithReserves /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager" /v MiscPolicyInfo /t REG_DWORD /d 2 /f >nul

:: Disable Prefetch/Superfetch
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnablePrefetcher /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableSuperfetch /t REG_DWORD /d 0 /f >nul

:: Disable background apps
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v LetAppsRunInBackground /t REG_DWORD /d 2 /f >nul

:: Memory optimization (small dumps only, disable paging executive)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v CrashDumpEnabled /t REG_DWORD /d 3 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v LogEvent /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingExecutive /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /t REG_DWORD /d 0 /f >nul

:: Network optimization
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" /v DisabledComponents /t REG_DWORD /d 255 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpTimedWaitDelay /t REG_DWORD /d 30 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v Size /t REG_DWORD /d 3 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v IRPStackSize /t REG_DWORD /d 20 /f >nul

:: Disable Timeline/Activity History
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableActivityFeed /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v PublishUserActivities /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v UploadUserActivities /t REG_DWORD /d 0 /f >nul

:: Disable Clipboard History
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v AllowClipboardHistory /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v AllowCrossDeviceClipboard /t REG_DWORD /d 0 /f >nul

:: Disable Location tracking
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v DisableLocation /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v DisableWindowsLocationProvider /t REG_DWORD /d 1 /f >nul

:: Current User tweaks
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarSmallIcons /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SoftLandingEnabled /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338389Enabled /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-310093Enabled /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338388Enabled /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SystemPaneSuggestionsEnabled /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v OemPreInstalledAppsEnabled /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v PreInstalledAppsEnabled /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f >nul

echo   Registry tweaks applied.
echo   Registry tweaks applied >> "%LOG%"

:: ============================================================
:: PHASE 6: VISUAL PERFORMANCE (disable animations/effects)
:: ============================================================
echo.
echo ============================================================
echo  [6/11] Visual Performance Tweaks...
echo ============================================================
echo [6/11] Visual Performance Tweaks... >> "%LOG%"

:: Set Visual Effects to Best Performance
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f >nul
reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9012038010000000 /f >nul
:: Disable transparency
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f >nul
:: Disable animations
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f >nul
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 0 /f >nul
:: Disable Aero Shake
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v DisallowShaking /t REG_DWORD /d 1 /f >nul
:: Disable Aero Peek
reg add "HKCU\Software\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 0 /f >nul
:: Disable window animation
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d 0 /f >nul
:: Disable cursor blink
reg add "HKCU\Control Panel\Desktop" /v CursorBlinkRate /t REG_SZ /d -1 /f >nul
:: Dark mode
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d 0 /f >nul
echo   Visual performance optimized.
echo   Visual performance optimized >> "%LOG%"

:: ============================================================
:: PHASE 7: DISABLE SCHEDULED TASKS + TELEMETRY
:: ============================================================
echo.
echo ============================================================
echo  [7/11] Disabling Scheduled Tasks + Telemetry...
echo ============================================================
echo [7/11] Disabling Scheduled Tasks + Telemetry... >> "%LOG%"

:: Disable telemetry/diagnostic tasks
for %%T in (
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"
    "\Microsoft\Windows\Application Experience\ProgramDataUpdater"
    "\Microsoft\Windows\Autochk\Proxy"
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator"
    "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"
    "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
    "\Microsoft\Windows\Feedback\Siuf\DmClient"
    "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload"
    "\Microsoft\Windows\Maps\MapsToastTask"
    "\Microsoft\Windows\Maps\MapsUpdateTask"
    "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem"
    "\Microsoft\Windows\Shell\FamilySafetyMonitor"
    "\Microsoft\Windows\Shell\FamilySafetyRefreshTask"
    "\Microsoft\Windows\Windows Error Reporting\QueueReporting"
    "\Microsoft\Windows\CloudExperienceHost\CreateObjectTask"
    "\Microsoft\Windows\Defrag\ScheduledDefrag"
) do (
    schtasks /Change /TN %%T /Disable >nul 2>&1
)
echo   - Scheduled tasks disabled

:: Block telemetry via hosts file
set "HOSTS=%SystemRoot%\System32\drivers\etc\hosts"
findstr /i "vortex.data.microsoft.com" "%HOSTS%" >nul 2>&1
if %errorlevel% neq 0 (
    echo. >> "%HOSTS%"
    echo # --- Block Telemetry --- >> "%HOSTS%"
    echo 0.0.0.0 vortex.data.microsoft.com >> "%HOSTS%"
    echo 0.0.0.0 settings-win.data.microsoft.com >> "%HOSTS%"
    echo 0.0.0.0 watson.telemetry.microsoft.com >> "%HOSTS%"
    echo 0.0.0.0 watson.microsoft.com >> "%HOSTS%"
    echo 0.0.0.0 dc.services.visualstudio.com >> "%HOSTS%"
    echo 0.0.0.0 telemetry.microsoft.com >> "%HOSTS%"
    echo 0.0.0.0 oca.telemetry.microsoft.com >> "%HOSTS%"
    echo 0.0.0.0 sqm.telemetry.microsoft.com >> "%HOSTS%"
    echo 0.0.0.0 feedback.windows.com >> "%HOSTS%"
    echo 0.0.0.0 feedback.microsoft-hohm.com >> "%HOSTS%"
)
echo   - Telemetry hosts blocked

:: Disable System Restore (saves disk space in VM)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore" /v DisableSR /t REG_DWORD /d 1 /f >nul
vssadmin delete shadows /all /quiet >nul 2>&1
sc config swprv start= disabled >nul 2>&1
echo   - System Restore disabled

:: Clear event logs
for /f "tokens=*" %%L in ('wevtutil el 2^>nul') do wevtutil cl "%%L" >nul 2>&1
echo   - Event logs cleared

:: Disable Notifications Center
reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v DisableNotificationCenter /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v ToastEnabled /t REG_DWORD /d 0 /f >nul
echo   - Notifications disabled

echo   Scheduled tasks + telemetry done.
echo   Scheduled tasks + telemetry done >> "%LOG%"

:: ============================================================
:: PHASE 6: CLEANUP FILES
:: ============================================================
echo.
echo ============================================================
echo  [8/11] Cleaning Up Files...
echo ============================================================
echo [8/11] Cleaning Up Files... >> "%LOG%"

:: Wallpapers
if exist "%SystemRoot%\Web\Wallpaper" (
    for /d %%W in ("%SystemRoot%\Web\Wallpaper\*") do rmdir /s /q "%%W" >nul 2>&1
)
if exist "%SystemRoot%\Web\4K" rmdir /s /q "%SystemRoot%\Web\4K" >nul 2>&1
if exist "%SystemRoot%\Web\Screen" rmdir /s /q "%SystemRoot%\Web\Screen" >nul 2>&1
echo   - Cleaned wallpapers

:: Screensavers
del /f /q "%SystemRoot%\System32\*.scr" >nul 2>&1
del /f /q "%SystemRoot%\SysWOW64\*.scr" >nul 2>&1
echo   - Cleaned screensavers

:: System sounds
if exist "%SystemRoot%\Media" del /f /q /s "%SystemRoot%\Media\*" >nul 2>&1
echo   - Cleaned system sounds

:: Migration wizard
if exist "%SystemRoot%\System32\migwiz" (
    takeown /f "%SystemRoot%\System32\migwiz" /r /d y >nul 2>&1
    icacls "%SystemRoot%\System32\migwiz" /grant administrators:F /t >nul 2>&1
    rmdir /s /q "%SystemRoot%\System32\migwiz" >nul 2>&1
)
echo   - Removed migration wizard

:: Speech/TTS
for %%D in ("%SystemRoot%\Speech" "%SystemRoot%\Speech_OneCore") do (
    if exist %%D (
        takeown /f %%D /r /d y >nul 2>&1
        icacls %%D /grant administrators:F /t >nul 2>&1
        rmdir /s /q %%D >nul 2>&1
    )
)
echo   - Removed Speech data

:: Retail Demo
if exist "%SystemRoot%\System32\RetailDemo" rmdir /s /q "%SystemRoot%\System32\RetailDemo" >nul 2>&1
echo   - Removed RetailDemo

:: Unused IME
for /d %%I in ("%SystemRoot%\IME\IMEJP*" "%SystemRoot%\IME\IMEKR*" "%SystemRoot%\IME\IMETC*" "%SystemRoot%\IME\IMESC*") do (
    if exist "%%I" (
        takeown /f "%%I" /r /d y >nul 2>&1
        icacls "%%I" /grant administrators:F /t >nul 2>&1
        rmdir /s /q "%%I" >nul 2>&1
    )
)
echo   - Cleaned unused IME

:: MusNotification (Update nag)
for %%F in (MusNotification.exe MusNotificationUx.exe) do (
    if exist "%SystemRoot%\System32\%%F" (
        takeown /f "%SystemRoot%\System32\%%F" >nul 2>&1
        icacls "%SystemRoot%\System32\%%F" /grant administrators:F >nul 2>&1
        del /f /q "%SystemRoot%\System32\%%F" >nul 2>&1
    )
)
echo   - Removed MusNotification

:: Temp/Logs/Caches
del /f /q /s "%SystemRoot%\Temp\*" >nul 2>&1
del /f /q /s "%SystemRoot%\Prefetch\*" >nul 2>&1
del /f /q /s "%SystemRoot%\SoftwareDistribution\Download\*" >nul 2>&1
del /f /q /s "%SystemRoot%\Logs\*" >nul 2>&1
del /f /q /s "%SystemRoot%\ServiceProfiles\LocalService\AppData\Local\FontCache\*" >nul 2>&1
echo   - Cleaned temp/logs/caches

:: Windows.old (leftover from upgrades)
if exist "%SystemDrive%\Windows.old" (
    takeown /f "%SystemDrive%\Windows.old" /r /d y >nul 2>&1
    icacls "%SystemDrive%\Windows.old" /grant administrators:F /t >nul 2>&1
    rmdir /s /q "%SystemDrive%\Windows.old" >nul 2>&1
    echo   - Removed Windows.old
)

:: Windows Help files
if exist "%SystemRoot%\Help" (
    takeown /f "%SystemRoot%\Help" /r /d y >nul 2>&1
    icacls "%SystemRoot%\Help" /grant administrators:F /t >nul 2>&1
    rmdir /s /q "%SystemRoot%\Help" >nul 2>&1
)
echo   - Removed Help files

:: Setup/Install logs
if exist "%SystemRoot%\Panther" rmdir /s /q "%SystemRoot%\Panther" >nul 2>&1
if exist "%SystemRoot%\inf\setupapi*" del /f /q "%SystemRoot%\inf\setupapi*" >nul 2>&1
echo   - Removed setup logs

:: Installer caches
if exist "%SystemRoot%\Installer\$PatchCache$" (
    rmdir /s /q "%SystemRoot%\Installer\$PatchCache$" >nul 2>&1
)
if exist "%ProgramData%\Package Cache" (
    rmdir /s /q "%ProgramData%\Package Cache" >nul 2>&1
)
if exist "%SystemRoot%\Downloaded Program Files" (
    rmdir /s /q "%SystemRoot%\Downloaded Program Files" >nul 2>&1
)
echo   - Cleaned installer caches

:: Crash dumps
if exist "%SystemRoot%\Minidump" rmdir /s /q "%SystemRoot%\Minidump" >nul 2>&1
if exist "%SystemRoot%\LiveKernelReports" rmdir /s /q "%SystemRoot%\LiveKernelReports" >nul 2>&1
if exist "%SystemRoot%\MEMORY.DMP" del /f /q "%SystemRoot%\MEMORY.DMP" >nul 2>&1
if exist "%SystemRoot%\SystemTemp" del /f /q /s "%SystemRoot%\SystemTemp\*" >nul 2>&1
echo   - Cleaned crash dumps

:: Diagnostics/Troubleshooters
if exist "%SystemRoot%\diagnostics" (
    takeown /f "%SystemRoot%\diagnostics" /r /d y >nul 2>&1
    icacls "%SystemRoot%\diagnostics" /grant administrators:F /t >nul 2>&1
    rmdir /s /q "%SystemRoot%\diagnostics" >nul 2>&1
)
echo   - Removed diagnostics

:: .NET Native Image Cache (will regenerate if needed)
if exist "%SystemRoot%\assembly\NativeImages_v4*" (
    for /d %%N in ("%SystemRoot%\assembly\NativeImages_v4*") do rmdir /s /q "%%N" >nul 2>&1
)
echo   - Cleaned .NET cache

:: Rescache
if exist "%SystemRoot%\rescache" rmdir /s /q "%SystemRoot%\rescache" >nul 2>&1
echo   - Cleaned rescache

:: Old driver packages (clean unused)
pnputil /enum-drivers >nul 2>&1 && (
    for /f "tokens=1,2 delims=: " %%a in ('pnputil /enum-drivers ^| findstr /i "oem"') do (
        pnputil /delete-driver %%b >nul 2>&1
    )
)
echo   - Cleaned old driver packages

echo   Deep cleanup done.
echo   Deep cleanup done >> "%LOG%"

:: ============================================================
:: PHASE 7: SYSTEM OPTIMIZATION
:: ============================================================
echo.
echo ============================================================
echo  [9/11] System Optimization...
echo ============================================================
echo [9/11] System Optimization... >> "%LOG%"

:: High Performance power plan
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
echo   - High Performance power plan set

:: Disable Hibernate
powercfg /h off
echo   - Hibernate disabled

:: Optimize pagefile
wmic computersystem where name="%COMPUTERNAME%" set AutomaticManagedPagefile=False >nul 2>&1
wmic pagefileset where name="C:\\pagefile.sys" set InitialSize=512,MaximumSize=1024 >nul 2>&1
echo   - Pagefile optimized

:: Disable Reserved Storage
dism /Online /Set-ReservedStorageState /State:Disabled >nul 2>&1
echo   - Reserved Storage disabled

:: Enable CompactOS
echo   - Enabling CompactOS (saves ~2GB)...
compact /compactos:always >nul 2>&1
echo   - CompactOS enabled

:: WinSxS cleanup
echo   - Cleaning WinSxS component store...
dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase >nul 2>&1
echo   - WinSxS cleaned

echo   System optimization done.
echo   System optimization done >> "%LOG%"

:: ============================================================
:: PHASE 8: ENABLE REMOTE DESKTOP
:: ============================================================
echo.
echo ============================================================
echo  [10/11] Enabling Remote Desktop...
echo ============================================================
echo [10/11] Enabling Remote Desktop... >> "%LOG%"

:: Enable RDP
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 0 /f >nul

:: Enable RDP firewall rules
netsh advfirewall firewall set rule group="Remote Desktop" new enable=yes >nul 2>&1

:: Start RDP service
sc config TermService start= auto >nul 2>&1
sc start TermService >nul 2>&1

:: ---- RDP Performance (mRemoteNG optimization) ----

:: Color depth 32-bit (best quality for dev work)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v ColorDepth /t REG_DWORD /d 4 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v ColorDepthPolicy /t REG_DWORD /d 1 /f >nul
echo   - RDP color depth: 32-bit

:: Enable bitmap caching (reduces bandwidth)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v AllowBitmapCaching /t REG_DWORD /d 1 /f >nul
echo   - Bitmap caching enabled

:: Enable RemoteFX hardware GPU encoding
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fEnableRemoteFXAdvancedRemoteApp /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v bEnumerateHWBeforeSW /t REG_DWORD /d 1 /f >nul
echo   - RemoteFX enabled

:: AVC/H.264 hardware encoding (smoother video)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v AVC444ModePreferred /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v AVCHardwareEncodePreferred /t REG_DWORD /d 1 /f >nul
echo   - AVC H.264 encoding enabled

:: Optimize compression (balanced CPU vs bandwidth)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v VisualExperiencePolicy /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v ImageQuality /t REG_DWORD /d 3 /f >nul

:: Disable wallpaper/theme over RDP (faster rendering)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fNoRemoteDesktopWallpaper /t REG_DWORD /d 1 /f >nul
echo   - RDP wallpaper disabled (faster)

:: Keep-alive interval (prevent disconnects)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v KeepAliveEnable /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v KeepAliveInterval /t REG_DWORD /d 1 /f >nul

:: Allow multiple simultaneous RDP sessions
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fSingleSessionPerUser /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v MaxInstanceCount /t REG_DWORD /d 10 /f >nul
echo   - Multiple RDP sessions allowed

:: Disable RDP security warning prompts
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v SecurityLayer /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v MinEncryptionLevel /t REG_DWORD /d 1 /f >nul
echo   - RDP security prompts disabled

:: Audio redirection over RDP (disabled for performance)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fDisableCam /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fDisablePNPRedir /t REG_DWORD /d 1 /f >nul
echo   - Camera/PnP redirection disabled

:: Faster screen updates
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v MaxMonitors /t REG_DWORD /d 4 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v MaxXResolution /t REG_DWORD /d 3840 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v MaxYResolution /t REG_DWORD /d 2160 /f >nul
echo   - Max resolution: 4K, 4 monitors

echo   Remote Desktop enabled + optimized for mRemoteNG.
echo   Remote Desktop enabled + optimized >> "%LOG%"

:: ============================================================
:: PHASE 9: FINAL CLEANUP
:: ============================================================
echo.
echo ============================================================
echo  [11/11] Final Cleanup...
echo ============================================================
echo [11/11] Final Cleanup... >> "%LOG%"

:: Clean temp files
del /f /q "%SystemRoot%\Temp\*" >nul 2>&1
del /f /q "%TEMP%\*" >nul 2>&1

echo ============================================================ >> "%LOG%"
echo  QuickOptimize - Completed: %DATE% %TIME% >> "%LOG%"
echo ============================================================ >> "%LOG%"

echo.
echo  =============================================
echo   QuickOptimize COMPLETE!
echo  =============================================
echo   Log: %LOG%
echo  =============================================
echo.

:: Self-delete
del /f /q "C:\QuickOptimize.bat" >nul 2>&1

endlocal

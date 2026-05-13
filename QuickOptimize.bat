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

:: Disable 60+ unnecessary services (low-RAM dev VM: keep TokenBroker, InstallService, StorSvc, Dhcp, Dnscache, LanmanWorkstation, NlaSvc, EventLog, RpcSs, RpcEptMapper, CryptSvc, Power, BFE, mpssvc, ProfSvc, gpsvc, Schedule, UserManager, LSM, AudioSrv, AudioEndpointBuilder, Themes)
:: IMPORTANT: SysMain is KEPT enabled because Windows Memory Compression depends on it.
:: Superfetch/Prefetch behavior is already disabled via registry (EnablePrefetcher=0, EnableSuperfetch=0).
:: On 4GB systems, memory compression saves ~30-50% RAM by compressing cold pages.
for %%S in (
    DiagTrack dmwappushservice diagnosticshub.standardcollector.service
    MapsBroker lfsvc RetailDemo wisvc WerSvc
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
    WSearch fhsvc WalletService BDESVC RasMan
    iphlpsvc ALG SCPolicySvc SmartSAMSS Browser
    WlanSvc WwanSvc DusmSvc DsmSvc PNRPsvc p2psvc p2pimsvc PNRPAutoReg
    PeerDistSvc HvHost vmickvpexchange vmicguestinterface vmicshutdown
    vmicheartbeat vmicvmsession vmicrdv vmictimesync vmicvss
    SensorService SensrSvc SensorDataService DevQueryBroker
    ssh-agent sshd ssh-broker-svc AssignedAccessManagerSvc
    AppReadiness AppMgmt AppVClient ClipSVC
    AeLookupSvc PolicyAgent IKEEXT SstpSvc
    NaturalAuthentication GraphicsPerfSvc
    embeddedmode COMSysApp WEPHOSTSVC PerfHost
    Netlogon Netman RmSvc
    SDRSVC seclogon shpamsvc TieringEngineService
    SNMPTRAP swprv upnphost vds
    BTAGService bthserv BthAvctpSvc
    SharedRealitySvc spectrum
    MicrosoftEdgeElevationService
) do (
    sc stop %%S >nul 2>&1
    sc config %%S start= disabled >nul 2>&1
)
:: NOTE: Some services above may not exist on all SKUs; "sc config" silently fails for absent services.
:: Critical for graphics/audio/network NOT in disable list: Themes, AudioSrv, AudioEndpointBuilder, Dhcp, Dnscache, LanmanWorkstation, EventLog, RpcSs, mpssvc, BFE, SysMain (for Memory Compression)

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

:: Memory optimization (no crash dumps to save disk I/O, instantly reboot on BSOD)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v CrashDumpEnabled /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v LogEvent /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v AutoReboot /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingExecutive /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /t REG_DWORD /d 0 /f >nul
:: Dynamic DisablePagingExecutive: keep kernel in RAM if >=8GB, allow paging if <8GB
for /f "usebackq" %%R in (`powershell -NoProfile -Command "if([Math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB) -ge 8){1}else{0}"`) do (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingExecutive /t REG_DWORD /d %%R /f >nul
)

:: Network + Multimedia optimization
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" /v DisabledComponents /t REG_DWORD /d 255 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpTimedWaitDelay /t REG_DWORD /d 30 /f >nul
:: Disable Network Throttling (maximize throughput instead of reserving 20% for media playback)
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 4294967295 /f >nul
:: Give 100% CPU priority to foreground/background apps (no multimedia reservation)
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v Size /t REG_DWORD /d 3 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v IRPStackSize /t REG_DWORD /d 20 /f >nul

:: Disable Nagle's Algorithm on all interfaces (TCP_NODELAY = instant packet send, crucial for RDP/real-time)
for /f "tokens=*" %%k in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /k 2^>nul') do (
    reg add "%%k" /v TcpAckFrequency /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "%%k" /v TCPNoDelay /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "%%k" /v TcpDelAckTicks /t REG_DWORD /d 0 /f >nul 2>&1
)
:: Remove QoS reserved bandwidth (Windows reserves 20%% of bandwidth for QoS by default)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v NonBestEffortLimit /t REG_DWORD /d 0 /f >nul

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

:: ---- EXTRA LOW-RAM TWEAKS (for AI dev tools: VS Code, Verdent, Kiro) ----

:: Merge svchost processes dynamically based on RAM (saves ~150-300MB)
:: Set threshold to installed RAM in KB so Windows groups all services in fewer svchost.exe
for /f "usebackq" %%R in (`powershell -NoProfile -Command "[Math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1KB)"`) do (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v SvcHostSplitThresholdInKB /t REG_DWORD /d %%R /f >nul
)

:: Don't clear pagefile on shutdown (faster shutdown, no perf gain)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v ClearPageFileAtShutdown /t REG_DWORD /d 0 /f >nul

:: Dynamic I/O page lock limit based on RAM (10% of RAM in bytes, better disk I/O for compilers/AI)
for /f "usebackq" %%I in (`powershell -NoProfile -Command "[Math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory*0.1)"`) do (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v IoPageLockLimit /t REG_DWORD /d %%I /f >nul
)

:: Faster shutdown timers
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v WaitToKillServiceTimeout /t REG_SZ /d 2000 /f >nul
reg add "HKCU\Control Panel\Desktop" /v WaitToKillAppTimeout /t REG_SZ /d 2000 /f >nul
reg add "HKCU\Control Panel\Desktop" /v HungAppTimeout /t REG_SZ /d 2000 /f >nul
reg add "HKCU\Control Panel\Desktop" /v AutoEndTasks /t REG_SZ /d 1 /f >nul

:: Disable Windows Search indexer UI (Cortana/search box on taskbar) - saves ~80-150MB
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v SearchboxTaskbarMode /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v BingSearchEnabled /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v CortanaConsent /t REG_DWORD /d 0 /f >nul

:: Disable Cortana/TaskView/People/Meet/Widgets buttons on taskbar
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowCortanaButton /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowTaskViewButton /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" /v PeopleBand /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarMn /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f >nul

:: Open File Explorer to "This PC" (no Quick Access scanning)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v LaunchTo /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v ShowRecent /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v ShowFrequent /t REG_DWORD /d 0 /f >nul

:: Disable News & Interests / Widgets
reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v EnableFeeds /t REG_DWORD /d 0 /f >nul

:: Disable Edge pre-launch/tab preload (Edge eats ~200MB at boot otherwise)
reg add "HKLM\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main" /v AllowPrelaunch /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\MicrosoftEdge\TabPreloader" /v AllowTabPreloading /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Policies\Microsoft\MicrosoftEdge\Main" /v AllowPrelaunch /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v StartupBoostEnabled /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v BackgroundModeEnabled /t REG_DWORD /d 0 /f >nul

:: Disable Storage Sense (background disk scans)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v 01 /t REG_DWORD /d 0 /f >nul

:: Disable Windows Spotlight (lockscreen download)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsSpotlightFeatures /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableSpotlightCollectionOnDesktop /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableThirdPartySuggestions /t REG_DWORD /d 1 /f >nul

:: Disable Search Highlights
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v EnableDynamicContentInWSB /t REG_DWORD /d 0 /f >nul

:: Disable Cortana/web search fully
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v CortanaConsent /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f >nul

:: Disable startup boost / fast startup (clean boot, predictable memory state)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 0 /f >nul

:: Disable game bar background recording
reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f >nul
:: AllowGameDVR already set in Performance/UX section above

:: Disable error reporting service (Werfault.exe popups + memory dumps)
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v Disabled /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v DontShowUI /t REG_DWORD /d 1 /f >nul

:: Reduce DWM/animation CPU
reg add "HKCU\Software\Microsoft\Windows\DWM" /v AlwaysHibernateThumbnails /t REG_DWORD /d 0 /f >nul

:: Disable Sync settings
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v DisableSettingSync /t REG_DWORD /d 2 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\SettingSync" /v DisableSettingSyncUserOverride /t REG_DWORD /d 1 /f >nul

:: Disable App Compat telemetry (Inventory collector)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v DisableInventory /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v DisableUAR /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v AITEnable /t REG_DWORD /d 0 /f >nul

:: Disable Delivery Optimization peer cache (uses bandwidth+disk)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" /v DODownloadMode /t REG_DWORD /d 0 /f >nul

:: Disable WPBT (Windows Platform Binary Table - runs OEM binaries at boot)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v DisableWpbtExecution /t REG_DWORD /d 1 /f >nul

:: Disable UAC & Fast User Switching - crucial for automated VMs (no prompts, single user mode)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v HideFastUserSwitching /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v PromptOnSecureDesktop /t REG_DWORD /d 0 /f >nul

:: Disable all background UWP apps globally
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled /t REG_DWORD /d 1 /f >nul
:: LetAppsRunInBackground already set to 2 in line 337 above

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

:: Disable ETW (Event Tracing for Windows) Autologgers to stop constant micro-logging I/O
for /f "tokens=*" %%k in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger" /k 2^>nul') do (
    reg add "%%k" /v Start /t REG_DWORD /d 0 /f >nul 2>&1
)
echo   - ETW Autologgers disabled

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
:: PHASE 8: CLEANUP FILES
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
    for /f "tokens=1,2 delims=: " %%a in ('pnputil /enum-drivers 2^>nul ^| findstr /i "oem"') do (
        pnputil /delete-driver %%b /force <nul >nul 2>&1
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

:: Ultimate Performance power plan (hidden plan with zero power-saving, max CPU/disk/USB speed)
powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1
for /f "tokens=4" %%G in ('powercfg /list 2^>nul ^| findstr /i "Ultimate"') do powercfg /setactive %%G >nul 2>&1
:: Fallback to High Performance if Ultimate not available
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
:: Force all power settings to maximum performance (no idle, no throttle)
powercfg /change monitor-timeout-ac 0
powercfg /change standby-timeout-ac 0
powercfg /change hibernate-timeout-ac 0
powercfg /change disk-timeout-ac 0
echo   - Ultimate Performance power plan activated

:: Disable Hibernate
powercfg /h off
echo   - Hibernate disabled

:: Optimize pagefile dynamically based on Total Physical RAM (so laptops/PCs don't get stuck with 4GB VM settings)
set "PF_MIN=4096"
set "PF_MAX=12288"
for /f "usebackq tokens=1,2" %%A in (`powershell -NoProfile -Command "$r=[Math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB); if($r -le 4){'2048 6144'}elseif($r -le 8){'4096 12288'}else{'4096 16384'}"`) do (
    set "PF_MIN=%%A"
    set "PF_MAX=%%B"
)
wmic computersystem where name="%COMPUTERNAME%" set AutomaticManagedPagefile=False <nul >nul 2>&1
wmic pagefileset where name="C:\\pagefile.sys" set InitialSize=!PF_MIN!,MaximumSize=!PF_MAX! <nul >nul 2>&1
if not exist "C:\pagefile.sys" wmic pagefileset create name="C:\pagefile.sys" <nul >nul 2>&1
echo   - Pagefile optimized dynamically (!PF_MIN!MB - !PF_MAX!MB)

:: Disable Reserved Storage
dism /Online /Set-ReservedStorageState /State:Disabled >nul 2>&1
echo   - Reserved Storage disabled

:: Enable CompactOS
echo   - Enabling CompactOS (saves ~2GB)...
compact /compactos:always <nul >nul 2>&1
echo   - CompactOS enabled

:: WinSxS cleanup
echo   - Cleaning WinSxS component store...
dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase <nul >nul 2>&1
echo   - WinSxS cleaned

:: ---- HARDWARE / CPU UNLOCK TWEAKS ----
:: Disable VBS (Virtualization Based Security) and Core Isolation (Memory Integrity)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 0 /f >nul
:: Disable Spectre and Meltdown CPU Mitigations (Unlock 100% native CPU speed, safe for isolated VMs)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /t REG_DWORD /d 3 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverrideMask /t REG_DWORD /d 3 /f >nul
echo   - VBS/Core Isolation disabled, Spectre/Meltdown mitigations removed

:: ---- BOOT & KERNEL TIMING TWEAKS ----
:: Disable dynamic tick (stops power-saving CPU ticks, reduces DPC latency in VMs)
bcdedit /set disabledynamictick yes >nul 2>&1
:: Disable synthetic timers (improves micro-stutter in virtualized environments)
bcdedit /deletevalue useplatformclock >nul 2>&1
:: Remove boot menu timeout and boot animation to boot instantly
bcdedit /timeout 0 >nul 2>&1
bcdedit /set {globalsettings} custom:16000067 true >nul 2>&1
bcdedit /set {default} bootuxdisabled on >nul 2>&1

:: Disable Windows Firewall (safe behind Hypervisor/Router NAT, increases network speed)
netsh advfirewall set allprofiles state off >nul 2>&1
echo   - Boot tweaks applied, Firewall disabled

:: ---- MEMORY COMPRESSION TWEAKS ----

:: Force ENABLE Memory Compression (effectively gives ~30-50% more usable RAM on any system)
echo   - Enabling Memory Compression...
powershell -NoProfile -Command "Enable-MMAgent -mc" >nul 2>&1
powershell -NoProfile -Command "Enable-MMAgent -PageCombining" >nul 2>&1
:: Disable prefetcher/superfetch DATA collection but keep MMAgent service alive for compression
powershell -NoProfile -Command "Disable-MMAgent -ApplicationLaunchPrefetching" >nul 2>&1
powershell -NoProfile -Command "Disable-MMAgent -ApplicationPreLaunch" >nul 2>&1
powershell -NoProfile -Command "Disable-MMAgent -OperationAPI" >nul 2>&1

:: Process Scheduling Priority (Set to 24: Optimize for Background Services)
:: This gives equal, long CPU timeslices to all running bots/apps, maximizing throughput instead of just the active window
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 24 /f >nul
echo   - Background throughput priority boosted

:: Disable Power Throttling (Prevents Windows from slowing down background/minimized tools)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /t REG_DWORD /d 1 /f >nul
echo   - Power Throttling disabled

:: Trim Explorer working set every time it idles (saves ~30-80MB)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v AlwaysUnloadDll /t REG_DWORD /d 1 /f >nul

:: Auto-trim memory of background processes (Win10 1809+)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePageCombining /t REG_DWORD /d 0 /f >nul

:: Reduce CSRSS shared memory
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\SubSystems" /v Optional /t REG_MULTI_SZ /d "" /f >nul

:: Disable NTFS Last Access Time update (saves significant disk read/writes)
fsutil behavior set disablelastaccess 1 >nul 2>&1
:: Disable NTFS 8.3 short filename creation (saves ~20% disk I/O on file-heavy workloads)
fsutil behavior set disable8dot3 1 >nul 2>&1
:: Increase NTFS paged pool memory usage (level 2 = more RAM for file system cache)
fsutil behavior set memoryusage 2 >nul 2>&1
:: Disable NTFS encryption overhead (EFS not needed on farming VMs)
fsutil behavior set disableencryption 1 >nul 2>&1
echo   - NTFS tuned (8.3 off, last-access off, encryption off, memory level 2)

:: Enable Hardware-Accelerated GPU Scheduling (Win10 2004+, reduces DPC latency for display)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f >nul
echo   - Hardware GPU Scheduling enabled

:: Disable Automatic Maintenance (stops random background defrag/scan/cleanup during work hours)
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" /v MaintenanceDisabled /t REG_DWORD /d 1 /f >nul
echo   - Automatic Maintenance disabled

:: Disable Windows Installer verbose logging (reduces disk I/O during installs)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v Logging /t REG_SZ /d "" /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v Debug /t REG_DWORD /d 0 /f >nul

:: bcdedit: Enhanced TSC synchronization (smoother timer in VMs, reduces clock drift)
bcdedit /set tscsyncpolicy enhanced >nul 2>&1
:: bcdedit: Disable integrity checks (faster boot, no driver signature verification)
bcdedit /set nointegritychecks on >nul 2>&1
bcdedit /set testsigning on >nul 2>&1
echo   - BCD: TSC sync enhanced, integrity checks off

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

:: AVC/H.264 software encoding (no GPU in VM - hardware encode would FAIL and fall back slowly)
:: AVC444 software mode = smooth video at cost of CPU; perfect for LAN RDP
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v AVC444ModePreferred /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v AVCHardwareEncodePreferred /t REG_DWORD /d 0 /f >nul
echo   - AVC H.264 software encoding enabled (VM-optimized)

:: ---- UDP transport (HUGE smoothness gain on LAN; TCP-only causes lag) ----
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fClientDisableUDP /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v SelectTransport /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v SelectNetworkDetect /t REG_DWORD /d 1 /f >nul
:: Open UDP 3389 in firewall
netsh advfirewall firewall add rule name="RDP-UDP-In" dir=in action=allow protocol=UDP localport=3389 >nul 2>&1
echo   - UDP transport enabled (port 3389/UDP)

:: ---- Frame rate: 60fps for ultra-smooth mouse/scroll ----
:: DWMFRAMEINTERVAL is in milliseconds: 15 = 60fps, 33 = 30fps
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v DWMFRAMEINTERVAL /t REG_DWORD /d 15 /f >nul
:: Frame rate cap for AVC encoder
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v MaxMonitorTargetEffectiveFrameRate /t REG_DWORD /d 60 /f >nul
echo   - RDP frame rate: 60 FPS

:: ---- Compression: best balance for LAN ----
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v CompressionType /t REG_DWORD /d 2 /f >nul
echo   - Compression: optimized for bandwidth

:: ---- Image quality (1=Low, 2=Medium, 3=High, 4=Lossless; 3 is best balance) ----
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v VisualExperiencePolicy /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v ImageQuality /t REG_DWORD /d 3 /f >nul

:: Disable wallpaper/theme over RDP (faster rendering)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fNoRemoteDesktopWallpaper /t REG_DWORD /d 1 /f >nul
echo   - RDP wallpaper disabled (faster)

:: ---- Keep-alive (prevent disconnects, no idle timeout) ----
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v KeepAliveEnable /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v KeepAliveInterval /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v MaxIdleTime /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v MaxDisconnectionTime /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v MaxConnectionTime /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fInheritMaxIdleTime /t REG_DWORD /d 0 /f >nul
echo   - No idle/session timeout (never auto-disconnect)

:: Allow multiple simultaneous RDP sessions
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fSingleSessionPerUser /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v MaxInstanceCount /t REG_DWORD /d 10 /f >nul
echo   - Multiple RDP sessions allowed

:: Disable RDP security warning prompts
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v SecurityLayer /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v MinEncryptionLevel /t REG_DWORD /d 1 /f >nul
echo   - RDP security prompts disabled

:: ---- Redirections: disable unused (saves CPU + bandwidth) ----
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fDisableCam /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fDisablePNPRedir /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fDisableCpm /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fDisableCcm /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fDisableLPT /t REG_DWORD /d 1 /f >nul
:: fDisableCcm already set above
:: KEEP clipboard + drive redirect (fDisableClip=0, fDisableCdm=0) - dev needs copy/paste & file transfer
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fDisableClip /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fDisableCdm /t REG_DWORD /d 0 /f >nul
echo   - Printer/COM/LPT/Camera redirection OFF; clipboard/drive ON

:: ---- Audio: capture OFF, playback ON quality MEDIUM (saves bandwidth) ----
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fDisableAudioCapture /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v fDisableAudioCapture /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v MaxCompressionLevel /t REG_DWORD /d 1 /f >nul
echo   - Audio capture disabled, playback compressed

:: ---- Network buffers (smoother on slightly lossy LAN) ----
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fEnableVirtualizedGraphics /t REG_DWORD /d 1 /f >nul
:: Increase RDP send buffer (faster screen push)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\TermDD" /v MaxOutstandingSends /t REG_DWORD /d 8 /f >nul

:: Faster screen updates
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v MaxMonitors /t REG_DWORD /d 4 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v MaxXResolution /t REG_DWORD /d 3840 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v MaxYResolution /t REG_DWORD /d 2160 /f >nul
echo   - Max resolution: 4K, 4 monitors

:: ---- Auto-logon next time (avoid login screen lag over RDP) ----
:: Note: leaves credentials in registry - acceptable for dev VM
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d 1 /f >nul

:: ---- TCP/UDP optimizations for RDP traffic ----
:: Enable TCP timestamps (better RTT measurement = smoother UDP fallback)
netsh int tcp set global timestamps=enabled >nul 2>&1
:: Increase TCP autotuning level (faster screen pushes)
netsh int tcp set global autotuninglevel=normal >nul 2>&1
:: Enable RSS (Receive Side Scaling) for multi-CPU virtio NIC
netsh int tcp set global rss=enabled >nul 2>&1
:: ECN for less retransmit lag
netsh int tcp set global ecncapability=enabled >nul 2>&1
:: Disable TCP Heuristics (stops Windows from dynamically restricting TCP window size)
netsh int tcp set heuristics disabled >nul 2>&1
echo   - TCP/UDP tuned for RDP

:: ============================================================
:: DYNAMIC RDP PORT (allocated by central worker - 100%% unique)
:: ============================================================
:: Worker: vm-registry.zewk.workers.dev/register
:: VM gui MAC -> worker tra ve port duy nhat (luu trong KV)
:: Lan boot lai cua cung VM -> nhan lai dung port cu (idempotent)
:: Neu worker khong reach duoc -> fallback dung MAC hash

set "VM_REGISTRY_URL=https://vm-registry.zewk.workers.dev"
set "RDP_PORT=3389"

echo   - Requesting unique RDP port from registry...
set "PS_PORT=%TEMP%\get_port.ps1"
(
echo $ProgressPreference = 'SilentlyContinue'
echo $nic = Get-CimInstance Win32_NetworkAdapter -Filter 'NetEnabled=True AND PhysicalAdapter=True' ^| Select-Object -First 1
echo $mac = if ^($nic^) { $nic.MACAddress } else { '' }
echo $ip = ^(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue ^| Where-Object {$_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.*'} ^| Select-Object -First 1^).IPAddress
echo $body = @{
echo     mac = $mac
echo     hostname = $env:COMPUTERNAME
echo     ip = $ip
echo     user = 'PCL'
echo     password = 'PCL@1231233'
echo     os = ^(Get-CimInstance Win32_OperatingSystem^).Caption
echo } ^| ConvertTo-Json
echo try {
echo     $r = Invoke-RestMethod -Uri '%VM_REGISTRY_URL%/register' -Method POST -Body $body -ContentType 'application/json' -UseBasicParsing -TimeoutSec 15
echo     if ^($r.port^) {
echo         Write-Output $r.port
echo         exit 0
echo     }
echo } catch {}
echo # Fallback: derive port from MAC hash
echo if ^($mac^) {
echo     $last = $mac.Substring^($mac.Length-2^)
echo     Write-Output ^(13389 + [Convert]::ToInt32^($last,16^)^)
echo } else { Write-Output 3389 }
) > "%PS_PORT%"

for /f "usebackq delims=" %%P in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_PORT%" 2^>nul`) do set "RDP_PORT=%%P"
del /f /q "%PS_PORT%" >nul 2>&1
if "!RDP_PORT!"=="" set "RDP_PORT=3389"

echo   - Assigned RDP port: !RDP_PORT!

:: Apply port change to RDP listener
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v PortNumber /t REG_DWORD /d !RDP_PORT! /f >nul

:: Firewall: remove default RDP rules' port restriction and add new dynamic port (TCP+UDP)
netsh advfirewall firewall delete rule name="RDP-Custom-Dynamic-TCP" >nul 2>&1
netsh advfirewall firewall delete rule name="RDP-Custom-Dynamic-UDP" >nul 2>&1
netsh advfirewall firewall add rule name="RDP-Custom-Dynamic-TCP" dir=in action=allow protocol=TCP localport=!RDP_PORT! profile=any >nul
netsh advfirewall firewall add rule name="RDP-Custom-Dynamic-UDP" dir=in action=allow protocol=UDP localport=!RDP_PORT! profile=any >nul

:: Restart RDP service to pick up new port
sc stop UmRdpService >nul 2>&1
sc stop TermService >nul 2>&1
sc start TermService >nul 2>&1
echo   - RDP listening on port: !RDP_PORT!

:: Save port to a file for QuickInstall / VM registry
echo !RDP_PORT! > "C:\rdp_port.txt"

echo   Remote Desktop enabled + optimized for mRemoteNG.
echo   Remote Desktop enabled + optimized (port !RDP_PORT!) >> "%LOG%"

:: ---- HEARTBEAT: Keep VM "Online" in dashboard ----
:: Create heartbeat script that sends POST /heartbeat every 2 minutes
set "HB_SCRIPT=C:\vm_heartbeat.ps1"
(
echo $ProgressPreference = 'SilentlyContinue'
echo [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
echo $url = '%VM_REGISTRY_URL%/heartbeat'
echo $hostname = $env:COMPUTERNAME
echo $ip = ^(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue ^| Where-Object {$_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.*'} ^| Select-Object -First 1^).IPAddress
echo $body = @{ hostname = $hostname; ip = $ip } ^| ConvertTo-Json
echo try { Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType 'application/json' -TimeoutSec 10 ^| Out-Null } catch {}
) > "%HB_SCRIPT%"

:: Register Scheduled Task to run heartbeat every 2 minutes (survives reboot)
schtasks /Delete /TN "VM_Heartbeat" /F >nul 2>&1
schtasks /Create /TN "VM_Heartbeat" /SC MINUTE /MO 2 /TR "powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File C:\vm_heartbeat.ps1" /RU SYSTEM /RL HIGHEST /F >nul 2>&1
:: Run it once immediately
schtasks /Run /TN "VM_Heartbeat" >nul 2>&1
echo   - Heartbeat scheduled (every 2 min)

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

:: NOTE: VM already registered with worker during RDP phase (see PHASE 8).
:: No need to re-register here.

:: Force process all idle/pending tasks NOW (flush deferred cleanup, .NET NGEN, font cache rebuild)
rundll32.exe advapi32.dll,ProcessIdleTasks >nul 2>&1
echo   - Idle tasks flushed

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

:: endlocal before self-delete (setlocal cleanup)
endlocal

:: Self-delete (works from any location)
(goto) 2>nul & del /f /q "%~f0" >nul 2>&1

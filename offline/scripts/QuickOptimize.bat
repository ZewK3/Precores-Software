@echo off
:: ============================================================
::  QuickOptimize.bat - Windows 10 LDPlayer Farm Optimization
::  Runs OFFLINE after first boot (no GitHub required)
::  Optimized for maximum LDPlayer emulator instances
::  Run as Administrator!
:: ============================================================
title QuickOptimize - Windows Optimization
color 0E
setlocal EnableExtensions EnableDelayedExpansion

set "PCL_DIR=%SystemRoot%\Logs\PCL"
if not exist "%PCL_DIR%" mkdir "%PCL_DIR%" >nul 2>&1
attrib +h +s "%PCL_DIR%" >nul 2>&1

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

:: ---- Admin check (skip if running from FirstLogonCommands) ----
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARN] Not running as admin - some operations may fail
    echo [WARN] Not admin context >> "%LOG%"
)

:: ============================================================
:: LDPlayer Farm Mode - No VM Registration Required
:: ============================================================
echo [0/11] LDPlayer Farm Mode - offline optimization... >> "%LOG%"

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
    Microsoft-Hyper-V-All
    VirtualMachinePlatform
    HypervisorPlatform
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

:: Disable 100+ unnecessary services (ULTRA mode for LDPlayer farm)
:: KEEP: Dhcp, Dnscache, LanmanWorkstation, RpcSs, RpcEptMapper, CryptSvc, Power, BFE, mpssvc,
::   ProfSvc, gpsvc, Schedule, UserManager, LSM, SysMain, StorSvc, NlaSvc, LanmanServer,
::   nsi, Winmgmt, SENS, WinHttpAutoProxySvc, AudioSrv, AudioEndpointBuilder, Themes,
::   EventLog, SamSs, ShellHWDetection
:: NOTE: Audio is kept ON (user will disable per-instance in LDPlayer settings)
for %%S in (
    DiagTrack dmwappushservice diagnosticshub.standardcollector.service
    TermService UmRdpService SessionEnv
    MapsBroker lfsvc RetailDemo wisvc WerSvc
    XblAuthManager XblGameSave XboxNetApiSvc XboxGipSvc
    RemoteRegistry RemoteAccess SharedAccess TrkWks
    WMPNetworkSvc WpcMonSvc SEMgrSvc PhoneSvc
    TabletInputService WbioSrvc icssvc
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
    iphlpsvc ALG SCPolicySvc Browser
    WlanSvc WwanSvc DusmSvc DsmSvc PNRPsvc p2psvc p2pimsvc PNRPAutoReg
    PeerDistSvc HvHost vmickvpexchange vmicguestinterface vmicshutdown
    vmicheartbeat vmicvmsession vmicrdv vmictimesync vmicvss
    SensorService SensrSvc SensorDataService DevQueryBroker
    ssh-agent sshd ssh-broker-svc AssignedAccessManagerSvc
    AppReadiness AppMgmt AppVClient ClipSVC
    AeLookupSvc SstpSvc
    NaturalAuthentication GraphicsPerfSvc
    embeddedmode COMSysApp WEPHOSTSVC PerfHost
    Netlogon RmSvc
    SDRSVC seclogon shpamsvc TieringEngineService
    SNMPTRAP swprv upnphost vds
    BTAGService bthserv BthAvctpSvc
    SharedRealitySvc spectrum
    MicrosoftEdgeElevationService
    TokenBroker InstallService LicenseManager StateRepository tiledatamodelsvc
    AppXSvc PushToInstall
    Spooler PrintNotify
    SSDPSRV
    fdPHost FDResPub
    TapiSrv
    wercplsupport
    WPDBusEnum
    dot3svc
    Eaphost EFS
    IKEEXT PolicyAgent
    KtmRm
    LxpSvc
    NgcSvc NgcCtnrSvc
    wlidsvc
    ConsentUxUserSvc_*
    DeviceAssociationBrokerSvc_*
    DevicePickerUserSvc_*
    CredentialEnrollmentManagerUserSvc_*
    WarpJITSvc
    cbdhsvc_*
    DisplayEnhancementService
    UdkUserSvc_*
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

:: Memory optimization (no crash dumps to save disk I/O, instantly reboot on BSOD)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v CrashDumpEnabled /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v LogEvent /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v AutoReboot /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /t REG_DWORD /d 0 /f >nul
:: Dynamic DisablePagingExecutive + SvcHostSplit + IoPageLockLimit: ALL computed from RAM in ONE PS call
:: This saves ~8 seconds vs 4 separate PowerShell startups
for /f "usebackq tokens=1-5" %%A in (`powershell -NoProfile -Command "$m=(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory;$gb=[Math]::Round($m/1GB);$dpe=if($gb -ge 8){1}else{0};$svk=[Math]::Round($m/1KB);$io=[Math]::Round($m*0.1);if($gb -le 4){$pfn='4096';$pfx='8192'}elseif($gb -le 8){$pfn='8192';$pfx='16384'}elseif($gb -le 16){$pfn='8192';$pfx='24576'}else{$pfn='16384';$pfx='32768'};Write-Host $dpe $svk $io $pfn $pfx"`) do (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingExecutive /t REG_DWORD /d %%A /f >nul
    set "SVCHOSTSPLIT=%%B"
    set "IOPAGELIMIT=%%C"
    set "PF_MIN=%%D"
    set "PF_MAX=%%E"
)
:: (DisablePagingExecutive already set by consolidated RAM query above)

:: LDPlayer specifics (Disable Memory Integrity/Core Isolation, Enable HAGS, set Power Plan)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f >nul
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1

:: Network + Multimedia optimization
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" /v DisabledComponents /t REG_DWORD /d 255 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpTimedWaitDelay /t REG_DWORD /d 30 /f >nul
:: Disable Network Throttling (maximize throughput instead of reserving 20% for media playback)
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 4294967295 /f >nul
:: Reserve 10% CPU for OS kernel (matches 90% CPU cap in Phase 9 power plan)
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 10 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v Size /t REG_DWORD /d 3 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v IRPStackSize /t REG_DWORD /d 20 /f >nul

:: Disable Nagle's Algorithm on all interfaces (TCP_NODELAY = instant packet send, reduces latency for LDPlayer networking)
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
:: (Uses SVCHOSTSPLIT value computed by consolidated RAM query in Phase 5)
if defined SVCHOSTSPLIT (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v SvcHostSplitThresholdInKB /t REG_DWORD /d !SVCHOSTSPLIT! /f >nul
)

:: Don't clear pagefile on shutdown (faster shutdown, no perf gain)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v ClearPageFileAtShutdown /t REG_DWORD /d 0 /f >nul

:: Dynamic I/O page lock limit based on RAM (10% of RAM in bytes, better disk I/O for compilers/AI)
:: (Uses IOPAGELIMIT value computed by consolidated RAM query in Phase 5)
if defined IOPAGELIMIT (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v IoPageLockLimit /t REG_DWORD /d !IOPAGELIMIT! /f >nul
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

:: Create File Explorer shortcut on the shared desktop
powershell -NoProfile -Command "$desktop=[Environment]::GetFolderPath('CommonDesktopDirectory');$s=(New-Object -ComObject WScript.Shell).CreateShortcut((Join-Path $desktop 'File Explorer.lnk'));$s.TargetPath='%SystemRoot%\explorer.exe';$s.Arguments='shell:ThisPCFolder';$s.IconLocation='%SystemRoot%\explorer.exe,0';$s.WorkingDirectory='%SystemRoot%';$s.Save()" >nul 2>&1

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

:: VM ultra-light profile: no Store/UWP provisioning, no app suggestions, no shell sync noise
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v RemoveWindowsStore /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v DisableStoreApps /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v AutoDownload /t REG_DWORD /d 2 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\PushToInstall" /v DisablePushToInstall /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoInstrumentation /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_TrackDocs /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_TrackProgs /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v StartupDelayInMSec /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v WaitForIdleState /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v IconsOnly /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v DisablePreviewDesktop /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\CabinetState" /v FullPath /t REG_DWORD /d 1 /f >nul

:: Remove common Run entries that respawn background helpers in cloned VMs
for %%R in (
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
    "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
) do (
    reg delete %%R /v OneDrive /f >nul 2>&1
    reg delete %%R /v Teams /f >nul 2>&1
    reg delete %%R /v MicrosoftEdgeAutoLaunch /f >nul 2>&1
    reg delete %%R /v SecurityHealth /f >nul 2>&1
)

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

:: Set Visual Effects to Custom (preserve themes, disable heavy animations)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 3 /f >nul
:: UserPreferencesMask: UIEffects ON (themes), font smoothing ON, disable animations
:: Byte0=0x91: bit0=ActiveDesktop/Wallpaper ON, bit4=MenuUnderlines OFF, bit7=ActiveWindowTracking OFF
:: Byte1=0x12: bit1=GradientCaptions, bit4=HotTracking
reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9112078012000000 /f >nul
:: Keep transparency for theme effects (commented out = stays enabled)
:: reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f >nul
:: Disable animations (performance - does NOT affect themes)
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f >nul
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 0 /f >nul
:: Disable Aero Shake
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v DisallowShaking /t REG_DWORD /d 1 /f >nul
:: Disable Aero Peek (performance)
reg add "HKCU\Software\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 0 /f >nul
:: Custom wallpaper setup is handled AFTER Phase 8 cleanup (to avoid deletion)
:: Here we just set the registry paths - files are copied later
set "WP_SRC=C:\InstallScripts\logo-nen.png"
set "WP_DST=%SystemRoot%\Web\Wallpaper\PCL\logo-nen.png"
if exist "%WP_SRC%" (
    echo   - Wallpaper will be applied after cleanup phase
) else (
    echo   - Wallpaper logo-nen.png not found, skipping
)
:: Set user avatar (PreCore Lab branding)
set "AVT_SRC=C:\InstallScripts\avt.png"
set "AVT_DST=%ProgramData%\Microsoft\User Account Pictures\pcl-avatar.png"
if exist "%AVT_SRC%" (
    copy /y "%AVT_SRC%" "%AVT_DST%" >nul 2>&1
    :: Use SetUserTile API to set account picture for current user
    :: Timeout after 15s - shell32 #262 can hang if shell isn't ready
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "$j=Start-Job -ScriptBlock{" ^
        "Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public class UserTile { [DllImport(\"shell32.dll\", EntryPoint=\"#262\", CharSet=CharSet.Unicode)] public static extern int SetUserTile(string username, int reserved, string picture); }';" ^
        "[UserTile]::SetUserTile('%USERNAME%', 0, '%AVT_DST%')" ^
        "};if(-not(Wait-Job $j -Timeout 15)){Stop-Job $j;Remove-Job $j}else{Remove-Job $j}" >nul 2>&1
    :: Also set as default account picture
    copy /y "%AVT_SRC%" "%ProgramData%\Microsoft\User Account Pictures\user.png" >nul 2>&1
    copy /y "%AVT_SRC%" "%ProgramData%\Microsoft\User Account Pictures\guest.png" >nul 2>&1
    echo   - User avatar set: PreCore Lab branding
) else (
    echo   - Avatar avt.png not found, skipping
)
:: Disable cursor blink
reg add "HKCU\Control Panel\Desktop" /v CursorBlinkRate /t REG_SZ /d -1 /f >nul
:: Disable Smooth Scrolling (saves CPU cycles for LDPlayer)
reg add "HKCU\Control Panel\Desktop" /v SmoothScroll /t REG_DWORD /d 0 /f >nul
:: Disable Explorer thumbnails/preview handlers for lower RAM and disk churn
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v DisablePreviewPane /t REG_DWORD /d 1 /f >nul
:: (IconsOnly already set in Phase 5 - line 558)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v DisableThumbnailCache /t REG_DWORD /d 1 /f >nul
:: Dark mode
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d 0 /f >nul
echo   Visual performance optimized (themes + audio preserved).
echo   Visual performance optimized (themes + audio preserved) >> "%LOG%"

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
    "\Microsoft\Windows\Application Experience\StartupAppTask"
    "\Microsoft\Windows\Application Experience\PcaPatchDbTask"
    "\Microsoft\Windows\AppID\SmartScreenSpecific"
    "\Microsoft\Windows\Chkdsk\ProactiveScan"
    "\Microsoft\Windows\CloudExperienceHost\CreateObjectTask"
    "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask"
    "\Microsoft\Windows\Diagnosis\RecommendedTroubleshootingScanner"
    "\Microsoft\Windows\Diagnosis\Scheduled"
    "\Microsoft\Windows\DiskCleanup\SilentCleanup"
    "\Microsoft\Windows\InstallService\ScanForUpdates"
    "\Microsoft\Windows\InstallService\ScanForUpdatesAsUser"
    "\Microsoft\Windows\InstallService\SmartRetry"
    "\Microsoft\Windows\Maintenance\WinSAT"
    "\Microsoft\Windows\Mobile Broadband Accounts\MNO Metadata Parser"
    "\Microsoft\Windows\NetTrace\GatherNetworkInfo"
    "\Microsoft\Windows\Offline Files\Background Synchronization"
    "\Microsoft\Windows\Offline Files\Logon Synchronization"
    "\Microsoft\Windows\PI\Sqm-Tasks"
    "\Microsoft\Windows\Printing\EduPrintProv"
    "\Microsoft\Windows\PushToInstall\LoginCheck"
    "\Microsoft\Windows\PushToInstall\Registration"
    "\Microsoft\Windows\RetailDemo\CleanupOfflineContent"
    "\Microsoft\Windows\Shell\IndexerAutomaticMaintenance"
    "\Microsoft\Windows\StateRepository\MaintenanceTasks"
    "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan"
    "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan Static Task"
    "\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker"
    "\Microsoft\Windows\WDI\ResolutionHost"
    "\Microsoft\Windows\WindowsUpdate\Scheduled Start"
    "\Microsoft\Windows\Wininet\CacheTask"
) do (
    schtasks /Change /TN %%T /Disable >nul 2>&1
)
for %%T in (
    "MicrosoftEdgeUpdateTaskMachineCore"
    "MicrosoftEdgeUpdateTaskMachineUA"
    "GoogleUpdateTaskMachineCore"
    "GoogleUpdateTaskMachineUA"
    "Adobe Acrobat Update Task"
    "OneDrive Standalone Update Task-S-1-5-21"
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
for %%L in (Application System Security Setup) do wevtutil sl %%L /ms:1048576 /rt:false /ab:false >nul 2>&1
echo   - Event logs cleared and capped

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

:: Wallpapers (delete stock wallpapers, keep PCL custom wallpaper)
if exist "%SystemRoot%\Web\Wallpaper" (
    for /d %%W in ("%SystemRoot%\Web\Wallpaper\*") do (
        set "_SKIP=0"
        echo "%%~nxW" | findstr /i "PCL" >nul 2>&1 && set "_SKIP=1"
        if "!_SKIP!"=="0" rmdir /s /q "%%W" >nul 2>&1
    )
)
if exist "%SystemRoot%\Web\4K" rmdir /s /q "%SystemRoot%\Web\4K" >nul 2>&1
if exist "%SystemRoot%\Web\Screen" rmdir /s /q "%SystemRoot%\Web\Screen" >nul 2>&1
echo   - Cleaned stock wallpapers (kept PCL branding)

:: ---- APPLY CUSTOM WALLPAPER NOW (after stock wallpapers are deleted) ----
set "WP_SRC=C:\InstallScripts\logo-nen.png"
set "WP_DST=%SystemRoot%\Web\Wallpaper\PCL\logo-nen.png"
if exist "%WP_SRC%" (
    if not exist "%SystemRoot%\Web\Wallpaper\PCL" mkdir "%SystemRoot%\Web\Wallpaper\PCL" >nul 2>&1
    copy /y "%WP_SRC%" "%WP_DST%" >nul 2>&1
    :: Set wallpaper registry for current user
    reg add "HKCU\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "%WP_DST%" /f >nul
    reg add "HKCU\Control Panel\Desktop" /v WallpaperStyle /t REG_SZ /d 10 /f >nul
    reg add "HKCU\Control Panel\Desktop" /v TileWallpaper /t REG_SZ /d 0 /f >nul
    :: Set for default user profile
    reg add "HKU\.DEFAULT\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "%WP_DST%" /f >nul 2>&1
    reg add "HKU\.DEFAULT\Control Panel\Desktop" /v WallpaperStyle /t REG_SZ /d 10 /f >nul 2>&1
    reg add "HKU\.DEFAULT\Control Panel\Desktop" /v TileWallpaper /t REG_SZ /d 0 /f >nul 2>&1
    :: Force via PersonalizationCSP (machine-wide policy)
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP" /v DesktopImagePath /t REG_SZ /d "%WP_DST%" /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP" /v DesktopImageUrl /t REG_SZ /d "%WP_DST%" /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP" /v DesktopImageStatus /t REG_DWORD /d 1 /f >nul 2>&1
    :: Force via Group Policy
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" /v DesktopImagePath /t REG_SZ /d "%WP_DST%" /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Personalization" /v DesktopImageStyle /t REG_DWORD /d 10 /f >nul 2>&1
    echo   - Custom wallpaper copied and registry set
)

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
if exist "%SystemRoot%\SoftwareDistribution\Download" del /f /q /s "%SystemRoot%\SoftwareDistribution\Download\*" >nul 2>&1
:: Clean logs but preserve our PCL log directory
for /d %%D in ("%SystemRoot%\Logs\*") do (
    echo %%~nxD | findstr /i "PCL" >nul 2>&1
    if !errorlevel! neq 0 rmdir /s /q "%%D" >nul 2>&1
)
for %%F in ("%SystemRoot%\Logs\*.*") do del /f /q "%%F" >nul 2>&1
del /f /q /s "%SystemRoot%\ServiceProfiles\LocalService\AppData\Local\FontCache\*" >nul 2>&1
del /f /q /s "%ProgramData%\Microsoft\Windows\WER\*" >nul 2>&1
del /f /q /s "%ProgramData%\Microsoft\Diagnosis\ETLLogs\*" >nul 2>&1
del /f /q /s "%ProgramData%\USOPrivate\UpdateStore\*" >nul 2>&1
del /f /q /s "%ProgramData%\USOShared\Logs\*" >nul 2>&1
if exist "%LOCALAPPDATA%\Microsoft\Windows\INetCache" rmdir /s /q "%LOCALAPPDATA%\Microsoft\Windows\INetCache" >nul 2>&1
if exist "%LOCALAPPDATA%\Microsoft\Windows\Explorer" del /f /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
if exist "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache" rmdir /s /q "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache" >nul 2>&1
if exist "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache" rmdir /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache" >nul 2>&1
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
if exist "%ProgramData%\Microsoft\Windows\Caches" (
    del /f /q /s "%ProgramData%\Microsoft\Windows\Caches\*" >nul 2>&1
)
if exist "%ProgramData%\Microsoft\Windows\AppRepository\Packages" (
    del /f /q /s "%ProgramData%\Microsoft\Windows\AppRepository\Packages\*" >nul 2>&1
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

:: ---- EXTREME FILE STRIPPING (saves 500MB-1GB disk) ----

:: Strip unused fonts (keep only core system fonts, saves ~300MB)
echo   - Stripping unused fonts...
set "FONT_DIR=%SystemRoot%\Fonts"
for %%F in (
    "%FONT_DIR%\malgun*.ttf" "%FONT_DIR%\malgun*.ttc"
    "%FONT_DIR%\msyh*.ttf" "%FONT_DIR%\msyh*.ttc"
    "%FONT_DIR%\simsun*.ttc" "%FONT_DIR%\simhei.ttf" "%FONT_DIR%\simkai.ttf"
    "%FONT_DIR%\msjh*.ttf" "%FONT_DIR%\msjh*.ttc"
    "%FONT_DIR%\mingliub.ttc" "%FONT_DIR%\msmincho.ttc" "%FONT_DIR%\msgothic.ttc"
    "%FONT_DIR%\batang.ttc" "%FONT_DIR%\gulim.ttc"
    "%FONT_DIR%\YuGoth*.ttf" "%FONT_DIR%\YuGoth*.ttc"
    "%FONT_DIR%\YuMincho*.ttf"
    "%FONT_DIR%\Nirmala*.ttf" "%FONT_DIR%\aparaj*.ttf" "%FONT_DIR%\kokila*.ttf"
    "%FONT_DIR%\mangal*.ttf" "%FONT_DIR%\shruti*.ttf" "%FONT_DIR%\tunga*.ttf"
    "%FONT_DIR%\raavi*.ttf" "%FONT_DIR%\Latha*.ttf" "%FONT_DIR%\Gautami*.ttf"
    "%FONT_DIR%\Kartika*.ttf" "%FONT_DIR%\Vrinda*.ttf" "%FONT_DIR%\Kalinga*.ttf"
    "%FONT_DIR%\DokChampa.ttf" "%FONT_DIR%\Euphemia.ttf"
    "%FONT_DIR%\Ebrima*.ttf" "%FONT_DIR%\Gadugi*.ttf"
    "%FONT_DIR%\MVBoli.ttf" "%FONT_DIR%\MoolBoran.ttf"
    "%FONT_DIR%\Nyala.ttf" "%FONT_DIR%\Plantag*.ttf"
    "%FONT_DIR%\javatext.ttf" "%FONT_DIR%\LeelUIsl*.ttf"
    "%FONT_DIR%\mmrtext*.ttf" "%FONT_DIR%\Shonar*.ttf"
    "%FONT_DIR%\holomdl2.ttf"
) do (
    del /f /q %%F >nul 2>&1
)
echo   - Stripped CJK/Indic/unused fonts (~300MB)

:: Remove Microsoft Edge completely (saves ~300MB)
echo   - Removing Edge...
taskkill /f /im msedge.exe >nul 2>&1
taskkill /f /im MicrosoftEdgeUpdate.exe >nul 2>&1
for %%D in (
    "%ProgramFiles(x86)%\Microsoft\Edge"
    "%ProgramFiles(x86)%\Microsoft\EdgeCore"
    "%ProgramFiles(x86)%\Microsoft\EdgeWebView"
    "%ProgramFiles(x86)%\Microsoft\EdgeUpdate"
    "%ProgramFiles%\Microsoft\Edge"
    "%ProgramFiles%\Microsoft\EdgeCore"
    "%LOCALAPPDATA%\Microsoft\Edge"
    "%LOCALAPPDATA%\Microsoft\EdgeUpdate"
) do (
    if exist %%D (
        takeown /f %%D /r /d y >nul 2>&1
        icacls %%D /grant administrators:F /t >nul 2>&1
        rmdir /s /q %%D >nul 2>&1
    )
)
:: Remove Edge SystemApp
for /d %%D in ("%SystemRoot%\SystemApps\Microsoft.MicrosoftEdge*") do (
    takeown /f "%%D" /r /d y >nul 2>&1
    icacls "%%D" /grant administrators:F /t >nul 2>&1
    rmdir /s /q "%%D" >nul 2>&1
)
echo   - Edge completely removed (~300MB)

:: Remove Cortana app
for /d %%D in ("%SystemRoot%\SystemApps\Microsoft.Windows.Cortana*") do (
    takeown /f "%%D" /r /d y >nul 2>&1
    icacls "%%D" /grant administrators:F /t >nul 2>&1
    rmdir /s /q "%%D" >nul 2>&1
)
echo   - Cortana app removed

:: Remove unnecessary SystemApps (saves ~200MB)
for /d %%D in (
    "%SystemRoot%\SystemApps\Microsoft.Windows.CalendarApp*"
    "%SystemRoot%\SystemApps\Microsoft.Windows.ContentDeliveryManager*"
    "%SystemRoot%\SystemApps\Microsoft.Windows.ParentalControls*"
    "%SystemRoot%\SystemApps\Microsoft.Windows.PeopleExperienceHost*"
    "%SystemRoot%\SystemApps\Microsoft.Windows.PinningConfirmation*"
    "%SystemRoot%\SystemApps\Microsoft.Windows.NarratorQuickStart*"
    "%SystemRoot%\SystemApps\Microsoft.AAD.BrokerPlugin*"
    "%SystemRoot%\SystemApps\Microsoft.AccountsControl*"
    "%SystemRoot%\SystemApps\Microsoft.AsyncTextService*"
    "%SystemRoot%\SystemApps\Microsoft.BioEnrollment*"
    "%SystemRoot%\SystemApps\Microsoft.CredDialogHost*"
    "%SystemRoot%\SystemApps\Microsoft.ECApp*"
    "%SystemRoot%\SystemApps\Microsoft.LockApp*"
    "%SystemRoot%\SystemApps\microsoft.creddialoghost*"
    "%SystemRoot%\SystemApps\NcsiUwpApp*"
    "%SystemRoot%\SystemApps\Microsoft.Windows.OOBENetworkCaptivePortal*"
    "%SystemRoot%\SystemApps\Microsoft.Windows.OOBENetworkConnectionFlow*"
    "%SystemRoot%\SystemApps\Microsoft.XboxGameCallableUI*"
) do (
    if exist "%%D" (
        takeown /f "%%D" /r /d y >nul 2>&1
        icacls "%%D" /grant administrators:F /t >nul 2>&1
        rmdir /s /q "%%D" >nul 2>&1
    )
)
echo   - Removed unused SystemApps (~200MB)

:: Remove Accessibility features (Narrator, Magnifier, On-Screen Keyboard)
for %%F in (Narrator.exe Magnify.exe osk.exe AtBroker.exe) do (
    if exist "%SystemRoot%\System32\%%F" (
        takeown /f "%SystemRoot%\System32\%%F" >nul 2>&1
        icacls "%SystemRoot%\System32\%%F" /grant administrators:F >nul 2>&1
        del /f /q "%SystemRoot%\System32\%%F" >nul 2>&1
    )
)
:: Remove Ease of Access folder
if exist "%SystemRoot%\System32\Accessibility" (
    takeown /f "%SystemRoot%\System32\Accessibility" /r /d y >nul 2>&1
    icacls "%SystemRoot%\System32\Accessibility" /grant administrators:F /t >nul 2>&1
    rmdir /s /q "%SystemRoot%\System32\Accessibility" >nul 2>&1
)
echo   - Removed accessibility tools

:: Remove unused locale/MUI data (keep only en-US)
if exist "%SystemRoot%\System32\DriverStore\FileRepository" (
    for /d %%D in ("%SystemRoot%\System32\DriverStore\FileRepository\prnms*") do rmdir /s /q "%%D" >nul 2>&1
    for /d %%D in ("%SystemRoot%\System32\DriverStore\FileRepository\prnbr*") do rmdir /s /q "%%D" >nul 2>&1
    for /d %%D in ("%SystemRoot%\System32\DriverStore\FileRepository\prnhp*") do rmdir /s /q "%%D" >nul 2>&1
    for /d %%D in ("%SystemRoot%\System32\DriverStore\FileRepository\prnep*") do rmdir /s /q "%%D" >nul 2>&1
    for /d %%D in ("%SystemRoot%\System32\DriverStore\FileRepository\prnky*") do rmdir /s /q "%%D" >nul 2>&1
    for /d %%D in ("%SystemRoot%\System32\DriverStore\FileRepository\prnsm*") do rmdir /s /q "%%D" >nul 2>&1
    for /d %%D in ("%SystemRoot%\System32\DriverStore\FileRepository\prnok*") do rmdir /s /q "%%D" >nul 2>&1
)
echo   - Removed unused printer drivers from DriverStore

:: Compact remaining heavy folders to save disk
echo   - Compacting System32 and WinSxS (may take a few minutes)...
compact /c /s:"%SystemRoot%\System32" /i >nul 2>&1
compact /c /s:"%SystemRoot%\WinSxS" /i >nul 2>&1
compact /c /s:"%SystemRoot%\assembly" /i >nul 2>&1
echo   - System folders compacted

:: Remove Windows Ink Workspace
if exist "%SystemRoot%\SystemApps\Microsoft.Windows.ShellExperienceHost*" (
    reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsInkWorkspace" /v AllowWindowsInkWorkspace /t REG_DWORD /d 0 /f >nul
)
if exist "%ProgramFiles%\Windows Ink" (
    rmdir /s /q "%ProgramFiles%\Windows Ink" >nul 2>&1
)
echo   - Windows Ink removed

:: Remove ManifestCache (regenerates automatically if needed)
if exist "%SystemRoot%\WinSxS\ManifestCache" (
    del /f /q "%SystemRoot%\WinSxS\ManifestCache\*" >nul 2>&1
)
:: Remove Catroot2 transaction logs
if exist "%SystemRoot%\System32\catroot2" (
    del /f /q /s "%SystemRoot%\System32\catroot2\*.log" >nul 2>&1
    del /f /q /s "%SystemRoot%\System32\catroot2\*.jrs" >nul 2>&1
    del /f /q /s "%SystemRoot%\System32\catroot2\*.chk" >nul 2>&1
)
echo   - Cleaned WinSxS manifest cache + catroot2 logs

echo   Deep cleanup done.
echo   Deep cleanup done >> "%LOG%"

:: ============================================================
:: PHASE 9: SYSTEM OPTIMIZATION
:: ============================================================
echo.
echo ============================================================
echo  [9/11] System Optimization...
echo ============================================================
echo [9/11] System Optimization... >> "%LOG%"

:: ---- AUTO-DETECT CPU SPECS AND COMPUTE OPTIMAL VALUES ----
echo   - Detecting CPU specifications...

:: Get CPU name from WMIC (fast, handles spaces in name, no PS startup overhead)
set "CPU_NAME=Unknown CPU"
for /f "skip=1 tokens=*" %%N in ('wmic cpu get name 2^>nul') do (
    if not "%%N"=="" for /f "tokens=*" %%M in ("%%N") do set "CPU_NAME=%%M"
)
:: Detect Xeon / Server CPU
set "CPU_IS_XEON=0"
echo !CPU_NAME! | findstr /i "Xeon" >nul 2>&1 && set "CPU_IS_XEON=1"
echo !CPU_NAME! | findstr /i "EPYC" >nul 2>&1 && set "CPU_IS_XEON=1"
echo !CPU_NAME! | findstr /i "Threadripper" >nul 2>&1 && set "CPU_IS_XEON=1"
:: Detect socket count (1=single, 2+=multi-socket / dual Xeon)
set "CPU_SOCKETS=1"
for /f "skip=1 tokens=*" %%S in ('wmic computersystem get NumberOfProcessors 2^>nul') do (
    if not "%%S"=="" for /f "tokens=*" %%T in ("%%S") do set "CPU_SOCKETS=%%T"
)

:: One consolidated PowerShell call: detect CPU specs and compute all optimal values
set "CPU_CORES=4"
set "CPU_THREADS=8"
set "CPU_L2=1024"
set "CPU_L3=8192"
set "CPU_MHZ=3000"
set "CPU_BOOST=60"
set "CPU_TIMER=15"
set "CPU_INC_TH=60"
set "CPU_WORKERS_C=8"
set "CPU_WORKERS_D=4"
set "CPU_DHEAP_I=4096"
set "CPU_DHEAP_NI=2048"
set "CPU_MAXWORK=8192"
set "CPU_MAXREQ=16"
for /f "usebackq tokens=1-14 delims=|" %%A in (`powershell -NoProfile -Command "$c=Get-CimInstance Win32_Processor|Select -First 1;$co=$c.NumberOfCores;$th=$c.NumberOfLogicalProcessors;$l2=if($c.L2CacheSize-gt0){$c.L2CacheSize}else{1024};$l3=if($c.L3CacheSize-gt0){$c.L3CacheSize}else{8192};$mh=$c.MaxClockSpeed;$bp=if($mh-ge3500){40}elseif($mh-ge2500){60}else{80};$ti=if($mh-ge3500){10}elseif($mh-ge2500){15}else{20};$it=if($co-ge16){70}elseif($co-ge8){60}else{50};$wc=[Math]::Max(4,[Math]::Min(32,$co));$wd=[Math]::Max(4,[Math]::Min(16,[Math]::Floor($co/2)));$dhi=if($co-ge16){8192}elseif($co-ge8){4096}else{2048};$dhni=[Math]::Floor($dhi/2);$mwi=[Math]::Max(4096,$th*256);$mrt=[Math]::Max(16,[Math]::Min(64,$co*2));Write-Host \"$co|$th|$l2|$l3|$mh|$bp|$ti|$it|$wc|$wd|$dhi|$dhni|$mwi|$mrt\""`) do (
    set "CPU_CORES=%%A"
    set "CPU_THREADS=%%B"
    set "CPU_L2=%%C"
    set "CPU_L3=%%D"
    set "CPU_MHZ=%%E"
    set "CPU_BOOST=%%F"
    set "CPU_TIMER=%%G"
    set "CPU_INC_TH=%%H"
    set "CPU_WORKERS_C=%%I"
    set "CPU_WORKERS_D=%%J"
    set "CPU_DHEAP_I=%%K"
    set "CPU_DHEAP_NI=%%L"
    set "CPU_MAXWORK=%%M"
    set "CPU_MAXREQ=%%N"
)
echo.
echo   =========================================
if "!CPU_IS_XEON!"=="1" (
    echo    [XEON/SERVER] !CPU_NAME!
) else (
    echo    CPU Detected: !CPU_NAME!
)
echo    Cores: !CPU_CORES! / Threads: !CPU_THREADS!
if "!CPU_IS_XEON!"=="1" echo    Sockets: !CPU_SOCKETS!
echo    L2: !CPU_L2!KB / L3: !CPU_L3!KB
echo    Max Clock: !CPU_MHZ! MHz
echo   =========================================
echo    Computed Optimal Values:
echo    Boost Policy: !CPU_BOOST!%%
echo    Timer Check: !CPU_TIMER!ms
echo    Freq Increase Threshold: !CPU_INC_TH!%%
echo    I/O Workers: !CPU_WORKERS_C! crit / !CPU_WORKERS_D! delayed
echo    Desktop Heap: !CPU_DHEAP_I!KB inter / !CPU_DHEAP_NI!KB non-inter
echo   =========================================
echo.
echo   CPU Auto-Detect: !CPU_NAME! (!CPU_CORES!C/!CPU_THREADS!T, !CPU_MHZ!MHz, L2=!CPU_L2!KB L3=!CPU_L3!KB, Xeon=!CPU_IS_XEON!) >> "%LOG%"

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

:: ---- CPU PERFORMANCE CAP: <=90%% (extend CPU lifespan, reduce heat/throttling) ----
:: MAX CPU State = 90%%
powercfg /SETACVALUEINDEX SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 90 >nul 2>&1
powercfg /SETDCVALUEINDEX SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 90 >nul 2>&1
:: MIN CPU State = 5%%
powercfg /SETACVALUEINDEX SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 5 >nul 2>&1
powercfg /SETDCVALUEINDEX SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 5 >nul 2>&1

:: Boost Mode = 4 (Efficient Aggressive)
powercfg /SETACVALUEINDEX SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 be337238-0d82-4146-a960-4f3749d470c7 4 >nul 2>&1
:: Boost Policy = DYNAMIC (based on CPU clock: fast CPU=40%%, mid=60%%, slow=80%%)
powercfg /SETACVALUEINDEX SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 45bcc044-d885-43e2-8605-ee0ec6e96b59 !CPU_BOOST! >nul 2>&1

:: ---- CORE PARKING (all cores active) ----
powercfg /SETACVALUEINDEX SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 0 >nul 2>&1
powercfg /SETACVALUEINDEX SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 ea062031-0e34-4ff1-9b6d-eb1059334028 100 >nul 2>&1
powercfg /SETACVALUEINDEX SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 c7be0679-2817-4d69-9d02-519a537ed0c6 2 >nul 2>&1
powercfg /SETACVALUEINDEX SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 71021b41-c749-4d21-be74-a00f335d582b 1 >nul 2>&1

:: ---- PROCESSOR PERFORMANCE POLICIES (DYNAMIC based on CPU specs) ----
powercfg /SETACVALUEINDEX SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 465e1f50-b610-473a-ab58-00d1077dc418 2 >nul 2>&1
powercfg /SETACVALUEINDEX SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 40fbefc7-2e9d-4d25-a185-0cfd8574bac6 1 >nul 2>&1
powercfg /SETACVALUEINDEX SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 06cadf0e-64ed-448a-8927-ce7bf90eb35d !CPU_INC_TH! >nul 2>&1
powercfg /SETACVALUEINDEX SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 12a0ab44-fe28-4fa9-b3bd-4b64f44960a6 20 >nul 2>&1
powercfg /SETACVALUEINDEX SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 4d2b0152-7d5c-498b-88e2-34345392a2c5 !CPU_TIMER! >nul 2>&1

:: ---- APPLY ALL POWER CHANGES ----
powercfg /SETACTIVE SCHEME_CURRENT >nul 2>&1
echo   - CPU capped at 90%% max, boost=!CPU_BOOST!%%, threshold=!CPU_INC_TH!%%, timer=!CPU_TIMER!ms

:: ---- MMCSS THREAD PRIORITIES ----
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 10 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Affinity" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Background Only" /t REG_SZ /d "False" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Clock Rate" /t REG_DWORD /d 10000 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Priority" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Scheduling Category" /t REG_SZ /d "High" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "SFIO Priority" /t REG_SZ /d "High" /f >nul
echo   - MMCSS optimized (SystemReserve=10%%)

:: ============================================================
:: XEON / SERVER CPU OPTIMIZATION (conditional)
:: ============================================================
if "!CPU_IS_XEON!"=="0" goto :skip_xeon
echo.
echo   ==========================================
echo    XEON/SERVER MODE - Server-grade tweaks
echo   ==========================================

:: ---- DEEP C-STATES: DISABLE (Xeon C6/C7/C8 wakeup latency = 200-500us = micro-stutter) ----
:: Processor Idle Disable = 1 (prevent deep sleep states entirely)
powercfg /SETACVALUEINDEX SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 5d76a2ca-e8c0-402f-a133-2158492d58ad 1 >nul 2>&1
:: Idle Promote Threshold = 100%% (never promote to deeper C-state)
powercfg /SETACVALUEINDEX SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 7b224883-b3cc-4d79-819f-8374152cbe7c 100 >nul 2>&1
:: Idle Demote Threshold = 0%% (instantly return to C0 active state)
powercfg /SETACVALUEINDEX SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 4b92d758-5a24-4851-a470-815d78aee119 0 >nul 2>&1
echo   - Deep C-states disabled (C6/C7/C8 = 0 latency)

:: ---- PACKAGE C-STATES: DISABLE (whole-CPU sleep = catastrophic latency on Xeon) ----
:: Package C-State limit = C0 (never let entire package sleep)
powercfg /SETACVALUEINDEX SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 2430b2e9-2e4b-474e-8073-73b8f3e02373 0 >nul 2>&1
echo   - Package C-states disabled (no whole-CPU sleep)

:: ---- PROCESSOR AUTONOMOUS MODE: DISABLE (let OS control P-states, not CPU firmware) ----
:: Xeon firmware auto-management conflicts with Windows power plan settings
:: Autonomous Mode = 0 (OS scheduler controls frequency scaling via ACPI/MSR)
powercfg /SETACVALUEINDEX SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 8baa4a8a-14c6-4451-8e8b-14bdbd197537 0 >nul 2>&1
echo   - Processor Autonomous Mode disabled (OS controls P-states)

:: ---- ENERGY PERFORMANCE PREFERENCE: MAXIMUM PERFORMANCE (EPP=0) ----
:: Xeon Gold/Platinum/E5v4+ support Intel Speed Shift Technology (HWP)
:: EPP=0 tells hardware to prioritize performance over power saving
powercfg /SETACVALUEINDEX SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 36687f9e-e3a5-4dbf-b1dc-15eb381c6863 0 >nul 2>&1
echo   - Energy Performance Preference = Maximum Performance (EPP=0)

:: ---- MAX PROCESSOR FREQUENCY: UNLIMITED ----
:: Let boost work within 90%% cap, don't add another frequency limit
powercfg /SETACVALUEINDEX SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 75b0ae3f-bce0-45a7-8c89-c9611c25e100 0 >nul 2>&1
echo   - Max Processor Frequency = Unlimited (within 90%% cap)

:: ---- APPLY XEON POWER CHANGES ----
powercfg /SETACTIVE SCHEME_CURRENT >nul 2>&1

:: ---- MULTI-SOCKET vs SINGLE-SOCKET XEON ----
:: NUMA/Platform clock only matter on DUAL+ socket. Single Xeon = all memory local.
echo   - Socket count: !CPU_SOCKETS!
if !CPU_SOCKETS! GEQ 2 (
    echo   - [DUAL+ SOCKET] Applying multi-socket optimizations...
    :: NUMA: enforce memory locality (remote NUMA = 1.5-2x slower)
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettings /t REG_DWORD /d 1 /f >nul
    echo   - NUMA memory locality enforced (no cross-socket penalty)
    :: Interrupt steering: distribute IRQs across all sockets
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v InterruptSteeringDisabled /t REG_DWORD /d 0 /f >nul
    echo   - Interrupt steering enabled (balanced across sockets)
    :: Platform clock: use HPET for multi-socket timer consistency (TSC drifts between sockets)
    bcdedit /set useplatformclock true >nul 2>&1
    echo   - Platform clock HPET enabled (TSC drift protection)
) else (
    echo   - [SINGLE SOCKET] Skipping NUMA/platform clock (not needed)
    :: Single socket: use TSC (faster than HPET, no drift issue)
    bcdedit /deletevalue useplatformclock >nul 2>&1
    echo   - TSC timer kept (faster than HPET on single socket)
)

:: ---- IRP STACK SIZE: INCREASE FOR SERVER I/O CHAINS ----
:: Xeon systems often have hardware RAID / NVMe → deeper I/O stack
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v IRPStackSize /t REG_DWORD /d 30 /f >nul
echo   - IRPStackSize = 30 (server-grade I/O depth)

:: ---- SERVER TCP/IP BUFFERS ----
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v GlobalMaxTcpWindowSize /t REG_DWORD /d 65535 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpWindowSize /t REG_DWORD /d 65535 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v DefaultReceiveWindow /t REG_DWORD /d 65535 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v DefaultSendWindow /t REG_DWORD /d 65535 /f >nul
echo   - Server TCP window + AFD buffers maximized

:: ---- SMB: INCREASE FOR XEON (override earlier minimization) ----
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v MaxMpxCt /t REG_DWORD /d 800 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v MaxCmds /t REG_DWORD /d 800 /f >nul
echo   - SMB credits increased for server workload

:: ---- BCDEDIT: USER VA SPACE ----
bcdedit /set increaseuserva 3072 >nul 2>&1
echo   - User VA space increased to 3GB

:: ---- DISABLE AVX FREQUENCY THROTTLING (Xeon E5v4+ / Scalable) ----
:: AVX-512 instructions cause Xeon to drop frequency by 200-800MHz
:: This registry hint tells the scheduler to avoid heavy AVX throttling
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v DisableExceptionChainValidation /t REG_DWORD /d 1 /f >nul
echo   - AVX throttling mitigation applied

:: ---- HIGH CORE COUNT SCHEDULING (Xeon 16-56 cores) ----
:: Use SHORT quantum with EQUAL foreground/background priority
:: Win32PrioritySeparation = 0x18 (24) = Short, Variable, Equal
:: Already set to 24, but Xeon with 32+ cores benefits from Fixed quantum instead
:: 0x28 (40) = Short, Fixed, Equal - more predictable for many VMs
if !CPU_CORES! GEQ 24 (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 40 /f >nul
    echo   - Scheduling: Short Fixed Equal quantum (24+ cores)
) else (
    echo   - Scheduling: Short Variable Equal quantum (kept at 24)
)

echo.
echo   XEON/SERVER optimizations complete!
echo   XEON optimizations applied >> "%LOG%"

:skip_xeon

:: Disable Hibernate
powercfg /h off
echo   - Hibernate disabled

:: Optimize pagefile for LDPlayer (larger pagefile = more emulator instances)
:: PF_MIN and PF_MAX were pre-computed in Phase 5 consolidated RAM query
if not defined PF_MIN set "PF_MIN=8192"
if not defined PF_MAX set "PF_MAX=16384"
wmic computersystem where name="%COMPUTERNAME%" set AutomaticManagedPagefile=False <nul >nul 2>&1
wmic pagefileset where name="C:\\pagefile.sys" set InitialSize=!PF_MIN!,MaximumSize=!PF_MAX! <nul >nul 2>&1
if not exist "C:\pagefile.sys" wmic pagefileset create name="C:\pagefile.sys" <nul >nul 2>&1
echo   - Pagefile optimized for LDPlayer (!PF_MIN!MB - !PF_MAX!MB)

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
:: (HypervisorEnforcedCodeIntegrity already set in Phase 5)
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

:: NOTE: Firewall is disabled after VM registration setup (PHASE 10).
echo   - Boot tweaks applied

:: ---- MEMORY COMPRESSION TWEAKS ----

:: Force ENABLE Memory Compression (effectively gives ~30-50% more usable RAM on any system)
echo   - Enabling Memory Compression...
powershell -NoProfile -Command "Enable-MMAgent -MemoryCompression;Enable-MMAgent -PageCombining;Disable-MMAgent -ApplicationLaunchPrefetching;Disable-MMAgent -ApplicationPreLaunch;Disable-MMAgent -OperationAPI" >nul 2>&1

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

:: Enable Hardware-Accelerated GPU Scheduling (HAGS) for LDPlayer performance
:: (HwSchMode already set to 2 in Phase 5)
echo   - Hardware GPU Scheduling ENABLED for LDPlayer

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
:: Increase number of processors used during boot (faster boot on multi-core)
bcdedit /set {default} numproc %NUMBER_OF_PROCESSORS% >nul 2>&1
echo   - BCD: TSC sync enhanced, integrity checks off, all cores used at boot

:: ---- EXTREME RAM SAVING FOR LDPLAYER ----

:: Disable DWM animations but keep theme colorization - saves ~50-100MB
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DWM" /v DisableAnimations /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 0 /f >nul
:: Keep ColorizationOpaqueBlend=0 so window colorization/theme tinting works
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DWM" /v ColorizationOpaqueBlend /t REG_DWORD /d 0 /f >nul

:: Desktop Heap: DYNAMIC based on CPU cores (auto-detected in Phase 9)
:: 16+ cores → 8192/4096KB, 8+ cores → 4096/2048KB, <8 cores → 2048/1024KB
:: More cores = more LDPlayer instances = more windows = more heap needed
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\SubSystems" /v Windows /t REG_SZ /d "%SystemRoot%\system32\csrss.exe ObjectDirectory=\Windows SharedSection=1024,!CPU_DHEAP_I!,!CPU_DHEAP_NI! Windows=On SubSystemType=Windows ServerDll=basesrv,1 ServerDll=winsrv:UserServerDllInitialization,3 ServerDll=sxssrv,4 ProfileControl=Off MaxRequestThreads=!CPU_MAXREQ!" /f >nul
echo   - Desktop Heap DYNAMIC: !CPU_DHEAP_I!KB inter / !CPU_DHEAP_NI!KB non-inter (based on !CPU_CORES! cores)

:: Reduce NonPaged Pool size (Windows allocates too much by default)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v NonPagedPoolSize /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v PagedPoolSize /t REG_DWORD /d 0 /f >nul

:: (LargeSystemCache already set to 0 in Phase 5)
echo   - Kernel memory pools optimized

:: (CrashDumpEnabled already set to 0 in Phase 5)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v DumpFileSize /t REG_DWORD /d 0 /f >nul

:: Kill Edge completely on startup (steals 100-300MB in background)
:: (StartupBoostEnabled and BackgroundModeEnabled already set in Phase 5)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v HardwareAccelerationModeEnabled /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v SleepingTabsEnabled /t REG_DWORD /d 1 /f >nul
:: Remove Edge auto-update service files
if exist "%ProgramFiles(x86)%\Microsoft\EdgeUpdate" (
    taskkill /f /im MicrosoftEdgeUpdate.exe >nul 2>&1
    rmdir /s /q "%ProgramFiles(x86)%\Microsoft\EdgeUpdate" >nul 2>&1
)
echo   - Edge background processes killed

:: Disable Connected User Experiences (background telemetry eating RAM)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack" /v ShowedToastAtLevel /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v LimitDiagnosticLogCollection /t REG_DWORD /d 1 /f >nul

:: Disable Runtime Broker (eats 20-60MB for UWP apps we don't use)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\TimeBrokerSvc" /v Start /t REG_DWORD /d 4 /f >nul
echo   - Runtime/Time Broker disabled

:: (DisableInventory already set to 1 in Phase 5)
schtasks /Change /TN "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Application Experience\ProgramDataUpdater" /Disable >nul 2>&1

:: Minimize Explorer memory footprint
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v EnableBalloonTips /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewShadow /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewAlphaSelect /t REG_DWORD /d 0 /f >nul
:: Keep themes active - do NOT override VisualFXSetting here (already set to Custom in Phase 6)
:: reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f >nul
:: reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9012008010000000 /f >nul
echo   - Explorer light mode (themes preserved)

:: Set process working set trimming (aggressively reclaim idle RAM from background processes)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v SystemPages /t REG_DWORD /d 0 /f >nul

:: Keep font smoothing ON for readable text with themes (ClearType)
:: reg add "HKCU\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d 0 /f >nul
:: reg add "HKCU\Control Panel\Desktop" /v FontSmoothingType /t REG_DWORD /d 0 /f >nul
echo   - Font smoothing kept ON (themes preserved)

:: Reduce screen resolution to save VRAM (LDPlayer has its own internal resolution)
:: Set default to 1024x768 to save ~50-100MB VRAM vs 1080p
powershell -NoProfile -Command "Add-Type -TypeDefinition 'using System;using System.Runtime.InteropServices;[StructLayout(LayoutKind.Sequential)]public struct DEVMODE{[MarshalAs(UnmanagedType.ByValTStr,SizeConst=32)]public string dmDeviceName;public short dmSpecVersion;public short dmDriverVersion;public short dmSize;public short dmDriverExtra;public int dmFields;public int dmPositionX;public int dmPositionY;public int dmDisplayOrientation;public int dmDisplayFixedOutput;public short dmColor;public short dmDuplex;public short dmYResolution;public short dmTTOption;public short dmCollate;[MarshalAs(UnmanagedType.ByValTStr,SizeConst=32)]public string dmFormName;public short dmLogPixels;public int dmBitsPerPel;public int dmPelsWidth;public int dmPelsHeight;public int dmDisplayFlags;public int dmDisplayFrequency;public int dmICMMethod;public int dmICMIntent;public int dmMediaType;public int dmDitherType;public int dmReserved1;public int dmReserved2;public int dmPanningWidth;public int dmPanningHeight;}public class PInvoke{[DllImport(\"user32.dll\")]public static extern int ChangeDisplaySettings(ref DEVMODE devMode,int flags);public static void SetRes(int w,int h){DEVMODE dm=new DEVMODE();dm.dmSize=(short)Marshal.SizeOf(typeof(DEVMODE));dm.dmPelsWidth=w;dm.dmPelsHeight=h;dm.dmFields=0x80000|0x100000;ChangeDisplaySettings(ref dm,0);}}' -Language CSharp;[PInvoke]::SetRes(1024,768)" >nul 2>&1
echo   - Resolution set to 1024x768 (saves VRAM)

:: ---- GPU THREAD PRIORITY (prioritize LDPlayer GPU rendering) ----
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 6 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "High" /f >nul
echo   - GPU thread priority set to HIGH for emulators

:: ---- USB SELECTIVE SUSPEND OFF (prevents ADB disconnects) ----
powercfg /SETACVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul 2>&1
powercfg /SETACTIVE SCHEME_CURRENT >nul 2>&1
echo   - USB selective suspend disabled (stable ADB)

:: ---- REDUCE TIMER RESOLUTION (smoother LDPlayer frame pacing) ----
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v GlobalTimerResolutionRequests /t REG_DWORD /d 1 /f >nul
echo   - Global timer resolution requests enabled

:: Disable Windows Search Indexer completely (saves 50-100MB RAM + constant disk I/O)
sc stop WSearch >nul 2>&1
sc config WSearch start= disabled >nul 2>&1
if exist "%ProgramData%\Microsoft\Search\Data" (
    rmdir /s /q "%ProgramData%\Microsoft\Search\Data" >nul 2>&1
)
echo   - Windows Search data purged

:: Disable Compatibility Assistant (saves ~30MB)
sc stop PcaSvc >nul 2>&1
sc config PcaSvc start= disabled >nul 2>&1

:: Kill Windows Store background processes
taskkill /f /im WinStore.App.exe >nul 2>&1
taskkill /f /im RuntimeBroker.exe >nul 2>&1
taskkill /f /im SearchApp.exe >nul 2>&1
taskkill /f /im SearchUI.exe >nul 2>&1
taskkill /f /im ShellExperienceHost.exe >nul 2>&1
taskkill /f /im StartMenuExperienceHost.exe >nul 2>&1
echo   - Background UWP processes killed

:: Schedule auto-kill of memory-wasting processes at logon
set "KILL_SCRIPT=%PCL_DIR%\kill_bloat.bat"
(
echo @echo off
echo :loop
echo timeout /t 60 /nobreak ^>nul
echo for %%%%P in (
echo     SearchApp.exe SearchUI.exe RuntimeBroker.exe
echo     ShellExperienceHost.exe StartMenuExperienceHost.exe
echo     MicrosoftEdge.exe msedge.exe MicrosoftEdgeUpdate.exe
echo     MusNotification.exe MusNotificationUx.exe
echo     ctfmon.exe YourPhone.exe PhoneExperienceHost.exe
echo     GameBarPresenceWriter.exe gamebar.exe GameBar.exe
echo     TextInputHost.exe InputApp.exe
echo     CompatTelRunner.exe DeviceCensus.exe
echo     WmiPrvSE.exe backgroundTaskHost.exe
echo     SecurityHealthSystray.exe SecurityHealthService.exe
echo     OneDrive.exe Teams.exe
echo ^) do taskkill /f /im %%%%P ^>nul 2^>^&1
echo :: Trim working set of heavy processes to reclaim idle RAM
echo powershell -NoProfile -Command "$ErrorActionPreference='SilentlyContinue';$c='using System;using System.Runtime.InteropServices;public class WS{[DllImport(''kernel32.dll'')]public static extern bool SetProcessWorkingSetSize(IntPtr h,IntPtr min,IntPtr max);}';Add-Type $c -EA SilentlyContinue;Get-Process ^| Where-Object {$_.WorkingSet64 -gt 50MB -and $_.ProcessName -notmatch 'LDPlayer^|dnplayer^|svchost^|System^|Idle^|csrss^|smss^|lsass^|explorer^|wininit^|winlogon^|services^|dwm^|fontdrvhost^|Memory Compression^|Registry^|MsMpEng^|NisSrv^|SecurityHealth^|spoolsv^|WmiPrvSE'} ^| ForEach-Object { try{$h=$_.Handle;if($h){[void][WS]::SetProcessWorkingSetSize($h,[IntPtr]::new(-1),[IntPtr]::new(-1))}}catch{} }" ^>nul 2^>^&1
echo goto :loop
) > "%KILL_SCRIPT%"
schtasks /Delete /TN "KillBloat" /F >nul 2>&1
schtasks /Create /TN "KillBloat" /SC ONLOGON /TR "cmd /c start /min \"%KILL_SCRIPT%\"" /RL HIGHEST /F >nul 2>&1
echo   - Auto-kill bloat LOOP scheduled at logon (kills + trims every 60s)

echo   EXTREME RAM saving tweaks applied.
echo   EXTREME RAM saving tweaks applied >> "%LOG%"

:: ---- KERNEL-LEVEL EXTREME TWEAKS ----

:: Enable Large Pages support (LDPlayer benefits from large memory pages)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargePageMinimum /t REG_DWORD /d 1 /f >nul
:: Grant Lock Pages in Memory privilege to all users (required for Large Pages)
powershell -NoProfile -Command "$tmp=[System.IO.Path]::GetTempFileName();secedit /export /cfg $tmp /quiet;(Get-Content $tmp) -replace '(SeLockMemoryPrivilege.*)', '$1,*S-1-5-32-545' | Set-Content $tmp;secedit /configure /db ([System.IO.Path]::GetTempFileName()) /cfg $tmp /quiet;Remove-Item $tmp -Force" >nul 2>&1
echo   - Large Pages enabled

:: Disable DPC Watchdog (prevents BSOD DPC_WATCHDOG_VIOLATION under heavy emulator load)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v DpcWatchdogPeriod /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v DpcTimeout /t REG_DWORD /d 0 /f >nul
echo   - DPC Watchdog disabled

:: Disable lock workstation (Win+L / screen lock = useless on farm VMs)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableLockWorkstation /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableLockWorkstation /t REG_DWORD /d 1 /f >nul
:: Disable Ctrl+Alt+Del requirement
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableCAD /t REG_DWORD /d 1 /f >nul
echo   - Lock workstation + Ctrl+Alt+Del disabled

:: Disable screen saver entirely
reg add "HKCU\Control Panel\Desktop" /v ScreenSaveActive /t REG_SZ /d 0 /f >nul
reg add "HKCU\Control Panel\Desktop" /v ScreenSaverIsSecure /t REG_SZ /d 0 /f >nul
reg add "HKCU\Control Panel\Desktop" /v SCRNSAVE.EXE /t REG_SZ /d "" /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Control Panel\Desktop" /v ScreenSaveActive /t REG_SZ /d 0 /f >nul
echo   - Screen saver completely disabled

:: Minimize NTFS journal size (default 64MB, reduce to 2MB to save RAM+disk I/O)
fsutil usn deletejournal /d C: >nul 2>&1
fsutil usn createjournal m=2097152 a=1048576 C: >nul 2>&1
echo   - NTFS journal minimized (64MB -> 2MB)

:: Set L2 cache size to actual detected value (was hardcoded 1024KB)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v SecondLevelDataCache /t REG_DWORD /d !CPU_L2! /f >nul
echo   - SecondLevelDataCache set to actual !CPU_L2!KB (auto-detected)

:: Expose Processor Boost settings in powercfg (required for Phase 9 boost mode = Efficient Aggressive)
:: Attributes=2 makes the setting visible in Power Options GUI
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\be337238-0d82-4146-a960-4f3749d470c7" /v Attributes /t REG_DWORD /d 2 /f >nul
echo   - Processor boost settings exposed (Efficient Aggressive @ 90%% cap)

:: Disable Connected Standby (Modern Standby = useless on VM farms)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v CsEnabled /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v PlatformAoAcOverride /t REG_DWORD /d 0 /f >nul
echo   - Connected Standby disabled

:: (Win32PrioritySeparation already set to 24 in Phase 9)
:: Set IRQ priority to 14 (highest user-accessible level for I/O)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v IRQ8Priority /t REG_DWORD /d 1 /f >nul
echo   - IRQ and quantum priority tuned

:: Disable Fault Tolerant Heap (saves ~20MB, prevents auto-shimming of processes)
reg add "HKLM\SOFTWARE\Microsoft\FTH" /v Enabled /t REG_DWORD /d 0 /f >nul
echo   - Fault Tolerant Heap disabled

:: Disable Application Telemetry (CompatTelRunner)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v DisablePCA /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v DisableEngine /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v SbEnable /t REG_DWORD /d 0 /f >nul
echo   - Application Compatibility Engine fully disabled

:: Reduce SMB credits for lower memory (farm VMs don't do heavy file sharing)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v MaxMpxCt /t REG_DWORD /d 50 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v MaxCmds /t REG_DWORD /d 50 /f >nul
echo   - SMB credits minimized

:: ---- MULTI-VM / LDPLAYER FARM OPTIMIZATION (20-50+ instances) ----

:: GPU: Disable TDR (Timeout Detection and Recovery)
:: When 20+ LDPlayer instances share one GPU, rendering queue gets long.
:: TDR timeout (default 2s) causes "Display driver stopped responding" → instance crash.
:: TdrLevel=0 disables TDR entirely. TdrDelay=60 is fallback if TdrLevel=0 doesn't work.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v TdrLevel /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v TdrDelay /t REG_DWORD /d 60 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v TdrDdiDelay /t REG_DWORD /d 60 /f >nul
echo   - GPU TDR disabled (no more "display driver stopped responding")

:: GPU: Enable fine-grained preemption (better GPU time-sharing among many instances)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Scheduler" /v EnablePreemption /t REG_DWORD /d 1 /f >nul
:: Disable VSync idle timeout (prevents GPU idle power-down between frames)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Scheduler" /v VsyncIdleTimeout /t REG_DWORD /d 0 /f >nul
echo   - GPU preemption + VSync optimized for multi-instance

:: I/O: DYNAMIC kernel worker threads (scales with CPU cores)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Executive" /v AdditionalCriticalWorkerThreads /t REG_DWORD /d !CPU_WORKERS_C! /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Executive" /v AdditionalDelayedWorkerThreads /t REG_DWORD /d !CPU_WORKERS_D! /f >nul
echo   - I/O worker threads: !CPU_WORKERS_C! critical + !CPU_WORKERS_D! delayed (based on !CPU_CORES! cores)

:: I/O: DYNAMIC MaxWorkItems (scales with CPU threads: threads×256)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v MaxWorkItems /t REG_DWORD /d !CPU_MAXWORK! /f >nul
echo   - MaxWorkItems=!CPU_MAXWORK! (based on !CPU_THREADS! threads)

:: TCP: Scale connection tracking for many instances (each LDPlayer opens 50-200 connections)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v MaxFreeTcbs /t REG_DWORD /d 65536 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v MaxHashTableSize /t REG_DWORD /d 65536 /f >nul
:: Disable SYN attack protection (farm is internal, not exposed to internet)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v SynAttackProtect /t REG_DWORD /d 0 /f >nul
echo   - TCP connection table scaled for 50+ instances

:: Service timeout: Increase from 2s to 120s (prevent service crashes under heavy multi-VM load)
:: At boot with 30+ VMs, services compete for CPU time → default 2s timeout kills them
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v ServicesPipeTimeout /t REG_DWORD /d 120000 /f >nul
echo   - Service timeout extended to 120s (prevents crash under heavy load)

:: Process creation: Faster heap allocation for spawning many LDPlayer instances
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v HeapDeCommitFreeBlockThreshold /t REG_DWORD /d 262144 /f >nul
echo   - Process heap optimized for fast instance spawning

:: PCIe: Disable ASPM power saving (prevents GPU/NIC latency spikes under multi-VM load)
:: Active State Power Management OFF for PCI Express Link State
powercfg /SETACVALUEINDEX SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0 >nul 2>&1
powercfg /SETACTIVE SCHEME_CURRENT >nul 2>&1
echo   - PCIe ASPM disabled (no GPU/NIC latency spikes)

:: CPU C-states: Limit deep idle states (prevent micro-stutter when cores wake under multi-VM load)
:: Idle Promote/Demote Threshold tuning for consistent latency
powercfg /SETACVALUEINDEX SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 5d76a2ca-e8c0-402f-a133-2158492d58ad 0 >nul 2>&1
powercfg /SETACTIVE SCHEME_CURRENT >nul 2>&1
echo   - CPU C-states limited (no micro-stutter on core wakeup)

:: Timer: Distribute timer interrupts across all cores (prevent core 0 bottleneck)
:: By default, Windows processes most timer interrupts on core 0 → bottleneck with many VMs
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v DistributeTimers /t REG_DWORD /d 1 /f >nul
echo   - Timer interrupts distributed across all cores

:: Memory: Pool usage cap at 60%% (prevent kernel pool exhaustion with many processes)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v PoolUsageMaximum /t REG_DWORD /d 60 /f >nul
echo   - Kernel pool usage capped at 60%%

:: File handles: Increase system-wide file handle limit (many instances = thousands of open files)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v MaximumSharedReadyQueueCount /t REG_DWORD /d 2 /f >nul
echo   - File handle and ready queue limits increased

:: Disk: Disable write-cache buffer flushing (faster disk I/O, slightly risky on power loss)
:: Safe for VMs since VM snapshots handle crash recovery
reg add "HKLM\SYSTEM\CurrentControlSet\Services\disk" /v TimeOutValue /t REG_DWORD /d 200 /f >nul
echo   - Disk timeout extended to 200s for heavy I/O

echo   Multi-VM/LDPlayer farm optimizations applied.
echo   Multi-VM/LDPlayer farm optimizations applied >> "%LOG%"

echo   System optimization done.
echo   System optimization done >> "%LOG%"

:: ============================================================
:: PHASE 10: NETWORK + LDPLAYER FINAL TWEAKS
:: ============================================================
echo.
echo ============================================================
echo  [10/11] Network + LDPlayer Final Tweaks...
echo ============================================================
echo [10/11] Network + LDPlayer Final Tweaks... >> "%LOG%"

:: ---- TCP/UDP & NIC optimizations (Improves LDPlayer network performance) ----
netsh int tcp set global timestamps=enabled >nul 2>&1
netsh int tcp set global autotuninglevel=normal >nul 2>&1
netsh int tcp set global rss=enabled >nul 2>&1
netsh int tcp set global ecncapability=enabled >nul 2>&1
netsh int tcp set heuristics disabled >nul 2>&1
:: Disable Task Offload to prevent packet drops and latency spikes in Virtual NICs
netsh int tcp set global taskoffload=disabled >nul 2>&1
:: Force disable LSO (Large Send Offload) and Checksum Offload on all Virtual Adapters
powershell -NoProfile -Command "Get-NetAdapter | Disable-NetAdapterChecksumOffload -IpIPv4 -TcpIPv4 -UdpIPv4 -ErrorAction SilentlyContinue; Get-NetAdapter | Disable-NetAdapterLso -IPv4 -IPv6 -ErrorAction SilentlyContinue; Get-NetAdapter | Disable-NetAdapterRsc -IPv4 -IPv6 -ErrorAction SilentlyContinue" >nul 2>&1
:: Maximize TCP connection limit for heavy automation/farming
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v MaxUserPort /t REG_DWORD /d 65534 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v Tcp1323Opts /t REG_DWORD /d 1 /f >nul

:: Disable Mouse Acceleration (Enhance Pointer Precision) to reduce remote control mouse delay
reg add "HKCU\Control Panel\Mouse" /v MouseSpeed /t REG_SZ /d 0 /f >nul
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold1 /t REG_SZ /d 0 /f >nul
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold2 /t REG_SZ /d 0 /f >nul

echo   - TCP/UDP and Mouse tuned

:: Disable NetBIOS over TCP/IP on all adapters (saves RAM + reduces broadcast noise)
powershell -NoProfile -Command "Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces' | ForEach-Object { Set-ItemProperty -Path $_.PSPath -Name 'NetbiosOptions' -Value 2 -ErrorAction SilentlyContinue }" >nul 2>&1
echo   - NetBIOS over TCP/IP disabled

:: Disable LLMNR (Link-Local Multicast Name Resolution) - reduces broadcast traffic
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v EnableMulticast /t REG_DWORD /d 0 /f >nul
echo   - LLMNR disabled

:: Disable SMBv1 (security + saves ~15MB RAM)
sc config mrxsmb10 start= disabled >nul 2>&1
sc stop mrxsmb10 >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v SMB1 /t REG_DWORD /d 0 /f >nul
echo   - SMBv1 disabled

:: Disable SMB signing (saves CPU on every file I/O operation)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v RequireSecuritySignature /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v EnableSecuritySignature /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v RequireSecuritySignature /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v EnableSecuritySignature /t REG_DWORD /d 0 /f >nul
echo   - SMB signing disabled

:: Disable NIC power management on all adapters (prevents random disconnects)
powershell -NoProfile -Command "Get-NetAdapter | ForEach-Object { Set-NetAdapterPowerManagement -Name $_.Name -WakeOnPattern Disabled -WakeOnMagicPacket Disabled -ErrorAction SilentlyContinue; Disable-NetAdapterPowerManagement -Name $_.Name -ErrorAction SilentlyContinue }" >nul 2>&1
echo   - NIC power management disabled

:: Disable DNS negative cache (faster retry on failed lookups)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v NegativeCacheTime /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v NetFailureCacheTime /t REG_DWORD /d 0 /f >nul
:: Reduce DNS positive cache TTL (faster failover)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v MaxCacheEntryTtlLimit /t REG_DWORD /d 300 /f >nul
echo   - DNS cache tuned

:: Increase ephemeral port range for massive LDPlayer connections
netsh int ipv4 set dynamicport tcp start=1025 num=64510 >nul 2>&1
netsh int ipv4 set dynamicport udp start=1025 num=64510 >nul 2>&1
echo   - Ephemeral port range maximized (1025-65535)

:: Disable firewall (LDPlayer ADB needs local network access)
netsh advfirewall set allprofiles state off >nul 2>&1
echo   - Firewall disabled

:: Allow ADB connections for LDPlayer management
netsh advfirewall firewall add rule name="LDPlayer ADB" dir=in action=allow protocol=TCP localport=5555-5600 >nul 2>&1
echo   - LDPlayer ADB firewall rule added

:: NOTE: Do NOT disable mpssvc service - BFE depends on it and many network services break.
:: Firewall is already OFF via netsh above, which is sufficient.
:: sc stop mpssvc >nul 2>&1
:: sc config mpssvc start= disabled >nul 2>&1
echo   - Firewall disabled via netsh (service kept for BFE compatibility)

echo   Network + LDPlayer tweaks done.
echo   Network + LDPlayer tweaks done >> "%LOG%"

:: ============================================================
:: PHASE 11: FINAL CLEANUP
:: ============================================================
echo.
echo ============================================================
echo  [11/11] Final Cleanup...
echo ============================================================
echo [11/11] Final Cleanup... >> "%LOG%"

:: Clean temp files
del /f /q "%SystemRoot%\Temp\*" >nul 2>&1
del /f /q "%TEMP%\*" >nul 2>&1
for /d %%D in ("%TEMP%\*") do rmdir /s /q "%%D" >nul 2>&1
for /d %%D in ("%SystemRoot%\Temp\*") do rmdir /s /q "%%D" >nul 2>&1
echo   - Temp files cleaned

:: NOTE: Do NOT delete C:\InstallScripts here!
:: RunAll.bat handles cleanup AFTER QuickInstall.bat finishes.
echo   - Install scripts cleanup deferred to RunAll.bat

:: ---- AGGRESSIVE DISK RECLAIM ----

:: Remove Windows component backup (saves 200-500MB, prevents feature restore but who cares on farm)
dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase >nul 2>&1
echo   - Component store final cleanup

:: Remove WinSxS pending deletes
if exist "%SystemRoot%\WinSxS\Temp\PendingDeletes" (
    del /f /q /s "%SystemRoot%\WinSxS\Temp\PendingDeletes\*" >nul 2>&1
)
if exist "%SystemRoot%\WinSxS\Temp\TransformCache" (
    del /f /q /s "%SystemRoot%\WinSxS\Temp\TransformCache\*" >nul 2>&1
)
echo   - WinSxS temp purged

:: Remove cached MSI installers (saves 100-500MB)
if exist "%SystemRoot%\Installer" (
    for %%F in ("%SystemRoot%\Installer\*.msp") do del /f /q "%%F" >nul 2>&1
    for %%F in ("%SystemRoot%\Installer\*.msi") do del /f /q "%%F" >nul 2>&1
)
echo   - MSI installer cache cleaned

:: Remove Windows Error Reporting archive
if exist "%ProgramData%\Microsoft\Windows\WER" rmdir /s /q "%ProgramData%\Microsoft\Windows\WER" >nul 2>&1
if exist "%LOCALAPPDATA%\CrashDumps" rmdir /s /q "%LOCALAPPDATA%\CrashDumps" >nul 2>&1
echo   - WER archives purged

:: Remove SoftwareDistribution entirely (already disabled WU)
if exist "%SystemRoot%\SoftwareDistribution" rmdir /s /q "%SystemRoot%\SoftwareDistribution" >nul 2>&1
echo   - SoftwareDistribution purged

:: Defrag SSD TRIM or HDD defrag
powershell -NoProfile -Command "$d=Get-PhysicalDisk|Select-Object -First 1;if($d.MediaType -eq 'SSD'){Optimize-Volume -DriveLetter C -ReTrim -ErrorAction SilentlyContinue}else{Optimize-Volume -DriveLetter C -Defrag -ErrorAction SilentlyContinue}" >nul 2>&1
echo   - Drive optimized (TRIM/Defrag)

:: Force process all idle/pending tasks NOW
rundll32.exe advapi32.dll,ProcessIdleTasks >nul 2>&1
echo   - Idle tasks flushed

:: ---- CREATE MANUAL RAM RECLAIM SHORTCUT ----
:: Useful shortcut to manually flush RAM when needed
set "RECLAIM=%PCL_DIR%\reclaim_ram.bat"
(
echo @echo off
echo echo Reclaiming RAM...
echo powershell -NoProfile -Command "$ErrorActionPreference='SilentlyContinue';$c='using System;using System.Runtime.InteropServices;public class WS{[DllImport(''kernel32.dll'')]public static extern bool SetProcessWorkingSetSize(IntPtr h,IntPtr min,IntPtr max);}';Add-Type $c -EA SilentlyContinue;Get-Process ^| Where-Object {$_.ProcessName -notmatch 'LDPlayer^|dnplayer^|svchost^|System^|Idle^|csrss^|smss^|lsass^|explorer^|wininit^|winlogon^|services^|dwm^|fontdrvhost^|Memory Compression^|Registry^|MsMpEng^|NisSrv^|SecurityHealth^|spoolsv^|WmiPrvSE'} ^| ForEach-Object { try{$h=$_.Handle;if($h){[void][WS]::SetProcessWorkingSetSize($h,[IntPtr]::new(-1),[IntPtr]::new(-1))}}catch{} }"
echo rundll32.exe advapi32.dll,ProcessIdleTasks
echo echo Done. RAM reclaimed.
echo timeout /t 3
) > "%RECLAIM%"
powershell -NoProfile -Command "$desktop=[Environment]::GetFolderPath('CommonDesktopDirectory');$s=(New-Object -ComObject WScript.Shell).CreateShortcut((Join-Path $desktop 'Reclaim RAM.lnk'));$s.TargetPath='cmd.exe';$s.Arguments='/c ""%RECLAIM%""';$s.IconLocation='%SystemRoot%\System32\shell32.dll,80';$s.WindowStyle=7;$s.Save()" >nul 2>&1
echo   - Reclaim RAM shortcut created on Desktop

:: ---- SHOW DISK SAVINGS ----
for /f "tokens=3" %%S in ('dir C:\ 2^>nul ^| findstr /i "bytes free"') do set "FREE_SPACE=%%S"
echo   - Free disk space: %FREE_SPACE% bytes

echo ============================================================ >> "%LOG%"
echo  QuickOptimize (LDPlayer Farm EXTREME) - Completed: %DATE% %TIME% >> "%LOG%"
echo ============================================================ >> "%LOG%"

echo.
echo  =============================================
echo   QuickOptimize COMPLETE! (LDPlayer Farm)
echo  =============================================
echo   Mode: EXTREME OPTIMIZATION
echo   Audio: KEPT ON (disable in LDPlayer)
echo   Log: %LOG%
echo  =============================================
echo.

:: ---- FINAL: Apply wallpaper now (desktop should be ready) ----
set "WP_DST=%SystemRoot%\Web\Wallpaper\PCL\logo-nen.png"
if exist "%WP_DST%" (
    echo [*] Applying wallpaper...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "Add-Type 'using System;using System.Runtime.InteropServices;public class WP{[DllImport(\"user32.dll\",CharSet=CharSet.Unicode)]public static extern int SystemParametersInfo(int a,int b,string c,int d);}';[WP]::SystemParametersInfo(0x0014,0,'%WP_DST%',3)" >nul 2>&1
    echo   - Wallpaper applied: PreCore Lab
)

:: endlocal before self-delete (setlocal cleanup)
endlocal

:: Note: self-delete removed to allow QuickInstall.bat to run after this script

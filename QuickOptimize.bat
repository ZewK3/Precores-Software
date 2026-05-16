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

:: ---- Admin check ----
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Run as Administrator!
    pause
    exit /b 1
)

:: ============================================================
:: EARLY VM REGISTRATION
:: ============================================================
set "VM_REGISTRY_URL=https://vm-registry.zewk.workers.dev"
echo [0/11] Early VM registration... >> "%LOG%"
echo   Registering VM with dashboard before long optimization phases...

set "PS_EARLY_REGISTER=%TEMP%\vm_early_register.ps1"
(
echo $ProgressPreference = 'SilentlyContinue'
echo [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
echo $url = '%VM_REGISTRY_URL%/register'
echo for ^($i = 1; $i -le 30; $i++^) {
echo     $nic = Get-CimInstance Win32_NetworkAdapter -Filter 'NetEnabled=True AND PhysicalAdapter=True' ^| Select-Object -First 1
echo     $mac = if ^($nic^) { $nic.MACAddress } else { '' }
echo     $ip = ^(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue ^| Where-Object {$_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.*'} ^| Select-Object -First 1^).IPAddress
echo     $hostname = $env:COMPUTERNAME
echo     if ^($hostname -like 'PCLPCL*'^) { $hostname = 'PCL' + $hostname.Substring^(6^) }
echo     if ^($ip^) {
echo         $body = @{ mac = $mac; hostname = $hostname; ip = $ip; user = 'PCL'; password = 'PCL@1231233'; os = ^(Get-CimInstance Win32_OperatingSystem^).Caption } ^| ConvertTo-Json -Depth 3
echo         try {
echo             Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType 'application/json' -TimeoutSec 15 ^| Out-Null
echo             Write-Output ^("EARLY_REGISTER_OK " + $hostname + " " + $ip^)
echo             exit 0
echo         } catch {
echo             Write-Output ^("EARLY_REGISTER_ERROR attempt=" + $i + " " + $_.Exception.Message^)
echo         }
echo     } else {
echo         Write-Output ^("EARLY_REGISTER_WAIT_IP attempt=" + $i^)
echo     }
echo     Start-Sleep -Seconds 10
echo }
echo Write-Output "EARLY_REGISTER_FAILED"
) > "%PS_EARLY_REGISTER%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_EARLY_REGISTER%" >> "%LOG%" 2>&1
del /f /q "%PS_EARLY_REGISTER%" >nul 2>&1

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

:: Disable 60+ unnecessary services (low-RAM dev VM)
:: NoMachine remote control: RDP services are disabled below.
:: KEEP for system: StorSvc, Dhcp, Dnscache, LanmanWorkstation, NlaSvc, EventLog, RpcSs, RpcEptMapper, CryptSvc, Power, BFE, mpssvc, ProfSvc, gpsvc, Schedule, UserManager, LSM, AudioSrv, AudioEndpointBuilder, Themes
:: IMPORTANT: SysMain is KEPT enabled because Windows Memory Compression depends on it.
:: Superfetch/Prefetch behavior is already disabled via registry (EnablePrefetcher=0, EnableSuperfetch=0).
:: On 4GB systems, memory compression saves ~30-50% RAM by compressing cold pages.
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
    iphlpsvc ALG SCPolicySvc SmartSAMSS Browser
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
    AppXSvc PushToInstall WpnService WpnUserService_*
    FontCache
) do (
    sc stop %%S >nul 2>&1
    sc config %%S start= disabled >nul 2>&1
)
:: NOTE: Some services above may not exist on all SKUs; "sc config" silently fails for absent services.
:: Critical for network/system/audio UI NOT in disable list: Dhcp, Dnscache, LanmanWorkstation, EventLog, RpcSs, mpssvc, BFE, SysMain, AudioSrv, AudioEndpointBuilder, Themes

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

:: Disable Nagle's Algorithm on all interfaces (TCP_NODELAY = instant packet send, useful for NoMachine/real-time control)
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

:: Add Firewall Rules for NoMachine (Port 4000 TCP/UDP)
netsh advfirewall firewall add rule name="NoMachine TCP" dir=in action=allow protocol=TCP localport=4000 >nul 2>&1
netsh advfirewall firewall add rule name="NoMachine UDP" dir=in action=allow protocol=UDP localport=4000 >nul 2>&1
echo   - NoMachine Firewall rules added

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
reg add "HKCU\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "" /f >nul
reg add "HKCU\Control Panel\Desktop" /v WallpaperStyle /t REG_SZ /d 0 /f >nul
reg add "HKCU\Control Panel\Desktop" /v TileWallpaper /t REG_SZ /d 0 /f >nul
reg add "HKCU\Control Panel\Colors" /v Background /t REG_SZ /d "0 0 0" /f >nul
:: Disable cursor blink
reg add "HKCU\Control Panel\Desktop" /v CursorBlinkRate /t REG_SZ /d -1 /f >nul
:: Disable Smooth Scrolling to save massive bandwidth on RustDesk
reg add "HKCU\Control Panel\Desktop" /v SmoothScroll /t REG_DWORD /d 0 /f >nul
:: Disable Explorer thumbnails/preview handlers for lower RAM and disk churn
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v DisablePreviewPane /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v DisableThumbnailCache /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v IconsOnly /t REG_DWORD /d 1 /f >nul
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

:: NOTE: Firewall will be disabled after RustDesk registry/monitoring setup (PHASE 8).
echo   - Boot tweaks applied

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

:: Disable Hardware-Accelerated GPU Scheduling (Causes WARP software rendering lag on headless VMs)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 1 /f >nul
echo   - Hardware GPU Scheduling disabled for headless VM stability

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
:: PHASE 8: VM DASHBOARD REGISTRATION
:: ============================================================
echo.
echo ============================================================
echo  [10/11] Registering VM...
echo ============================================================
echo [10/11] Registering VM... >> "%LOG%"

:: ---- TCP/UDP & NIC optimizations (Improves RustDesk / Network performance) ----
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

echo   - TCP/UDP and Mouse tuned for instant remote control

:: ============================================================
:: VM REGISTRATION (Worker: vm-registry.zewk.workers.dev/register)
:: ============================================================

set "VM_REGISTRY_URL=https://vm-registry.zewk.workers.dev"

echo   - Requesting registration from registry...
set "PS_REGISTER=%TEMP%\vm_register.ps1"
(
echo $ProgressPreference = 'SilentlyContinue'
echo [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
echo $nic = Get-CimInstance Win32_NetworkAdapter -Filter 'NetEnabled=True AND PhysicalAdapter=True' ^| Select-Object -First 1
echo $mac = if ^($nic^) { $nic.MACAddress } else { '' }
echo $ip = ^(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue ^| Where-Object {$_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.*'} ^| Select-Object -First 1^).IPAddress
echo $hostname = $env:COMPUTERNAME
echo if ^($hostname -like 'PCLPCL*'^) { $hostname = 'PCL' + $hostname.Substring^(6^) }
echo $rd_id = ''
echo $paths = @("$env:ProgramFiles\RustDesk\config\RustDesk.toml", "$env:ProgramData\RustDesk\config\RustDesk.toml", "$env:LOCALAPPDATA\RustDesk\config\RustDesk.toml", "C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk.toml", "C:\Windows\System32\config\systemprofile\AppData\Roaming\RustDesk\config\RustDesk.toml", "C:\Users\Public\RustDesk\config\RustDesk.toml")
echo foreach^($p in $paths^) {
echo     if^(Test-Path $p^) {
echo         $raw = Get-Content $p -Raw
echo         $m = $raw -match "id\s*=\s*['""]?(\d+)['""]?"
echo         if^($m^) { $rd_id = $Matches[1].Trim^(^); break }
echo     }
echo }
echo $body = @{
echo     mac = $mac
echo     hostname = $hostname
echo     ip = $ip
echo     rustdesk = $rd_id
echo     user = 'PCL'
echo     password = 'PCL@1231233'
echo     os = ^(Get-CimInstance Win32_OperatingSystem^).Caption
echo } ^| ConvertTo-Json
echo try { Invoke-RestMethod -Uri '%VM_REGISTRY_URL%/register' -Method POST -Body $body -ContentType 'application/json' -UseBasicParsing -TimeoutSec 15 ^| Out-Null; Write-Output "REGISTER_OK" } catch { Write-Output ^("REGISTER_ERROR " + $_.Exception.Message^); exit 1 }
) > "%PS_REGISTER%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_REGISTER%" >> "%LOG%" 2>&1
del /f /q "%PS_REGISTER%" >nul 2>&1

echo   - VM Registered.

:: Now disable firewall (safe behind Hypervisor/Router NAT, allows RustDesk)
netsh advfirewall set allprofiles state off >nul 2>&1
echo   - Firewall disabled

echo   VM Registration complete.
echo   VM Registration complete >> "%LOG%"

:: ---- HEARTBEAT & MONITORING: Keep VM "Online" and send Thumbnail ----
set "HB_SCRIPT=%PCL_DIR%\vm_heartbeat.ps1"
(
echo $ProgressPreference = 'SilentlyContinue'
echo [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
echo $url = '%VM_REGISTRY_URL%/heartbeat'
echo $registerUrl = '%VM_REGISTRY_URL%/register'
echo $hostname = $env:COMPUTERNAME
echo if ^($hostname -like 'PCLPCL*'^) { $hostname = 'PCL' + $hostname.Substring^(6^) }
echo while ^($true^) {
echo $ip = ^(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue ^| Where-Object {$_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.*'} ^| Select-Object -First 1^).IPAddress
echo 
echo $rd_id = ''
echo $paths = @("$env:ProgramFiles\RustDesk\config\RustDesk.toml", "$env:ProgramData\RustDesk\config\RustDesk.toml", "$env:LOCALAPPDATA\RustDesk\config\RustDesk.toml", "C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk.toml", "C:\Windows\System32\config\systemprofile\AppData\Roaming\RustDesk\config\RustDesk.toml", "C:\Users\Public\RustDesk\config\RustDesk.toml")
echo foreach^($p in $paths^) {
echo     if^(Test-Path $p^) {
echo         $raw = Get-Content $p -Raw
echo         $m = $raw -match "id\s*=\s*['""]?(\d+)['""]?"
echo         if^($m^) { $rd_id = $Matches[1].Trim^(^); break }
echo     }
echo }
echo 
echo $screenshot = ''
echo try {
echo     Add-Type -AssemblyName System.Windows.Forms
echo     Add-Type -AssemblyName System.Drawing
echo     $bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
echo     $bmp = New-Object System.Drawing.Bitmap^($bounds.Width, $bounds.Height^)
echo     $gfx = [System.Drawing.Graphics]::FromImage^($bmp^)
echo     $gfx.CopyFromScreen^(0, 0, 0, 0, $bmp.Size^)
echo     $thumb = New-Object System.Drawing.Bitmap^(320, 180^)
echo     $g2 = [System.Drawing.Graphics]::FromImage^($thumb^)
echo     $g2.DrawImage^($bmp, 0, 0, 320, 180^)
echo     $stream = New-Object System.IO.MemoryStream
echo     $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders^(^) ^| Where-Object {$_.MimeType -eq 'image/jpeg'} ^| Select-Object -First 1
echo     $jpegParams = New-Object System.Drawing.Imaging.EncoderParameters^(1^)
echo     $jpegParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter^([System.Drawing.Imaging.Encoder]::Quality, 55L^)
echo     $thumb.Save^($stream, $codec, $jpegParams^)
echo     $screenshot = [Convert]::ToBase64String^($stream.ToArray^(^)^)
echo     $jpegParams.Dispose^(^); $g2.Dispose^(^); $thumb.Dispose^(^); $gfx.Dispose^(^); $bmp.Dispose^(^); $stream.Dispose^(^)
echo } catch {}
echo 
echo $os = ^(Get-CimInstance Win32_OperatingSystem^).Caption
echo $body = @{ hostname = $hostname; ip = $ip; rustdesk = $rd_id; screenshot = $screenshot; os = $os; user = 'PCL'; password = 'PCL@1231233' } ^| ConvertTo-Json -Depth 3
echo try {
echo     Invoke-RestMethod -Uri $url -Method POST -Body $body -ContentType 'application/json' -TimeoutSec 10 ^| Out-Null
echo } catch {
echo     try { Invoke-RestMethod -Uri $registerUrl -Method POST -Body $body -ContentType 'application/json' -TimeoutSec 10 ^| Out-Null } catch {}
echo }
echo Start-Sleep -Seconds 60
echo }
) > "%HB_SCRIPT%"
attrib +h +s "%PCL_DIR%" "%HB_SCRIPT%" >nul 2>&1

:: Register Scheduled Task to run heartbeat continuously on logon
schtasks /Delete /TN "VM_Heartbeat" /F >nul 2>&1
schtasks /Create /TN "VM_Heartbeat" /SC ONLOGON /TR "powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""%HB_SCRIPT%""" /RU "PCL" /IT /RL HIGHEST /F >> "%LOG%" 2>&1
:: Run it once immediately
schtasks /Run /TN "VM_Heartbeat" >> "%LOG%" 2>&1
echo   - Heartbeat + Monitoring scheduled (every 1 min)

:: ---- COMMAND AGENT: Poll dashboard commands and execute them locally ----
set "CMD_AGENT=%PCL_DIR%\vm_command_agent.ps1"
> "%CMD_AGENT%" echo $ProgressPreference = 'SilentlyContinue'
>> "%CMD_AGENT%" echo [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
>> "%CMD_AGENT%" echo $base = '%VM_REGISTRY_URL%'
>> "%CMD_AGENT%" echo $hostname = $env:COMPUTERNAME
>> "%CMD_AGENT%" echo if ($hostname -like 'PCLPCL*') { $hostname = 'PCL' + $hostname.Substring(6) }
>> "%CMD_AGENT%" echo $seen = @{}
>> "%CMD_AGENT%" echo while ($true) {
>> "%CMD_AGENT%" echo     try {
>> "%CMD_AGENT%" echo         $encodedHost = [uri]::EscapeDataString($hostname)
>> "%CMD_AGENT%" echo         $taskUrl = $base + '/agent/tasks?hostname=' + $encodedHost
>> "%CMD_AGENT%" echo         $resultUrl = $base + '/agent/task-result'
>> "%CMD_AGENT%" echo         $tasks = Invoke-RestMethod -Uri $taskUrl -Method GET -TimeoutSec 10
>> "%CMD_AGENT%" echo         foreach ($task in @($tasks)) {
>> "%CMD_AGENT%" echo             if ($seen.ContainsKey($task.id)) { continue }
>> "%CMD_AGENT%" echo             $seen[$task.id] = (Get-Date)
>> "%CMD_AGENT%" echo             $output = ''
>> "%CMD_AGENT%" echo             $exitCode = 0
>> "%CMD_AGENT%" echo             try {
>> "%CMD_AGENT%" echo                 if ($task.shell -eq 'cmd') {
>> "%CMD_AGENT%" echo                     $output = cmd.exe /d /s /c $task.command 2^>^&1 ^| Out-String
>> "%CMD_AGENT%" echo                     $exitCode = $LASTEXITCODE
>> "%CMD_AGENT%" echo                 } else {
>> "%CMD_AGENT%" echo                     $output = powershell.exe -NoProfile -ExecutionPolicy Bypass -Command $task.command 2^>^&1 ^| Out-String
>> "%CMD_AGENT%" echo                     $exitCode = $LASTEXITCODE
>> "%CMD_AGENT%" echo                 }
>> "%CMD_AGENT%" echo                 $status = if ($exitCode -eq 0) { 'ok' } else { 'error' }
>> "%CMD_AGENT%" echo             } catch {
>> "%CMD_AGENT%" echo                 $status = 'error'
>> "%CMD_AGENT%" echo                 $exitCode = -1
>> "%CMD_AGENT%" echo                 $output = $_.Exception.Message
>> "%CMD_AGENT%" echo             }
>> "%CMD_AGENT%" echo             if ($null -eq $output) { $output = '' }
>> "%CMD_AGENT%" echo             if ($output.Length -gt 3900) { $output = $output.Substring(0, 3900) }
>> "%CMD_AGENT%" echo             $body = @{ hostname = $hostname; id = $task.id; status = $status; exitCode = $exitCode; output = $output } ^| ConvertTo-Json -Depth 3
>> "%CMD_AGENT%" echo             try { Invoke-RestMethod -Uri $resultUrl -Method POST -Body $body -ContentType 'application/json' -TimeoutSec 10 ^| Out-Null } catch {}
>> "%CMD_AGENT%" echo         }
>> "%CMD_AGENT%" echo         $now = Get-Date
>> "%CMD_AGENT%" echo         foreach ($k in @($seen.Keys)) {
>> "%CMD_AGENT%" echo             $age = $now - $seen[$k]
>> "%CMD_AGENT%" echo             if ($age.TotalHours -gt 24) { $seen.Remove($k) }
>> "%CMD_AGENT%" echo         }
>> "%CMD_AGENT%" echo     } catch {}
>> "%CMD_AGENT%" echo     Start-Sleep -Seconds 5
>> "%CMD_AGENT%" echo }
attrib +h +s "%PCL_DIR%" "%CMD_AGENT%" >nul 2>&1
schtasks /Delete /TN "VM_CommandAgent" /F >nul 2>&1
schtasks /Create /TN "VM_CommandAgent" /SC ONLOGON /TR "powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File %CMD_AGENT%" /RU "PCL" /IT /RL HIGHEST /F >> "%LOG%" 2>&1
schtasks /Run /TN "VM_CommandAgent" >> "%LOG%" 2>&1
echo   - Command agent scheduled (polls every 5 sec)

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

:: NOTE: VM already registered with worker during RustDesk monitoring phase (see PHASE 8).
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

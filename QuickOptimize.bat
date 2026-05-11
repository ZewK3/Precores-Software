
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

set "LOG_FILE=C:\QuickOptimize_Log.txt"
echo ============================================================ > "%LOG_FILE%"
echo  QuickOptimize - Started: %DATE% %TIME% >> "%LOG_FILE%"
echo ============================================================ >> "%LOG_FILE%"

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
echo  [1/8] Removing UWP Bloatware...
echo ============================================================
echo [1/8] Removing UWP Bloatware... >> "%LOG_FILE%"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"$apps = @(" ^
"'Microsoft.BingWeather','Microsoft.GetHelp','Microsoft.Getstarted'," ^
"'Microsoft.Microsoft3DViewer','Microsoft.MicrosoftSolitaireCollection'," ^
"'Microsoft.MixedReality.Portal','Microsoft.MSPaint'," ^
"'Microsoft.WindowsAlarms','Microsoft.WindowsCamera'," ^
"'Microsoft.WindowsSoundRecorder','Microsoft.ScreenSketch'," ^
"'Microsoft.Windows.Photos','Microsoft.WindowsFeedbackHub'," ^
"'Microsoft.MicrosoftStickyNotes','Microsoft.WindowsMaps'," ^
"'Microsoft.People','Microsoft.SkypeApp','Microsoft.YourPhone'," ^
"'microsoft.windowscommunicationsapps','Microsoft.Messaging'," ^
"'Microsoft.OneConnect','Microsoft.ZuneMusic','Microsoft.ZuneVideo'," ^
"'Microsoft.MicrosoftOfficeHub','Microsoft.Office.OneNote'," ^
"'Microsoft.Office.Sway','Microsoft.XboxApp'," ^
"'Microsoft.XboxGameOverlay','Microsoft.XboxGamingOverlay'," ^
"'Microsoft.XboxIdentityProvider','Microsoft.XboxSpeechToTextOverlay'," ^
"'Microsoft.Xbox.TCUI','Microsoft.Advertising.Xaml'," ^
"'Microsoft.Wallet','Microsoft.Print3D','Microsoft.3DBuilder'," ^
"'Microsoft.BingFinance','Microsoft.BingNews','Microsoft.BingSports'," ^
"'Microsoft.BingTranslator','Microsoft.Todos'," ^
"'Microsoft.PowerAutomateDesktop','MicrosoftTeams'," ^
"'MicrosoftCorporationII.QuickAssist','Clipchamp.Clipchamp'," ^
"'Microsoft.549981C3F5F10'" ^
"); " ^
"foreach ($app in $apps) { " ^
"  Get-AppxPackage -AllUsers -Name $app 2>$null | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue; " ^
"  Get-AppxProvisionedPackage -Online 2>$null | Where-Object {$_.DisplayName -like $app} | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue; " ^
"  Write-Host \"  - $app\"; " ^
"}"
echo   Done.
echo   UWP apps removed >> "%LOG_FILE%"

:: ============================================================
:: PHASE 2: DISABLE WINDOWS FEATURES
:: ============================================================
echo.
echo ============================================================
echo  [2/8] Disabling Windows Features...
echo ============================================================
echo [2/8] Disabling Windows Features... >> "%LOG_FILE%"

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
echo   Features disabled >> "%LOG_FILE%"

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
echo   OneDrive removed >> "%LOG_FILE%"

:: ============================================================
:: PHASE 3: DISABLE WINDOWS DEFENDER
:: ============================================================
echo.
echo ============================================================
echo  [3/8] Disabling Windows Defender...
echo ============================================================
echo [3/8] Disabling Windows Defender... >> "%LOG_FILE%"

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
echo   Defender disabled + files removed >> "%LOG_FILE%"

:: ============================================================
:: PHASE 4: DISABLE WINDOWS UPDATE + SERVICES
:: ============================================================
echo.
echo ============================================================
echo  [4/8] Disabling Windows Update + Services...
echo ============================================================
echo [4/8] Disabling Windows Update + Services... >> "%LOG_FILE%"

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

:: Disable 30+ unnecessary services
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
    sc stop %%S >nul 2>&1
    sc config %%S start= disabled >nul 2>&1
)

echo   Services disabled + files removed.
echo   Services disabled + files removed >> "%LOG_FILE%"

:: ============================================================
:: PHASE 5: REGISTRY OPTIMIZATIONS
:: ============================================================
echo.
echo ============================================================
echo  [5/8] Applying Registry Tweaks...
echo ============================================================
echo [5/8] Applying Registry Tweaks... >> "%LOG_FILE%"

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
echo   Registry tweaks applied >> "%LOG_FILE%"

:: ============================================================
:: PHASE 6: CLEANUP FILES
:: ============================================================
echo.
echo ============================================================
echo  [6/8] Cleaning Up Files...
echo ============================================================
echo [6/8] Cleaning Up Files... >> "%LOG_FILE%"

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

echo   Files cleanup done.
echo   Files cleanup done >> "%LOG_FILE%"

:: ============================================================
:: PHASE 7: SYSTEM OPTIMIZATION
:: ============================================================
echo.
echo ============================================================
echo  [7/8] System Optimization...
echo ============================================================
echo [7/8] System Optimization... >> "%LOG_FILE%"

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
echo   System optimization done >> "%LOG_FILE%"

:: ============================================================
:: PHASE 8: CLEANUP SELF
:: ============================================================
echo.
echo ============================================================
echo  [8/8] Final Cleanup...
echo ============================================================
echo [8/8] Final Cleanup... >> "%LOG_FILE%"

:: Clean temp files
del /f /q "%SystemRoot%\Temp\*" >nul 2>&1
del /f /q "%TEMP%\*" >nul 2>&1

echo.
echo ============================================================ >> "%LOG_FILE%"
echo  QuickOptimize - Completed: %DATE% %TIME% >> "%LOG_FILE%"
echo ============================================================ >> "%LOG_FILE%"

echo.
echo  =============================================
echo   QuickOptimize COMPLETE!
echo  =============================================
echo   Log: %LOG_FILE%
echo  =============================================
echo.

:: Self-delete
del /f /q "C:\QuickOptimize.bat" >nul 2>&1

endlocal

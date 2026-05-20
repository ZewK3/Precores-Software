@echo off
:: ============================================================
::  PreCores PC - System Maintenance Tool
::  PreCore Lab (c) 2026
:: ============================================================
setlocal EnableExtensions EnableDelayedExpansion

:: --- Lock console window size and disable resizing ---
title PreCores PC - System Maintenance
color 0B
mode con: cols=62 lines=40
:: Disable Quick Edit + Insert mode, lock window size via registry
reg add "HKCU\Console\PreCores PC - System Maintenance" /v WindowSize /t REG_DWORD /d 0x00280042 /f >nul 2>&1
reg add "HKCU\Console\PreCores PC - System Maintenance" /v ScreenBufferSize /t REG_DWORD /d 0x012C0042 /f >nul 2>&1
reg add "HKCU\Console\PreCores PC - System Maintenance" /v QuickEdit /t REG_DWORD /d 0 /f >nul 2>&1

:: --- Admin check ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo  [!] Requesting Administrator privileges...
    powershell -NoProfile -Command "Start-Process cmd -ArgumentList '/c \"%~f0\"' -Verb RunAs"
    exit /b
)

:main_menu
cls
echo.
echo  +------------------------------------------------------------+
echo  :                                                            :
echo  :          ########  ########  ##                            :
echo  :          ##    ##  ##        ##                            :
echo  :          ########  ##        ##                            :
echo  :          ##        ##        ##                            :
echo  :          ##        ########  ########                      :
echo  :                                                            :
echo  :            PreCores PC - System Maintenance                :
echo  :                  PreCore Lab 2026                           :
echo  :                                                            :
echo  +------------------------------------------------------------+
echo  :                                                            :
echo  :   [1]  Clean Junk Files + Cache                            :
echo  :   [2]  Clean Browser Data (Chrome/Edge)                    :
echo  :   [3]  Reclaim RAM (Trim Working Sets)                     :
echo  :   [4]  Flush DNS + Reset Network                           :
echo  :   [5]  Disk Cleanup (Windows Built-in)                     :
echo  :   [6]  Optimize Drive (TRIM/Defrag)                        :
echo  :   [7]  System Info                                         :
echo  :   [8]  Kill Bloatware Processes                            :
echo  :   [9]  Fix Common Issues                                   :
echo  :   [0]  ALL-IN-ONE (1+2+3+4+8)                              :
echo  :                                                            :
echo  :   [A]  Startup Manager                                     :
echo  :   [B]  Find Large Files (top 20)                           :
echo  :   [C]  Auto Shutdown Timer                                 :
echo  :   [D]  LDPlayer Tools                                      :
echo  :   [E]  Restart Explorer                                    :
echo  :                                                            :
echo  :   [Q]  Exit                                                :
echo  :                                                            :
echo  +------------------------------------------------------------+
echo.
set "choice="
set /p "choice=  Select [0-9/A-E/Q]: "
if /i "!choice!"=="q" goto :quit
if "!choice!"=="1" goto :clean_junk
if "!choice!"=="2" goto :clean_browser
if "!choice!"=="3" goto :reclaim_ram
if "!choice!"=="4" goto :flush_dns
if "!choice!"=="5" goto :disk_cleanup
if "!choice!"=="6" goto :optimize_drive
if "!choice!"=="7" goto :sys_info
if "!choice!"=="8" goto :kill_bloat
if "!choice!"=="9" goto :fix_issues
if "!choice!"=="0" goto :all_in_one
if /i "!choice!"=="a" goto :startup_mgr
if /i "!choice!"=="b" goto :large_files
if /i "!choice!"=="c" goto :auto_shutdown
if /i "!choice!"=="d" goto :ldplayer_tools
if /i "!choice!"=="e" goto :restart_explorer
goto :main_menu

:: ============================================================
:: [1] CLEAN JUNK FILES + CACHE
:: ============================================================
:clean_junk
cls
echo.
echo  +----------------------------------------------------------+
echo  :  [1] Cleaning Junk Files + Cache...                      :
echo  +----------------------------------------------------------+
echo.
set "FREED=0"

echo   [*] Windows Temp files...
for /f "tokens=3" %%A in ('dir /s /a "%SystemRoot%\Temp" 2^>nul ^| findstr "File(s)"') do set "SZ=%%A"
del /f /q /s "%SystemRoot%\Temp\*" >nul 2>&1
for /d %%D in ("%SystemRoot%\Temp\*") do rmdir /s /q "%%D" >nul 2>&1
echo       Done.

echo   [*] User Temp files...
del /f /q /s "%TEMP%\*" >nul 2>&1
for /d %%D in ("%TEMP%\*") do rmdir /s /q "%%D" >nul 2>&1
echo       Done.

echo   [*] Prefetch cache...
del /f /q /s "%SystemRoot%\Prefetch\*" >nul 2>&1
echo       Done.

echo   [*] Thumbnail cache...
del /f /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
echo       Done.

echo   [*] Recent files list...
del /f /q "%APPDATA%\Microsoft\Windows\Recent\*" >nul 2>&1
del /f /q "%APPDATA%\Microsoft\Windows\Recent\AutomaticDestinations\*" >nul 2>&1
del /f /q "%APPDATA%\Microsoft\Windows\Recent\CustomDestinations\*" >nul 2>&1
echo       Done.

echo   [*] Windows Error Reports...
if exist "%ProgramData%\Microsoft\Windows\WER" rmdir /s /q "%ProgramData%\Microsoft\Windows\WER" >nul 2>&1
if exist "%LOCALAPPDATA%\CrashDumps" rmdir /s /q "%LOCALAPPDATA%\CrashDumps" >nul 2>&1
del /f /q "%SystemRoot%\MEMORY.DMP" >nul 2>&1
if exist "%SystemRoot%\Minidump" rmdir /s /q "%SystemRoot%\Minidump" >nul 2>&1
echo       Done.

echo   [*] Windows Update cache...
net stop wuauserv >nul 2>&1
if exist "%SystemRoot%\SoftwareDistribution\Download" (
    del /f /q /s "%SystemRoot%\SoftwareDistribution\Download\*" >nul 2>&1
)
echo       Done.

echo   [*] Delivery Optimization cache...
if exist "%SystemRoot%\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization" (
    del /f /q /s "%SystemRoot%\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\*" >nul 2>&1
)
echo       Done.

echo   [*] Font cache...
net stop FontCache >nul 2>&1
del /f /q /s "%SystemRoot%\ServiceProfiles\LocalService\AppData\Local\FontCache\*" >nul 2>&1
net start FontCache >nul 2>&1
echo       Done.

echo   [*] Event Tracing logs...
del /f /q /s "%ProgramData%\Microsoft\Diagnosis\ETLLogs\AutoLogger\*" >nul 2>&1
echo       Done.

echo   [*] INet cache...
if exist "%LOCALAPPDATA%\Microsoft\Windows\INetCache" (
    rmdir /s /q "%LOCALAPPDATA%\Microsoft\Windows\INetCache" >nul 2>&1
)
echo       Done.

echo   [*] DNS cache...
ipconfig /flushdns >nul 2>&1
echo       Done.

for /f "tokens=3" %%S in ('dir C:\ 2^>nul ^| findstr /i "bytes free"') do set "FREE=%%S"
echo.
echo  +--------------------------------------------------+
echo  :  DONE! Free disk space: %FREE% bytes
echo  +--------------------------------------------------+
echo.
pause
goto :main_menu

:: ============================================================
:: [2] CLEAN BROWSER DATA
:: ============================================================
:clean_browser
cls
echo.
echo  +----------------------------------------------------------+
echo  :  [2] Cleaning Browser Cache...                           :
echo  +----------------------------------------------------------+
echo.

:: Kill browsers first
taskkill /f /im chrome.exe >nul 2>&1
taskkill /f /im msedge.exe >nul 2>&1
timeout /t 2 /nobreak >nul

echo   [*] Google Chrome cache...
set "CHROME_DIR=%LOCALAPPDATA%\Google\Chrome\User Data"
if exist "%CHROME_DIR%\Default\Cache" rmdir /s /q "%CHROME_DIR%\Default\Cache" >nul 2>&1
if exist "%CHROME_DIR%\Default\Code Cache" rmdir /s /q "%CHROME_DIR%\Default\Code Cache" >nul 2>&1
if exist "%CHROME_DIR%\Default\Service Worker\CacheStorage" rmdir /s /q "%CHROME_DIR%\Default\Service Worker\CacheStorage" >nul 2>&1
if exist "%CHROME_DIR%\Default\GPUCache" rmdir /s /q "%CHROME_DIR%\Default\GPUCache" >nul 2>&1
if exist "%CHROME_DIR%\Default\Storage\ext" rmdir /s /q "%CHROME_DIR%\Default\Storage\ext" >nul 2>&1
if exist "%CHROME_DIR%\ShaderCache" rmdir /s /q "%CHROME_DIR%\ShaderCache" >nul 2>&1
echo       Done.

echo   [*] Microsoft Edge cache...
set "EDGE_DIR=%LOCALAPPDATA%\Microsoft\Edge\User Data"
if exist "%EDGE_DIR%\Default\Cache" rmdir /s /q "%EDGE_DIR%\Default\Cache" >nul 2>&1
if exist "%EDGE_DIR%\Default\Code Cache" rmdir /s /q "%EDGE_DIR%\Default\Code Cache" >nul 2>&1
if exist "%EDGE_DIR%\Default\GPUCache" rmdir /s /q "%EDGE_DIR%\Default\GPUCache" >nul 2>&1
if exist "%EDGE_DIR%\ShaderCache" rmdir /s /q "%EDGE_DIR%\ShaderCache" >nul 2>&1
echo       Done.

echo.
echo   DONE! Browser caches cleared.
echo.
pause
goto :main_menu

:: ============================================================
:: [3] RECLAIM RAM
:: ============================================================
:reclaim_ram
cls
echo.
echo  +----------------------------------------------------------+
echo  :  [3] Reclaiming RAM...                                   :
echo  +----------------------------------------------------------+
echo.

:: Show current RAM usage
for /f "usebackq" %%M in (`powershell -NoProfile -Command "[Math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)"`) do set "FREE_BEFORE=%%M"
echo   Free RAM before: !FREE_BEFORE! GB

echo   [*] Trimming working sets of background processes...
set "TRIM_PS=%TEMP%\pcl_trim.ps1"
(
echo $ErrorActionPreference='SilentlyContinue'
echo Add-Type 'using System;using System.Runtime.InteropServices;public class WS{[DllImport("kernel32.dll")]public static extern bool SetProcessWorkingSetSize(IntPtr h,IntPtr min,IntPtr max);}' -EA SilentlyContinue
echo $skip='LDPlayer|dnplayer|svchost|System|Idle|csrss|smss|lsass|explorer|wininit|winlogon|services|dwm|fontdrvhost|Memory Compression|Registry'
echo Get-Process ^| Where-Object {$_.ProcessName -notmatch $skip} ^| ForEach-Object { try{$h=$_.Handle;if($h){[void][WS]::SetProcessWorkingSetSize($h,[IntPtr]::new(-1^),[IntPtr]::new(-1^))}}catch{} }
) > "%TRIM_PS%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%TRIM_PS%" >nul 2>&1
del /f /q "%TRIM_PS%" >nul 2>&1
echo       Done.

echo   [*] Flushing idle tasks...
rundll32.exe advapi32.dll,ProcessIdleTasks >nul 2>&1
echo       Done.

timeout /t 3 /nobreak >nul
for /f "usebackq" %%M in (`powershell -NoProfile -Command "[Math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)"`) do set "FREE_AFTER=%%M"
echo.
echo   Free RAM after:  !FREE_AFTER! GB
echo.
echo   DONE! RAM reclaimed.
echo.
pause
goto :main_menu

:: ============================================================
:: [4] FLUSH DNS + RESET NETWORK
:: ============================================================
:flush_dns
cls
echo.
echo  +----------------------------------------------------------+
echo  :  [4] Network Reset...                                    :
echo  +----------------------------------------------------------+
echo.

echo   [*] Flushing DNS cache...
ipconfig /flushdns >nul 2>&1
echo       Done.

echo   [*] Releasing/renewing IP...
ipconfig /release >nul 2>&1
ipconfig /renew >nul 2>&1
echo       Done.

echo   [*] Resetting Winsock catalog...
netsh winsock reset >nul 2>&1
echo       Done.

echo   [*] Resetting TCP/IP stack...
netsh int ip reset >nul 2>&1
echo       Done.

echo   [*] Flushing ARP cache...
netsh interface ip delete arpcache >nul 2>&1
echo       Done.

echo.
echo   DONE! Network stack reset. Reboot recommended.
echo.
pause
goto :main_menu

:: ============================================================
:: [5] DISK CLEANUP
:: ============================================================
:disk_cleanup
cls
echo.
echo  +----------------------------------------------------------+
echo  :  [5] Running Windows Disk Cleanup...                     :
echo  +----------------------------------------------------------+
echo.

:: Pre-configure disk cleanup categories
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Files" /v StateFlags0100 /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Recycle Bin" /v StateFlags0100 /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Files" /v StateFlags0100 /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Thumbnail Cache" /v StateFlags0100 /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Setup Files" /v StateFlags0100 /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Old ChkDsk Files" /v StateFlags0100 /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Setup Log Files" /v StateFlags0100 /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Update Cleanup" /v StateFlags0100 /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Upgrade Log Files" /v StateFlags0100 /t REG_DWORD /d 2 /f >nul 2>&1

echo   Running cleanmgr (this may take a few minutes)...
cleanmgr /sagerun:100 >nul 2>&1

echo.
echo   DONE! Disk Cleanup completed.
echo.
pause
goto :main_menu

:: ============================================================
:: [6] OPTIMIZE DRIVE
:: ============================================================
:optimize_drive
cls
echo.
echo  +----------------------------------------------------------+
echo  :  [6] Optimizing Drive...                                 :
echo  +----------------------------------------------------------+
echo.

echo   [*] Detecting drive type...
set "OPT_PS=%TEMP%\pcl_opt.ps1"
(
echo $d=Get-PhysicalDisk^|Select-Object -First 1
echo if($d.MediaType -eq 'SSD'^){
echo     Write-Host '  Drive: SSD - Running TRIM...'
echo     Optimize-Volume -DriveLetter C -ReTrim -ErrorAction SilentlyContinue
echo }else{
echo     Write-Host '  Drive: HDD - Running Defrag...'
echo     Optimize-Volume -DriveLetter C -Defrag -ErrorAction SilentlyContinue
echo }
echo Write-Host '  Done.'
) > "%OPT_PS%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%OPT_PS%"
del /f /q "%OPT_PS%" >nul 2>&1

echo.
echo   DONE! Drive optimized.
echo.
pause
goto :main_menu

:: ============================================================
:: [7] SYSTEM INFO
:: ============================================================
:sys_info
cls
echo.
echo  +----------------------------------------------------------+
echo  :  [7] System Information                                  :
echo  +----------------------------------------------------------+
echo.

:: Computer Name
echo   Computer:    %COMPUTERNAME%

:: OS Version
for /f "tokens=4-5 delims=[]. " %%A in ('ver') do echo   Windows:     %%A.%%B

:: CPU
for /f "tokens=2 delims==" %%C in ('wmic cpu get Name /value 2^>nul ^| findstr "Name"') do echo   CPU:         %%C

:: RAM
for /f "usebackq" %%M in (`powershell -NoProfile -Command "[Math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,1)"`) do echo   Total RAM:   %%M GB
for /f "usebackq" %%M in (`powershell -NoProfile -Command "[Math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)"`) do echo   Free RAM:    %%M GB

:: Disk
for /f "tokens=3" %%S in ('dir C:\ 2^>nul ^| findstr /i "bytes free"') do echo   Free Disk:   %%S bytes

:: GPU
for /f "tokens=2 delims==" %%G in ('wmic path win32_VideoController get Name /value 2^>nul ^| findstr "Name"') do echo   GPU:         %%G

:: Uptime
for /f "usebackq" %%U in (`powershell -NoProfile -Command "$u=(Get-Date)-(Get-CimInstance Win32_OperatingSystem).LastBootUpTime;'{0}d {1}h {2}m' -f $u.Days,$u.Hours,$u.Minutes"`) do echo   Uptime:      %%U

:: IP
for /f "tokens=2 delims=:" %%I in ('ipconfig ^| findstr /i "IPv4" ^| findstr /v "169.254"') do echo   IP:         %%I

echo.
echo  +----------------------------------------------------------+
echo.
pause
goto :main_menu

:: ============================================================
:: [8] KILL BLOATWARE
:: ============================================================
:kill_bloat
cls
echo.
echo  +----------------------------------------------------------+
echo  :  [8] Killing Bloatware Processes...                      :
echo  +----------------------------------------------------------+
echo.

set "KILLED=0"
for %%P in (
    SearchApp.exe SearchUI.exe RuntimeBroker.exe
    ShellExperienceHost.exe StartMenuExperienceHost.exe
    MicrosoftEdge.exe msedge.exe MicrosoftEdgeUpdate.exe
    MusNotification.exe MusNotificationUx.exe
    YourPhone.exe PhoneExperienceHost.exe
    GameBarPresenceWriter.exe gamebar.exe GameBar.exe
    TextInputHost.exe InputApp.exe
    CompatTelRunner.exe DeviceCensus.exe
    backgroundTaskHost.exe
    SecurityHealthSystray.exe SecurityHealthService.exe
    OneDrive.exe Teams.exe
    WmiApSrv.exe
) do (
    tasklist /fi "IMAGENAME eq %%P" 2>nul | findstr /i "%%P" >nul 2>&1
    if !errorlevel! equ 0 (
        taskkill /f /im %%P >nul 2>&1
        echo   [X] Killed: %%P
        set /a KILLED+=1
    )
)

if !KILLED! equ 0 (
    echo   No bloatware processes found running.
) else (
    echo.
    echo   Killed !KILLED! bloatware process(es).
)

echo.
echo   DONE!
echo.
pause
goto :main_menu

:: ============================================================
:: [9] FIX COMMON ISSUES
:: ============================================================
:fix_issues
cls
echo.
echo  +----------------------------------------------------------+
echo  :  [9] Fix Common Issues                                   :
echo  +----------------------------------------------------------+
echo.
echo   [A] Repair System Files (SFC)
echo   [B] Repair Windows Image (DISM)
echo   [C] Reset Windows Icon Cache
echo   [D] Re-register Start Menu
echo   [E] Fix File Associations
echo   [F] Clear Print Spooler
echo   [Q] Back to Main Menu
echo.
set "fix="
set /p "fix=  Select [A-F/Q]: "
if /i "!fix!"=="q" goto :main_menu

if /i "!fix!"=="a" (
    echo.
    echo   Running System File Checker (may take 5-10 min)...
    sfc /scannow
    echo   Done.
)
if /i "!fix!"=="b" (
    echo.
    echo   Running DISM Repair (may take 10-15 min)...
    dism /Online /Cleanup-Image /RestoreHealth
    echo   Done.
)
if /i "!fix!"=="c" (
    echo.
    echo   Resetting icon cache...
    taskkill /f /im explorer.exe >nul 2>&1
    del /f /q /a:h "%LOCALAPPDATA%\IconCache.db" >nul 2>&1
    del /f /q /s "%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache_*.db" >nul 2>&1
    start explorer.exe
    echo   Done. Icons will refresh.
)
if /i "!fix!"=="d" (
    echo.
    echo   Re-registering Start Menu apps...
    powershell -NoProfile -Command "Get-AppXPackage -AllUsers | ForEach-Object { Add-AppxPackage -DisableDevelopmentMode -Register ($_.InstallLocation + '\AppXManifest.xml') -EA SilentlyContinue }" >nul 2>&1
    echo   Done.
)
if /i "!fix!"=="e" (
    echo.
    echo   Resetting file associations...
    dism /Online /Remove-DefaultAppAssociations >nul 2>&1
    echo   Done. Default associations restored.
)
if /i "!fix!"=="f" (
    echo.
    echo   Clearing print spooler...
    net stop spooler >nul 2>&1
    del /f /q "%SystemRoot%\System32\spool\PRINTERS\*" >nul 2>&1
    net start spooler >nul 2>&1
    echo   Done.
)

echo.
pause
goto :fix_issues

:: ============================================================
:: [0] ALL-IN-ONE
:: ============================================================
:all_in_one
cls
echo.
echo  +----------------------------------------------------------+
echo  :  [0] ALL-IN-ONE Cleanup...                               :
echo  +----------------------------------------------------------+
echo.

echo  -- Step 1/4: Cleaning Junk Files --
del /f /q /s "%SystemRoot%\Temp\*" >nul 2>&1
for /d %%D in ("%SystemRoot%\Temp\*") do rmdir /s /q "%%D" >nul 2>&1
del /f /q /s "%TEMP%\*" >nul 2>&1
for /d %%D in ("%TEMP%\*") do rmdir /s /q "%%D" >nul 2>&1
del /f /q /s "%SystemRoot%\Prefetch\*" >nul 2>&1
del /f /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
del /f /q "%APPDATA%\Microsoft\Windows\Recent\*" >nul 2>&1
if exist "%ProgramData%\Microsoft\Windows\WER" rmdir /s /q "%ProgramData%\Microsoft\Windows\WER" >nul 2>&1
if exist "%LOCALAPPDATA%\CrashDumps" rmdir /s /q "%LOCALAPPDATA%\CrashDumps" >nul 2>&1
del /f /q /s "%ProgramData%\Microsoft\Diagnosis\ETLLogs\AutoLogger\*" >nul 2>&1
echo   Done.

echo  -- Step 2/4: Cleaning Browser Cache --
taskkill /f /im chrome.exe >nul 2>&1
taskkill /f /im msedge.exe >nul 2>&1
timeout /t 1 /nobreak >nul
if exist "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache" rmdir /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache" >nul 2>&1
if exist "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Code Cache" rmdir /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Code Cache" >nul 2>&1
if exist "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache" rmdir /s /q "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache" >nul 2>&1
echo   Done.

echo  -- Step 3/4: Reclaiming RAM --
set "TRIM_PS=%TEMP%\pcl_trim.ps1"
(
echo $ErrorActionPreference='SilentlyContinue'
echo Add-Type 'using System;using System.Runtime.InteropServices;public class WS{[DllImport("kernel32.dll")]public static extern bool SetProcessWorkingSetSize(IntPtr h,IntPtr min,IntPtr max);}' -EA SilentlyContinue
echo $skip='LDPlayer|dnplayer|svchost|System|Idle|csrss|smss|lsass|explorer|wininit|winlogon|services|dwm|fontdrvhost|Memory Compression|Registry'
echo Get-Process ^| Where-Object {$_.ProcessName -notmatch $skip} ^| ForEach-Object { try{$h=$_.Handle;if($h){[void][WS]::SetProcessWorkingSetSize($h,[IntPtr]::new(-1^),[IntPtr]::new(-1^))}}catch{} }
) > "%TRIM_PS%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%TRIM_PS%" >nul 2>&1
del /f /q "%TRIM_PS%" >nul 2>&1
rundll32.exe advapi32.dll,ProcessIdleTasks >nul 2>&1
echo   Done.

echo  -- Step 4/4: Killing Bloatware + Flush DNS --
for %%P in (
    SearchApp.exe RuntimeBroker.exe MicrosoftEdgeUpdate.exe
    MusNotification.exe YourPhone.exe GameBarPresenceWriter.exe
    CompatTelRunner.exe backgroundTaskHost.exe SecurityHealthSystray.exe
    OneDrive.exe TextInputHost.exe
) do taskkill /f /im %%P >nul 2>&1
ipconfig /flushdns >nul 2>&1
echo   Done.

echo.
for /f "tokens=3" %%S in ('dir C:\ 2^>nul ^| findstr /i "bytes free"') do set "FREE=%%S"
echo  +----------------------------------------------------------+
echo  :  ALL-IN-ONE COMPLETE!                                    :
echo  :  Free disk space: %FREE% bytes
echo  +----------------------------------------------------------+
echo.
pause
goto :main_menu

:quit
cls
echo.
echo   Thank you for using PreCores PC!
echo   PreCore Lab 2026
echo.
timeout /t 2 /nobreak >nul
endlocal
exit /b 0

:: ============================================================
:: [A] STARTUP MANAGER
:: ============================================================
:startup_mgr
cls
echo.
echo  +----------------------------------------------------------+
echo  :  [A] Startup Manager                                     :
echo  +----------------------------------------------------------+
echo.
echo   -- HKCU Run (Current User) --
set "CNT=0"
for /f "tokens=1,2,*" %%A in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" 2^>nul ^| findstr /i "REG_SZ REG_EXPAND_SZ"') do (
    set /a CNT+=1
    echo   !CNT!. %%A
    echo      %%C
)
echo.
echo   -- HKLM Run (All Users) --
for /f "tokens=1,2,*" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" 2^>nul ^| findstr /i "REG_SZ REG_EXPAND_SZ"') do (
    set /a CNT+=1
    echo   !CNT!. %%A
    echo      %%C
)
echo.
echo   -- Startup Folder --
if exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup" (
    for %%F in ("%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\*") do (
        set /a CNT+=1
        echo   !CNT!. %%~nxF
    )
)
if !CNT! equ 0 echo   (no startup items found)
echo.
echo   Total: !CNT! startup item(s)
echo.
echo   [D] Delete a startup entry by name
echo   [Q] Back to Main Menu
echo.
set "schoice="
set /p "schoice=  Select [D/Q]: "
if /i "!schoice!"=="q" goto :main_menu
if /i "!schoice!"=="d" (
    set "sname="
    set /p "sname=  Enter value name to delete: "
    if defined sname (
        reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "!sname!" /f >nul 2>&1
        reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "!sname!" /f >nul 2>&1
        echo   Deleted: !sname!
    )
)
echo.
pause
goto :startup_mgr

:: ============================================================
:: [B] FIND LARGE FILES
:: ============================================================
:large_files
cls
echo.
echo  +----------------------------------------------------------+
echo  :  [B] Finding Top 20 Largest Files on C:\...              :
echo  +----------------------------------------------------------+
echo.
echo   Scanning... (this may take 30-60 seconds)
echo.
set "LF_PS=%TEMP%\pcl_large.ps1"
(
echo Get-ChildItem C:\ -Recurse -File -ErrorAction SilentlyContinue ^|
echo   Sort-Object Length -Descending ^|
echo   Select-Object -First 20 ^|
echo   ForEach-Object {
echo     $sz = if($_.Length -ge 1GB){'{0:N1} GB' -f ($_.Length/1GB)}
echo          elseif($_.Length -ge 1MB){'{0:N1} MB' -f ($_.Length/1MB)}
echo          else{'{0:N0} KB' -f ($_.Length/1KB)}
echo     '  {0,10}  {1}' -f $sz,$_.FullName
echo   }
) > "%LF_PS%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%LF_PS%"
del /f /q "%LF_PS%" >nul 2>&1
echo.
pause
goto :main_menu

:: ============================================================
:: [C] AUTO SHUTDOWN TIMER
:: ============================================================
:auto_shutdown
cls
echo.
echo  +----------------------------------------------------------+
echo  :  [C] Auto Shutdown Timer                                 :
echo  +----------------------------------------------------------+
echo.
echo   [1] Shutdown in 30 minutes
echo   [2] Shutdown in 1 hour
echo   [3] Shutdown in 2 hours
echo   [4] Shutdown in 4 hours
echo   [5] Custom (enter minutes)
echo   [6] CANCEL scheduled shutdown
echo   [Q] Back
echo.
set "stimer="
set /p "stimer=  Select [1-6/Q]: "
if /i "!stimer!"=="q" goto :main_menu
if "!stimer!"=="1" (shutdown /s /t 1800 & echo   Shutdown scheduled in 30 minutes.)
if "!stimer!"=="2" (shutdown /s /t 3600 & echo   Shutdown scheduled in 1 hour.)
if "!stimer!"=="3" (shutdown /s /t 7200 & echo   Shutdown scheduled in 2 hours.)
if "!stimer!"=="4" (shutdown /s /t 14400 & echo   Shutdown scheduled in 4 hours.)
if "!stimer!"=="5" (
    set "mins="
    set /p "mins=  Enter minutes: "
    if defined mins (
        set /a secs=!mins!*60
        shutdown /s /t !secs!
        echo   Shutdown scheduled in !mins! minutes.
    )
)
if "!stimer!"=="6" (
    shutdown /a >nul 2>&1
    echo   Scheduled shutdown CANCELLED.
)
echo.
pause
goto :main_menu

:: ============================================================
:: [D] LDPLAYER TOOLS
:: ============================================================
:ldplayer_tools
cls
echo.
echo  +----------------------------------------------------------+
echo  :  [D] LDPlayer Tools                                      :
echo  +----------------------------------------------------------+
echo.

:: Count running instances
set "LD_CNT=0"
for /f %%N in ('tasklist /fi "IMAGENAME eq dnplayer.exe" 2^>nul ^| find /c "dnplayer"') do set "LD_CNT=%%N"
echo   Running LDPlayer instances: !LD_CNT!
echo.
echo   [1] Kill ALL LDPlayer instances
echo   [2] Clear LDPlayer temp/cache files
echo   [3] Show LDPlayer disk usage
echo   [Q] Back
echo.
set "ldchoice="
set /p "ldchoice=  Select [1-3/Q]: "
if /i "!ldchoice!"=="q" goto :main_menu
if "!ldchoice!"=="1" (
    echo.
    echo   Killing all LDPlayer processes...
    taskkill /f /im dnplayer.exe >nul 2>&1
    taskkill /f /im LdVBoxHeadless.exe >nul 2>&1
    taskkill /f /im LDPlayer.exe >nul 2>&1
    taskkill /f /im dnconsole.exe >nul 2>&1
    taskkill /f /im dnmultiplayer.exe >nul 2>&1
    echo   All LDPlayer instances killed.
)
if "!ldchoice!"=="2" (
    echo.
    echo   Clearing LDPlayer cache...
    set "LD_DIR=%LOCALAPPDATA%\LDPlayer\LDPlayer9"
    if exist "!LD_DIR!" (
        for /d %%V in ("!LD_DIR!\vms\*") do (
            if exist "%%V\temp" rmdir /s /q "%%V\temp" >nul 2>&1
            if exist "%%V\cache" rmdir /s /q "%%V\cache" >nul 2>&1
        )
        echo   Cache cleared.
    ) else (
        echo   LDPlayer directory not found.
    )
)
if "!ldchoice!"=="3" (
    echo.
    echo   Scanning LDPlayer disk usage...
    set "LD_DIR=%LOCALAPPDATA%\LDPlayer"
    if exist "!LD_DIR!" (
        for /f "tokens=3" %%S in ('dir /s "!LD_DIR!" 2^>nul ^| findstr "File(s)"') do echo   LDPlayer total: %%S bytes
    ) else (
        set "LD_DIR=%ProgramFiles%\LDPlayer"
        if exist "!LD_DIR!" (
            for /f "tokens=3" %%S in ('dir /s "!LD_DIR!" 2^>nul ^| findstr "File(s)"') do echo   LDPlayer total: %%S bytes
        ) else (
            echo   LDPlayer not found.
        )
    )
)
echo.
pause
goto :ldplayer_tools

:: ============================================================
:: [E] RESTART EXPLORER
:: ============================================================
:restart_explorer
echo.
echo   Restarting Explorer...
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul
start explorer.exe
echo   Explorer restarted.
timeout /t 1 /nobreak >nul
goto :main_menu

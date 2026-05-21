@echo off
chcp 65001 >nul
:: ============================================================
::  PreCores PC - System Maintenance Tool
::  PreCore Lab (c) 2026
:: ============================================================
setlocal EnableExtensions EnableDelayedExpansion

:: --- Lock console window: fixed size, no resize, no scrollbar ---
title PreCores PC - Maintenance Suite
mode con: cols=72 lines=34

:: Force buffer = window (eliminates scrollbar completely)
:: Disable Quick Edit and Insert mode, lock window size via registry
reg add "HKCU\Console\PreCores PC - Maintenance Suite" /v WindowSize /t REG_DWORD /d 0x00220048 /f >nul 2>&1
reg add "HKCU\Console\PreCores PC - Maintenance Suite" /v ScreenBufferSize /t REG_DWORD /d 0x00220048 /f >nul 2>&1
reg add "HKCU\Console\PreCores PC - Maintenance Suite" /v QuickEdit /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Console\PreCores PC - Maintenance Suite" /v InsertMode /t REG_DWORD /d 0 /f >nul 2>&1

:: --- Admin check ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo  [!] Requesting Administrator privileges...
    powershell -NoProfile -Command "Start-Process cmd -ArgumentList '/k \"%~f0\"' -Verb RunAs"
    exit /b
)

:: --- Color codes setup ---
for /F "tokens=1 delims=#" %%E in ('"prompt #$E# & echo on & for %%B in (1) do rem" ^<nul') do set "ESC=%%E"
set "R=%ESC%[91m"
set "G=%ESC%[92m"
set "Y=%ESC%[93m"
set "B=%ESC%[94m"
set "M=%ESC%[95m"
set "C=%ESC%[96m"
set "W=%ESC%[97m"
set "DG=%ESC%[90m"
set "N=%ESC%[0m"

:main_menu
cls
echo.
echo   %C%╔══════════════════════════════════════════════════════════════╗%N%
call :box_line 62 "PreCores PC" "%W%PreCores PC%N%"
call :box_line 62 "Fast maintenance tools." "%DG%Fast maintenance tools.%N%"
echo   %C%╠══════════════════════════════════════════════════════════════╣%N%
call :box_line 62 "[1] Cleanup tools          [2] RAM tools" "%G%[1]%N% Cleanup tools          %G%[2]%N% RAM tools"
call :box_line 62 "[3] Network tools          [4] System tools" "%G%[3]%N% Network tools          %G%[4]%N% System tools"
call :box_line 62 "[5] Driver tools           [6] Drive tools" "%G%[5]%N% Driver tools           %G%[6]%N% Drive tools"
call :box_line 62 "[7] Emulator/VM tools      [Q] Exit" "%G%[7]%N% Emulator/VM tools      %R%[Q]%N% Exit"
echo   %C%╚══════════════════════════════════════════════════════════════╝%N%
echo.
set "choice="
set /p "choice=  %C%➤%N% Select %W%[1-7/Q]%N%: "
if /i "!choice!"=="q" goto :quit
if "!choice!"=="1" goto :cleanup_tools
if "!choice!"=="2" goto :ram_tools
if "!choice!"=="3" goto :flush_dns
if "!choice!"=="4" goto :system_tools
if "!choice!"=="5" goto :driver_tools
if "!choice!"=="6" goto :drive_tools
if "!choice!"=="7" goto :ldplayer_tools
goto :main_menu

:: ============================================================
:: HEADER HELPER (reusable sub-header for each feature)
:: ============================================================
:show_header
cls
echo.
echo   %C%╔══════════════════════════════════════════════════════════════╗%N%
call :box_line 62 "PreCores PC  %~1" "%W%PreCores PC%N%  %DG%%~1%N%"
echo   %C%╚══════════════════════════════════════════════════════════════╝%N%
echo.
exit /b

:box_line
set "BOX_WIDTH=%~1"
set "BOX_VISIBLE=%~2"
set "BOX_STYLED=%~3"
set "BOX_PAD=                                                                          "
call :strlen BOX_VISIBLE BOX_LEN
set /a BOX_FILL=BOX_WIDTH-2-BOX_LEN
if !BOX_FILL! lss 0 set "BOX_FILL=0"
echo   %C%║%N%  !BOX_STYLED!!BOX_PAD:~0,%BOX_FILL%!%C%║%N%
exit /b

:box_blank
call :box_line %~1 "" ""
exit /b

:clean_chromium_cache
set "BROWSER_NAME=%~1"
set "BROWSER_DIR=%~2"
echo   %G%[■]%N% !BROWSER_NAME! cache...
if not exist "!BROWSER_DIR!" (
    echo       %DG%Not installed.%N%
    exit /b
)
set "PROFILE_COUNT=0"
for /d %%P in ("!BROWSER_DIR!\*") do (
    if exist "%%~fP\Cache" rmdir /s /q "%%~fP\Cache" >nul 2>&1
    if exist "%%~fP\Cache\Cache_Data" rmdir /s /q "%%~fP\Cache\Cache_Data" >nul 2>&1
    if exist "%%~fP\Code Cache" rmdir /s /q "%%~fP\Code Cache" >nul 2>&1
    if exist "%%~fP\GPUCache" rmdir /s /q "%%~fP\GPUCache" >nul 2>&1
    if exist "%%~fP\Service Worker\CacheStorage" rmdir /s /q "%%~fP\Service Worker\CacheStorage" >nul 2>&1
    if exist "%%~fP\Media Cache" rmdir /s /q "%%~fP\Media Cache" >nul 2>&1
    set /a PROFILE_COUNT+=1
)
if exist "!BROWSER_DIR!\ShaderCache" rmdir /s /q "!BROWSER_DIR!\ShaderCache" >nul 2>&1
echo       %DG%Done. Profiles checked: !PROFILE_COUNT!%N%
exit /b

:strlen
setlocal EnableDelayedExpansion
set "STR=!%~1!"
set "LEN=0"
:strlen_loop
if defined STR (
    set "STR=!STR:~1!"
    set /a LEN+=1
    goto :strlen_loop
)
endlocal & set "%~2=%LEN%"
exit /b

:: ============================================================
:: [1.1] CLEAN JUNK FILES + CACHE
:: ============================================================
:clean_junk
call :show_header "[1.1] Cleaning Junk Files + Cache"
set "FREED=0"

echo   %G%[■]%N% Windows Temp files...
for /f "tokens=3" %%A in ('dir /s /a "%SystemRoot%\Temp" 2^>nul ^| findstr "File(s)"') do set "SZ=%%A"
del /f /q /s "%SystemRoot%\Temp\*" >nul 2>&1
for /d %%D in ("%SystemRoot%\Temp\*") do rmdir /s /q "%%D" >nul 2>&1
echo       %DG%Done.%N%

echo   %G%[■]%N% User Temp files...
del /f /q /s "%TEMP%\*" >nul 2>&1
for /d %%D in ("%TEMP%\*") do rmdir /s /q "%%D" >nul 2>&1
echo       %DG%Done.%N%

echo   %G%[■]%N% Prefetch cache...
del /f /q /s "%SystemRoot%\Prefetch\*" >nul 2>&1
echo       %DG%Done.%N%

echo   %G%[■]%N% Thumbnail cache...
del /f /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
echo       %DG%Done.%N%

echo   %G%[■]%N% Recent files list...
del /f /q "%APPDATA%\Microsoft\Windows\Recent\*" >nul 2>&1
del /f /q "%APPDATA%\Microsoft\Windows\Recent\AutomaticDestinations\*" >nul 2>&1
del /f /q "%APPDATA%\Microsoft\Windows\Recent\CustomDestinations\*" >nul 2>&1
echo       %DG%Done.%N%

echo   %G%[■]%N% Windows Error Reports...
if exist "%ProgramData%\Microsoft\Windows\WER" rmdir /s /q "%ProgramData%\Microsoft\Windows\WER" >nul 2>&1
if exist "%LOCALAPPDATA%\CrashDumps" rmdir /s /q "%LOCALAPPDATA%\CrashDumps" >nul 2>&1
del /f /q "%SystemRoot%\MEMORY.DMP" >nul 2>&1
if exist "%SystemRoot%\Minidump" rmdir /s /q "%SystemRoot%\Minidump" >nul 2>&1
echo       %DG%Done.%N%

echo   %G%[■]%N% Windows Update cache...
net stop wuauserv >nul 2>&1
if exist "%SystemRoot%\SoftwareDistribution\Download" (
    del /f /q /s "%SystemRoot%\SoftwareDistribution\Download\*" >nul 2>&1
)
echo       %DG%Done.%N%

echo   %G%[■]%N% Delivery Optimization cache...
if exist "%SystemRoot%\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization" (
    del /f /q /s "%SystemRoot%\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\*" >nul 2>&1
)
echo       %DG%Done.%N%

echo   %G%[■]%N% Font cache...
net stop FontCache >nul 2>&1
del /f /q /s "%SystemRoot%\ServiceProfiles\LocalService\AppData\Local\FontCache\*" >nul 2>&1
net start FontCache >nul 2>&1
echo       %DG%Done.%N%

echo   %G%[■]%N% Event Tracing logs...
del /f /q /s "%ProgramData%\Microsoft\Diagnosis\ETLLogs\AutoLogger\*" >nul 2>&1
echo       %DG%Done.%N%

echo   %G%[■]%N% INet cache...
if exist "%LOCALAPPDATA%\Microsoft\Windows\INetCache" (
    rmdir /s /q "%LOCALAPPDATA%\Microsoft\Windows\INetCache" >nul 2>&1
)
echo       %DG%Done.%N%

echo   %G%[■]%N% DNS cache...
ipconfig /flushdns >nul 2>&1
echo       %DG%Done.%N%

for /f "tokens=3" %%S in ('dir C:\ 2^>nul ^| findstr /i "bytes free"') do set "FREE=%%S"
echo.
echo   %C%╔══════════════════════════════════════════════════════════╗%N%
call :box_line 58 "✓ DONE  Free disk space: %FREE% bytes" "%G%✓ DONE%N%  Free disk space: %W%%FREE%%N% bytes"
echo   %C%╚══════════════════════════════════════════════════════════╝%N%
echo.
pause
goto :cleanup_tools

:: ============================================================
:: [1.2] CLEAN BROWSER DATA
:: ============================================================
:clean_browser
call :show_header "[1.2] Cleaning Browser Cache"

echo   %Y%Browsers will be closed to release locked cache files.%N%
for %%P in (chrome.exe msedge.exe brave.exe) do taskkill /f /im %%P >nul 2>&1
timeout /t 1 /nobreak >nul

call :clean_chromium_cache "Google Chrome" "%LOCALAPPDATA%\Google\Chrome\User Data"
call :clean_chromium_cache "Microsoft Edge" "%LOCALAPPDATA%\Microsoft\Edge\User Data"
call :clean_chromium_cache "Brave" "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data"

echo.
echo   %G%✓ DONE!%N% Browser caches cleared.
echo.
pause
goto :cleanup_tools

:: ============================================================
:: [2] RAM TOOLS
:: ============================================================
:ram_tools
call :show_header "[2] RAM Tools"
echo   %G%[1]%N% Reclaim/free RAM now
echo   %G%[2]%N% Show top RAM usage apps
echo   %G%[3]%N% Virtual memory/pagefile
echo   %G%[4]%N% RAM summary
echo   %R%[Q]%N% Back
echo.
set "ramchoice="
set /p "ramchoice=  %C%➤%N% Select %W%[1-4/Q]%N%: "
if /i "!ramchoice!"=="q" goto :main_menu
if "!ramchoice!"=="1" goto :reclaim_ram
if "!ramchoice!"=="2" goto :ram_top_apps
if "!ramchoice!"=="3" goto :virtual_memory_tools
if "!ramchoice!"=="4" goto :ram_summary
goto :ram_tools

:reclaim_ram
call :show_header "[2.1] Reclaiming RAM"

:: Show current RAM usage
for /f "usebackq" %%M in (`powershell -NoProfile -Command "[Math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)"`) do set "FREE_BEFORE=%%M"
echo   %DG%Free RAM before:%N% %W%!FREE_BEFORE! GB%N%
echo.

echo   %G%[■]%N% Trimming working sets of background processes...
if exist "%ProgramData%\PCL\trim_ram.exe" (
    "%ProgramData%\PCL\trim_ram.exe" >nul 2>&1
    goto :trim_done_1
)
set "TRIM_PS=%TEMP%\pcl_trim.ps1"
echo $ErrorActionPreference='SilentlyContinue' > "!TRIM_PS!"
echo Add-Type 'using System;using System.Runtime.InteropServices;public class WS{[DllImport("kernel32.dll")]public static extern bool SetProcessWorkingSetSize(IntPtr h,IntPtr min,IntPtr max);}' -EA SilentlyContinue >> "!TRIM_PS!"
echo $skip='LDPlayer^|dnplayer^|LdVBoxHeadless^|svchost^|System^|Idle^|csrss^|smss^|lsass^|explorer^|wininit^|winlogon^|services^|dwm^|fontdrvhost^|Memory Compression^|Registry' >> "!TRIM_PS!"
echo Get-Process ^| Where-Object {$_.ProcessName -notmatch $skip} ^| ForEach-Object { try{$h=$_.Handle;if($h){[void][WS]::SetProcessWorkingSetSize($h,[IntPtr]::new(-1),[IntPtr]::new(-1))}}catch{} } >> "!TRIM_PS!"
powershell -NoProfile -ExecutionPolicy Bypass -File "!TRIM_PS!" >nul 2>&1
del /f /q "!TRIM_PS!" >nul 2>&1
:trim_done_1
echo       %DG%Done.%N%

echo   %G%[■]%N% Flushing idle tasks...
rundll32.exe advapi32.dll,ProcessIdleTasks >nul 2>&1
echo       %DG%Done.%N%

timeout /t 1 /nobreak >nul
for /f "usebackq" %%M in (`powershell -NoProfile -Command "[Math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)"`) do set "FREE_AFTER=%%M"
echo.
echo   %DG%Free RAM after:%N%  %G%!FREE_AFTER! GB%N%
echo.
echo   %G%✓ DONE!%N% RAM reclaimed.
echo.
pause
goto :ram_tools

:ram_top_apps
call :show_header "[2.2] Top RAM Usage"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 20 @{Name='RAM_MB';Expression={[math]::Round($_.WorkingSet64/1MB,1)}},ProcessName,Id,CPU | Format-Table -AutoSize"
echo.
pause
goto :ram_tools

:ram_summary
call :show_header "[2.4] RAM Summary"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$os=Get-CimInstance Win32_OperatingSystem;$cs=Get-CimInstance Win32_ComputerSystem;$pf=Get-CimInstance Win32_PageFileUsage -ErrorAction SilentlyContinue;[pscustomobject]@{TotalRAM_GB=[math]::Round($cs.TotalPhysicalMemory/1GB,2);FreeRAM_GB=[math]::Round($os.FreePhysicalMemory/1MB,2);UsedRAM_GB=[math]::Round(($cs.TotalPhysicalMemory/1GB)-($os.FreePhysicalMemory/1MB),2);PageFile=($pf | ForEach-Object { $_.Name + ' ' + $_.CurrentUsage + 'MB used / ' + $_.AllocatedBaseSize + 'MB' }) -join '; '} | Format-List"
echo.
pause
goto :ram_tools

:virtual_memory_tools
call :show_header "[2.3] Virtual Memory"
echo   %G%[1]%N% Show current pagefile
echo   %G%[2]%N% Set system-managed pagefile
echo   %G%[3]%N% Set custom pagefile size
echo   %G%[4]%N% Open Windows advanced settings
echo   %R%[Q]%N% Back
echo.
set "vmchoice="
set /p "vmchoice=  %C%➤%N% Select %W%[1-4/Q]%N%: "
if /i "!vmchoice!"=="q" goto :ram_tools
if "!vmchoice!"=="1" goto :vmem_show
if "!vmchoice!"=="2" goto :vmem_system_managed
if "!vmchoice!"=="3" goto :vmem_custom
if "!vmchoice!"=="4" start "" SystemPropertiesAdvanced.exe
goto :virtual_memory_tools

:vmem_show
call :show_header "[2.3] Current Pagefile"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Write-Host 'Computer setting:' -ForegroundColor Cyan;Get-CimInstance Win32_ComputerSystem | Select-Object AutomaticManagedPagefile | Format-List;Write-Host 'Pagefile setting:' -ForegroundColor Cyan;Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue | Select-Object Name,InitialSize,MaximumSize | Format-Table -AutoSize;Write-Host 'Pagefile usage:' -ForegroundColor Cyan;Get-CimInstance Win32_PageFileUsage -ErrorAction SilentlyContinue | Select-Object Name,AllocatedBaseSize,CurrentUsage,PeakUsage | Format-Table -AutoSize"
echo.
pause
goto :virtual_memory_tools

:vmem_system_managed
call :show_header "[2.3] System Managed Pagefile"
echo   %Y%This changes virtual memory settings. Reboot is recommended.%N%
set "VM_CONFIRM="
set /p "VM_CONFIRM=  Type YES to continue: "
if /i not "!VM_CONFIRM!"=="YES" goto :virtual_memory_tools
wmic computersystem where name="%COMPUTERNAME%" set AutomaticManagedPagefile=True >nul 2>&1
echo.
echo   %G%✓ DONE!%N% Pagefile set to system-managed.
echo   %Y%Reboot recommended.%N%
echo.
pause
goto :virtual_memory_tools

:vmem_custom
call :show_header "[2.3] Custom Pagefile"
set "PAGE_DRIVE="
set /p "PAGE_DRIVE=  Drive letter %DG%(default C)%N%: "
if not defined PAGE_DRIVE set "PAGE_DRIVE=C"
set "PAGE_DRIVE=!PAGE_DRIVE::=!"
set "PAGE_DRIVE=!PAGE_DRIVE:~0,1!"
if not exist "!PAGE_DRIVE!:\" (
    echo.
    echo   %R%Drive not found:%N% %W%!PAGE_DRIVE!:%N%
    echo.
    pause
    goto :virtual_memory_tools
)
set "PAGE_INIT="
set /p "PAGE_INIT=  Initial size MB: "
echo(!PAGE_INIT!| findstr /r "^[1-9][0-9]*$" >nul || goto :vmem_bad_input
set "PAGE_MAX="
set /p "PAGE_MAX=  Maximum size MB: "
echo(!PAGE_MAX!| findstr /r "^[1-9][0-9]*$" >nul || goto :vmem_bad_input
set "VM_CONFIRM="
set /p "VM_CONFIRM=  Type SET to apply custom pagefile: "
if not "!VM_CONFIRM!"=="SET" goto :virtual_memory_tools
set "PAGEFILE_WMI=!PAGE_DRIVE!:\\pagefile.sys"
wmic computersystem where name="%COMPUTERNAME%" set AutomaticManagedPagefile=False >nul 2>&1
wmic pagefileset where name="!PAGEFILE_WMI!" delete >nul 2>&1
wmic pagefileset create name="!PAGEFILE_WMI!" >nul 2>&1
wmic pagefileset where name="!PAGEFILE_WMI!" set InitialSize=!PAGE_INIT!,MaximumSize=!PAGE_MAX! >nul 2>&1
echo.
echo   %G%✓ DONE!%N% Custom pagefile requested for !PAGE_DRIVE!:.
echo   %Y%Reboot required for the change to fully apply.%N%
echo.
pause
goto :virtual_memory_tools

:vmem_bad_input
echo.
echo   %R%Invalid size. Use numbers only.%N%
echo.
pause
goto :virtual_memory_tools

:: ============================================================
:: [3] NETWORK TOOLS
:: ============================================================
:flush_dns
call :show_header "[3] Network Tools"
echo   %G%[1]%N% Flush DNS only
echo   %G%[2]%N% Renew IP + full Winsock/TCP reset
echo   %G%[3]%N% Proxy settings (HTTP/SOCKS/WinHTTP)
echo   %G%[4]%N% Optimize network adapters
echo   %R%[Q]%N% Back
echo.
set "netchoice="
set /p "netchoice=  %C%➤%N% Select %W%[1-4/Q]%N%: "
if /i "!netchoice!"=="q" goto :main_menu
if "!netchoice!"=="1" goto :flush_dns_only
if "!netchoice!"=="2" goto :full_network_reset
if "!netchoice!"=="3" goto :proxy_tools
if "!netchoice!"=="4" goto :optimize_network_adapters
goto :flush_dns

:flush_dns_only
call :show_header "[3.1] Flush DNS"

echo   %G%[■]%N% Flushing DNS cache...
ipconfig /flushdns >nul 2>&1
echo       %DG%Done.%N%
echo.
echo   %G%✓ DONE!%N% DNS cache flushed.
echo.
pause
goto :flush_dns

:optimize_network_adapters
call :show_header "[3.4] Optimize Network Adapters"
echo   %Y%Configuring network adapters for low latency / VMs...%N%
powershell -NoProfile -Command "Get-NetAdapter | Set-NetAdapterAdvancedProperty -DisplayName 'Energy Efficient Ethernet' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue"
powershell -NoProfile -Command "Get-NetAdapter | Set-NetAdapterAdvancedProperty -DisplayName 'Green Ethernet' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue"
powershell -NoProfile -Command "Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.PhysicalAdapter } | ForEach-Object { reg add ('HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\' + $_.DeviceID.ToString().PadLeft(4,'0')) /v PnPCapabilities /t REG_DWORD /d 24 /f >nul 2>&1 }"
echo.
echo   %G%✓ DONE!%N% Network adapters optimized (Power Saving disabled).
echo.
pause
goto :flush_dns

:full_network_reset
call :show_header "[3.2] Full Network Reset"
echo   %Y%This can temporarily disconnect network/remote sessions.%N%
set "confirm="
set /p "confirm=  Type YES to continue: "
if /i not "!confirm!"=="YES" goto :flush_dns
echo.

echo   %G%[■]%N% Releasing/renewing IP...
ipconfig /release >nul 2>&1
ipconfig /renew >nul 2>&1
echo       %DG%Done.%N%

echo   %G%[■]%N% Resetting Winsock catalog...
netsh winsock reset >nul 2>&1
echo       %DG%Done.%N%

echo   %G%[■]%N% Resetting TCP/IP stack...
netsh int ip reset >nul 2>&1
echo       %DG%Done.%N%

echo   %G%[■]%N% Flushing ARP cache...
netsh interface ip delete arpcache >nul 2>&1
echo       %DG%Done.%N%

echo.
echo   %G%✓ DONE!%N% Network stack reset. %Y%Reboot recommended.%N%
echo.
pause
goto :flush_dns

:proxy_tools
call :show_header "[3.3] Proxy Settings"
echo   %G%[1]%N% Show current proxy
echo   %G%[2]%N% Set HTTP/HTTPS proxy
echo   %G%[3]%N% Set SOCKS proxy
echo   %G%[4]%N% Clear all proxy settings
echo   %G%[5]%N% Import user proxy to WinHTTP
echo   %G%[6]%N% Enable auto-detect proxy
echo   %G%[7]%N% Set PAC script URL
echo   %G%[8]%N% Open Windows proxy settings
echo   %G%[9]%N% Delete saved proxy credential
echo   %R%[Q]%N% Back
echo.
set "proxy_choice="
set /p "proxy_choice=  %C%➤%N% Select %W%[1-9/Q]%N%: "
if /i "!proxy_choice!"=="q" goto :flush_dns
if "!proxy_choice!"=="1" goto :proxy_show
if "!proxy_choice!"=="2" goto :proxy_set_http
if "!proxy_choice!"=="3" goto :proxy_set_socks
if "!proxy_choice!"=="4" goto :proxy_clear
if "!proxy_choice!"=="5" goto :proxy_import_winhttp
if "!proxy_choice!"=="6" goto :proxy_auto_detect
if "!proxy_choice!"=="7" goto :proxy_set_pac
if "!proxy_choice!"=="8" goto :proxy_open_settings
if "!proxy_choice!"=="9" goto :proxy_delete_creds
goto :proxy_tools

:proxy_show
call :show_header "[3.3] Current Proxy"
echo   %C%User proxy (WinINET):%N%
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable 2>nul
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer 2>nul
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyOverride 2>nul
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v AutoConfigURL 2>nul
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v AutoDetect 2>nul
echo.
echo   %C%WinHTTP proxy:%N%
netsh winhttp show proxy
echo.
pause
goto :proxy_tools

:proxy_set_http
call :show_header "[3.3] Set HTTP/HTTPS Proxy"
echo   %DG%Example:%N% %W%127.0.0.1:7890%N%  %DG%or%N%  %W%proxy.company.com:8080%N%
set "PROXY_ADDR="
set /p "PROXY_ADDR=  Proxy host:port: "
if not defined PROXY_ADDR goto :proxy_tools
set "PROXY_BYPASS="
set /p "PROXY_BYPASS=  Bypass list (default: localhost;127.*): "
if not defined PROXY_BYPASS set "PROXY_BYPASS=localhost;127.*"
set "PROXY_SERVER=http=!PROXY_ADDR!;https=!PROXY_ADDR!"
echo.
echo   %G%[■]%N% Setting user HTTP/HTTPS proxy...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /t REG_SZ /d "!PROXY_SERVER!" /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyOverride /t REG_SZ /d "!PROXY_BYPASS!" /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v AutoDetect /t REG_DWORD /d 0 /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v AutoConfigURL /f >nul 2>&1
echo   %G%[■]%N% Setting WinHTTP proxy...
netsh winhttp set proxy proxy-server="!PROXY_SERVER!" bypass-list="!PROXY_BYPASS!" >nul
for /f "tokens=1 delims=:" %%H in ("!PROXY_ADDR!") do set "PROXY_HOST=%%~H"
call :proxy_save_creds "!PROXY_HOST!" "!PROXY_ADDR!"
echo   %G%✓ DONE!%N% HTTP/HTTPS proxy enabled.
echo.
pause
goto :proxy_tools

:proxy_set_socks
call :show_header "[3.3] Set SOCKS Proxy"
echo   %DG%Example:%N% %W%127.0.0.1:1080%N%
echo   %Y%Note:%N% WinHTTP does not support SOCKS directly; this sets user WinINET proxy only.
set "SOCKS_ADDR="
set /p "SOCKS_ADDR=  SOCKS host:port: "
if not defined SOCKS_ADDR goto :proxy_tools
set "PROXY_BYPASS="
set /p "PROXY_BYPASS=  Bypass list (default: localhost;127.*): "
if not defined PROXY_BYPASS set "PROXY_BYPASS=localhost;127.*"
echo.
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /t REG_SZ /d "socks=!SOCKS_ADDR!" /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyOverride /t REG_SZ /d "!PROXY_BYPASS!" /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v AutoDetect /t REG_DWORD /d 0 /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v AutoConfigURL /f >nul 2>&1
for /f "tokens=1 delims=:" %%H in ("!SOCKS_ADDR!") do set "PROXY_HOST=%%~H"
call :proxy_save_creds "!PROXY_HOST!" "!SOCKS_ADDR!"
echo   %G%✓ DONE!%N% SOCKS proxy enabled for user apps.
echo.
pause
goto :proxy_tools

:proxy_clear
call :show_header "[3.3] Clear Proxy"
echo   %G%[■]%N% Clearing user proxy...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f >nul
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyOverride /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v AutoConfigURL /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v AutoDetect /t REG_DWORD /d 0 /f >nul 2>&1
echo   %G%[■]%N% Clearing WinHTTP proxy...
netsh winhttp reset proxy >nul
echo   %G%✓ DONE!%N% Proxy cleared.
echo.
pause
goto :proxy_tools

:proxy_import_winhttp
call :show_header "[3.3] Import Proxy to WinHTTP"
echo   %G%[■]%N% Importing current user proxy to WinHTTP...
netsh winhttp import proxy source=ie
echo.
pause
goto :proxy_tools

:proxy_auto_detect
call :show_header "[3.3] Auto-Detect Proxy"
echo   %G%[■]%N% Enabling automatic proxy detection...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f >nul
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyOverride /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v AutoConfigURL /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v AutoDetect /t REG_DWORD /d 1 /f >nul 2>&1
netsh winhttp reset proxy >nul
echo   %G%✓ DONE!%N% Auto-detect proxy enabled for user apps.
echo.
pause
goto :proxy_tools

:proxy_set_pac
call :show_header "[3.3] Set PAC Script"
echo   %DG%Example:%N% %W%http://127.0.0.1:7890/proxy.pac%N%
set "PAC_URL="
set /p "PAC_URL=  PAC script URL: "
if not defined PAC_URL goto :proxy_tools
echo.
echo   %G%[■]%N% Setting PAC script URL...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f >nul
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyOverride /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v AutoConfigURL /t REG_SZ /d "!PAC_URL!" /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v AutoDetect /t REG_DWORD /d 0 /f >nul 2>&1
netsh winhttp reset proxy >nul
echo   %G%✓ DONE!%N% PAC script configured for user apps.
echo.
pause
goto :proxy_tools

:proxy_open_settings
start "" ms-settings:network-proxy
goto :proxy_tools

:proxy_delete_creds
call :show_header "[3.3] Delete Proxy Credential"
echo   %DG%Enter the same proxy host:port used before.%N%
set "PROXY_CRED_INPUT="
set /p "PROXY_CRED_INPUT=  Proxy host:port: "
if not defined PROXY_CRED_INPUT goto :proxy_tools
for /f "tokens=1 delims=:" %%H in ("!PROXY_CRED_INPUT!") do set "PROXY_CRED_HOST=%%~H"
echo.
echo   %G%[■]%N% Removing saved credentials...
cmdkey /delete:!PROXY_CRED_HOST! >nul 2>&1
cmdkey /delete:!PROXY_CRED_INPUT! >nul 2>&1
cmdkey /delete:http://!PROXY_CRED_HOST! >nul 2>&1
cmdkey /delete:https://!PROXY_CRED_HOST! >nul 2>&1
cmdkey /delete:http://!PROXY_CRED_INPUT! >nul 2>&1
cmdkey /delete:https://!PROXY_CRED_INPUT! >nul 2>&1
echo   %G%✓ DONE!%N% Matching proxy credentials removed if they existed.
echo.
pause
goto :proxy_tools

:proxy_save_creds
set "PROXY_CRED_HOST=%~1"
set "PROXY_CRED_ADDR=%~2"
if not defined PROXY_CRED_HOST exit /b
echo.
echo   %Y%If this proxy needs login, save credentials now.%N%
echo   %DG%Leave blank or choose N if your app/browser asks separately.%N%
set "SAVE_PROXY_CREDS="
set /p "SAVE_PROXY_CREDS=  Save proxy username/password? [y/N]: "
if /i not "!SAVE_PROXY_CREDS!"=="y" exit /b
echo.
set "PROXY_CRED_HOST_ENV=!PROXY_CRED_HOST!"
set "PROXY_CRED_ADDR_ENV=!PROXY_CRED_ADDR!"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$hostName=$env:PROXY_CRED_HOST_ENV;$addr=$env:PROXY_CRED_ADDR_ENV;$user=Read-Host '  Proxy username';if([string]::IsNullOrWhiteSpace($user)){exit 0};$sec=Read-Host '  Proxy password' -AsSecureString;$b=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec);try{$pass=[Runtime.InteropServices.Marshal]::PtrToStringBSTR($b);$targets=@($hostName,$addr,'http://'+$hostName,'https://'+$hostName,'http://'+$addr,'https://'+$addr) | Where-Object {$_} | Select-Object -Unique;foreach($t in $targets){cmdkey.exe /generic:$t /user:$user /pass:$pass | Out-Null};Write-Host '  Credentials saved in Windows Credential Manager.'}finally{if($b -ne [IntPtr]::Zero){[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b)}}"
exit /b

:: ============================================================
:: [1] CLEANUP TOOLS
:: ============================================================
:disk_cleanup
:cleanup_tools
call :show_header "[1] Cleanup Tools"
echo   %G%[1]%N% Junk/cache cleanup
echo   %G%[2]%N% Browser cache cleanup
echo   %G%[3]%N% Windows Disk Cleanup
echo   %G%[4]%N% Find large files
echo   %G%[5]%N% Search installed apps
echo   %G%[6]%N% Uninstall classic app
echo   %G%[7]%N% Remove Microsoft Store/Appx app
echo   %G%[8]%N% Force delete file/folder
echo   %G%[9]%N% Delete file/folder on reboot
echo   %G%[A]%N% Kill process by image name
echo   %G%[B]%N% Deep leftover cleanup
echo   %G%[C]%N% Kill bloatware processes
echo   %G%[D]%N% All-in-one cleanup
echo   %G%[E]%N% Open Apps ^& Features
echo   %R%[Q]%N% Back
echo.
set "cleanchoice="
set /p "cleanchoice=  %C%➤%N% Select %W%[1-9/A-E/Q]%N%: "
if /i "!cleanchoice!"=="q" goto :main_menu
if "!cleanchoice!"=="1" goto :clean_junk
if "!cleanchoice!"=="2" goto :clean_browser
if "!cleanchoice!"=="3" goto :run_disk_cleanup
if "!cleanchoice!"=="4" goto :large_files
if "!cleanchoice!"=="5" goto :remover_search_apps
if "!cleanchoice!"=="6" goto :remover_uninstall_classic
if "!cleanchoice!"=="7" goto :remover_appx
if "!cleanchoice!"=="8" goto :remover_force_delete
if "!cleanchoice!"=="9" goto :remover_schedule_delete
if /i "!cleanchoice!"=="a" goto :remover_kill_process
if /i "!cleanchoice!"=="b" goto :remover_deep_leftovers
if /i "!cleanchoice!"=="c" goto :kill_bloat
if /i "!cleanchoice!"=="d" goto :all_in_one
if /i "!cleanchoice!"=="e" start "" ms-settings:appsfeatures
goto :cleanup_tools

:run_disk_cleanup
call :show_header "[1.3] Windows Disk Cleanup"

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

echo   %Y%⏳%N% Running cleanmgr (this may take a few minutes)...
cleanmgr /sagerun:100 >nul 2>&1

echo.
echo   %G%✓ DONE!%N% Disk Cleanup completed.
echo.
pause
goto :cleanup_tools

:: ============================================================
:: [5] DRIVER TOOLS / [6] DRIVE TOOLS
:: ============================================================
:driver_tools
call :show_header "[5] Driver Tools"
echo   %G%[1]%N% List installed driver packages
echo   %G%[2]%N% List devices and current drivers
echo   %G%[3]%N% Disable device by Instance ID
echo   %G%[4]%N% Enable device by Instance ID
echo   %G%[5]%N% Install/update driver from folder
echo   %G%[6]%N% Delete driver package
echo   %G%[7]%N% Open Device Manager
echo   %R%[Q]%N% Back
echo.
set "drvchoice="
set /p "drvchoice=  %C%➤%N% Select %W%[1-7/Q]%N%: "
if /i "!drvchoice!"=="q" goto :main_menu
if "!drvchoice!"=="1" goto :driver_list_packages
if "!drvchoice!"=="2" goto :driver_list_devices
if "!drvchoice!"=="3" goto :driver_disable_device
if "!drvchoice!"=="4" goto :driver_enable_device
if "!drvchoice!"=="5" goto :driver_install_folder
if "!drvchoice!"=="6" goto :driver_delete_package
if "!drvchoice!"=="7" start "" devmgmt.msc
goto :driver_tools

:driver_list_packages
call :show_header "[5.1] Driver Packages"
pnputil /enum-drivers
echo.
pause
goto :driver_tools

:driver_list_devices
call :show_header "[5.2] Devices + Drivers"
pnputil /enum-devices /drivers
echo.
pause
goto :driver_tools

:driver_disable_device
call :show_header "[5.3] Disable Device"
echo   %Y%Copy the Instance ID from the device list.%N%
set "DRV_INSTANCE="
set /p "DRV_INSTANCE=  Device Instance ID: "
if not defined DRV_INSTANCE goto :driver_tools
set "DRV_CONFIRM="
set /p "DRV_CONFIRM=  Type DISABLE to disable this device: "
if not "!DRV_CONFIRM!"=="DISABLE" goto :driver_tools
pnputil /disable-device "!DRV_INSTANCE!"
echo.
pause
goto :driver_tools

:driver_enable_device
call :show_header "[5.4] Enable Device"
set "DRV_INSTANCE="
set /p "DRV_INSTANCE=  Device Instance ID: "
if not defined DRV_INSTANCE goto :driver_tools
set "DRV_CONFIRM="
set /p "DRV_CONFIRM=  Type ENABLE to enable this device: "
if not "!DRV_CONFIRM!"=="ENABLE" goto :driver_tools
pnputil /enable-device "!DRV_INSTANCE!"
echo.
pause
goto :driver_tools

:driver_install_folder
call :show_header "[5.5] Install/Update Driver"
echo   %DG%Folder must contain .inf files. Subfolders are included.%N%
set "DRV_FOLDER="
set /p "DRV_FOLDER=  Driver folder path: "
if not defined DRV_FOLDER goto :driver_tools
if not exist "!DRV_FOLDER!" (
    echo.
    echo   %R%Folder not found:%N% %W%!DRV_FOLDER!%N%
    echo.
    pause
    goto :driver_tools
)
set "DRV_CONFIRM="
set /p "DRV_CONFIRM=  Type INSTALL to add/update drivers: "
if not "!DRV_CONFIRM!"=="INSTALL" goto :driver_tools
pnputil /add-driver "!DRV_FOLDER!\*.inf" /subdirs /install
echo.
pause
goto :driver_tools

:driver_delete_package
call :show_header "[5.6] Delete Driver Package"
echo   %Y%Use an OEM INF name from driver packages, for example oem42.inf.%N%
set "DRV_INF="
set /p "DRV_INF=  OEM INF name: "
if not defined DRV_INF goto :driver_tools
set "DRV_CONFIRM="
set /p "DRV_CONFIRM=  Type DELETE to uninstall and force delete package: "
if not "!DRV_CONFIRM!"=="DELETE" goto :driver_tools
pnputil /delete-driver "!DRV_INF!" /uninstall /force
echo.
pause
goto :driver_tools

:drive_tools
call :show_header "[6] Drive Tools"
echo   %G%[1]%N% Optimize drive (TRIM/Defrag)
echo   %G%[2]%N% Drive space summary
echo   %G%[3]%N% Disk health summary
echo   %G%[4]%N% CHKDSK scan
echo   %G%[5]%N% Open Disk Management
echo   %R%[Q]%N% Back
echo.
set "drivechoice="
set /p "drivechoice=  %C%➤%N% Select %W%[1-5/Q]%N%: "
if /i "!drivechoice!"=="q" goto :main_menu
if "!drivechoice!"=="1" goto :optimize_drive
if "!drivechoice!"=="2" goto :drive_space_summary
if "!drivechoice!"=="3" goto :drive_health_summary
if "!drivechoice!"=="4" goto :drive_chkdsk_scan
if "!drivechoice!"=="5" start "" diskmgmt.msc
goto :drive_tools

:optimize_drive
call :show_header "[6.1] Optimizing Drive"

echo   %G%[■]%N% Detecting drive type...
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
echo   %G%✓ DONE!%N% Drive optimized.
echo.
pause
goto :drive_tools

:drive_space_summary
call :show_header "[6.2] Drive Space"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | Select-Object DeviceID,VolumeName,@{Name='Size_GB';Expression={[math]::Round($_.Size/1GB,1)}},@{Name='Free_GB';Expression={[math]::Round($_.FreeSpace/1GB,1)}},@{Name='FreePct';Expression={[math]::Round(($_.FreeSpace/$_.Size)*100,1)}} | Format-Table -AutoSize"
echo.
pause
goto :drive_tools

:drive_health_summary
call :show_header "[6.3] Disk Health"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-PhysicalDisk -ErrorAction SilentlyContinue | Select-Object FriendlyName,MediaType,HealthStatus,OperationalStatus,@{Name='Size_GB';Expression={[math]::Round($_.Size/1GB,1)}} | Format-Table -AutoSize;Write-Host '';Get-CimInstance Win32_DiskDrive -ErrorAction SilentlyContinue | Select-Object Model,Status,InterfaceType,@{Name='Size_GB';Expression={[math]::Round($_.Size/1GB,1)}} | Format-Table -AutoSize"
echo.
pause
goto :drive_tools

:drive_chkdsk_scan
call :show_header "[6.4] CHKDSK Scan"
set "CHK_DRIVE="
set /p "CHK_DRIVE=  Drive letter %DG%(default C)%N%: "
if not defined CHK_DRIVE set "CHK_DRIVE=C"
set "CHK_DRIVE=!CHK_DRIVE::=!"
set "CHK_DRIVE=!CHK_DRIVE:~0,1!"
if not exist "!CHK_DRIVE!:\" (
    echo.
    echo   %R%Drive not found:%N% %W%!CHK_DRIVE!:%N%
    echo.
    pause
    goto :drive_tools
)
echo.
echo   %Y%Running read-only online scan for !CHK_DRIVE!: ...%N%
chkdsk !CHK_DRIVE!: /scan
echo.
pause
goto :drive_tools

:: ============================================================
:: [4] SYSTEM TOOLS
:: ============================================================
:system_tools
call :show_header "[4] System Tools"
echo   %G%[1]%N% System information
echo   %G%[2]%N% Startup manager
echo   %G%[3]%N% Shutdown timer
echo   %G%[4]%N% Fix common Windows issues
echo   %G%[5]%N% Restart Explorer
echo   %G%[6]%N% User profile manager
echo   %G%[7]%N% System identity/name
echo   %G%[8]%N% CPU settings (Turbo Boost)
echo   %G%[9]%N% Windows Update Manager
echo   %G%[A]%N% Open System Properties
echo   %R%[Q]%N% Back
echo.
set "syschoice="
set /p "syschoice=  %C%➤%N% Select %W%[1-9/A/Q]%N%: "
if /i "!syschoice!"=="q" goto :main_menu
if "!syschoice!"=="1" goto :sys_info
if "!syschoice!"=="2" goto :startup_mgr
if "!syschoice!"=="3" goto :auto_shutdown
if "!syschoice!"=="4" goto :fix_issues
if "!syschoice!"=="5" goto :restart_explorer
if "!syschoice!"=="6" goto :profile_manager
if "!syschoice!"=="7" goto :system_identity_tools
if "!syschoice!"=="8" goto :cpu_settings_menu
if "!syschoice!"=="9" goto :windows_update_manager
if /i "!syschoice!"=="a" start "" SystemPropertiesAdvanced.exe
goto :system_tools

:cpu_settings_menu
call :show_header "[4.8] CPU Settings (Turbo Boost)"
echo   %G%[1]%N% Enable CPU Turbo Boost (Maximum Performance)
echo   %G%[2]%N% Disable CPU Turbo Boost (Lower Temperature)
echo   %G%[3]%N% Set Minimum CPU State to 5%% (Allows downclocking when idle)
echo   %G%[4]%N% Set Minimum CPU State to 100%% (Constant high clock)
echo   %R%[Q]%N% Back
echo.
set "cpuchoice="
set /p "cpuchoice=  %C%➤%N% Select %W%[1-4/Q]%N%: "
if /i "!cpuchoice!"=="q" goto :system_tools
if "!cpuchoice!"=="1" (
    powercfg /SETACVALUEINDEX SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 be337238-0d82-4146-a960-4f3749d470c7 2 >nul 2>&1
    powercfg /SETACTIVE SCHEME_CURRENT >nul 2>&1
    echo.
    echo   %G%✓ DONE!%N% CPU Turbo Boost enabled (Aggressive).
)
if "!cpuchoice!"=="2" (
    powercfg /SETACVALUEINDEX SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 be337238-0d82-4146-a960-4f3749d470c7 0 >nul 2>&1
    powercfg /SETACTIVE SCHEME_CURRENT >nul 2>&1
    echo.
    echo   %G%✓ DONE!%N% CPU Turbo Boost disabled (Lower Temperature).
)
if "!cpuchoice!"=="3" (
    powercfg /SETACVALUEINDEX SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 5 >nul 2>&1
    powercfg /SETACTIVE SCHEME_CURRENT >nul 2>&1
    echo.
    echo   %G%✓ DONE!%N% Minimum CPU State set to 5%%.
)
if "!cpuchoice!"=="4" (
    powercfg /SETACVALUEINDEX SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 100 >nul 2>&1
    powercfg /SETACTIVE SCHEME_CURRENT >nul 2>&1
    echo.
    echo   %G%✓ DONE!%N% Minimum CPU State set to 100%%.
)
echo.
pause
goto :cpu_settings_menu

:windows_update_manager
call :show_header "[4.9] Windows Update Manager"
echo   %G%[1]%N% Disable Windows Update completely
echo   %G%[2]%N% Enable Windows Update (Default)
echo   %R%[Q]%N% Back
echo.
set "wuchoice="
set /p "wuchoice=  %C%➤%N% Select %W%[1-2/Q]%N%: "
if /i "!wuchoice!"=="q" goto :system_tools
if "!wuchoice!"=="1" (
    echo.
    echo   %Y%Disabling and stopping Windows Update services...%N%
    net stop wuauserv >nul 2>&1
    net stop bits >nul 2>&1
    net stop dosvc >nul 2>&1
    sc config wuauserv start= disabled >nul 2>&1
    sc config bits start= disabled >nul 2>&1
    sc config dosvc start= disabled >nul 2>&1
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f >nul 2>&1
    echo   %G%✓ DONE!%N% Windows Update has been disabled.
)
if "!wuchoice!"=="2" (
    echo.
    echo   %G%Enabling Windows Update services...%N%
    sc config wuauserv start= demand >nul 2>&1
    sc config bits start= demand >nul 2>&1
    sc config dosvc start= demand >nul 2>&1
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /f >nul 2>&1
    net start wuauserv >nul 2>&1
    net start bits >nul 2>&1
    echo   %G%✓ DONE!%N% Windows Update has been enabled.
)
echo.
pause
goto :windows_update_manager


:sys_info
call :show_header "[4.1] System Information"

set "OS_VER=Unknown"
for /f "tokens=4-5 delims=[]. " %%A in ('ver') do set "OS_VER=%%A.%%B"
set "CPU_NAME=Unknown"
for /f "tokens=2 delims==" %%C in ('wmic cpu get Name /value 2^>nul ^| findstr "Name"') do set "CPU_NAME=%%C"
set "GPU_NAME=Unknown"
for /f "tokens=2 delims==" %%G in ('wmic path win32_VideoController get Name /value 2^>nul ^| findstr "Name"') do set "GPU_NAME=%%G"
for /f "usebackq" %%M in (`powershell -NoProfile -Command "[Math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,1)"`) do set "TOTAL_RAM=%%M GB"
for /f "usebackq" %%M in (`powershell -NoProfile -Command "[Math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)"`) do set "FREE_RAM=%%M GB"
for /f "tokens=3" %%S in ('dir C:\ 2^>nul ^| findstr /i "bytes free"') do set "FREE_DISK=%%S bytes"
for /f "usebackq" %%U in (`powershell -NoProfile -Command "$u=(Get-Date)-(Get-CimInstance Win32_OperatingSystem).LastBootUpTime;'{0}d {1}h {2}m' -f $u.Days,$u.Hours,$u.Minutes"`) do set "UPTIME=%%U"
set "CPU_NAME=!CPU_NAME:~0,48!"
set "GPU_NAME=!GPU_NAME:~0,48!"

echo   %C%╔══════════════════════════════════════════════════════════════╗%N%
call :box_line 62 "Computer:   !COMPUTERNAME!" "%C%Computer:%N%   %W%!COMPUTERNAME!%N%"
call :box_line 62 "Windows:    !OS_VER!" "%C%Windows:%N%    %W%!OS_VER!%N%"
call :box_line 62 "CPU:        !CPU_NAME!" "%C%CPU:%N%        %W%!CPU_NAME!%N%"
call :box_line 62 "Total RAM:  !TOTAL_RAM!" "%C%Total RAM:%N%  %W%!TOTAL_RAM!%N%"
call :box_line 62 "Free RAM:   !FREE_RAM!" "%C%Free RAM:%N%   %G%!FREE_RAM!%N%"
call :box_line 62 "Free Disk:  !FREE_DISK!" "%C%Free Disk:%N%  %W%!FREE_DISK!%N%"
call :box_line 62 "GPU:        !GPU_NAME!" "%C%GPU:%N%        %W%!GPU_NAME!%N%"
call :box_line 62 "Uptime:     !UPTIME!" "%C%Uptime:%N%     %W%!UPTIME!%N%"
call :box_blank 62
for /f "tokens=2 delims=:" %%I in ('ipconfig ^| findstr /i "IPv4" ^| findstr /v "169.254"') do (
    set "IP_ADDR=%%I"
    set "IP_ADDR=!IP_ADDR:~1!"
    call :box_line 62 "IP:         !IP_ADDR!" "%C%IP:%N%         %W%!IP_ADDR!%N%"
)
echo   %C%╚══════════════════════════════════════════════════════════════╝%N%
echo.
pause
goto :system_tools

:profile_manager
call :show_header "[4.6] User Profile Manager"
echo   %G%[1]%N% List local profiles
echo   %G%[2]%N% Delete unloaded local profile
echo   %G%[3]%N% Open user accounts
echo   %R%[Q]%N% Back
echo.
set "profilechoice="
set /p "profilechoice=  %C%➤%N% Select %W%[1-3/Q]%N%: "
if /i "!profilechoice!"=="q" goto :system_tools
if "!profilechoice!"=="1" goto :profile_list
if "!profilechoice!"=="2" goto :profile_delete
if "!profilechoice!"=="3" start "" netplwiz
goto :profile_manager

:profile_list
call :show_header "[4.6] Local Profiles"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_UserProfile | Where-Object {-not $_.Special} | Sort-Object LocalPath | Select-Object LocalPath,Loaded,Status,@{Name='LastUse';Expression={$_.LastUseTime}} | Format-Table -AutoSize"
echo.
pause
goto :profile_manager

:profile_delete
call :show_header "[4.6] Delete Local Profile"
echo   %Y%Only unloaded non-system profiles are listed.%N%
powershell -NoProfile -ExecutionPolicy Bypass -Command "$profiles=@(Get-CimInstance Win32_UserProfile | Where-Object {-not $_.Special -and -not $_.Loaded -and $_.LocalPath -like '*\Users\*'} | Sort-Object LocalPath);if(!$profiles){Write-Host '  No removable unloaded profiles found.' -ForegroundColor Yellow;exit 0};for($i=0;$i -lt $profiles.Count;$i++){Write-Host ('  [{0}] {1}' -f ($i+1),$profiles[$i].LocalPath)};$n=Read-Host '  Select number';$tmp=0;if(-not [int]::TryParse($n,[ref]$tmp)){exit 1};$idx=$tmp-1;if($idx -lt 0 -or $idx -ge $profiles.Count){exit 1};$p=$profiles[$idx];$ok=Read-Host ('  Type DELETE to remove profile '+$p.LocalPath);if($ok -ne 'DELETE'){Write-Host '  Cancelled.';exit 0};try{$p.Delete();Write-Host ('  Deleted profile: '+$p.LocalPath) -ForegroundColor Green}catch{Write-Host ('  Failed: '+$_.Exception.Message) -ForegroundColor Yellow}"
echo.
pause
goto :profile_manager

:system_identity_tools
call :show_header "[4.7] System Identity"
echo   %C%Computer name:%N% %W%%COMPUTERNAME%%N%
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v RegisteredOwner 2>nul
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v RegisteredOrganization 2>nul
echo.
echo   %G%[1]%N% Set registered owner/organization
echo   %G%[2]%N% Rename computer
echo   %R%[Q]%N% Back
echo.
set "identchoice="
set /p "identchoice=  %C%➤%N% Select %W%[1-2/Q]%N%: "
if /i "!identchoice!"=="q" goto :system_tools
if "!identchoice!"=="1" goto :set_registered_identity
if "!identchoice!"=="2" goto :rename_computer_tool
goto :system_identity_tools

:set_registered_identity
set "REG_OWNER="
set /p "REG_OWNER=  Registered owner: "
set "REG_ORG="
set /p "REG_ORG=  Registered organization: "
if defined REG_OWNER reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v RegisteredOwner /t REG_SZ /d "!REG_OWNER!" /f >nul
if defined REG_ORG reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v RegisteredOrganization /t REG_SZ /d "!REG_ORG!" /f >nul
echo.
echo   %G%✓ DONE!%N% Registered identity updated.
echo.
pause
goto :system_identity_tools

:rename_computer_tool
set "NEW_PC_NAME="
set /p "NEW_PC_NAME=  New computer name: "
if not defined NEW_PC_NAME goto :system_identity_tools
set "RENAME_CONFIRM="
set /p "RENAME_CONFIRM=  Type RENAME to apply and require reboot: "
if not "!RENAME_CONFIRM!"=="RENAME" goto :system_identity_tools
set "NEW_PC_NAME_ENV=!NEW_PC_NAME!"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Rename-Computer -NewName $env:NEW_PC_NAME_ENV -Force"
echo.
echo   %G%✓ DONE!%N% Rename requested. %Y%Reboot required.%N%
echo.
pause
goto :system_identity_tools

:: ============================================================
:: [1.C] KILL BLOATWARE
:: ============================================================
:kill_bloat
call :show_header "[1.C] Killing Bloatware Processes"

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
        echo   %R%[X]%N% Killed: %W%%%P%N%
        set /a KILLED+=1
    )
)

if !KILLED! equ 0 (
    echo   %DG%No bloatware processes found running.%N%
) else (
    echo.
    echo   %G%Killed !KILLED! bloatware process(es).%N%
)

echo.
echo   %G%✓ DONE!%N%
echo.
pause
goto :cleanup_tools

:: ============================================================
:: [4.4] FIX COMMON ISSUES
:: ============================================================
:fix_issues
call :show_header "[4.4] Fix Common Windows Issues"
echo   %G%[A]%N% Repair system files (SFC)
echo   %G%[B]%N% Repair Windows image (DISM)
echo   %G%[C]%N% Reset Windows icon cache
echo   %G%[D]%N% Re-register Start Menu
echo   %G%[E]%N% Fix file associations
echo   %G%[F]%N% Clear print spooler
echo.
echo   %R%[Q]%N% Back to System Tools
echo.
set "fix="
set /p "fix=  %C%➤%N% Select %W%[A-F/Q]%N%: "
if /i "!fix!"=="q" goto :system_tools

if /i "!fix!"=="a" (
    echo.
    echo   %Y%⏳%N% Running System File Checker (may take 5-10 min)...
    sfc /scannow
    echo   %G%✓ Done.%N%
)
if /i "!fix!"=="b" (
    echo.
    echo   %Y%⏳%N% Running DISM Repair (may take 10-15 min)...
    dism /Online /Cleanup-Image /RestoreHealth
    echo   %G%✓ Done.%N%
)
if /i "!fix!"=="c" (
    echo.
    echo   %G%[■]%N% Resetting icon cache...
    taskkill /f /im explorer.exe >nul 2>&1
    del /f /q /a:h "%LOCALAPPDATA%\IconCache.db" >nul 2>&1
    del /f /q /s "%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache_*.db" >nul 2>&1
    start explorer.exe
    echo   %G%✓ Done.%N% Icons will refresh.
)
if /i "!fix!"=="d" (
    echo.
    echo   %Y%⏳%N% Re-registering Start Menu apps...
    powershell -NoProfile -Command "Get-AppXPackage -AllUsers | ForEach-Object { Add-AppxPackage -DisableDevelopmentMode -Register ($_.InstallLocation + '\AppXManifest.xml') -EA SilentlyContinue }" >nul 2>&1
    echo   %G%✓ Done.%N%
)
if /i "!fix!"=="e" (
    echo.
    echo   %G%[■]%N% Resetting file associations...
    dism /Online /Remove-DefaultAppAssociations >nul 2>&1
    echo   %G%✓ Done.%N% Default associations restored.
)
if /i "!fix!"=="f" (
    echo.
    echo   %G%[■]%N% Clearing print spooler...
    net stop spooler >nul 2>&1
    del /f /q "%SystemRoot%\System32\spool\PRINTERS\*" >nul 2>&1
    net start spooler >nul 2>&1
    echo   %G%✓ Done.%N%
)

echo.
pause
goto :fix_issues

:: ============================================================
:: [1.D] ALL-IN-ONE
:: ============================================================
:all_in_one
call :show_header "[1.D] ALL-IN-ONE Cleanup"

echo   %M%── Step 1/4 ──%N% Cleaning Junk Files
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
echo   %G%✓ Done.%N%

echo   %M%── Step 2/4 ──%N% Cleaning Browser Cache
for %%P in (chrome.exe msedge.exe brave.exe) do taskkill /f /im %%P >nul 2>&1
timeout /t 1 /nobreak >nul
call :clean_chromium_cache "Google Chrome" "%LOCALAPPDATA%\Google\Chrome\User Data"
call :clean_chromium_cache "Microsoft Edge" "%LOCALAPPDATA%\Microsoft\Edge\User Data"
call :clean_chromium_cache "Brave" "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data"

echo   %M%── Step 3/4 ──%N% Reclaiming RAM
if exist "%ProgramData%\PCL\trim_ram.exe" (
    "%ProgramData%\PCL\trim_ram.exe" >nul 2>&1
    goto :trim_done_2
)
set "TRIM_PS=%TEMP%\pcl_trim.ps1"
echo $ErrorActionPreference='SilentlyContinue' > "!TRIM_PS!"
echo Add-Type 'using System;using System.Runtime.InteropServices;public class WS{[DllImport("kernel32.dll")]public static extern bool SetProcessWorkingSetSize(IntPtr h,IntPtr min,IntPtr max);}' -EA SilentlyContinue >> "!TRIM_PS!"
echo $skip='LDPlayer^|dnplayer^|LdVBoxHeadless^|svchost^|System^|Idle^|csrss^|smss^|lsass^|explorer^|wininit^|winlogon^|services^|dwm^|fontdrvhost^|Memory Compression^|Registry' >> "!TRIM_PS!"
echo Get-Process ^| Where-Object {$_.ProcessName -notmatch $skip} ^| ForEach-Object { try{$h=$_.Handle;if($h){[void][WS]::SetProcessWorkingSetSize($h,[IntPtr]::new(-1),[IntPtr]::new(-1))}}catch{} } >> "!TRIM_PS!"
powershell -NoProfile -ExecutionPolicy Bypass -File "!TRIM_PS!" >nul 2>&1
del /f /q "!TRIM_PS!" >nul 2>&1
:trim_done_2
rundll32.exe advapi32.dll,ProcessIdleTasks >nul 2>&1
echo   %G%✓ Done.%N%

echo   %M%── Step 4/4 ──%N% Killing Bloatware + Flush DNS
for %%P in (
    SearchApp.exe RuntimeBroker.exe MicrosoftEdgeUpdate.exe
    MusNotification.exe YourPhone.exe GameBarPresenceWriter.exe
    CompatTelRunner.exe backgroundTaskHost.exe SecurityHealthSystray.exe
    OneDrive.exe TextInputHost.exe
) do taskkill /f /im %%P >nul 2>&1
ipconfig /flushdns >nul 2>&1
echo   %G%✓ Done.%N%

echo.
for /f "tokens=3" %%S in ('dir C:\ 2^>nul ^| findstr /i "bytes free"') do set "FREE=%%S"
echo   %C%╔══════════════════════════════════════════════════════════╗%N%
call :box_line 58 "✓ ALL-IN-ONE COMPLETE" "%G%✓ ALL-IN-ONE COMPLETE%N%"
call :box_line 58 "Free disk space: %FREE% bytes" "%DG%Free disk space:%N% %W%%FREE%%N% bytes"
echo   %C%╚══════════════════════════════════════════════════════════╝%N%
echo.
pause
goto :cleanup_tools

:remover_search_apps
call :show_header "[1.5] Search Installed Apps"
set "PCL_APP_QUERY="
set /p "PCL_APP_QUERY=  App keyword: "
if not defined PCL_APP_QUERY goto :cleanup_tools
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$kw=$env:PCL_APP_QUERY;$paths='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*','HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*';$apps=Get-ItemProperty $paths -ErrorAction SilentlyContinue ^| Where-Object {$_.DisplayName -and $_.DisplayName -like ('*'+$kw+'*')} ^| Sort-Object DisplayName ^| Select-Object DisplayName,DisplayVersion,Publisher,InstallLocation -First 40;if($apps){$apps ^| Format-Table -AutoSize}else{Write-Host '  No classic apps found.' -ForegroundColor Yellow};Write-Host '';Write-Host '  Appx/UWP matches:' -ForegroundColor Cyan;Get-AppxPackage -AllUsers ^| Where-Object {$_.Name -like ('*'+$kw+'*') -or $_.PackageFullName -like ('*'+$kw+'*')} ^| Select-Object Name,PackageFullName -First 40 ^| Format-Table -AutoSize"
echo.
pause
goto :cleanup_tools

:remover_uninstall_classic
call :show_header "[1.6] Uninstall Classic App"
echo   %Y%This runs the app's own uninstaller. Review the match carefully.%N%
set "PCL_APP_QUERY="
set /p "PCL_APP_QUERY=  App name keyword: "
if not defined PCL_APP_QUERY goto :cleanup_tools
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$kw=$env:PCL_APP_QUERY;$paths='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*','HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*';$apps=@(Get-ItemProperty $paths -ErrorAction SilentlyContinue ^| Where-Object {$_.DisplayName -and $_.DisplayName -like ('*'+$kw+'*')} ^| Sort-Object DisplayName ^| Select-Object -First 30);if(!$apps){Write-Host '  No matching app found.' -ForegroundColor Yellow;exit 0};for($i=0;$i -lt $apps.Count;$i++){Write-Host ('  [{0}] {1}  {2}' -f ($i+1),$apps[$i].DisplayName,$apps[$i].DisplayVersion)};$n=Read-Host '  Select number';$tmp=0;if(-not [int]::TryParse($n,[ref]$tmp)){exit 1};$idx=$tmp-1;if($idx -lt 0 -or $idx -ge $apps.Count){exit 1};$app=$apps[$idx];$cmd=$app.QuietUninstallString;if([string]::IsNullOrWhiteSpace($cmd)){$cmd=$app.UninstallString};if([string]::IsNullOrWhiteSpace($cmd)){Write-Host '  No uninstall command found.' -ForegroundColor Red;exit 1};$ok=Read-Host ('  Type UNINSTALL to remove '+$app.DisplayName);if($ok -ne 'UNINSTALL'){Write-Host '  Cancelled.';exit 0};Start-Process -FilePath 'cmd.exe' -ArgumentList '/c',$cmd -Wait"
echo.
pause
goto :cleanup_tools

:remover_appx
call :show_header "[1.7] Remove Store/Appx App"
echo   %Y%This removes installed Appx package and provisioned package if found.%N%
set "PCL_APP_QUERY="
set /p "PCL_APP_QUERY=  Appx name/package keyword: "
if not defined PCL_APP_QUERY goto :cleanup_tools
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$kw=$env:PCL_APP_QUERY;$pkgs=@(Get-AppxPackage -AllUsers ^| Where-Object {$_.Name -like ('*'+$kw+'*') -or $_.PackageFullName -like ('*'+$kw+'*')} ^| Sort-Object Name ^| Select-Object -First 30);if(!$pkgs){Write-Host '  No Appx package found.' -ForegroundColor Yellow;exit 0};for($i=0;$i -lt $pkgs.Count;$i++){Write-Host ('  [{0}] {1}' -f ($i+1),$pkgs[$i].PackageFullName)};$n=Read-Host '  Select number';$tmp=0;if(-not [int]::TryParse($n,[ref]$tmp)){exit 1};$idx=$tmp-1;if($idx -lt 0 -or $idx -ge $pkgs.Count){exit 1};$pkg=$pkgs[$idx];$ok=Read-Host ('  Type REMOVE to delete '+$pkg.Name);if($ok -ne 'REMOVE'){Write-Host '  Cancelled.';exit 0};Get-AppxPackage -AllUsers -Name $pkg.Name ^| ForEach-Object {try{Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction Stop;Write-Host ('  Removed: '+$_.PackageFullName)}catch{Write-Host ('  Failed: '+$_.PackageFullName+' - '+$_.Exception.Message) -ForegroundColor Yellow}};Get-AppxProvisionedPackage -Online ^| Where-Object {$_.DisplayName -eq $pkg.Name} ^| ForEach-Object {try{Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction Stop ^| Out-Null;Write-Host ('  Deprovisioned: '+$_.PackageName)}catch{Write-Host ('  Deprovision failed: '+$_.PackageName) -ForegroundColor Yellow}}"
echo.
pause
goto :cleanup_tools

:remover_force_delete
call :show_header "[1.8] Force Delete Path"
echo   %Y%Use this only for known leftovers. Root drives are blocked.%N%
set "DEL_TARGET="
set /p "DEL_TARGET=  File/folder full path: "
if not defined DEL_TARGET goto :cleanup_tools
for %%P in ("!DEL_TARGET!") do set "DEL_FULL=%%~fP"
if /i "!DEL_FULL!"=="%SystemDrive%\" goto :remover_blocked_path
if /i "!DEL_FULL!"=="%WINDIR%" goto :remover_blocked_path
if /i "!DEL_FULL!"=="%WINDIR%\" goto :remover_blocked_path
if not exist "!DEL_FULL!" (
    echo.
    echo   %R%Path not found:%N% %W%!DEL_FULL!%N%
    echo.
    pause
    goto :cleanup_tools
)
echo.
echo   %R%Target:%N% %W%!DEL_FULL!%N%
set "DEL_CONFIRM="
set /p "DEL_CONFIRM=  Type DELETE to force remove: "
if not "!DEL_CONFIRM!"=="DELETE" goto :cleanup_tools
echo.
echo   %G%[■]%N% Taking ownership and granting Administrators full access...
takeown /f "!DEL_FULL!" /r /d y >nul 2>&1
icacls "!DEL_FULL!" /grant Administrators:F /t /c >nul 2>&1
attrib -r -s -h "!DEL_FULL!" /s /d >nul 2>&1
echo   %G%[■]%N% Removing target...
if exist "!DEL_FULL!\*" (
    rmdir /s /q "!DEL_FULL!" >nul 2>&1
) else (
    del /f /q "!DEL_FULL!" >nul 2>&1
)
if exist "!DEL_FULL!" (
    echo   %Y%Still exists.%N% Try option [5] to delete on reboot.
) else (
    echo   %G%✓ DONE!%N% Target removed.
)
echo.
pause
goto :cleanup_tools

:remover_schedule_delete
call :show_header "[1.9] Delete On Reboot"
set "DEL_TARGET="
set /p "DEL_TARGET=  File/folder full path: "
if not defined DEL_TARGET goto :cleanup_tools
for %%P in ("!DEL_TARGET!") do set "DEL_FULL=%%~fP"
if /i "!DEL_FULL!"=="%SystemDrive%\" goto :remover_blocked_path
if /i "!DEL_FULL!"=="%WINDIR%" goto :remover_blocked_path
if /i "!DEL_FULL!"=="%WINDIR%\" goto :remover_blocked_path
echo.
echo   %R%Target:%N% %W%!DEL_FULL!%N%
set "DEL_CONFIRM="
set /p "DEL_CONFIRM=  Type DELETE to schedule removal after reboot: "
if not "!DEL_CONFIRM!"=="DELETE" goto :cleanup_tools
set "PCL_DELETE_TARGET=!DEL_FULL!"
set "PCL_DELETE_DIR=%ProgramData%\PreCoresPC"
if not exist "!PCL_DELETE_DIR!" mkdir "!PCL_DELETE_DIR!" >nul 2>&1
set "PCL_DELETE_SCRIPT=!PCL_DELETE_DIR!\force-delete-!RANDOM!!RANDOM!.cmd"
set "PCL_DELETE_SCRIPT_ENV=!PCL_DELETE_SCRIPT!"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$q=[char]34;$t=$env:PCL_DELETE_TARGET;$s=$env:PCL_DELETE_SCRIPT_ENV;$lines=@('@echo off','takeown /f '+$q+$t+$q+' /r /d y >nul 2>&1','icacls '+$q+$t+$q+' /grant Administrators:F /t /c >nul 2>&1','attrib -r -s -h '+$q+$t+$q+' /s /d >nul 2>&1','if exist '+$q+$t+'\*'+$q+' (rmdir /s /q '+$q+$t+$q+') else (del /f /q '+$q+$t+$q+')','del /f /q '+$q+'%%~f0'+$q+' >nul 2>&1');Set-Content -LiteralPath $s -Value $lines -Encoding ASCII"
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v "PreCoresForceDelete" /t REG_SZ /d "!PCL_DELETE_SCRIPT!" /f >nul
echo.
echo   %G%✓ DONE!%N% Delete scheduled. Reboot required.
echo.
pause
goto :cleanup_tools

:remover_kill_process
call :show_header "[1.A] Kill Process"
set "PROC_NAME="
set /p "PROC_NAME=  Process image name (example app.exe): "
if not defined PROC_NAME goto :cleanup_tools
echo.
tasklist /fi "imagename eq !PROC_NAME!"
echo.
set "KILL_CONFIRM="
set /p "KILL_CONFIRM=  Type KILL to terminate: "
if not "!KILL_CONFIRM!"=="KILL" goto :cleanup_tools
taskkill /f /im "!PROC_NAME!" /t
echo.
pause
goto :cleanup_tools

:remover_deep_leftovers
call :show_header "[1.B] Deep Leftover Cleanup"
echo   %Y%Scans AppData, ProgramData, Program Files, Desktop and Start Menu.%N%
echo   %Y%Keyword must be at least 3 characters.%N%
set "PCL_CLEAN_QUERY="
set /p "PCL_CLEAN_QUERY=  Leftover keyword/app name: "
if not defined PCL_CLEAN_QUERY goto :cleanup_tools
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$q=[char]34;$kw=$env:PCL_CLEAN_QUERY;if($kw.Length -lt 3){Write-Host '  Keyword too short.' -ForegroundColor Red;exit 1};$roots=@($env:ProgramData,$env:LOCALAPPDATA,$env:APPDATA,$env:ProgramFiles,${env:ProgramFiles(x86)},(Join-Path $env:USERPROFILE 'Desktop'),(Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu'),(Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu')) ^| Where-Object {$_ -and (Test-Path -LiteralPath $_)} ^| Select-Object -Unique;$items=@();foreach($r in $roots){$items += Get-ChildItem -LiteralPath $r -Force -Recurse -ErrorAction SilentlyContinue ^| Where-Object {$_.Name -like ('*'+$kw+'*')}};$items=$items ^| Sort-Object FullName -Unique ^| Select-Object -First 80;if(!$items){Write-Host '  No leftovers found.' -ForegroundColor Yellow;exit 0};$items ^| ForEach-Object {Write-Host ('  '+$_.FullName)};Write-Host '';Write-Host ('  Total listed: '+$items.Count) -ForegroundColor Cyan;$ok=Read-Host '  Type CLEAN to remove all listed items';if($ok -ne 'CLEAN'){Write-Host '  Cancelled.';exit 0};foreach($it in $items){try{cmd /c ('takeown /f '+$q+$it.FullName+$q+' /r /d y >nul 2>&1') ^| Out-Null;cmd /c ('icacls '+$q+$it.FullName+$q+' /grant Administrators:F /t /c >nul 2>&1') ^| Out-Null;Remove-Item -LiteralPath $it.FullName -Recurse -Force -ErrorAction Stop;Write-Host ('  removed: '+$it.FullName)}catch{Write-Host ('  failed: '+$it.FullName) -ForegroundColor Yellow}}"
echo.
pause
goto :cleanup_tools

:remover_blocked_path
echo.
echo   %R%Blocked critical path:%N% %W%!DEL_FULL!%N%
echo   %DG%Root drives and the Windows directory itself cannot be deleted here.%N%
echo.
pause
goto :cleanup_tools

:quit
cls
echo.
echo.
echo   %C%╔══════════════════════════════════════════════════════════════╗%N%
call :box_line 62 "" ""
call :box_line 62 "    Thank you for using PreCores PC." "    %W%Thank you for using PreCores PC.%N%"
call :box_line 62 "    PreCore Lab 2026" "    %DG%PreCore Lab 2026%N%"
call :box_line 62 "" ""
echo   %C%╚══════════════════════════════════════════════════════════════╝%N%
echo.
ping -n 2 127.0.0.1 >nul
endlocal
exit 0

:: ============================================================
:: [4.2] STARTUP MANAGER
:: ============================================================
:startup_mgr
call :show_header "[4.2] Startup Manager"
echo   %DG%── HKCU Run (Current User) ──%N%
set "CNT=0"
for /f "tokens=1,2,*" %%A in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" 2^>nul ^| findstr /i "REG_SZ REG_EXPAND_SZ"') do (
    set /a CNT+=1
    echo   %G%!CNT!.%N% %W%%%A%N%
    echo      %DG%%%C%N%
)
echo.
echo   %DG%── HKLM Run (All Users) ──%N%
for /f "tokens=1,2,*" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" 2^>nul ^| findstr /i "REG_SZ REG_EXPAND_SZ"') do (
    set /a CNT+=1
    echo   %G%!CNT!.%N% %W%%%A%N%
    echo      %DG%%%C%N%
)
echo.
echo   %DG%── Startup Folder ──%N%
if exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup" (
    for %%F in ("%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\*") do (
        set /a CNT+=1
        echo   %G%!CNT!.%N% %W%%%~nxF%N%
    )
)
if !CNT! equ 0 echo   %DG%(no startup items found)%N%
echo.
echo   %C%Total:%N% %W%!CNT!%N% startup item(s)
echo.
echo   %G%[D]%N% Delete a startup entry by name
echo   %R%[Q]%N% Back to System Tools
echo.
set "schoice="
set /p "schoice=  %C%➤%N% Select %W%[D/Q]%N%: "
if /i "!schoice!"=="q" goto :system_tools
if /i "!schoice!"=="d" (
    set "sname="
    set /p "sname=  Enter value name to delete: "
    if defined sname (
        reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "!sname!" /f >nul 2>&1
        reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "!sname!" /f >nul 2>&1
        echo   %R%Deleted:%N% %W%!sname!%N%
    )
)
echo.
pause
goto :startup_mgr

:: ============================================================
:: [1.4] FIND LARGE FILES
:: ============================================================
:large_files
call :show_header "[1.4] Find Large Files"
set "SCAN_DRIVE="
set /p "SCAN_DRIVE=  Drive to scan %DG%(default C)%N%: "
if not defined SCAN_DRIVE set "SCAN_DRIVE=C"
set "SCAN_DRIVE=!SCAN_DRIVE::=!"
set "SCAN_DRIVE=!SCAN_DRIVE:~0,1!"
set "SCAN_ROOT=!SCAN_DRIVE!:\"
if not exist "!SCAN_ROOT!" (
    echo.
    echo   %R%Drive not found:%N% %W%!SCAN_ROOT!%N%
    echo.
    pause
    goto :cleanup_tools
)
echo.
echo   %Y%⏳%N% Scanning !SCAN_ROOT! ... this can take 1-3 minutes on large disks.
echo   %DG%Tip: run as Administrator for fewer access-denied skips.%N%
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='SilentlyContinue';$root='%SCAN_ROOT%';$files=Get-ChildItem -LiteralPath $root -Recurse -File -Force -ErrorAction SilentlyContinue | Sort-Object Length -Descending | Select-Object -First 20;if(-not $files){Write-Host '  No files found or access was denied.' -ForegroundColor Yellow;exit 0};$files | ForEach-Object {$sz=if($_.Length -ge 1GB){'{0:N1} GB' -f ($_.Length/1GB)}elseif($_.Length -ge 1MB){'{0:N1} MB' -f ($_.Length/1MB)}else{'{0:N0} KB' -f ($_.Length/1KB)};'  {0,10}  {1}' -f $sz,$_.FullName}"
if errorlevel 1 (
    echo.
    echo   %R%Large file scan failed.%N% PowerShell returned errorlevel !errorlevel!.
)
echo.
pause
goto :cleanup_tools

:: ============================================================
:: [4.3] AUTO SHUTDOWN TIMER
:: ============================================================
:auto_shutdown
cls
echo.
echo   %C%╔══════════════════════════════════════════════════════════════╗%N%
call :box_line 62 "»» [4.3] Auto Shutdown Timer" "%Y%»»%N% %W%[4.3] Auto Shutdown Timer%N%"
echo   %C%╠══════════════════════════════════════════════════════════════╣%N%
call :box_line 62 "" ""
call :box_line 62 "[1] Shutdown in 30 minutes" "%G%[1]%N% Shutdown in 30 minutes"
call :box_line 62 "[2] Shutdown in 1 hour" "%G%[2]%N% Shutdown in 1 hour"
call :box_line 62 "[3] Shutdown in 2 hours" "%G%[3]%N% Shutdown in 2 hours"
call :box_line 62 "[4] Shutdown in 4 hours" "%G%[4]%N% Shutdown in 4 hours"
call :box_line 62 "[5] Custom minutes" "%G%[5]%N% Custom minutes"
call :box_line 62 "[6] Cancel scheduled shutdown" "%R%[6]%N% Cancel scheduled shutdown"
call :box_line 62 "" ""
call :box_line 62 "[Q] Back" "%R%[Q]%N% Back"
call :box_line 62 "" ""
echo   %C%╚══════════════════════════════════════════════════════════════╝%N%
echo.
set "stimer="
set /p "stimer=  %C%➤%N% Select %W%[1-6/Q]%N%: "
if /i "!stimer!"=="q" goto :system_tools
if "!stimer!"=="1" (shutdown /s /t 1800 & echo   %G%✓%N% Shutdown scheduled in 30 minutes.)
if "!stimer!"=="2" (shutdown /s /t 3600 & echo   %G%✓%N% Shutdown scheduled in 1 hour.)
if "!stimer!"=="3" (shutdown /s /t 7200 & echo   %G%✓%N% Shutdown scheduled in 2 hours.)
if "!stimer!"=="4" (shutdown /s /t 14400 & echo   %G%✓%N% Shutdown scheduled in 4 hours.)
if "!stimer!"=="5" (
    set "mins="
    set /p "mins=  Enter minutes: "
    echo(!mins!| findstr /r "^[1-9][0-9]*$" >nul
    if errorlevel 1 (
        echo   %R%Invalid minutes.%N%
    ) else (
        set /a secs=!mins!*60
        shutdown /s /t !secs!
        echo   %G%✓%N% Shutdown scheduled in !mins! minutes.
    )
)
if "!stimer!"=="6" (
    shutdown /a >nul 2>&1
    echo   %Y%Scheduled shutdown CANCELLED.%N%
)
if not defined stimer goto :auto_shutdown
echo.
pause
goto :system_tools

:: ============================================================
:: [7] EMULATOR / VM TOOLS
:: ============================================================
:ldplayer_tools
cls
echo.
echo   %C%╔══════════════════════════════════════════════════════════════╗%N%
call :box_line 62 "»» [7] Emulator / VM Tools" "%Y%»»%N% %W%[7] Emulator / VM Tools%N%"
echo   %C%╠══════════════════════════════════════════════════════════════╣%N%
call :box_line 62 "" ""

:: Count running instances
set "LD_CNT=0"
for /f %%N in ('tasklist /fi "IMAGENAME eq dnplayer.exe" 2^>nul ^| find /c "dnplayer"') do set "LD_CNT=%%N"
set "VMW_CNT=0"
for /f %%N in ('tasklist /fi "IMAGENAME eq vmware-vmx.exe" 2^>nul ^| find /c "vmware-vmx"') do set "VMW_CNT=%%N"
call :box_line 62 "LDPlayer: !LD_CNT! running   VMware VMs: !VMW_CNT! running" "%DG%LDPlayer:%N% %W%!LD_CNT! running%N%   %DG%VMware VMs:%N% %W%!VMW_CNT! running%N%"
call :box_line 62 "" ""
call :box_line 62 "[1] Kill all LDPlayer instances" "%G%[1]%N% Kill all LDPlayer instances"
call :box_line 62 "[2] Clear LDPlayer/VMware temp" "%G%[2]%N% Clear LDPlayer/VMware temp"
call :box_line 62 "[3] Show emulator/VM disk usage" "%G%[3]%N% Show emulator/VM disk usage"
call :box_line 62 "[4] Boost running emulator priority" "%G%[4]%N% Boost running emulator priority"
call :box_line 62 "[5] Optimize host power/GPU/USB" "%G%[5]%N% Optimize host power/GPU/USB"
call :box_line 62 "[6] Disable Hyper-V/VBS for native mode" "%Y%[6]%N% Disable Hyper-V/VBS for native mode"
call :box_line 62 "[7] Set permanent emulator priority" "%G%[7]%N% Set permanent emulator priority"
call :box_line 62 "[8] Add defender exceptions for emulators" "%G%[8]%N% Add defender exceptions for emulators"
call :box_line 62 "[9] Compact VMware virtual disks (.vmdk)" "%G%[9]%N% Compact VMware virtual disks (.vmdk)"
call :box_line 62 "[Q] Back" "%R%[Q]%N% Back"
call :box_line 62 "" ""
echo   %C%╚══════════════════════════════════════════════════════════════╝%N%
echo.
set "ldchoice="
set /p "ldchoice=  %C%➤%N% Select %W%[1-9/Q]%N%: "
if /i "!ldchoice!"=="q" goto :main_menu
if "!ldchoice!"=="1" (
    echo.
    echo   %G%[■]%N% Killing all LDPlayer processes...
    taskkill /f /im dnplayer.exe >nul 2>&1
    taskkill /f /im LdVBoxHeadless.exe >nul 2>&1
    taskkill /f /im LDPlayer.exe >nul 2>&1
    taskkill /f /im dnconsole.exe >nul 2>&1
    taskkill /f /im dnmultiplayer.exe >nul 2>&1
    echo   %G%✓%N% All LDPlayer instances killed.
)
if "!ldchoice!"=="2" (
    echo.
    echo   %G%[■]%N% Clearing LDPlayer cache...
    set "LD_DIR=%LOCALAPPDATA%\LDPlayer\LDPlayer9"
    if exist "!LD_DIR!" (
        for /d %%V in ("!LD_DIR!\vms\*") do (
            if exist "%%V\temp" rmdir /s /q "%%V\temp" >nul 2>&1
            if exist "%%V\cache" rmdir /s /q "%%V\cache" >nul 2>&1
        )
        echo   %G%✓%N% Cache cleared.
    ) else (
        echo   %Y%LDPlayer directory not found.%N%
    )
    echo   %G%[■]%N% Clearing VMware temp/log cache...
    for /d %%D in ("%TEMP%\vmware-*") do rmdir /s /q "%%D" >nul 2>&1
    for /d %%D in ("%LOCALAPPDATA%\Temp\vmware-*") do rmdir /s /q "%%D" >nul 2>&1
    if exist "%APPDATA%\VMware\logs" del /f /q "%APPDATA%\VMware\logs\*" >nul 2>&1
    echo   %G%✓%N% Temp/cache cleanup finished.
)
if "!ldchoice!"=="3" (
    echo.
    echo   %G%[■]%N% Scanning emulator/VM disk usage...
    set "LD_DIR=%LOCALAPPDATA%\LDPlayer"
    if exist "!LD_DIR!" (
        for /f "tokens=3" %%S in ('dir /s "!LD_DIR!" 2^>nul ^| findstr "File(s)"') do echo   %C%LDPlayer total:%N% %W%%%S bytes%N%
    ) else (
        set "LD_DIR=%ProgramFiles%\LDPlayer"
        if exist "!LD_DIR!" (
            for /f "tokens=3" %%S in ('dir /s "!LD_DIR!" 2^>nul ^| findstr "File(s)"') do echo   %C%LDPlayer total:%N% %W%%%S bytes%N%
        ) else (
            echo   %Y%LDPlayer not found.%N%
        )
    )
    if exist "%USERPROFILE%\Documents\Virtual Machines" (
        for /f "tokens=3" %%S in ('dir /s "%USERPROFILE%\Documents\Virtual Machines" 2^>nul ^| findstr "File(s)"') do echo   %C%VMware VMs:%N%    %W%%%S bytes%N%
    ) else (
        echo   %DG%VMware VM folder not found in Documents.%N%
    )
)
if "!ldchoice!"=="4" goto :boost_emulators
if "!ldchoice!"=="5" goto :optimize_vm_host
if "!ldchoice!"=="6" goto :disable_hyperv_vbs
if "!ldchoice!"=="7" goto :set_permanent_priority
if "!ldchoice!"=="8" goto :add_defender_exclusions
if "!ldchoice!"=="9" goto :compact_vmdk_tool
echo.
pause
goto :ldplayer_tools

:boost_emulators
call :show_header "[7.4] Boost Running Emulators"
echo   %G%[■]%N% Setting LDPlayer/VMware processes to Above Normal...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$names='dnplayer','LDPlayer','LdVBoxHeadless','dnconsole','vmware','vmware-vmx';$count=0;Get-Process -ErrorAction SilentlyContinue | Where-Object {$names -contains $_.ProcessName} | ForEach-Object {try{$_.PriorityClass='AboveNormal';$count++;Write-Host ('  boosted: '+$_.ProcessName+' ['+$_.Id+']')}catch{}};Write-Host ('  total boosted: '+$count)"
echo.
echo   %G%✓ DONE!%N% Current emulator/VM processes boosted.
echo.
pause
goto :ldplayer_tools

:optimize_vm_host
call :show_header "[7.5] Host Performance Optimize"
echo   %G%[■]%N% Enabling Ultimate/High Performance power plan...
powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1
set "_ULTIMATE_SET=0"
for /f "tokens=4" %%G in ('powercfg /list 2^>nul ^| findstr /i "Ultimate"') do (
    powercfg /setactive %%G >nul 2>&1
    set "_ULTIMATE_SET=1"
)
if "!_ULTIMATE_SET!"=="0" powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
powercfg /change standby-timeout-ac 0 >nul 2>&1
powercfg /change hibernate-timeout-ac 0 >nul 2>&1
powercfg /change disk-timeout-ac 0 >nul 2>&1
powercfg /SETACVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul 2>&1
powercfg /SETACVALUEINDEX SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0 >nul 2>&1
powercfg /SETACTIVE SCHEME_CURRENT >nul 2>&1
echo       %DG%Power plan optimized.%N%

echo   %G%[■]%N% Enabling GPU scheduling / VM latency registry hints...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 6 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v GlobalTimerResolutionRequests /t REG_DWORD /d 1 /f >nul 2>&1
echo       %DG%GPU/latency hints applied.%N%

echo.
echo   %G%✓ DONE!%N% Host optimized. %Y%Reboot recommended for GPU changes.%N%
echo.
pause
goto :ldplayer_tools

:disable_hyperv_vbs
call :show_header "[7.6] Hyper-V / VBS Native Mode"
echo   %Y%This improves native LDPlayer/VMware performance on many systems,%N%
echo   %Y%but can break WSL2, Hyper-V VMs, Windows Sandbox, and VBS features.%N%
echo.
bcdedit /enum "{current}" | findstr /i "hypervisorlaunchtype"
echo.
set "confirm="
set /p "confirm=  Type YES to disable Hyper-V/VBS and require reboot: "
if /i not "!confirm!"=="YES" goto :ldplayer_tools
echo.
echo   %G%[■]%N% Disabling boot hypervisor and VBS...
bcdedit /set hypervisorlaunchtype off >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
for %%F in (Microsoft-Hyper-V-All VirtualMachinePlatform HypervisorPlatform) do (
    dism /Online /Disable-Feature /FeatureName:%%F /NoRestart >nul 2>&1
)
echo.
echo   %G%✓ DONE!%N% Hyper-V/VBS disable requested. %Y%Reboot required.%N%
echo.
pause
goto :ldplayer_tools

:set_permanent_priority
call :show_header "[7.7] Permanent Priority Setup"
echo   %Y%This configures Windows registry to automatically run%N%
echo   %Y%LDPlayer and VMware at Above Normal priority.%N%
echo.
echo   %G%[1]%N% Enable permanent Above Normal CPU priority
echo   %G%[2]%N% Disable permanent CPU priority (Restore default)
echo   %R%[Q]%N% Back
echo.
set "prichoice="
set /p "prichoice=  %C%➤%N% Select %W%[1-2/Q]%N%: "
if /i "!prichoice!"=="q" goto :ldplayer_tools
if "!prichoice!"=="1" (
    echo.
    echo   %G%[■]%N% Setting Registry PerfOptions...
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\dnplayer.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\LdVBoxHeadless.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\vmware-vmx.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 6 /f >nul 2>&1
    echo   %G%✓ DONE!%N% Permanent CPU priority configured.
)
if "!prichoice!"=="2" (
    echo.
    echo   %G%[■]%N% Removing Registry PerfOptions...
    reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\dnplayer.exe\PerfOptions" /v CpuPriorityClass /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\LdVBoxHeadless.exe\PerfOptions" /v CpuPriorityClass /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\vmware-vmx.exe\PerfOptions" /v CpuPriorityClass /f >nul 2>&1
    echo   %G%✓ DONE!%N% CPU priority restored to default.
)
echo.
pause
goto :set_permanent_priority

:add_defender_exclusions
call :show_header "[7.8] Antivirus Exclusions"
echo   %Y%Adding emulator paths to Windows Defender exclusion list%N%
echo   %Y%to reduce background scanning overhead and CPU usage...%N%
echo.
powershell -NoProfile -Command "Add-MpPreference -ExclusionPath '$env:LOCALAPPDATA\LDPlayer', '$env:ProgramFiles\LDPlayer', '$env:USERPROFILE\Documents\Virtual Machines' -ErrorAction SilentlyContinue"
echo   %G%✓ DONE!%N% Exclusions added:
echo     - %W%%LOCALAPPDATA%\LDPlayer%N%
echo     - %W%%ProgramFiles%\LDPlayer%N%
echo     - %W%%USERPROFILE%\Documents\Virtual Machines%N%
echo.
pause
goto :ldplayer_tools

:compact_vmdk_tool
call :show_header "[7.9] Compact VMware Virtual Disks"
if not exist "!ProgramFiles(x86)!\VMware\VMware Workstation\vmware-vdiskmanager.exe" (
    echo   %R%Error:%N% VMware Workstation is not installed at the default path.
    echo          Could not locate vmware-vdiskmanager.exe.
    echo.
    pause
    goto :ldplayer_tools
)
echo   %Y%This utility will compact the specified .vmdk file%N%
echo   %Y%to reclaim unused disk space on the host SSD/HDD.%N%
echo.
echo   - Enter full path to the .vmdk file:
echo     %DG%(e.g. C:\Users\Admin\Documents\Virtual Machines\Win10\Win10.vmdk)%N%
set /p "vmdk_path=  ➤ "
if not defined vmdk_path goto :ldplayer_tools
if not exist "!vmdk_path!" (
    echo.
    echo   %R%Error:%N% File not found: %W%!vmdk_path!%N%
    echo.
    pause
    goto :compact_vmdk_tool
)
echo.
echo   %G%⏳%N% Compacting virtual disk (this may take a few minutes)...
"!ProgramFiles(x86)!\VMware\VMware Workstation\vmware-vdiskmanager.exe" -k "!vmdk_path!"
echo.
echo   %G%✓ DONE!%N% Virtual disk compaction complete.
echo.
pause
goto :ldplayer_tools


:: ============================================================
:: [4.5] RESTART EXPLORER
:: ============================================================
:restart_explorer
echo.
echo   %G%[■]%N% Restarting Explorer...
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul
start explorer.exe
echo   %G%✓%N% Explorer restarted.
timeout /t 1 /nobreak >nul
goto :system_tools

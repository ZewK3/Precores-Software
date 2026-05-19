@echo off
:: ============================================================
:: RunAll.bat - Wrapper to run both scripts sequentially
:: Called by FirstLogonCommands (autounattend.xml)
:: Each script runs in its own isolated cmd /c process
:: ============================================================
echo.
echo  =============================================
echo   PCL Auto Setup - Starting...
echo  =============================================
echo.

cd /d "C:\InstallScripts"

if exist "QuickOptimize.bat" (
    echo [1/2] Running QuickOptimize.bat...
    cmd /c "C:\InstallScripts\QuickOptimize.bat"
    echo [1/2] QuickOptimize.bat finished. Exit code: %errorlevel%
) else (
    echo [1/2] QuickOptimize.bat not found - skipping
)

echo.

if exist "QuickInstall.bat" (
    echo [2/2] Running QuickInstall.bat...
    cmd /c "C:\InstallScripts\QuickInstall.bat"
    echo [2/2] QuickInstall.bat finished. Exit code: %errorlevel%
) else (
    echo [2/2] QuickInstall.bat not found - skipping
)

echo.
echo  =============================================
echo   PCL Auto Setup - ALL DONE!
echo  =============================================
echo.
timeout /t 5 /nobreak >nul

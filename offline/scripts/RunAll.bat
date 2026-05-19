@echo off
:: ============================================================
::  RunAll.bat - Master wrapper for post-install scripts
::  Called by autounattend.xml FirstLogonCommands
::  Runs QuickOptimize first, then QuickInstall
:: ============================================================
title RunAll - Post-Install Setup
color 0A
setlocal EnableExtensions

echo.
echo  =============================================
echo   RunAll - Running Post-Install Scripts
echo  =============================================
echo   1. QuickOptimize.bat (system tweaks)
echo   2. QuickInstall.bat  (software install)
echo  =============================================
echo.

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: ---- Step 1: Run QuickOptimize ----
if exist "%SCRIPT_DIR%\QuickOptimize.bat" (
    echo [1/2] Running QuickOptimize.bat...
    call "%SCRIPT_DIR%\QuickOptimize.bat"
    echo [1/2] QuickOptimize.bat finished.
) else (
    echo [1/2] WARNING: QuickOptimize.bat not found at %SCRIPT_DIR%
)

echo.

:: ---- Step 2: Run QuickInstall ----
if exist "%SCRIPT_DIR%\QuickInstall.bat" (
    echo [2/2] Running QuickInstall.bat...
    call "%SCRIPT_DIR%\QuickInstall.bat"
    echo [2/2] QuickInstall.bat finished.
) else (
    echo [2/2] WARNING: QuickInstall.bat not found at %SCRIPT_DIR%
)

echo.
echo  =============================================
echo   RunAll - All scripts completed!
echo   %DATE% %TIME%
echo  =============================================
echo.

:: ---- Cleanup: Remove install scripts folder ----
:: Wait a moment to ensure all file handles are released
timeout /t 5 /nobreak >nul

endlocal

:: Self-cleanup: remove the entire InstallScripts folder
set "CLEANUP_DIR=%~dp0"
if "%CLEANUP_DIR:~-1%"=="\" set "CLEANUP_DIR=%CLEANUP_DIR:~0,-1%"
(goto) 2>nul & rmdir /s /q "%CLEANUP_DIR%" >nul 2>&1

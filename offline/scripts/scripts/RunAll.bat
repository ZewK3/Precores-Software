@echo off
:: ============================================================
::  RunAll.bat - Master wrapper for post-install scripts
::  Called by autounattend.xml FirstLogonCommands
::  OR by SetupComplete.cmd (fallback)
::  Runs QuickOptimize first, then QuickInstall
:: ============================================================
title RunAll - Post-Install Setup
color 0A
setlocal EnableExtensions EnableDelayedExpansion

:: Ensure we're running as admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Not admin. Elevating...
    powershell -NoProfile -Command "Start-Process cmd -ArgumentList '/c \"%~f0\"' -Verb RunAs"
    exit /b
)

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "FLAG=%SCRIPT_DIR%\.completed"

:: Prevent double-run (SetupComplete + FirstLogonCommands)
if exist "%FLAG%" (
    echo [SKIP] Scripts already completed. Exiting.
    timeout /t 3 /nobreak >nul
    exit /b 0
)

echo.
echo  =============================================
echo   RunAll - Running Post-Install Scripts
echo  =============================================
echo   1. QuickOptimize.bat (system tweaks)
echo   2. QuickInstall.bat  (software install)
echo  =============================================
echo.
echo   %DATE% %TIME%
echo.

:: ---- Step 1: Run QuickOptimize ----
if exist "%SCRIPT_DIR%\QuickOptimize.bat" (
    echo [1/2] Running QuickOptimize.bat...
    echo ──────────────────────────────────────────
    call "%SCRIPT_DIR%\QuickOptimize.bat"
    echo ──────────────────────────────────────────
    echo [1/2] QuickOptimize.bat finished.
) else (
    echo [1/2] WARNING: QuickOptimize.bat not found at %SCRIPT_DIR%
)

echo.

:: ---- Step 2: Run QuickInstall ----
if exist "%SCRIPT_DIR%\QuickInstall.bat" (
    echo [2/2] Running QuickInstall.bat...
    echo ──────────────────────────────────────────
    call "%SCRIPT_DIR%\QuickInstall.bat"
    echo ──────────────────────────────────────────
    echo [2/2] QuickInstall.bat finished.
) else (
    echo [2/2] WARNING: QuickInstall.bat not found at %SCRIPT_DIR%
)

:: ---- Create completion flag ----
echo completed > "%FLAG%"

echo.
echo  =============================================
echo   RunAll - All scripts completed!
echo   %DATE% %TIME%
echo  =============================================
echo.
echo   Press any key to finish and cleanup...
pause >nul

endlocal

:: Self-cleanup: schedule deletion after this process exits
:: Use a delayed cmd to avoid file-lock issues
set "CLEANUP_DIR=%~dp0"
if "%CLEANUP_DIR:~-1%"=="\" set "CLEANUP_DIR=%CLEANUP_DIR:~0,-1%"
start /min cmd /c "timeout /t 10 /nobreak >nul & rmdir /s /q "%CLEANUP_DIR%" >nul 2>&1"
exit /b

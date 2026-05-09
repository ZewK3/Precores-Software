@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem QuickInstall - edit these links before pushing to git
set "CHROME_URL=https://dl.google.com/chrome/install/googlechromestandaloneenterprise64.msi"
set "NODE_URL=https://nodejs.org/dist/v20.18.0/node-v20.18.0-x64.msi"
set "GIT_URL=https://github.com/git-for-windows/git/releases/download/v2.49.0.windows.1/Git-2.49.0-64-bit.exe"

set "TEMP_DIR=%SystemRoot%\Temp"
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

echo Installing Chrome...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%CHROME_URL%' -OutFile '%TEMP_DIR%\chrome.msi'; Start-Process msiexec.exe -ArgumentList '/i "%TEMP_DIR%\chrome.msi" /qn /norestart' -Wait -NoNewWindow; Remove-Item '%TEMP_DIR%\chrome.msi' -Force -ErrorAction SilentlyContinue"

echo Installing Node.js (npm)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%NODE_URL%' -OutFile '%TEMP_DIR%\nodejs.msi'; Start-Process msiexec.exe -ArgumentList '/i "%TEMP_DIR%\nodejs.msi" /qn /norestart' -Wait -NoNewWindow; Remove-Item '%TEMP_DIR%\nodejs.msi' -Force -ErrorAction SilentlyContinue"

echo Installing Git...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%GIT_URL%' -OutFile '%TEMP_DIR%\git.exe'; Start-Process '%TEMP_DIR%\git.exe' -ArgumentList '/VERYSILENT /NORESTART /SP-' -Wait -NoNewWindow; Remove-Item '%TEMP_DIR%\git.exe' -Force -ErrorAction SilentlyContinue"

echo Done.
endlocal

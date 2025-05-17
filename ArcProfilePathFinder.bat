@echo off
setlocal

:: === LOG FILE ===
set LOG_FILE=%USERPROFILE%\Desktop\ArcProfilePathCheck.log
echo Arc Profile Path Check Log > "%LOG_FILE%"

:: === EXPECTED STORE PATH (Common for Microsoft Store installs) ===
set BASE_PATH=%LOCALAPPDATA%\Packages
set ARC_DIR_NAME=TheBrowserCompany.Arc_*

echo Scanning for Arc install path... >> "%LOG_FILE%"
for /d %%D in ("%BASE_PATH%\%ARC_DIR_NAME%") do (
    echo Found: %%D >> "%LOG_FILE%"
    set ARC_PATH=%%D
)

:: === DIG DEEPER TO FIND CACHE LOCATION ===
set ARC_CACHE_PATH=%ARC_PATH%\LocalCache

if exist "%ARC_CACHE_PATH%" (
    echo Arc Cache Path Found: %ARC_CACHE_PATH% >> "%LOG_FILE%"
    echo.
    echo ✅ Arc Profile data likely resides in:
    echo %ARC_CACHE_PATH%
    echo.
    echo Path also logged here:
    echo %LOG_FILE%
) else (
    echo Arc Cache Path NOT found. >> "%LOG_FILE%"
    echo.
    echo ❌ Arc profile directory was not located via default Store path.
    echo You may need to launch Arc or check the system for alternate profile data.
)

pause
endlocal

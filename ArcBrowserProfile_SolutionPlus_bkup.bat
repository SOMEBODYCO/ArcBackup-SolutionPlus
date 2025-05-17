@echo off
setlocal

:: === SETTINGS ===
set ARC_PROFILE_DIR=%LOCALAPPDATA%\Packages\TheBrowserCompany.Arc_ttt1ap7aakyb4\LocalCache
set BACKUP_DIR=Z:\THE_BLACK_VAULT\_BACKUPS\ArcBackups
set SMART_LOG_DIR=C:\Temple_Strike\Scripts\SMART_LOGS

:: === CLEAN TIMESTAMP (remove illegal characters and format hour) ===
for /f "tokens=1-4 delims=/ " %%a in ("%date%") do (
    set yyyy=%%d
    set mm=%%b
    set dd=%%c
)
for /f "tokens=1-3 delims=:." %%a in ("%time%") do (
    set /a hh=10%%a %% 100
    set min=%%b
    set sec=%%c
)
set TIMESTAMP=%yyyy%-%mm%-%dd%_%hh%-%min%-%sec%
set DEST_DIR=%BACKUP_DIR%\ArcBackup_%TIMESTAMP%
set ZIP_FILE=%DEST_DIR%.zip
set LOG_FILE=%SMART_LOG_DIR%\ArcBackupLog_%TIMESTAMP%.txt

:: === CHECK IF ARC IS RUNNING ===
tasklist /FI "IMAGENAME eq Arc.exe" | find /I "Arc.exe" >nul
if %ERRORLEVEL%==0 (
    echo Arc Browser is currently running. Please close it before running this backup.
    echo %DATE% %TIME% - ABORTED: Arc was open >> "%LOG_FILE%"
    pause
    exit /b
)

:: === CHECK IF ARC PROFILE DIRECTORY EXISTS ===
if not exist "%ARC_PROFILE_DIR%" (
    echo Arc profile directory not found at: %ARC_PROFILE_DIR%
    echo %DATE% %TIME% - ERROR: Arc user data directory not found. Aborting backup. >> "%LOG_FILE%"
    pause
    exit /b
)

:: === DISPLAY WHAT'S HAPPENING ===
echo Backing up Arc Browser data...
echo Source: %ARC_PROFILE_DIR%
echo Destination: %DEST_DIR%
echo.
echo %DATE% %TIME% - Starting backup... >> "%LOG_FILE%"

:: === CREATE DESTINATION FOLDER ===
mkdir "%DEST_DIR%" >nul 2>&1

:: === COPY FILES ===
robocopy "%ARC_PROFILE_DIR%" "%DEST_DIR%" /E /R:3 /W:5 >> "%LOG_FILE%"

:: === COMPRESS BACKUP (ZIP SANCTIFIER MODE) ===
echo Compressing backup to ZIP (final fix)...
powershell -NoProfile -Command ^
"Try { ^
  $Files = Get-ChildItem -Path '%DEST_DIR%' -Recurse; ^
  if ($Files.Count -eq 0) { throw 'No files found to compress.' }; ^
  Compress-Archive -Path $Files.FullName -DestinationPath '%ZIP_FILE%' -Force -ErrorAction Stop; ^
  Write-Host 'ZIP SUCCESS' ^
} Catch { ^
  Write-Host 'ZIP FAIL:'; Write-Host $_.Exception.Message ^
}" > "%LOG_FILE%" 2>&1

:: === CLEAN UP UNZIPPED FOLDER IF ZIP EXISTS ===
if exist "%ZIP_FILE%" (
    rd /s /q "%DEST_DIR%"
    echo %DATE% %TIME% - ZIP archive created: %ZIP_FILE% >> "%LOG_FILE%"
    echo ZIP archive created successfully.
) else (
    echo Compression failed. Backup folder preserved at: %DEST_DIR%
    echo %DATE% %TIME% - Compression FAILED. Unzipped backup remains: %DEST_DIR% >> "%LOG_FILE%"
)

:: === DELETE OLD BACKUPS (>30 DAYS) ===
echo Cleaning up old backups (older than 30 days)...
forfiles /p "%BACKUP_DIR%" /m ArcBackup_* /d -30 /c "cmd /c echo Deleting: @path && rd /s /q @path" 2>> "%LOG_FILE%"
echo %DATE% %TIME% - Cleanup complete. >> "%LOG_FILE%"

:: === DONE ===
echo Backup process complete.
echo %DATE% %TIME% - Backup finished. >> "%LOG_FILE%"
pause
endlocal

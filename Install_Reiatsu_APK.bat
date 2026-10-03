@echo off
setlocal enabledelayedexpansion
title Reiatsu - 1-Click ADB Phone Installation
chcp 65001 >nul

echo ============================================================
echo   Reiatsu (霊圧) — 1-Click Android Phone Installation
echo   100%% On-Device Execution (Android 8.0 to Android 15/16)
echo ============================================================
echo.

:: 1. Locate ADB
set "ADB_CMD=adb"
where adb >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" (
        set "ADB_CMD=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
    ) else (
        echo [ERROR] adb.exe not found in PATH or Android SDK platform-tools!
        echo Please ensure Android platform-tools are installed or adb is on your PATH.
        pause
        exit /b 1
    )
)

echo [1/4] Checking connected Android devices via ADB...
"%ADB_CMD%" devices
echo.

for /f "skip=1 tokens=1,2" %%i in ('"%ADB_CMD%" devices') do (
    if "%%j"=="device" (
        set "DEVICE_ID=%%i"
        goto :device_found
    )
)

echo [WARNING] No authorized device detected.
echo 1. Connect your phone via USB.
echo 2. Enable USB Debugging in Developer Options.
echo 3. Tap 'Allow USB debugging' on your phone screen.
pause
exit /b 1

:device_found
echo [SUCCESS] Connected device: !DEVICE_ID!
echo.

:: 2. Find APK
set "APK_FILE="
if exist "%~dp0Reiatsu-v1.0.0.apk" set "APK_FILE=%~dp0Reiatsu-v1.0.0.apk"
if not defined APK_FILE if exist "%~dp0app-debug.apk" set "APK_FILE=%~dp0app-debug.apk"
if not defined APK_FILE (
    for %%f in ("%~dp0*.apk") do (
        set "APK_FILE=%%f"
        goto :apk_found
    )
)

:apk_found
if not defined APK_FILE (
    echo [ERROR] Reiatsu APK not found in this folder!
    echo Please download Reiatsu-v1.0.0.apk from GitHub Releases:
    echo https://github.com/Orsted-Ninja/Reiatsu/releases/latest
    echo and place it in the same directory as this script.
    pause
    exit /b 1
)

echo [2/4] Installing Reiatsu APK onto !DEVICE_ID!...
echo APK: !APK_FILE!
"%ADB_CMD%" -s !DEVICE_ID! shell am force-stop com.storagesense.app.debug >nul 2>&1
"%ADB_CMD%" -s !DEVICE_ID! install -r -d "!APK_FILE!"
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Installation failed!
    pause
    exit /b %ERRORLEVEL%
)
echo [SUCCESS] Reiatsu installed successfully!
echo.

:: 3. Storage Permissions & Model Directories
echo [3/4] Configuring storage permissions and model storage...
"%ADB_CMD%" -s !DEVICE_ID! shell appops set com.storagesense.app.debug MANAGE_EXTERNAL_STORAGE allow
"%ADB_CMD%" -s !DEVICE_ID! shell "mkdir -p /sdcard/StorageSense/models /sdcard/Download/models"
echo.

:: 4. Launch App
echo [4/4] Launching Reiatsu on your phone...
"%ADB_CMD%" -s !DEVICE_ID! shell am start -n com.storagesense.app.debug/com.storagesense.app.ui.MainActivity
echo.
echo ============================================================
echo   Reiatsu is now running on your phone!
echo.
echo   Model Location: /sdcard/StorageSense/models/
echo   (Optional: Run Download_And_Push_Gemma.bat to push Gemma LLM)
echo ============================================================
echo.
pause

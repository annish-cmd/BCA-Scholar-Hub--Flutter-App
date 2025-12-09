@echo off
echo Installing BCA Scholar Hub APK...
echo.

REM Check if device is connected
adb devices | findstr "device$" >nul
if %errorlevel% == 0 (
    echo Device found. Installing APK...
    echo.
    
    REM Install the arm64-v8a version (most common for modern Android devices)
    adb install -r build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
    
    if %errorlevel% == 0 (
        echo.
        echo APK installed successfully!
        echo Launching app...
        adb shell am start -n com.example.anish_library/.MainActivity
    ) else (
        echo.
        echo Failed to install APK. Trying universal APK...
        adb install -r build\app\outputs\flutter-apk\app-release.apk
        
        if %errorlevel% == 0 (
            echo.
            echo Universal APK installed successfully!
            echo Launching app...
            adb shell am start -n com.example.anish_library/.MainActivity
        ) else (
            echo.
            echo Failed to install APK. Please check your device connection.
        )
    )
) else (
    echo No device found. Please connect your Android device and enable USB debugging.
)

echo.
pause
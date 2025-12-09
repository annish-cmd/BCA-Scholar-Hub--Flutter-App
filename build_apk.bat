@echo off
echo BCA Scholar Hub - APK Build Script
echo =================================
echo.

echo Cleaning previous builds...
flutter clean
echo.

echo Getting dependencies...
flutter pub get
echo.

echo Building split APKs (lighter installation)...
flutter build apk --split-per-abi
echo.

echo Build completed successfully!
echo.

echo Available APKs:
dir build\app\outputs\flutter-apk\*.apk
echo.

echo To install on your device, run install_apk.bat
echo.

pause
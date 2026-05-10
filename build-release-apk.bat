@echo off
setlocal

cd /d "%~dp0"

echo ================================
echo Building Flutter Release APK...
echo ================================
echo.

where flutter
echo.

echo Current folder:
cd
echo.

echo Checking Flutter...
call flutter --version
echo.

echo Running flutter clean...
call flutter clean
if errorlevel 1 goto error

echo.
echo Running flutter pub get...
call flutter pub get
if errorlevel 1 goto error

echo.
echo Running flutter build apk --release...
call flutter build apk --release
if errorlevel 1 goto error

echo.
echo ================================
echo APK build completed successfully!
echo ================================
echo.
echo APK path:
echo %cd%\build\app\outputs\flutter-apk\app-release.apk
echo.

explorer "%cd%\build\app\outputs\flutter-apk"

goto end

:error
echo.
echo ================================
echo Build failed.
echo ================================
echo.
echo Error code: %errorlevel%
echo.
echo Make sure:
echo 1. This file is beside pubspec.yaml
echo 2. Flutter works from this terminal
echo 3. Android SDK and Gradle are okay
echo.

:end
echo.
echo Press any key to close...
pause >nul
endlocal
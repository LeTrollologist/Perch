@echo off
setlocal
echo ========================================================
echo  Building Perch Focus HUD with Tungsten Genesis
echo ========================================================

set "TUNGSTEN_DIR=%~dp0..\Tungsten"
if not exist "%TUNGSTEN_DIR%\bin\tgc.exe" (
    echo [ERROR] Tungsten compiler not found at %TUNGSTEN_DIR%\bin\tgc.exe
    exit /b 1
)

pushd "%TUNGSTEN_DIR%"
.\bin\tgc.exe build "%~dp0perch.tg" -o "%~dp0perch.exe"
set "BUILD_STATUS=%ERRORLEVEL%"
popd

if %BUILD_STATUS% equ 0 (
    echo.
    echo [SUCCESS] Perch successfully compiled to:
    echo           %~dp0perch.exe
) else (
    echo.
    echo [ERROR] Compilation failed with status %BUILD_STATUS%
    exit /b %BUILD_STATUS%
)

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

if %BUILD_STATUS% equ 0 (
    echo [Perch] Linking as native Windows GUI subsystem...
    clang --target=x86_64-pc-windows-gnu -nostartfiles -Wl,--subsystem,windows -o "%~dp0perch.exe" "%~dp0perch.exe.ll" target/crt/crt2.o -Ltarget/crt -lmingw32 -lmingwex -lmsvcrt -lkernel32 -luser32 -lgdi32 -lwinmm -lws2_32 -lgcc
    set "BUILD_STATUS=%ERRORLEVEL%"
    del "%~dp0perch.exe.ll" 2>nul
)
popd

if %BUILD_STATUS% equ 0 (
    echo.
    echo [SUCCESS] Pure GUI executable successfully built:
    echo           %~dp0perch.exe
) else (
    echo.
    echo [ERROR] Compilation failed with status %BUILD_STATUS%
    exit /b %BUILD_STATUS%
)

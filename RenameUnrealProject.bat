::Engage Software Unreal Project Renamer

@echo off
setlocal EnableDelayedExpansion

:: Find the .uproject file and old project name
set "uprojectfile="
for %%f in (*.uproject) do (
    set "uprojectfile=%%~nxf"
    set "oldname=%%~nf"
    goto :entername
)
echo ERROR: No .uproject file found in current folder.
pause
exit /b

:entername

echo Current project name: %uprojectfile%
set /p newname=Enter new project name:

if "%newname%"=="" (
    echo ERROR: No name entered.
    echo.
    goto :entername
)

:: Validate: only allow alphanumeric characters
echo %newname% | findstr /R /C:"^[a-z A-Z 0-9]*$" >nul
if errorlevel 1 (
    echo ERROR: New name contains invalid characters.
    echo.
    goto :entername
)

echo.

set "filesToDelete=%oldname%.sln .vsconfig"
set "foldersToDelete=Intermediate Saved DerivedDataCache .vs Binaries Build %LOCALAPPDATA%\UnrealEngine\Common\DerivedDataCache"

echo Deleting generated files...
for %%F in (%filesToDelete%) do (
    if exist "%%F" (
        echo Deleting file %%F
        del /f /q "%%F"
    )
)

echo Deleting generated folders...
for %%F in (%foldersToDelete%) do (
    if exist "%%F" (
        echo Deleting folder %%F
        rmdir /s /q "%%F"
    )
)

if not exist "Plugins\" (
    goto :rename
)

for /d /r "Plugins" %%I in (*) do (
    if /i "%%~nxI"=="Intermediate" (
        if exist "%%I" (
            echo Deleting: %%I
            rd /s /q "%%I"
        )
    )
)

:rename

echo.

echo Replacing all instances of "%oldname%" with "%newname%" inside files...

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Get-ChildItem -Path 'Source','Config' -Recurse -File | ForEach-Object { " ^
    "$content = Get-Content -Raw -LiteralPath $_.FullName; " ^
    "$content = $content -replace [regex]::Escape('%oldname%'), '%newname%'; " ^
    "Set-Content -LiteralPath $_.FullName -Value $content -Encoding UTF8 " ^
    "}"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$file = '%uprojectfile%';" ^
    "if (Test-Path $file) { " ^
    "$content = Get-Content -Raw -LiteralPath $file; " ^
    "$content = $content -replace [regex]::Escape('%oldname%'), '%newname%'; " ^
    "Set-Content -LiteralPath $file -Value $content -Encoding UTF8 }"

echo Replacing all instances of "%oldname%" with "%newname%" in file names...

for %%d in (Source Config) do (
    if exist "%%d" (
        for /f "delims=" %%f in ('dir /b /s /a:-d "%%d" ^| sort /r') do (
            set "filename=%%~nxf"
            setlocal EnableDelayedExpansion
            set "newfilename=!filename:%oldname%=%newname%!"
            if /i not "!filename!"=="!newfilename!" (
                ren "%%f" "!newfilename!"
            )
            endlocal
        )
    )
)

echo Replacing all instances of "%oldname%" with "%newname%" in folder names...

for %%d in (Source Config) do (
    if exist "%%d" (
        for /f "delims=" %%f in ('dir /b /s /a:d "%%d" ^| sort /r') do (
            set "foldername=%%~nxf"
            set "folderpath=%%~dpf"
            setlocal EnableDelayedExpansion
            set "newfoldername=!foldername:%oldname%=%newname%!"
            if /i not "!foldername!"=="!newfoldername!" (
                pushd "!folderpath!"
                ren "!foldername!" "!newfoldername!"
                popd
            )
            endlocal
        )
    )
)

set "newuprojectfile=%newname%.uproject"
if exist "%uprojectfile%" (
    ren "%uprojectfile%" "%newuprojectfile%"
)

echo.
echo Project renamed successfully.
echo.

pause
exit /b

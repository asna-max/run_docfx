@echo off
setlocal enabledelayedexpansion

REM Define the PDF file name
set PDF_FILE=_site\toc.pdf

REM Define the URL for the latest DocFX release (replace with the latest version if needed)
set DOCFX_URL=https://github.com/dotnet/docfx/releases/download/v2.58.9/docfx.zip
set DOCFX_ZIP=%TEMP%\docfx.zip
set DOCFX_DIR=C:\DocFX

REM Check if DocFX is already installed
docfx --version 2>nul
if %ERRORLEVEL% neq 0 (
    echo DocFX is not installed.
    :prompt_install
    set /p INSTALL="Do you want to proceed with the installation? (Y/N): "
    if /i "!INSTALL!"=="Y" (
        call :download_docfx
        call :extract_docfx
        echo Cleaning up installer...
        del %DOCFX_ZIP%
        call :set_the_new_PATH
				set "PATH=%DOCFX_DIR%;%PATH%"
    ) else if /i "!INSTALL!"=="N" (
        echo Installation aborted by the user.
        goto :end
    ) else (
        echo Invalid input. Please enter 'Y' for Yes or 'N' for No.
        goto :prompt_install
    )
) else (
    echo DocFX is already installed.
)
call :serve

goto :end

REM Function to download DocFX
:download_docfx
echo Downloading DocFX...
powershell -Command "Invoke-WebRequest -Uri %DOCFX_URL% -OutFile %DOCFX_ZIP%" || (
    echo Error: Failed to download DocFX. Please check your internet connection and try again.
    exit /b 1
)
goto :eof

REM Function to extract DocFX
:extract_docfx
echo Extracting DocFX...
powershell -Command "Expand-Archive -Path %DOCFX_ZIP% -DestinationPath %DOCFX_DIR% -Force" || (
    echo Error: Failed to extract DocFX. Please check the ZIP file and try again.
    exit /b 1
)
goto :eof

REM Set the new PATH
:set_the_new_PATH
for /F "tokens=*" %%i in ('powershell -Command "[System.Environment]::GetEnvironmentVariable('PATH', 'Machine')"') do set CURRENT_PATH=%%i
set NEW_PATH=!CURRENT_PATH!;%DOCFX_DIR%
setx PATH "!NEW_PATH!"
goto :eof

REM Build the documentation
:docfx_build
docfx build
REM Check if the PDF file exists
if not exist "%PDF_FILE%" (
    echo Generating the PDF...
    docfx pdf
) else (
    echo PDF file already exists. Skipping PDF generation.
)
goto :eof

:serve
REM Serve the site locally using DocFX
echo Starting local server for the site...
start cmd /c "docfx serve _site"

REM Waiting a few seconds to ensure the server is up
timeout /t 2 /nobreak

REM Opening the localhost in the default browser
echo Opening the site in your default browser...
start http://localhost:8080
goto :eof

:end
REM End of batch file
echo Script execution completed.
endlocal

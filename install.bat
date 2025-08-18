@echo off
REM Pickit - Lightroom Classic Plugin Installation Script for Windows
REM This script automates the installation process

echo ======================================
echo    Pickit AI - Lightroom Plugin
echo    Automated Installation Script
echo ======================================
echo.

REM Step 1: Check Node.js installation
echo Step 1: Checking Node.js installation...
where node >nul 2>nul
if %errorlevel% == 0 (
    for /f "tokens=*" %%i in ('node -v') do set NODE_VERSION=%%i
    echo [OK] Node.js is installed: %NODE_VERSION%
) else (
    echo [ERROR] Node.js is not installed!
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)
echo.

REM Step 2: Install dependencies
echo Step 2: Installing dependencies...
cd LightroomAISelector\node-bridge
if exist package.json (
    call npm install
    if %errorlevel% == 0 (
        echo [OK] Dependencies installed successfully
    ) else (
        echo [ERROR] Failed to install dependencies
        pause
        exit /b 1
    )
) else (
    echo [ERROR] package.json not found
    pause
    exit /b 1
)
echo.

REM Step 3: Download AI models
echo Step 3: Downloading AI models...
if exist scripts\download-models.js (
    call npm run install-models
    if %errorlevel% == 0 (
        echo [OK] AI models downloaded successfully
    ) else (
        echo [WARNING] Failed to download some models, but continuing...
    )
) else (
    echo [WARNING] Model download script not found, skipping...
)
echo.

REM Step 4: Setup credentials (optional)
echo Step 4: Setting up Google Sheets API (optional)...
if not exist credentials.json (
    if exist credentials.example.json (
        set /p response="Would you like to set up Google Sheets feedback? (y/n): "
        if /i "%response%"=="y" (
            copy credentials.example.json credentials.json
            echo [WARNING] Please edit credentials.json with your Google Cloud credentials
            echo [WARNING] See GOOGLE_SHEETS_SETUP.md for instructions
        ) else (
            echo [OK] Skipping Google Sheets setup
        )
    )
) else (
    echo [OK] Credentials already configured
)
echo.

REM Step 5: Install Lightroom plugin
echo Step 5: Installing Lightroom plugin...
set LIGHTROOM_DIR=%APPDATA%\Adobe\Lightroom\Modules

set /p response="Would you like to install the plugin to Lightroom? (y/n): "
if /i "%response%"=="y" (
    REM Create directory if it doesn't exist
    if not exist "%LIGHTROOM_DIR%" mkdir "%LIGHTROOM_DIR%"
    
    REM Copy plugin
    xcopy /E /I /Y "..\..\LightroomAISelector" "%LIGHTROOM_DIR%\LightroomAISelector"
    
    if %errorlevel% == 0 (
        echo [OK] Plugin copied to Lightroom directory
    ) else (
        echo [ERROR] Failed to copy plugin
        echo Please manually add the plugin through Lightroom's Plugin Manager
    )
) else (
    echo.
    echo [WARNING] Manual installation required:
    echo 1. Open Lightroom Classic
    echo 2. Go to File - Plug-in Manager
    echo 3. Click 'Add' and select the 'LightroomAISelector' folder
)
echo.

REM Step 6: Start the server
echo Step 6: Starting the Node.js server...
echo.
echo [WARNING] The server needs to run continuously for the plugin to work
set /p response="Would you like to start the server now? (y/n): "

if /i "%response%"=="y" (
    echo.
    echo [OK] Starting server...
    echo [WARNING] Keep this command window open!
    echo.
    echo ----------------------------------------
    echo Server output:
    echo ----------------------------------------
    call npm start
) else (
    echo.
    echo [WARNING] To start the server later, run:
    echo   cd LightroomAISelector\node-bridge
    echo   npm start
)

echo.
echo ======================================
echo [OK] Installation Complete!
echo ======================================
echo.
echo Next steps:
echo 1. Make sure the Node.js server is running (npm start)
echo 2. Open Lightroom Classic
echo 3. Enable the plugin in File - Plug-in Manager
echo 4. Select photos and right-click - Pickit - Analyze
echo.
echo For detailed instructions, see INSTALLATION_GUIDE.md
echo.
echo Happy photo selection!
pause
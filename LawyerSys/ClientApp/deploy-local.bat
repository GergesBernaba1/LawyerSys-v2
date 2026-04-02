@echo off
REM Local deployment script (no admin required)
REM Deploys to a folder in the current directory

echo ================================================
echo LawyerSys ClientApp - Local Deployment
echo ================================================
echo.

REM Configuration - Deploy to local folder
set SOURCE_PATH=%~dp0
set DEPLOY_PATH=%SOURCE_PATH%deploy

echo Source Path: %SOURCE_PATH%
echo Deploy Path: %DEPLOY_PATH%
echo.

REM Build the application
echo [1/5] Building Next.js application...
cd /d "%SOURCE_PATH%"
call npm run build
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Build failed!
    pause
    exit /b 1
)
echo Build completed successfully.
echo.

REM Clean deployment folder
echo [2/5] Cleaning deployment folder...
if exist "%DEPLOY_PATH%" (
    rd /S /Q "%DEPLOY_PATH%"
)
mkdir "%DEPLOY_PATH%"
echo Deployment folder ready.
echo.

REM Copy standalone build
echo [3/5] Copying standalone server files...
if exist "%SOURCE_PATH%\.next\standalone" (
    xcopy /E /I /Y /Q "%SOURCE_PATH%\.next\standalone\*" "%DEPLOY_PATH%\" >nul
    echo Standalone files copied.
) else (
    echo ERROR: .next\standalone folder not found!
    echo Make sure next.config.js contains output: 'standalone'
    pause
    exit /b 1
)
echo.

REM Copy static assets (CRITICAL FOR STYLING)
echo [4/5] Copying static assets (.next/static)...
if exist "%SOURCE_PATH%\.next\static" (
    xcopy /E /I /Y /Q "%SOURCE_PATH%\.next\static" "%DEPLOY_PATH%\.next\static" >nul
    echo Static assets copied.
) else (
    echo ERROR: .next\static folder not found!
    pause
    exit /b 1
)
echo.

REM Copy public files
echo [5/5] Copying public files...
if exist "%SOURCE_PATH%\public" (
    xcopy /E /I /Y /Q "%SOURCE_PATH%\public" "%DEPLOY_PATH%\public" >nul
    echo Public files copied.
)
echo.

REM Create environment file
echo Creating environment configuration...
(
echo NODE_ENV=production
echo PORT=3002
echo HOSTNAME=0.0.0.0
echo NEXT_PUBLIC_BACKEND_URL=https://localhost:7001/api
) > "%DEPLOY_PATH%\.env.local"
echo Environment file created.
echo.

REM Create start script
echo Creating start script...
(
echo @echo off
echo echo Starting LawyerSys ClientApp...
echo set NODE_ENV=production
echo set PORT=3002
echo set HOSTNAME=0.0.0.0
echo set NEXT_PUBLIC_BACKEND_URL=https://localhost:7001/api
echo node server.js
) > "%DEPLOY_PATH%\start.bat"
echo.

REM Verify deployment
echo ================================================
echo Verifying deployment...
echo ================================================
echo.

if exist "%DEPLOY_PATH%\server.js" (
    echo [OK] server.js found
) else (
    echo [ERROR] server.js NOT found!
)

if exist "%DEPLOY_PATH%\.next\static" (
    echo [OK] .next/static folder found
) else (
    echo [ERROR] .next/static folder NOT found!
)

echo.
echo ================================================
echo Deployment Complete!
echo ================================================
echo.
echo Deployed to: %DEPLOY_PATH%
echo.
echo To start the server:
echo   cd "%DEPLOY_PATH%"
echo   start.bat
echo.
echo Or run directly:
echo   cd "%DEPLOY_PATH%"
echo   node server.js
echo.
echo The application will be available at:
echo   http://localhost:3002
echo.
pause

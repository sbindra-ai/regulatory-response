@echo off
setlocal EnableExtensions EnableDelayedExpansion
title RAISE - Dev Server

:: Run from repo root (same folder as this .bat)
cd /d "%~dp0"

:: ── Resolve Node.js (no system install required if portable is present) ─────
:: Option A — set before running this file, e.g.:
::   set PORTABLE_NODE_DIR=C:\tools\node-v22.14.0-win-x64
:: Option B — extract the official Windows x64 zip so you have:
::   <repo>\node\node-v22.14.0-win-x64\node.exe
::   Download: https://nodejs.org/dist/v22.14.0/node-v22.14.0-win-x64.zip

set "NODE_DIR="
set "USE_SYSTEM_NODE="

if defined PORTABLE_NODE_DIR set "NODE_DIR=%PORTABLE_NODE_DIR%"
if not defined NODE_DIR if defined NODE_HOME set "NODE_DIR=%NODE_HOME%"

if not defined NODE_DIR if exist "%~dp0node\node-v22.14.0-win-x64\node.exe" (
    set "NODE_DIR=%~dp0node\node-v22.14.0-win-x64"
)

if not defined NODE_DIR (
    for /d %%i in ("%~dp0node\node-v*-win-x64") do (
        if exist "%%~fi\node.exe" (
            set "NODE_DIR=%%~fi"
            goto :node_dir_done
        )
    )
)
:node_dir_done

if defined NODE_DIR (
    if not exist "%NODE_DIR%\node.exe" (
        echo ERROR: NODE_DIR is set but node.exe was not found:
        echo   %NODE_DIR%\node.exe
        pause
        exit /b 1
    )
    if not exist "%NODE_DIR%\npm.cmd" (
        echo ERROR: npm.cmd not found next to node.exe. Use the official Node Windows zip, not only node.exe.
        echo   Expected: %NODE_DIR%\npm.cmd
        pause
        exit /b 1
    )
    set "PATH=%NODE_DIR%;%PATH%"
    echo.
    echo  Regulatory AI for Structured Execution (RAISE) - Development Server
    echo  Using Node.js: %NODE_DIR%\node.exe
    echo.
    goto :run_npm
)

where node >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo.
    echo  Regulatory AI for Structured Execution (RAISE) - Development Server
    echo  Using Node.js from PATH ^(no portable folder under .\node\^)
    echo.
    goto :run_npm
)

echo ERROR: Node.js was not found.
echo.
echo  Fix one of the following:
echo   1. Extract the portable zip into this repo:
echo      %~dp0node\node-v22.14.0-win-x64\
echo      https://nodejs.org/dist/v22.14.0/node-v22.14.0-win-x64.zip
echo   2. Or set PORTABLE_NODE_DIR to your extracted folder ^(must contain node.exe and npm.cmd^).
echo   3. Or install Node.js and ensure `node` is on your PATH.
echo.
pause
exit /b 1

:run_npm
:: ── Step 1: Install dependencies ───────────────────────────────────────────
echo ==========================================================
echo  Step 1/2: Installing dependencies ^(npm install^)...
echo ==========================================================
call npm install
if %ERRORLEVEL% neq 0 (
    echo.
    echo ERROR: npm install failed. Check the output above.
    pause
    exit /b 1
)

:: ── Step 2: Start the dev server ────────────────────────────────────────────
echo.
echo ==========================================================
echo  Step 2/2: Starting Next.js dev server ^(npm run dev^)...
echo  Open http://localhost:3000 in your browser.
echo ==========================================================
echo.
call npm run dev

pause
endlocal

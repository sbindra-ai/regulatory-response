@echo off
setlocal EnableExtensions EnableDelayedExpansion
title RAISE - Dev Server

:: Always run from this repo root (folder containing this .bat)
cd /d "%~dp0"
if not exist "package.json" (
    echo ERROR: package.json not found. This script must live in the regulatory-response repo root.
    echo Current directory: %CD%
    pause
    exit /b 1
)

:: Optional: force dependency install — start-dev.bat install
set "DO_INSTALL=0"
if /i "%~1"=="install" set "DO_INSTALL=1"
if defined FORCE_NPM_INSTALL set "DO_INSTALL=1"

:: ── Resolve Node.js (portable under .\node\ or PATH) ─────────────────────────
set "NODE_DIR="
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
    if not exist "!NODE_DIR!\node.exe" (
        echo ERROR: NODE_DIR is set but node.exe was not found:
        echo   !NODE_DIR!\node.exe
        pause
        exit /b 1
    )
    if not exist "!NODE_DIR!\npm.cmd" (
        echo ERROR: npm.cmd not found next to node.exe. Use the official Node Windows zip.
        echo   Expected: !NODE_DIR!\npm.cmd
        pause
        exit /b 1
    )
    set "PATH=!NODE_DIR!;%PATH%"
    echo.
    echo  Regulatory AI for Structured Execution (RAISE^) - Development Server
    echo  Using Node.js: !NODE_DIR!\node.exe
    echo.
    goto :have_node
)

where node >nul 2>&1
if !errorlevel! equ 0 (
    echo.
    echo  Regulatory AI for Structured Execution (RAISE^) - Development Server
    echo  Using Node.js from PATH ^(no portable folder under .\node\^)
    echo.
    goto :have_node
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

:have_node
:: ── Dependencies: install only when missing or forced ────────────────────────
if "!DO_INSTALL!"=="1" goto :do_install
if not exist "node_modules\next" (
    echo node_modules missing or incomplete — running npm install...
    goto :do_install
)
echo Dependencies present ^(node_modules\next found^). Skipping npm install.
echo To reinstall: run   start-dev.bat install   or set FORCE_NPM_INSTALL=1
echo.
goto :start_dev

:do_install
echo ==========================================================
echo  Installing dependencies ^(npm install^)...
echo ==========================================================
call npm install
if errorlevel 1 (
    echo.
    echo ERROR: npm install failed. Check the output above.
    pause
    exit /b 1
)
echo.

:start_dev
echo ==========================================================
echo  Starting Next.js dev server ^(npm run dev^)...
echo  Open http://localhost:3000 in your browser.
echo  Press Ctrl+C to stop the server.
echo ==========================================================
echo.
call npm run dev

echo.
echo Server stopped ^(Ctrl+C or process ended^).
pause
endlocal
exit /b 0

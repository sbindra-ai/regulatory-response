@echo off
title Lynkuet Development Server
echo Starting Portable Node.js Server...
set PATH=%~dp0\node\node-v22.14.0-win-x64;%PATH%

echo.
echo ==========================================================
echo Step 1/2: Installing dependencies...
call npm install

echo.
echo ==========================================================
echo Step 2/2: Starting Application...
call npm run dev

pause

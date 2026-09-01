@echo off
title Animula Official - Server
cd /d "%~dp0"
echo ========================================
echo  Animula Official - Secure Server
echo  http://localhost:3000
echo ========================================
echo  Jangan tutup window ini!
echo.
if not exist "node_modules" (
  echo Installing dependencies...
  call npm install
)
node --env-file=.env server.js
pause

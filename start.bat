@echo off
chcp 65001 > nul
title ER Status System

echo.
echo  ==========================================
echo    ER Status System - Hospital Dashboard
echo  ==========================================
echo.

cd /d "%~dp0"

:: Check if Node.js is installed
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo  [ERROR] ไม่พบ Node.js กรุณาติดตั้งก่อน
    echo  Download: https://nodejs.org
    pause
    exit /b 1
)

:: Install dependencies if needed
if not exist node_modules (
    echo  [1/2] กำลังติดตั้ง dependencies...
    npm install
    echo.
)

echo  [2/2] Starting server...
echo.
echo  เปิดเบราว์เซอร์ไปที่ : http://localhost:4000
echo  กด Ctrl+C เพื่อหยุด
echo.

node server.js
pause

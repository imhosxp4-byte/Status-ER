@echo off
chcp 65001 > nul
cd /d "%~dp0"
title ER Status — กำลังตั้งค่าระบบ...

echo.
echo  ████████████████████████████████████████
echo   ER Status Dashboard — Auto Setup
echo  ████████████████████████████████████████
echo.

:: ── 1. ตรวจสอบ Node.js ─────────────────────────────────────────
echo [1/5] ตรวจสอบ Node.js...
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo       ไม่พบ Node.js — กำลังติดตั้งอัตโนมัติ...
    winget install --id OpenJS.NodeJS.LTS -e --silent ^
        --accept-source-agreements --accept-package-agreements
    if %errorlevel% neq 0 (
        echo       ติดตั้ง Node.js ไม่สำเร็จ
        echo       กรุณาดาวน์โหลดด้วยตัวเองที่ https://nodejs.org แล้วรันไฟล์นี้ใหม่
        pause
        exit /b 1
    )
    :: รีโหลด PATH หลังติดตั้ง
    set "PATH=%ProgramFiles%\nodejs;%APPDATA%\npm;%PATH%"
    where node >nul 2>&1
    if %errorlevel% neq 0 (
        echo       กรุณา Restart คอมพิวเตอร์แล้วรันไฟล์นี้ใหม่
        pause
        exit /b 1
    )
    echo       ติดตั้ง Node.js สำเร็จ
) else (
    for /f "tokens=*" %%v in ('node --version 2^>nul') do echo       พบ Node.js %%v
)

:: ── 2. ติดตั้ง npm packages ───────────────────────────────────
echo [2/5] ติดตั้ง npm packages...
if not exist node_modules (
    npm install --silent --no-fund --no-audit
    if %errorlevel% neq 0 (
        echo       npm install ไม่สำเร็จ — ตรวจสอบ internet connection
        pause
        exit /b 1
    )
    echo       ติดตั้ง packages สำเร็จ
) else (
    echo       packages ครบแล้ว
)

:: ── 3. ลงทะเบียนให้เปิดอัตโนมัติเมื่อ Windows เริ่ม ─────────
echo [3/5] ลงทะเบียนเปิดอัตโนมัติตอน Windows เริ่ม...
set "startupDir=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
copy /y "%~dp0launch.vbs" "%startupDir%\ER-Status-Launch.vbs" >nul 2>&1
if %errorlevel% == 0 (
    echo       ลงทะเบียนสำเร็จ
) else (
    echo       ลงทะเบียนไม่สำเร็จ ^(ไม่มีสิทธิ์^) — ข้ามขั้นตอนนี้
)

:: ── 4. สร้าง Shortcut บน Desktop ─────────────────────────────
echo [4/5] สร้าง Shortcut บน Desktop...
cscript //nologo "%~dp0setup-shortcut.vbs" >nul 2>&1
echo       สร้าง Shortcut เรียบร้อย

:: ── 5. เปิด Server และเบราว์เซอร์ ────────────────────────────
echo [5/5] เปิด Server...

:: ตรวจว่า port 3000 ว่างหรือไม่
netstat -ano | findstr ":4000 " | findstr "LISTENING" >nul 2>&1
if %errorlevel% == 0 (
    echo       Server ทำงานอยู่แล้ว
    goto OPEN_BROWSER
)

:: เปิด server แบบซ่อน window (ใช้ cd + relative path หลีกเลี่ยง quoting bug)
start "ER Status Server" /min cmd /c "cd /d "%~dp0" && node server.js > server.log 2>&1"

:: รอ server พร้อม — poll ทุก 1 วิ สูงสุด 30 วิ
set /a WAIT=0
:WAIT_LOOP
timeout /t 1 /nobreak >nul
netstat -ano | findstr ":4000 " | findstr "LISTENING" >nul 2>&1
if %errorlevel% == 0 goto SERVER_READY
set /a WAIT+=1
if %WAIT% lss 30 goto WAIT_LOOP

echo       Server เริ่มช้า — เปิดเบราว์เซอร์ก่อน หน้าจอจะโหลดข้อมูลเองอัตโนมัติ
goto OPEN_BROWSER

:SERVER_READY
echo       Server พร้อมแล้ว

:OPEN_BROWSER
echo.
echo  ════════════════════════════════════════
echo   ตั้งค่าเสร็จสมบูรณ์!
echo   เปิดเบราว์เซอร์...
echo  ════════════════════════════════════════
echo.

:: เปิด settings ถ้ายังไม่มี config / เปิด dashboard ถ้ามีแล้ว
if not exist "%~dp0config.json" (
    start "" "http://localhost:4000/settings.html"
) else (
    start "" "http://localhost:4000/dashboard.html"
)

:: ปิดหน้าต่างนี้หลัง 3 วิ
timeout /t 3 /nobreak >nul
exit

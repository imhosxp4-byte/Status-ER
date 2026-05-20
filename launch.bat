@echo off
chcp 65001 > nul
cd /d "%~dp0"

:: ── ตรวจสอบ Node.js ───────────────────────────────────────
where node >nul 2>&1
if %errorlevel% neq 0 (
    msg * "ไม่พบ Node.js กรุณารัน autostart.bat ก่อน"
    exit /b 1
)

:: ── ติดตั้ง dependencies ถ้ายังไม่มี ──────────────────────
if not exist node_modules (
    npm install --silent --no-fund --no-audit > nul 2>&1
)

:: ── ตรวจว่า port 4000 เปิดอยู่แล้วหรือไม่ ─────────────────
netstat -ano | findstr ":4000 " | findstr "LISTENING" >nul 2>&1
if %errorlevel% == 0 goto OPEN_BROWSER

:: ── เปิด server (ใช้ cd แล้วรัน relative path — หลีกเลี่ยง quoting bug)
start "ER Status Server" /min cmd /c "cd /d "%~dp0" && node server.js > server.log 2>&1"

:: ── รอ server พร้อม (poll ทุก 1 วิ สูงสุด 20 วิ) ──────────
set /a COUNT=0
:WAIT_LOOP
timeout /t 1 /nobreak >nul
netstat -ano | findstr ":4000 " | findstr "LISTENING" >nul 2>&1
if %errorlevel% == 0 goto OPEN_BROWSER
set /a COUNT+=1
if %COUNT% lss 20 goto WAIT_LOOP

:OPEN_BROWSER
:: ── เปิด settings ถ้ายังไม่มี config / เปิด dashboard ถ้ามีแล้ว ──
if not exist "%~dp0config.json" (
    start "" "http://localhost:4000/settings.html"
) else (
    start "" "http://localhost:4000/dashboard.html"
)
exit

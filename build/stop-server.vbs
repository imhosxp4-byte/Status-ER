' ER Status — Stop Server
Option Explicit
Dim oShell
Set oShell = CreateObject("WScript.Shell")
' หา PID ที่ใช้ port 4000 แล้ว kill
oShell.Run "cmd /c for /f ""tokens=5"" %a in ('netstat -ano ^| findstr :4000 ^| findstr LISTENING') do taskkill /F /PID %a", 0, True
MsgBox "หยุด Server เรียบร้อยแล้ว", 64, "Status ER"

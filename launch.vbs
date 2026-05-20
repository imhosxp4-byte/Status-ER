' ER Status — Silent Launcher (ไม่แสดง command window)
' ดับเบิลคลิกไฟล์นี้เพื่อเปิดระบบ

Set oShell = CreateObject("WScript.Shell")
Set oFSO   = CreateObject("Scripting.FileSystemObject")
strDir = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\") - 1)

' ── ตรวจว่า port 3000 เปิดอยู่แล้วหรือไม่ ─────────────────────
Set oExec = oShell.Exec("cmd /c netstat -ano | findstr "":4000 "" | findstr ""LISTENING""")
strOut = oExec.StdOut.ReadAll()

If Len(Trim(strOut)) = 0 Then
  ' Server ยังไม่ได้เปิด — รัน launch.bat แบบซ่อน window
  oShell.Run "cmd /c """ & strDir & "\launch.bat""", 0, False
End If

' ── เปิดเบราว์เซอร์ ────────────────────────────────────────────
' รอ 2 วิให้ server เริ่มก่อน (dashboard มี auto-retry อยู่แล้ว)
WScript.Sleep 2000
oShell.Run "http://localhost:4000/dashboard.html"

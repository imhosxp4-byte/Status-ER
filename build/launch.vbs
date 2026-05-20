' ER Status — Silent Launcher v1.0
' เปิด server + browser โดยไม่มี command window
Option Explicit
Dim oShell, oFSO, oExec, strDir, strOut, strNode, strServer

Set oShell = CreateObject("WScript.Shell")
Set oFSO   = CreateObject("Scripting.FileSystemObject")
strDir = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\") - 1)

' ── ตรวจว่า server เปิดอยู่แล้วหรือไม่ ──────────────────────
Set oExec = oShell.Exec("cmd /c netstat -ano | findstr "":4000 "" | findstr ""LISTENING""")
strOut = oExec.StdOut.ReadAll()

If Len(Trim(strOut)) = 0 Then
  ' เริ่ม server แบบซ่อน window (0 = hidden)
  strNode   = Chr(34) & strDir & "\node.exe" & Chr(34)
  strServer = Chr(34) & strDir & "\server.js" & Chr(34)
  oShell.Run strNode & " " & strServer, 0, False
  WScript.Sleep 2500
End If

' ── เปิด browser ──────────────────────────────────────────────
If oFSO.FileExists(strDir & "\config.json") Then
  oShell.Run "http://localhost:4000/dashboard.html"
Else
  oShell.Run "http://localhost:4000/settings.html"
End If

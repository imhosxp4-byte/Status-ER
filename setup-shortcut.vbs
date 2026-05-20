' ER Status — สร้าง Shortcut บน Desktop
' รันไฟล์นี้ครั้งเดียว เพื่อสร้างไอคอนบน Desktop

Set oWS  = WScript.CreateObject("WScript.Shell")
strDir   = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\") - 1)
strDesk  = oWS.SpecialFolders("Desktop")

' ── สร้าง shortcut บน Desktop ─────────────────────────────
Set oLink = oWS.CreateShortcut(strDesk & "\ER Status Dashboard.lnk")
oLink.TargetPath       = strDir & "\launch.vbs"
oLink.WorkingDirectory = strDir
oLink.Description      = "ER Status Dashboard - ระบบแสดงสถานะห้องฉุกเฉิน"
oLink.IconLocation     = "%SystemRoot%\system32\shell32.dll, 23"
oLink.Save

' ── ลงทะเบียนเปิดตอน Windows เริ่ม ───────────────────────
Dim startupPath
startupPath = oWS.SpecialFolders("Startup") & "\ER-Status-Launch.vbs"

Dim oFSO
Set oFSO = CreateObject("Scripting.FileSystemObject")
oFSO.CopyFile strDir & "\launch.vbs", startupPath, True

' ── แจ้งผล ────────────────────────────────────────────────
MsgBox "ตั้งค่าเรียบร้อยแล้ว!" & Chr(10) & Chr(10) & _
       "✅ สร้าง Shortcut 'ER Status Dashboard' บน Desktop" & Chr(10) & _
       "✅ ลงทะเบียนเปิดอัตโนมัติตอน Windows เริ่ม" & Chr(10) & Chr(10) & _
       "วิธีใช้งาน:" & Chr(10) & _
       "  ดับเบิลคลิก 'ER Status Dashboard' บน Desktop" & Chr(10) & _
       "  หรือ รัน autostart.bat ครั้งแรก", _
       vbInformation, "ER Status System"

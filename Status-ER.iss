; ============================================================
;  Status ER — Inno Setup 6 Installer Script
;  https://github.com/imhosxp4-byte/Status-ER
; ============================================================

#define MyAppName      "Status ER"
#define MyAppVersion   "1.0.0"
#define MyAppPublisher "imhosxp4-byte"
#define MyAppURL       "https://github.com/imhosxp4-byte/Status-ER"
#define SrcDir         "C:\Users\MS-10\Desktop\Status-ER"

[Setup]
AppId={{D7684450-FFD4-42FC-91E3-1C50A684D546}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\StatusER
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir={#SrcDir}\dist
OutputBaseFilename=Status-ER-Setup
SetupIconFile={#SrcDir}\build\status-er.ico
UninstallDisplayName={#MyAppName}
UninstallDisplayIcon={app}\status-er.ico
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
CloseApplications=yes
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "สร้าง Desktop Shortcut"; GroupDescription: "ตั้งค่าเพิ่มเติม:"; Flags: checkedonce

; ── ไฟล์ทั้งหมดที่ติดตั้ง ───────────────────────────────────
[Files]

; Node.js runtime (bundled — ไม่ต้องใช้อินเตอร์เน็ต)
Source: "C:\Program Files\nodejs\node.exe"; DestDir: "{app}"; Flags: ignoreversion

; Launcher scripts
Source: "{#SrcDir}\build\launch.vbs";      DestDir: "{app}"; Flags: ignoreversion
Source: "{#SrcDir}\build\stop-server.vbs"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SrcDir}\build\status-er.ico";   DestDir: "{app}"; Flags: ignoreversion

; Web UI
Source: "{#SrcDir}\dashboard.html"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SrcDir}\tv.html";        DestDir: "{app}"; Flags: ignoreversion
Source: "{#SrcDir}\index.html";     DestDir: "{app}"; Flags: ignoreversion
Source: "{#SrcDir}\settings.html";  DestDir: "{app}"; Flags: ignoreversion

; Server
Source: "{#SrcDir}\server.js";          DestDir: "{app}"; Flags: ignoreversion
Source: "{#SrcDir}\package.json";       DestDir: "{app}"; Flags: ignoreversion
Source: "{#SrcDir}\package-lock.json";  DestDir: "{app}"; Flags: ignoreversion
Source: "{#SrcDir}\config.example.json"; DestDir: "{app}"; Flags: ignoreversion

; DB config (pre-configured — เชื่อมต่อได้ทันทีหลังติดตั้ง)
Source: "{#SrcDir}\config.json"; DestDir: "{app}"; Flags: ignoreversion

; node_modules (pre-installed — offline ใช้ได้ทันที)
Source: "{#SrcDir}\node_modules\*"; DestDir: "{app}\node_modules"; \
  Flags: ignoreversion recursesubdirs createallsubdirs

; ── Shortcuts ────────────────────────────────────────────────
[Icons]
; Start Menu
Name: "{group}\เปิด Status ER";   Filename: "{sys}\wscript.exe"; \
  Parameters: """{app}\launch.vbs"""; WorkingDir: "{app}"; \
  IconFilename: "{app}\status-er.ico"; Comment: "เปิดระบบ ER Status Dashboard"

Name: "{group}\หยุด Server";       Filename: "{sys}\wscript.exe"; \
  Parameters: """{app}\stop-server.vbs"""; WorkingDir: "{app}"; \
  IconFilename: "{app}\status-er.ico"; Comment: "หยุด ER Status Server"

Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"; \
  IconFilename: "{app}\status-er.ico"

; Desktop shortcut (ติ๊กถามผู้ใช้)
Name: "{commondesktop}\Status ER"; Filename: "{sys}\wscript.exe"; \
  Parameters: """{app}\launch.vbs"""; WorkingDir: "{app}"; \
  IconFilename: "{app}\status-er.ico"; Comment: "เปิดระบบ ER Status Dashboard"; \
  Tasks: desktopicon

; ── หลังติดตั้ง ──────────────────────────────────────────────
[Run]
Filename: "{sys}\wscript.exe"; \
  Parameters: """{app}\launch.vbs"""; \
  Description: "เปิดโปรแกรม Status ER ทันที"; \
  Flags: postinstall nowait skipifsilent

; ── ก่อนถอนติดตั้ง ───────────────────────────────────────────
[UninstallRun]
Filename: "cmd.exe"; \
  Parameters: "/c for /f ""tokens=5"" %a in ('netstat -ano ^| findstr :4000 ^| findstr LISTENING') do taskkill /F /PID %a"; \
  Flags: runhidden; RunOnceId: "KillNode4000"

; ── Pascal Script ────────────────────────────────────────────
[Code]
procedure CurStepChanged(CurStep: TSetupStep);
var
  ResultCode: Integer;
begin
  if CurStep = ssInstall then
  begin
    // หยุด server เก่าก่อนติดตั้ง
    Exec('cmd.exe',
      '/c for /f "tokens=5" %a in (''netstat -ano ^| findstr :4000 ^| findstr LISTENING'') do taskkill /F /PID %a',
      '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    Sleep(600);
  end;
end;

#define MyAppName "hentai_library"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "hentai_library"
#define MyAppExeName "hentai_library.exe"
#define MySourceDir "build\windows\x64\runner\Release"
#define MyAppId "{{8FCD170B-6A2A-47A9-8FB9-89B84DABEEA5}"

#ifexist "windows\runner\resources\app_icon.ico"
  #define MySetupIconFile "windows\runner\resources\app_icon.ico"
#endif

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=dist_installer
OutputBaseFilename={#MyAppName}_Setup_{#MyAppVersion}_x64
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
ShowLanguageDialog=no
LanguageDetectionMethod=uilanguage
#ifdef MySetupIconFile
SetupIconFile={#MySetupIconFile}
#endif

[Languages]
Name: "chinesesimp"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加任务:"; Flags: unchecked

[Files]
Source: "{#MySourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "启动 {#MyAppName}"; Flags: nowait postinstall skipifsilent

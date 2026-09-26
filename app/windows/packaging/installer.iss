#define MyAppName "hentai_library"
#ifndef MyAppVersion
  #define MyAppVersion "0.0.1"
#endif
#ifndef OutputDir
  #define OutputDir "..\..\..\dist"
#endif
#define MyAppPublisher "hentai_library"
#define MyAppExeName "hentai_library.exe"
#define MySourceDir "..\..\build\windows\x64\runner\Release"
#define MyAppId "{{8FCD170B-6A2A-47A9-8FB9-89B84DABEEA5}"

#ifexist "..\runner\resources\app_icon.ico"
  #define MySetupIconFile "..\runner\resources\app_icon.ico"
#endif

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir={#OutputDir}
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
Name: "chinesesimp"; MessagesFile: "ChineseSimplified.isl"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加任务:"; Flags: unchecked

[Files]
Source: "{#MySourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "启动 {#MyAppName}"; Flags: nowait postinstall skipifsilent

[Code]
var
  DeleteUserDataCheckBox: TNewCheckBox;
  DeleteUserDataHintLabel: TNewStaticText;

procedure InitializeUninstallProgressForm();
begin
  DeleteUserDataHintLabel := TNewStaticText.Create(UninstallProgressForm);
  DeleteUserDataHintLabel.Parent := UninstallProgressForm;
  DeleteUserDataHintLabel.Caption := '请先关闭应用以确保数据完全删除。';
  DeleteUserDataHintLabel.Left := ScaleX(8);
  DeleteUserDataHintLabel.Top := UninstallProgressForm.ProgressBar.Top + ScaleY(24);
  DeleteUserDataHintLabel.Width := UninstallProgressForm.Width - ScaleX(16);
  DeleteUserDataHintLabel.AutoSize := False;
  DeleteUserDataHintLabel.WordWrap := True;

  DeleteUserDataCheckBox := TNewCheckBox.Create(UninstallProgressForm);
  DeleteUserDataCheckBox.Parent := UninstallProgressForm;
  DeleteUserDataCheckBox.Caption := '同时删除用户数据（数据库、元数据备份、日志与缓存）';
  DeleteUserDataCheckBox.Left := ScaleX(8);
  DeleteUserDataCheckBox.Top := DeleteUserDataHintLabel.Top + ScaleY(28);
  DeleteUserDataCheckBox.Width := UninstallProgressForm.Width - ScaleX(16);
  DeleteUserDataCheckBox.Checked := False;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  UserDataDir: String;
begin
  if CurUninstallStep = usPostUninstall then
  begin
    if DeleteUserDataCheckBox.Checked then
    begin
      UserDataDir := ExpandConstant('{userappdata}\com.example\hentai_library');
      if DirExists(UserDataDir) then
      begin
        DelTree(UserDataDir, True, True, True);
      end;
    end;
  end;
end;

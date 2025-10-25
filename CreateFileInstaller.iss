; ===================================================================
; CreateFile Installer (Inno Setup Script)
; ===================================================================

[Setup]
; --- App metadata ---
AppId={{7C8A9A3B-BAA7-4B8A-9A96-7E470C7302F0}}
AppName=CreateFile
AppVersion=0.0.2
VersionInfoVersion=0.0.2
AppPublisher=NiZhaZi
; AppPublisherURL=https://example.com
DefaultDirName={autopf}\CreateFile
DefaultGroupName=CreateFile
OutputBaseFilename=CreateFile-0.0.2-x86_64-Setup
OutputDir=output
WizardStyle=modern

; --- Install behavior ---
Compression=lzma2
SolidCompression=yes
PrivilegesRequired=admin
; Broadcast environment changes after install/uninstall
ChangesEnvironment=yes
ArchitecturesAllowed=x86 x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Dirs]
; Ensure a "bin" directory exists under the app folder
Name: "{app}\bin"

[Files]
; NOTE: Place "createFile.exe" next to this .iss or update the Source path below.
Source: "createFile.exe"; DestDir: "{app}\bin"; Flags: ignoreversion

[Icons]
; (Optional) Start Menu shortcut to the tool
Name: "{group}\CreateFile"; Filename: "{app}\bin\createFile.exe"; WorkingDir: "{app}\bin"
; (Optional) Uninstall shortcut
Name: "{group}\Uninstall CreateFile"; Filename: "{uninstallexe}"

[Registry]
; === Explorer Right-Click (Context Menu) entries ===
; 1) Right-click on empty background inside a folder
Root: HKCR; Subkey: "Directory\Background\shell\Create File"; ValueType: string; ValueName: ""; ValueData: "Create File"; Flags: uninsdeletekey
Root: HKCR; Subkey: "Directory\Background\shell\Create File"; ValueType: string; ValueName: "Icon"; ValueData: "{app}\bin\createFile.exe"
Root: HKCR; Subkey: "Directory\Background\shell\Create File\command"; ValueType: string; ValueName: ""; ValueData: """{app}\bin\createFile.exe"""

; 2) Right-click on a folder itself
Root: HKCR; Subkey: "Directory\shell\Create File"; ValueType: string; ValueName: ""; ValueData: "Create File"; Flags: uninsdeletekey
Root: HKCR; Subkey: "Directory\shell\Create File"; ValueType: string; ValueName: "Icon"; ValueData: "{app}\bin\createFile.exe"
Root: HKCR; Subkey: "Directory\shell\Create File\command"; ValueType: string; ValueName: ""; ValueData: """{app}\bin\createFile.exe"" ""%1"""

; If you also want a context menu on *all files*, uncomment below:
; Root: HKCR; Subkey: "*\shell\Create File"; ValueType: string; ValueName: ""; ValueData: "Create File"; Flags: uninsdeletekey
; Root: HKCR; Subkey: "*\shell\Create File"; ValueType: string; ValueName: "Icon"; ValueData: "{app}\bin\createFile.exe"
; Root: HKCR; Subkey: "*\shell\Create File\command"; ValueType: string; ValueName: ""; ValueData: """{app}\bin\createFile.exe"" ""%1"""

[Code]
// -------------------------------------------------------------------
// PATH handling: add {app}\bin to PATH on install, remove on uninstall
// Robustly avoids duplicates and cleans up during uninstall.
// -------------------------------------------------------------------

const
  EnvKey = 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment';

function ReadEnvPath(RootKey: Integer; var Value: string): Boolean;
begin
  Result := RegQueryStringValue(RootKey, EnvKey, 'Path', Value);
end;

function TokenEquals(a, b: string): Boolean;
begin
  Result := UpperCase(Trim(a)) = UpperCase(Trim(b));
end;

function PathContainsToken(Path, Token: string): Boolean;
var
  rest, part: string;
  p: Integer;
begin
  rest := Path;
  Result := False;
  while rest <> '' do
  begin
    p := Pos(';', rest);
    if p = 0 then
    begin
      part := rest;
      rest := '';
    end
    else
    begin
      part := Copy(rest, 1, p - 1);
      Delete(rest, 1, p);
    end;
    if TokenEquals(part, Token) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function BuildPathWithoutToken(Path, Token: string): string;
var
  rest, part: string;
  p: Integer;
begin
  rest := Path;
  Result := '';
  while rest <> '' do
  begin
    p := Pos(';', rest);
    if p = 0 then
    begin
      part := rest;
      rest := '';
    end
    else
    begin
      part := Copy(rest, 1, p - 1);
      Delete(rest, 1, p);
    end;
    if not TokenEquals(part, Token) then
    begin
      if Result = '' then
        Result := part
      else
        Result := Result + ';' + part;
    end;
  end;
end;

function AppendToEnvPath(RootKey: Integer; DirToAdd: string): Boolean;
var
  OldPath, NewPath: string;
begin
  if not ReadEnvPath(RootKey, OldPath) then
    OldPath := '';

  if PathContainsToken(OldPath, DirToAdd) then
  begin
    Result := True; // already present
    Exit;
  end;

  if OldPath <> '' then
    NewPath := OldPath + ';' + DirToAdd
  else
    NewPath := DirToAdd;

  Result := RegWriteExpandStringValue(RootKey, EnvKey, 'Path', NewPath);
end;

function RemoveFromEnvPath(RootKey: Integer; DirToRemove: string): Boolean;
var
  OldPath, NewPath: string;
begin
  if not ReadEnvPath(RootKey, OldPath) then
  begin
    Result := True;
    Exit;
  end;

  NewPath := BuildPathWithoutToken(OldPath, DirToRemove);
  if NewPath = OldPath then
  begin
    Result := True; // nothing to do
    Exit;
  end;

  Result := RegWriteExpandStringValue(RootKey, EnvKey, 'Path', NewPath);
end;

procedure AddAppBinToPath;
var
  dir: string;
begin
  dir := ExpandConstant('{app}\bin');
  // Prefer system-wide PATH (requires admin). Fall back to user PATH.
  if not AppendToEnvPath(HKEY_LOCAL_MACHINE, dir) then
    AppendToEnvPath(HKEY_CURRENT_USER, dir);
end;

procedure RemoveAppBinFromPath;
var
  dir: string;
begin
  dir := ExpandConstant('{app}\bin');
  // Try to remove from both system and user PATH (harmless if not present).
  RemoveFromEnvPath(HKEY_LOCAL_MACHINE, dir);
  RemoveFromEnvPath(HKEY_CURRENT_USER, dir);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    AddAppBinToPath;
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
  begin
    RemoveAppBinFromPath;
  end;
end;

; Inno Setup Script File - createFile.iss
; For creating install package for createFile.exe

[Setup]
; Application information
AppName=createFile
AppVersion=0.0.1
AppPublisher=Your Company Name
DefaultDirName={autopf}\createFile
DefaultGroupName=createFile
OutputDir=Output
OutputBaseFilename=createFile_Setup
; SetupIconFile=createFile.ico  ; Optional: if you have an icon file
Compression=lzma
SolidCompression=yes
PrivilegesRequired=admin
; Optional: let advanced users override via UI or /ALLUSERS /CURRENTUSER
; PrivilegesRequiredOverridesAllowed=dialog

; Uninstall information
UninstallDisplayIcon={app}\bin\createFile.exe
UninstallDisplayName=createFile

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
; Install createFile.exe to bin directory
Source: "createFile.exe"; DestDir: "{app}\bin"; Flags: ignoreversion

[Registry]
; Add to right-click context menu - appears when right-clicking on folder background
Root: HKCR; Subkey: "Directory\Background\shell\createFile"; ValueType: string; ValueName: ""; ValueData: "Create File with createFile"; Flags: uninsdeletekey
Root: HKCR; Subkey: "Directory\Background\shell\createFile"; ValueType: string; ValueName: "Icon"; ValueData: "{app}\bin\createFile.exe"; Flags: uninsdeletekey
Root: HKCR; Subkey: "Directory\Background\shell\createFile\command"; ValueType: string; ValueName: ""; ValueData: """{app}\bin\createFile.exe"" ""%V"""; Flags: uninsdeletekey

; Optional: Add to file right-click menu (if you want it to appear when right-clicking files)
Root: HKCR; Subkey: "*\shell\createFile"; ValueType: string; ValueName: ""; ValueData: "Process with createFile"; Flags: uninsdeletekey
Root: HKCR; Subkey: "*\shell\createFile"; ValueType: string; ValueName: "Icon"; ValueData: "{app}\bin\createFile.exe"; Flags: uninsdeletekey
Root: HKCR; Subkey: "*\shell\createFile\command"; ValueType: string; ValueName: ""; ValueData: """{app}\bin\createFile.exe"" ""%1"""; Flags: uninsdeletekey

; Add to PATH environment variable
Root: HKLM; Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; ValueType: expandsz; ValueName: "Path"; ValueData: "{olddata};{app}\bin"; Check: NeedsAddPath('{app}\bin')

[Code]
// Function to check if PATH needs to be updated
function NeedsAddPath(Param: string): boolean;
var
  OrigPath: string;
begin
  if not RegQueryStringValue(HKEY_LOCAL_MACHINE,
    'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
    'Path', OrigPath)
  then begin
    Result := True;
    exit;
  end;
  
  // Look for the path with leading and trailing semicolon
  // Pos() returns 0 if not found
  Result := Pos(';' + Param + ';', ';' + OrigPath + ';') = 0;
  
  // Also check if it's at the beginning or end
  if Result then
    Result := (Pos(Param + ';', OrigPath) <> 1) and (Pos(';' + Param, OrigPath) <> Length(OrigPath) - Length(Param));
end;

// Alternative method to add to PATH if registry method doesn't work
procedure CurStepChanged(CurStep: TSetupStep);
var
  Path: string;
  BinPath: string;
begin
  if CurStep = ssPostInstall then
  begin
    // Get system PATH environment variable
    if RegQueryStringValue(HKEY_LOCAL_MACHINE, 
      'SYSTEM\CurrentControlSet\Control\Session Manager\Environment', 
      'Path', Path) then
    begin
      // Set bin directory path
      BinPath := ExpandConstant('{app}\bin');
      
      // Check if path already contains bin directory
      if Pos(BinPath, Path) = 0 then
      begin
        // Add bin directory to PATH
        Path := Path + ';' + BinPath;
        RegWriteStringValue(HKEY_LOCAL_MACHINE, 
          'SYSTEM\CurrentControlSet\Control\Session Manager\Environment', 
          'Path', Path);
        
        // Broadcast environment change
        BroadcastEnvironmentMessage;
      end;
    end;
  end;
end;

// Broadcast environment change message
procedure BroadcastEnvironmentMessage;
var
  Msg: LongWord;
  Res: LongInt;
begin
  Msg := RegisterWindowMessage('EnvironmentChanged');
  SendNotifyMessage(HWND_BROADCAST, Msg, 0, 0);
  Res := BroadcastSystemMessage($FFFF, nil, $1A {WM_SETTINGCHANGE}, 0, LongInt(PChar('Environment')));
end;

// Clean up during uninstall
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  Path: string;
  BinPath: string;
  NewPath: string;
  PosStart: Integer;
begin
  if CurUninstallStep = usPostUninstall then
  begin
    // Get system PATH environment variable
    if RegQueryStringValue(HKEY_LOCAL_MACHINE, 
      'SYSTEM\CurrentControlSet\Control\Session Manager\Environment', 
      'Path', Path) then
    begin
      // Set the bin directory path to remove
      BinPath := ExpandConstant('{app}\bin');
      
      // Remove bin directory from PATH
      PosStart := Pos(BinPath, Path);
      if PosStart > 0 then
      begin
        // Remove the path (including the preceding semicolon if not at start)
        if PosStart = 1 then
        begin
          // At beginning, remove path and following semicolon
          NewPath := Copy(Path, Length(BinPath) + 2, MaxInt)
        end
        else
        begin
          // In middle or end, remove preceding semicolon and path
          NewPath := Copy(Path, 1, PosStart - 2) + Copy(Path, PosStart + Length(BinPath), MaxInt);
        end;
        
        // Update PATH environment variable
        RegWriteStringValue(HKEY_LOCAL_MACHINE, 
          'SYSTEM\CurrentControlSet\Control\Session Manager\Environment', 
          'Path', NewPath);
        
        // Broadcast environment change
        BroadcastEnvironmentMessage;
      end;
    end;
  end;
end;

[Run]
; Optional: Show prompt after installation
Filename: "{app}\bin\createFile.exe"; Description: "Launch createFile"; Flags: nowait postinstall skipifsilent

[Icons]
; Create shortcuts in Start Menu
Name: "{group}\createFile"; Filename: "{app}\bin\createFile.exe"
Name: "{group}\Uninstall createFile"; Filename: "{uninstallexe}"
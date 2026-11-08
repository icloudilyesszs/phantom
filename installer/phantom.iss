; Installateur Windows de Phantom (Inno Setup)

[Setup]
AppId={{6F3B8C2A-91D4-4E7B-A5C1-PHANTOM00001}
AppName=Phantom
AppVersion=1.0
AppPublisher=Phantom
DefaultDirName={localappdata}\Programs\Phantom
DefaultGroupName=Phantom
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=Output
OutputBaseFilename=Phantom-Setup
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\Phantom.exe
Compression=lzma2
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64compatible
ArchitecturesAllowed=x64compatible

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "Créer une icône sur le Bureau"; GroupDescription: "Raccourcis :"

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Phantom"; Filename: "{app}\Phantom.exe"
Name: "{autodesktop}\Phantom"; Filename: "{app}\Phantom.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\Phantom.exe"; Description: "Lancer Phantom"; Flags: nowait postinstall skipifsilent

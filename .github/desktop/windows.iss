[Setup]
AppId=InfiniteCanvasDesktop
AppName=无限画布
AppVersion={#ReleaseVersion}
DefaultDirName={localappdata}\Programs\Infinite Canvas
DefaultGroupName=无限画布
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#ReleaseOutput}
OutputBaseFilename=InfiniteCanvas-v{#ReleaseVersion}-win-x64-setup
Compression=lzma2/fast
SolidCompression=yes
UninstallDisplayIcon={app}\无限画布.exe
WizardStyle=modern

[Files]
Source: "{#BundleDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\无限画布"; Filename: "{app}\无限画布.exe"; WorkingDir: "{app}"

[Run]
Filename: "{app}\无限画布.exe"; Description: "启动无限画布"; Flags: nowait postinstall skipifsilent

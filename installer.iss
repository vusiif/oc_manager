; OC Manager 安装脚本
; 用 Inno Setup 编译

[Setup]
AppName=OC Manager
AppVersion=1.1.0
AppPublisher=OC Manager
AppPublisherURL=https://github.com/vusiif/oc_manager
DefaultDirName={autopf}\OC Manager
DefaultGroupName=OC Manager
OutputBaseFilename=OCManager_Setup_v1.1.0
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
SetupIconFile=
UninstallDisplayIcon={app}\oc_manager.exe
LicenseFile=LICENSE
LanguageDetectionMethod=uilanguage
ShowLanguageDialog=yes

[Languages]
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Messages]
WelcomeLabel1=欢迎安装 OC Manager%n%nOC Manager 是一个原创角色（OC）管理工具，帮助您管理世界观、人物关系、标签等信息。%n%n本程序基于 MIT 开源协议发布，源代码托管在 GitHub：%nhttps://github.com/vusiif/oc_manager%n%n点击"下一步"继续安装。
FinishedLabel=OC Manager 已成功安装到您的电脑上。%n%n您可以通过桌面快捷方式或开始菜单启动程序。%n%n感谢使用 OC Manager！

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加图标:"
Name: "quicklaunchicon"; Description: "创建快速启动栏快捷方式"; GroupDescription: "附加图标:"; Flags: unchecked

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\OC Manager"; Filename: "{app}\oc_manager.exe"
Name: "{group}\卸载 OC Manager"; Filename: "{uninstallexe}"
Name: "{autodesktop}\OC Manager"; Filename: "{app}\oc_manager.exe"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\OC Manager"; Filename: "{app}\oc_manager.exe"; Tasks: quicklaunchicon

[Run]
Filename: "{app}\oc_manager.exe"; Description: "启动 OC Manager"; Flags: nowait postinstall skipifsilent

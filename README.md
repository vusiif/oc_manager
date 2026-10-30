# OC Manager (二创与原创角色人设管理工作台)

<p align="center">
  <img src="https://img.shields.io/badge/Version-v1.1.0-6366F1?style=flat-square" alt="Version" />
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white&style=flat-square" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white&style=flat-square" alt="Dart" />
  <img src="https://img.shields.io/badge/Platform-Windows%20%7C%20Android-4CAF50?style=flat-square" alt="Platform" />
  <img src="https://img.shields.io/badge/Database-SQLite%20%2F%20Drift-003B57?logo=sqlite&logoColor=white&style=flat-square" alt="SQLite" />
  <img src="https://img.shields.io/badge/Tests-16%2F16%20Passed-brightgreen?style=flat-square" alt="Tests" />
  <img src="https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square" alt="License" />
</p>

**OC Manager** 是一款专为小说创作者、漫画家、跑团（TRPG）玩家及二创爱好者打造的**本地优先、隐私安全、高颜值**的角色人设（Original Character）与世界观设定管理工作台。

界面深度参考 **AppFlowy** 式现代桌面三栏信息架构，人物卡片汲取 **Milanote** 视觉展示语言，关系图谱对齐 **Obsidian Canvas** 交互体验，并采用 **SQLite + Drift** 强类型数据库保障数据底座的绝对安全。

---

## 🌟 核心特性

### 1. 多世界观与设定工作区 (Worldbuilding Hub)
- **多空间强隔离**：支持创建多个独立世界观，底层 DAO 事务与分组严格拦截跨世界观数据渗透；
- **桌面端信息中枢**：卡片式网格 Hub 概览，快捷进入人物列表、关系图谱及设置；
- **分层组织架构**：树状层级导航（`工作台 > 世界观 > 分组 > 人物`），支持人物多对多分组归属与平滑拖拽归档；
- **丝滑抽屉侧边栏**：基于 `ClipRect + AnimatedAlign` 架构的 250ms 缓动折叠过渡，彻底消除文字挤压溢出与离屏焦点误触。

### 2. 人设档案与自定义扩展体系 (OC Character Profiles)
- **统一人设卡片 (`OcCard`)**：自适应浅色/深色主题，支持悬停动态光晕微动效、草稿/正式状态标识、收藏与置顶快捷切换；
- **精准局部更新 (`updatePartial`)**：置顶与收藏切换仅对目标属性原子写入，杜绝旧版全行覆盖意外抹除性别或生平小传的隐患；
- **本地沙盒立绘管理**：图片立绘持久化至应用私有沙盒 `avatars/` 目录，以相对路径存储，跨机备份恢复与设备迁移永不失效；
- **多元性别语义**：支持男、女及自定义性别，卡片与图谱自适应语义色相与几何形状徽章；
- **多维扩展字段**：内置基本信息、背景故事大文本（失焦自动保存）、多类型自定义字段（文本/数值/日期/选项），支持全局模版快速套用。

### 3. 可视化人物关系与家谱图谱 (Relation & Family Canvas)
- **Obsidian Canvas 交互对齐**：
  - **边缘悬停手柄直连**：鼠标移至人物节点边缘自动浮现 `+` 手柄，拖拽预览连线至目标人物一键建立关系；
  - **连线选中高亮与管理**：点击关系线呈现品牌色光晕（Halo Glow），唤起“双向/单向切换”、“反转箭头”、“编辑备注”、“安全删除”四合一快捷弹窗；
- **精确外框几何算法 (`GraphGeometry`)**：
  - 依据男性（矩形）、女性（圆形）、其他（菱形）边界精确求解光线相交切点，连线与箭头严密贴合节点外轮廓，彻底消除箭头穿透节点内部的视觉缺陷；
- **多重关系与反向边支持**：同对人物多重关系自适应走弧线排版，根据真实方向独立计算正反向与切线偏角；
- **遗传图谱家谱树**：支持单亲、双亲、多子女的复杂家族谱系连线渲染；
- **自适应居中与缩放 (Fit to View)**：一键平滑计算节点包围盒并居中呈现全图；
- **无损 PNG 导出**：基于底层矢量 `PictureRecorder` + `Canvas` 自动计算节点外接矩形与安全边距，将整张关系图无损导出为高清 PNG 图片。

### 4. 现代排版与系统级色彩体验 (Design & Typography)
- **Windows 高品质中文字体链**：配置 `AppFonts` 跨平台回退链（Windows 优先采用 `Microsoft YaHei UI`、macOS/iOS 优先采用 `PingFang SC`），并在全局主题与自绘画布中统一注入，彻底根除 Windows DirectWrite 默认回退为老旧宋体导致的粗糙、发虚视觉瑕疵；
- **默认跟随系统主题**：开箱即用完美契合 Windows / macOS 系统的深色与浅色偏好，且支持偏好持久化存储与设置页无感切换；
- **暗色自适应徽标**：关系图标签采用自适应胶囊设计，深色模式下呈现舒适的半透明深灰底色与清晰白字，消除刺眼白底色块。

### 5. 工业级数据安全底座 (Bulletproof Data Engine)
- **SQLite 在线一致性备份**：采用 `PRAGMA wal_checkpoint(FULL)` + `VACUUM INTO` 机制，生成事务一致的独立快照，避免锁冲突；
- **还原点与原子回滚**：数据恢复前自动创建本地 `.rollback_bak` 还原点，执行 `PRAGMA integrity_check` 完整性校验，发生异常自动原子回退；
- **全量级联回收站**：删除人物/世界观时将其子字段、标签、分组映射、画布坐标全量打包快照，恢复时 100% 等价还原；
- **自动级联清理**：删除标签、世界观或模板时同步清理全部关联记录，根除孤儿数据残留。

---

## 🛠️ 技术栈

| 分层 | 技术选型 | 说明 |
| :--- | :--- | :--- |
| **UI 框架** | Flutter 3.x (Stable) | 深度适配 Windows 桌面端，兼顾 Android |
| **状态管理** | Flutter Riverpod 2.6+ | 声明式响应流与全局依赖解耦 |
| **数据持久化** | Drift 2.22+ & SQLite3 | 强类型 ORM，支持异步事务、DAO 模块化与自动迁移 |
| **路由导航** | GoRouter 14.8+ | 声明式路由（支持深链直达人物详情） |
| **系统交互** | FilePicker & ImagePicker | 跨平台文件导出、数据库备份与立绘安全沙盒存储 |
| **打包分发** | Inno Setup 6.7+ | Windows 工业级单文件安装包（快捷方式、开机菜单与卸载程序） |

---

## 📂 项目结构

```text
lib/
├── core/                        # 核心底座与设计系统
│   ├── design/                  # 设计规范 Tokens 与高保真组件
│   │   ├── design_tokens.dart   # 色彩阶梯、间距、圆角统一规范
│   │   └── components/          # OcCard, OcAvatar, EmptyStateView, showConfirmDialog
│   ├── storage/                 # 本地资产与沙盒管理 (ImageStorageService)
│   └── theme/                   # 全局浅色/深色主题与字体链配置 (AppTheme, AppFonts)
├── data/database/               # 数据持久层
│   ├── app_database.dart        # Drift SQLite 核心实例与备份/恢复/校验实现
│   ├── daos/                    # 业务数据访问对象 (Character, World, Group, Relation, etc.)
│   └── tables/                  # 数据库表结构定义
├── features/                    # 业务功能模块
│   ├── character/               # 人物详情页、人物创建/编辑弹窗
│   ├── main_shell.dart          # 桌面三栏工作台架构、动效侧边栏与动态面包屑
│   ├── relation/                # 关系图谱画布、几何算法 (GraphGeometry)、PNG 导出
│   ├── settings/                # 主题偏好、SQLite 在线备份与回滚恢复
│   ├── sidebar/                 # 树状层级导航与跨世界观防穿透拖拽 (TreeSidebar)
│   ├── template/                # 自定义人设模板管理与字段配置
│   ├── trash/                   # 全量关联级联回收站
│   └── world/                   # 世界观卡片网格 Hub 与详情页
└── providers/                   # Riverpod 状态管理与业务调度层
```

---

## 🚀 快速上手与本地构建

### 前置环境要求
1. **Flutter SDK**：`^3.47.0` 或更高版本（Channel stable）；
2. **Dart SDK**：`^3.13.0`；
3. **Windows 桌面开发负载**：Visual Studio 2022 生成工具（包含“使用 C++ 的桌面开发”工作负载）；
4. **Inno Setup**（如需打包 Windows 安装包）：Inno Setup 6.x+；
5. **Android SDK**（如需构建 Android APK）：API Level 33+。

### 安装依赖与运行
```bash
# 1. 克隆代码库
git clone https://github.com/vusiif/oc_manager.git
cd oc_manager

# 2. 安装 Flutter 依赖包
flutter pub get

# 3. 代码生成（若修改了 Drift 表结构）
dart run build_runner build --delete-conflicting-outputs

# 4. 运行静态代码检查（保证 0 issues）
flutter analyze

# 5. 运行完整自动化测试套件（16 项全部通过）
flutter test

# 6. 本地 Windows 桌面端调试运行
flutter run -d windows
```

### 构建与发布

#### 1. Windows Release 绿色免安装版
```bash
flutter build windows --release
```
编译产物生成于 `build/windows/x64/runner/Release/` 目录。

#### 2. Windows Inno Setup 安装包
已配置自动化打包脚本 [`installer.iss`](installer.iss)，在编译 Release 后执行：
```powershell
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer.iss
```
安装包将生成于 `Output/OCManager_Setup_v1.1.0.exe`（单文件安装包，内含完整 DLL 依赖与资源）。

#### 3. Android Release APK
```bash
flutter build apk --release
```
APK 产物生成于 `build/app/outputs/flutter-apk/app-release.apk`。

---

## 🧪 自动化测试验证

项目配置有严谨的单元测试、状态隔离与几何运算断言套件，采用内存数据库沙盒隔离，避免干扰生产数据：

- **`test/relation_logic_test.dart`**：
  - 关系对配对唯一性；
  - 正向边、反向边与箭头切线偏角判定；
  - 增量坐标同步；
  - 女性（圆形）、男性（矩形）、其他（菱形）外边框精确相交射线算法。
- **`test/trash_and_isolation_test.dart`**：
  - 跨世界观分组强制数据隔离拒绝验证；
  - 软删除人物时关联字段、标签、分组全量快照与 100% 还原；
  - 收藏/置顶局部更新字段保护（杜绝抹除无关属性）；
  - `GraphLayouts` 历史多行重复记录容错与防膨胀验证。
- **`test/settings_theme_test.dart`**：
  - 设置项幂等读写与键冲突防御；
  - 全局默认主题跟随系统（`ThemeMode.system`）验证。
- **`test/widget_test.dart`**：
  - 应用核心主流程加载与 Widget 基础渲染断言；
  - 侧边栏缓动动画因子与状态折叠验证。

---

## 📄 开源许可证

本项目基于 [MIT License](LICENSE) 开源发布。

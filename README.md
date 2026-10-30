# OC Manager (二创与原创角色人设管理工作台)

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Platform-Windows%20%7C%20Android-4CAF50" alt="Platform" />
  <img src="https://img.shields.io/badge/Database-SQLite%20%2F%20Drift-003B57?logo=sqlite&logoColor=white" alt="SQLite" />
  <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License" />
</p>

**OC Manager** 是一款专为小说创作者、漫画家、跑团（TRPG）玩家及二创爱好者打造的**本地优先、隐私安全、高颜值**的角色人设（Original Character）与世界观设定管理工作台。

主界面参考 **AppFlowy** 式现代桌面三栏信息架构，人物卡片汲取 **Milanote** 视觉展示语言，关系图谱深度对齐 **Obsidian Canvas** 交互体验，并采用 **SQLite + Drift** 强类型数据库保障数据底座的绝对安全。

---

## 🌟 核心特性

### 1. 多世界观与设定工作区 (Worldbuilding Hub)
- **多空间强隔离**：支持创建多个独立世界观，严格拦截跨世界观脏数据渗透；
- **桌面端信息中枢**：卡片式网格 Hub 概览，支持快捷进入人物列表、关系图谱及设置；
- **分层组织架构**：树状层级导航（`工作台 > 世界观 > 分组 > 人物`），支持人物多对多归属与拖拽归档。

### 2. 人设档案与自定义扩展体系 (OC Character Profiles)
- **统一人设卡片 (`OcCard`)**：自适应浅色/深色主题，支持动态光晕微动效、草稿/正式状态标识、收藏置顶快捷切换；
- **本地沙盒立绘管理**：本地图片安全持久化至应用沙盒目录，采用相对路径存储，跨机导出迁移与备份恢复永不失效；
- **多元性别语义**：支持男、女及自定义性别，卡片与图谱自适应语义颜色与形状识别；
- **多维扩展字段**：内置基本信息、背景故事大文本（失焦自动保存）、多类型自定义字段，并支持全局字段模板套用。

### 3. 可视化人物关系与家谱图谱 (Relation & Family Canvas)
- **Obsidian Canvas 交互对齐**：
  - 节点边缘悬停手柄直连：鼠标移至人物卡片浮现 `+` 手柄，拖拽预览连线至目标人物直接建关系；
  - 连线点击高亮与快捷管理：点击关系线呈现品牌色光晕，快捷唤起“双向/单向切换”、“反转箭头”、“编辑备注”、“安全删除”四合一弹窗；
- **精确外框几何算法 (`GraphGeometry`)**：
  - 依据男性（矩形）、女性（圆形）、其他（菱形）边界精确求解切线交点，连线与箭头严密贴合节点外轮廓，彻底根除箭头穿透节点内部的缺陷；
- **多重关系与反向边支持**：同对人物多重关系自适应走弧线排版，正反向边箭头切线方向精准渲染；
- **遗传图谱家谱树**：完整支持单亲、双亲、多子女的家族分支树渲染；
- **自适应居中与缩放 (Fit to View)**：一键平滑计算节点包围盒并居中呈现全图；
- **无损 PNG 导出**：基于底层矢量 `PictureRecorder` 自动计算外接矩形与安全边距，将整张关系图无损导出为高清 PNG 图片。

### 4. 工业级数据安全底座 (Bulletproof Data Engine)
- **SQLite 在线一致性备份**：弃用简单的文件复制，采用 `PRAGMA wal_checkpoint(FULL)` + `VACUUM INTO` 生成事务一致的独立快照；
- **还原点与自动回滚**：数据恢复前自动创建本地 `.rollback_bak` 还原点，执行 `PRAGMA integrity_check` 完整性校验，发生异常自动原子回滚；
- **全量级联回收站**：删除人物/世界观时将其子字段、标签、分组映射、画布坐标全量打包快照，恢复时 100% 等价还原。

---

## 🛠️ 技术栈

| 分层 | 技术选型 | 说明 |
| :--- | :--- | :--- |
| **UI 框架** | Flutter 3.x (Stable) | 优先精细化适配 Windows 桌面端，兼顾 Android |
| **状态管理** | Flutter Riverpod 2.6+ | 声明式响应流与全局依赖解耦 |
| **数据持久化** | Drift 2.22+ & SQLite3 | 强类型 ORM，支持异步事务、DAO 模块化与自动迁移 |
| **路由导航** | GoRouter 14.8+ | 声明式深度链接路由（含详情页直达路由） |
| **系统交互** | FilePicker & ImagePicker | 跨平台文件导出、数据库备份与立绘安全存储 |

---

## 📂 项目结构

```text
lib/
├── core/                        # 核心底座与设计系统
│   ├── design/                  # 设计规范 Tokens 与高保真组件
│   │   ├── design_tokens.dart   # 色彩、间距、圆角统一规范
│   │   └── components/          # OcCard, OcAvatar, EmptyStateView, ConfirmationDialog
│   ├── storage/                 # 本地资产与沙盒管理 (ImageStorageService)
│   └── theme/                   # 全局浅色/深色主题配置 (AppTheme)
├── data/database/               # 数据底座
│   ├── app_database.dart        # Drift SQLite 核心实例与备份恢复实现
│   ├── daos/                    # 业务数据访问对象 (Character, World, Group, Relation, etc.)
│   └── tables/                  # 数据库表定义
├── features/                    # 业务功能模块
│   ├── character/               # 人物详情、人物创建/编辑弹窗
│   ├── main_shell.dart          # 桌面三栏工作台与动态面包屑导航
│   ├── relation/                # 关系图谱画布、几何算法 (GraphGeometry)、导出逻辑
│   ├── settings/                # 主题设置、SQLite 在线备份与回滚恢复
│   ├── trash/                   # 全量关联级联回收站
│   └── world/                   # 世界观卡片网格 Hub 与详情页
└── providers/                   # Riverpod 状态提供器与业务操作封装层
```

---

## 🚀 快速上手与本地构建

### 前置环境要求
1. **Flutter SDK**：`^3.47.0` 或更高版本（Channel stable）；
2. **Dart SDK**：`^3.13.0`；
3. **Windows 桌面开发负载**：Visual Studio 2022 生成工具（包含 C++ 桌面开发工作负载）；
4. **Android SDK**（如需构建 Android APK）：API Level 33+。

### 安装依赖与运行
```bash
# 1. 克隆代码库
git clone https://github.com/vusiif/oc_manager.git
cd oc_manager

# 2. 安装 Flutter 依赖包
flutter pub get

# 3. 代码生成（若修改了 Drift 表结构）
dart run build_runner build --delete-conflicting-outputs

# 4. 运行静态代码检查
flutter analyze

# 5. 运行完整自动化测试套件
flutter test

# 6. 本地桌面端调试运行
flutter run -d windows
```

### 构建生产发布产物
```bash
# 构建 Windows Release 可执行文件
flutter build windows --release

# 构建 Android Release APK
flutter build apk --release
```
Windows 产物生成于 `build\windows\x64\runner\Release\` 目录中。

---

## 🧪 自动化测试验证

项目配置有严谨的单元测试与逻辑断言套件，涵盖核心数据流与几何计算：
- `test/relation_logic_test.dart`：
  - 关系对配对唯一性；
  - 正向边、反向边与箭头切线判定；
  - 增量坐标同步；
  - 女性（圆形）、男性（矩形）、其他（菱形）边界相交精确算法验证。
- `test/trash_and_isolation_test.dart`：
  - 跨世界观分组强制数据隔离拒绝验证；
  - 软删除人物时关联字段、标签、分组全量快照与 100% 还原断言。
- `test/widget_test.dart`：应用核心主流程加载与 Widget 基础渲染断言。

---

## 📄 开源许可证

本项目基于 [MIT License](LICENSE) 开源发布。

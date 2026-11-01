# OC Manager (二创与原创角色人设管理工作台)

<p align="center">
  <img src="https://img.shields.io/badge/Version-v1.5.0-6366F1?style=flat-square" alt="Version" />
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white&style=flat-square" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white&style=flat-square" alt="Dart" />
  <img src="https://img.shields.io/badge/Platform-Windows%20%7C%20Android-4CAF50?style=flat-square" alt="Platform" />
  <img src="https://img.shields.io/badge/Database-SQLite%20%2F%20Drift%20v9-003B57?logo=sqlite&logoColor=white&style=flat-square" alt="SQLite" />
  <img src="https://img.shields.io/badge/Tests-59%2F59%20Passed-brightgreen?style=flat-square" alt="Tests" />
  <img src="https://img.shields.io/badge/Security-Hardened%20(XSS%20%26%20Sandbox)-orange?style=flat-square" alt="Security" />
  <img src="https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square" alt="License" />
</p>

**OC Manager** 是一款专为小说创作者、漫画家、跑团（TRPG）玩家及二创爱好者打造的**本地优先、隐私安全、高颜值**的角色人设（Original Character）与世界观设定管理工作台。

界面深度参考 **AppFlowy** 式现代桌面三栏信息架构，人物卡片汲取 **Milanote** 视觉展示语言，关系图谱对齐 **Obsidian Canvas** 交互体验，结合 **Notion** 多维矩阵与出版级设定集编译引擎，采用 **SQLite + Drift (Schema v9)** 强类型数据库保障数据底座的绝对安全。

---

## 🌟 核心特性与功能矩阵

### 1. 多世界观与三维视图矩阵 (Worldbuilding Hub & Views)
- **多空间强隔离**：支持创建多个独立世界观，底层 DAO 事务与分组严格拦截跨世界观数据渗透；
- **桌面端信息中枢**：卡片式网格 Hub 概览，一键直达经典卡片流、关系图谱、大事件编年史与数据大盘；
- **经典卡片视图 (Card Flow)**：自适应流式网格，支持悬停动态光晕微动效、状态胶囊、收藏与置顶快捷切换；
- **泳道看板视图 (Kanban Board)**：按“创作状态”（构思草稿 / 细化中 / 已定稿 / 历史归档）或“组织阵营”分列，支持卡片跨列拖拽（Drag & Drop）流转与实时持久化；
- **多维表格矩阵视图 (Table Matrix)**：Notion / Airtable 式高密度信息网格，支持按姓名、性别、状态、更新时间列排序、就地快速流转创作状态、多维搜索与过滤；
- **丝滑抽屉侧边栏**：基于 `ClipRect + AnimatedAlign` 架构的 250ms 缓动折叠过渡，彻底消除文字挤压溢出与离屏焦点误触。

### 2. 人设档案、能力雷达与差分画廊 (OC Profiles, Radar & Galleries)
- **六维能力/特质雷达图 (`RadarChart`)**：
  - 支持 3~8 维动态多边形自绘渲染，内置 4 套官方特质预设（战斗战力、RPG 跑团、现代社交、学识科研），支持自由编辑数值与最大基准；
- **差分相册画廊与色卡提取 (`CharacterGalleries`)**：
  - 支持单角色多姿态、差分表情与服装立绘管理，主封面原子同步；
  - **调色板 Hex 提取 (`PaletteExtractor`)**：自动分析图像像素聚类并提取 Top 5 代表性主题色，支持一键点击复制 Hex 颜色代码；
  - **全屏灯箱查看器**：双击与双指手势平滑缩放、图片详情说明与便捷幻灯切换；
- **人设排版长图海报导出 (`CharacterPosterDialog`)**：
  - 内置 4 套高保真视觉排版主题（**现代杂志 / 古典传奇 / 赛博霓虹 / 绝密档案**），智能聚合档案、六维雷达、生平轨迹与画廊切片；
  - 支持 **1x / 2x / 3x** 级无损高清 PNG 海报一键导出并支持打开目录定位。

### 3. 可视化人物关系与家谱图谱 (Obsidian-style Relation Canvas)
- **Obsidian Canvas 交互对齐**：
  - **边缘悬停手柄直连**：鼠标移至人物节点边缘自动浮现 `+` 手柄，拖拽预览连线至目标人物一键建立关系；
  - **连线选中高亮与管理**：点击关系线呈现品牌色光晕（Halo Glow），唤起“双向/单向切换”、“反转箭头”、“编辑备注”、“安全删除”四合一快捷弹窗；
- **精确外框几何算法 (`GraphGeometry`)**：
  - 依据男性（矩形）、女性（圆形）、其他（菱形）边界精确求解光线相交切点，连线与箭头严密贴合节点外轮廓，彻底消除箭头穿透节点内部的视觉缺陷；
- **多重关系与反向边支持**：同对人物多重关系自适应走弧线排版，根据真实方向独立计算正反向与切线偏角；
- **遗传图谱家谱树**：支持单亲、双亲、多子女的复杂家族谱系连线渲染；
- **自适应居中与缩放 (Fit to View)**：一键平滑计算节点包围盒并居中呈现全图；
- **无损 PNG 导出**：基于底层矢量 `PictureRecorder` + `Canvas` 自动计算节点外接矩形与安全边距，将整张关系图无损导出为高清 PNG 图片。

### 4. 纪元编年史与生平时间轴 (World Chronicle & Timeline)
- **世界观全景编年史大厅 (`ChroniclePage`)**：
  - 沉浸式垂直时间轴排版，支持 6 大核心事件分类芯片过滤（政治大事件、战争战役、奇幻魔法、科技跃迁、灾厄异变、日常杂记）；
  - 支持 1~3 星历史重要度分级高亮展示，支持跨纪元时间折叠与检索；
- **个人生平时间线 (`CharacterTimelineSection`)**：
  - 详情页内嵌个人成长里程碑时间轴，支持快速增删改查生平大事件，与世界纪年无缝互通；
- **角色视界穿梭**：在编年史中点击关联角色微标，瞬间路由切换至该角色专属的生平轨迹视角。

### 5. 维基双向链接与反向引用 (Wiki-style `[[Character]]` & Backlinks)
- **维基链接双向解析引擎 (`WikiLinkParser`)**：
  - 在小传或设定中书写 `[[角色名]]` 语法，浏览态自动解析为典雅交互胶囊微标，点击瞬间路由直达对应角色档案；
  - 若引用的角色不存在，智能呈现虚线警示与友好 Tooltip 提示，100% 兼容 Markdown 规范；
- **小传编辑智能辅助**：
  - 输入时支持快捷呼出候选角色弹窗，并在顶部提供高频角色 Chips 气泡，一键免手敲插入 `[[角色名]]`；
- **反向引用聚合面板 (Backlinks)**：
  - 详情页全自动计算“有哪些角色在设定小传中提及了我”，展示引用者档案、原句上下文切片与一键直达按钮，构建网状人际知识图谱。

### 6. 世界观全局大盘与关系网络分析 (World Analytics & Hubs Centrality)
- **全景数据分析计算引擎 (`WorldAnalyticsEngine`)**：
  - 自动聚合多维资产：计算创作生命周期阶段占比、性别比例构成、各组织势力规模与占比、以及整体网络紧密度公式 $D = \frac{2E}{N(N-1)}$；
- **原生自绘环形图 (`DonutChart` & `DonutLegend`)**：
  - 基于 Flutter `CustomPainter` 自主绘制平滑扇区与多维图例，中心动态凸显关键核心指标；
- **网络度中心性分析 (Degree Centrality)**：
  - 根据人际关系连线出入度与邻居去重度，自动计算世界观内的 **Top 核心纽带人物（Hubs）** 榜单并计算归一化权重进度条；
- **全屏大盘弹窗 (`WorldAnalyticsDialog`)**：
  - 包含 4 大核心指标卡片、双环形结构图、阵营势力分布柱状图与金/银/铜纽带人物榜单，随时全局一键唤出。

### 7. 全格式互通与出版物导出 (Booklet Export & `.ocpkg` Sharing)
- **出版级独立单文件 HTML 设定集 (`BookletExportService`)**：
  - **典雅出版物排版**：内置 `@media print` 针对 A4 纸张排版（独立封面 Cover、全书目录 Contents、世界序章、组织阵营、纪元大事记、角色单页分页 `page-break-after: always`）；
  - **纯 SVG 矢量雷达图**：零外部脚本依赖，原生数学算法计算多边形与辐向网格，在浏览器打开或打印导出时保持 100% 矢量级清晰度；
  - **维基双链胶囊与 Base64 脱机内嵌**：立绘与画廊图片全自动 Base64 内嵌，单个 HTML 文件直接脱机离线阅览，浏览器按 `Ctrl+P` 一键存为高清印刷 PDF；
- **知识库 Markdown 文档树归档 (.zip)**：
  - 完美契合 Obsidian / Notion / Logseq 知识库，包含 `index.md` 目录索引、YAML Frontmatter 元数据、相对资源目录 `assets/` 与人际拓扑；
- **设定集向导交互弹窗 (`BookletExportDialog`)**：
  - 支持自由开关章节模块与精确收录角色筛选；
- **独立数据分享包 (`.ocpkg`)**：
  - 一键将世界观及所有关联角色、相册切片、六维属性、编年史、人际关系与沙盒图片打包为单文件便携归档；
  - **安全预检与三维冲突解决策略 (`ConflictPolicy`)**：
    - **自动创建副本 (renameCopy)**：同名角色与世界观自动追加 `(导入)` 后缀，全自动重映射所有外键与关系网，100% 保护已有数据零覆盖；
    - **覆盖已有记录 (overwrite)**：就地更新同名角色设定与小传；
    - **跳过同名记录 (skip)**：忽略已存在同名角色，仅导入新增项。

### 8. 工业级数据安全底座与安全加固 (Bulletproof Security)
- **沙盒隔离与防越界（Path Traversal 免疫）**：图片与多媒体强制受控保存在应用私有沙盒 `oc_manager/` 目录中，实施 `canonicalize` 边界校验与图片扩展名白名单，阻断任意本地文件非法越界访问；
- **XSS 跨站脚本防御**：出版物导出与设定集渲染时对所有文本进行严密 HTML 转义，免疫任何脚本注入载荷；
- **孤儿实体恢复外键自愈**：回收站恢复人物时增加父世界存在性校验，原世界被物理删除后自动降级收纳，彻底根除 SQLite 787 外键约束红屏崩溃；
- **SQLite 在线一致性备份**：采用 `PRAGMA wal_checkpoint(FULL)` + `VACUUM INTO` 机制，生成事务一致的独立快照，发生异常自动原子回退；
- **全量级联回收站**：删除人物/世界观时将其子字段、标签、分组映射、画布坐标、相册画廊与时间线全量打包快照，恢复时 100% 等价还原。

---

## 🛠️ 技术栈

| 分层 | 技术选型 | 说明 |
| :--- | :--- | :--- |
| **UI 框架** | Flutter 3.x (Stable) | 深度适配 Windows 桌面端，兼顾 Android |
| **状态管理** | Flutter Riverpod 2.6+ | 声明式响应流与全局依赖解耦 |
| **数据持久化** | Drift 2.22+ & SQLite3 | 强类型 ORM，支持异步事务、DAO 模块化与安全迁移 (Schema v9) |
| **路由导航** | GoRouter 14.8+ | 声明式路由（支持深链直达人物详情、编年史等） |
| **文件归档与互通** | Archive 4.5+ | 纯 Dart 实现的无损 ZIP 压缩与解压引擎（零 C++ 依赖风险） |
| **系统交互** | FilePicker & ImagePicker | 跨平台文件导出、数据库备份与立绘安全沙盒存储 |
| **打包分发** | Inno Setup 6.7+ | Windows 工业级单文件安装包（快捷方式、开机菜单与卸载程序） |

---

## 📂 项目结构

```text
lib/
├── core/                        # 核心底座与通用服务
│   ├── analytics/               # 世界观全局统计引擎与度中心性算法 (WorldAnalyticsEngine)
│   ├── constants/               # 创作状态四态枚举 (CharacterCreationStatus)
│   ├── design/                  # 设计规范 Tokens 与高保真自绘组件
│   │   ├── design_tokens.dart   # 色彩阶梯、间距、圆角统一规范
│   │   └── components/          # RadarChart, DonutChart, OcCard, OcAvatar, EmptyStateView
│   ├── export/                  # 出版级导出与数据包分享系统
│   │   ├── booklet_export_service.dart # HTML / Markdown ZIP 设定集编译引擎
│   │   ├── oc_package_service.dart     # .ocpkg 打包/预检/三维冲突导入引擎
│   │   └── models/export_bundle.dart   # 序列化与包清单模型
│   ├── storage/                 # 本地资产沙盒与防越界管理 (ImageStorageService)
│   ├── theme/                   # 全局浅色/深色主题与字体链配置 (AppTheme)
│   └── util/                    # 调色盘提取器 (PaletteExtractor)、维基链接解析 (WikiLinkParser)
├── data/database/               # 数据持久层 (Drift Schema v9)
│   ├── app_database.dart        # Drift SQLite 核心实例与迁移逻辑
│   ├── daos/                    # 业务数据访问对象 (Character, World, Group, Relation, Timeline, etc.)
│   └── tables/                  # 数据库表结构定义
├── features/                    # 业务功能模块
│   ├── character/               # 人物详情、小传维基双链、画廊切片、雷达图卡片、海报导出
│   ├── main_shell.dart          # 桌面三栏工作台架构、动效侧边栏与动态面包屑
│   ├── relation/                # 关系图谱画布、外框几何算法 (GraphGeometry)、PNG 导出
│   ├── settings/                # 主题偏好、SQLite 在线备份、恢复与数据分享包导入
│   ├── sidebar/                 # 树状层级导航与跨世界观防穿透拖拽 (TreeSidebar)
│   ├── tag/                     # 标签管理与颜色选择器
│   ├── template/                # 自定义人设模板管理与字段配置
│   ├── trash/                   # 全量关联级联回收站
│   └── world/                   # 世界观详情页、看板/表格多维视图、编年史、大盘弹窗、设定集向导
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

# 5. 运行完整自动化测试套件（全量 59 项全部通过）
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
安装包将生成于 `Output/OCManager_Setup_v1.5.0.exe`（单文件安装包，内含完整依赖与图标配置）。

#### 3. Android Release APK
```bash
flutter build apk --release
```
APK 产物生成于 `build/app/outputs/flutter-apk/app-release.apk`。

---

## 🧪 自动化测试验证 (59 项全绿)

项目配置有严密的单元测试、安全沙盒防御、状态隔离与几何运算断言套件，采用内存数据库沙盒隔离，避免污染生产数据：

- **`test/booklet_export_test.dart`**：出版级 HTML 设定集生成、纯 SVG 矢量雷达图多边形顶点计算、Markdown 文档树打包及 **XSS 恶意脚本载荷过滤免疫**验证；
- **`test/oc_package_test.dart`**：`.ocpkg` 归档预检、**自定义字段与标签完整导入断言**、三维冲突解决策略（`renameCopy` 外键关系自愈重映射、`skip` 跳过冲突、`overwrite` 覆盖更新）；
- **`test/image_storage_security_test.dart`**：**沙盒越界防御测试**，验证绝对路径拦截与 `../../` 路径穿越拒绝；
- **`test/world_analytics_test.dart`**：度中心性 (Degree Centrality) 排名与归一化计算、网络紧密度公式、`DonutChart` 自绘与大盘弹窗断言；
- **`test/kanban_and_table_test.dart`**：泳道看板按状态/阵营分列与跨列拖拽、多维表格列排序与过滤断言；
- **`test/wiki_link_test.dart`**：`[[角色名]]` 胶囊标记生成、未命中虚线警示、小传富文本渲染与反向引用聚合计算；
- **`test/timeline_test.dart`**：大事件增删改查、重要度分级高亮、分类芯片过滤与个人生平时间线同步；
- **`test/character_poster_test.dart`**：4 大主题长图海报布局与无损渲染断言；
- **`test/character_gallery_test.dart`**：差分画廊 CRUD、封面原子联动与调色板主色提取算法；
- **`test/character_stats_test.dart`**：六维雷达图属性预设、增删改查与极值边界防除零保护；
- **`test/trash_and_isolation_test.dart`**：跨世界观数据隔离、软删除全量子表级联快照还原、以及**原世界观被物理删除后的孤儿角色安全降级恢复**；
- **`test/relation_logic_test.dart`**：关系对配对唯一性、外框精确相交射线算法（圆形/矩形/菱形）及切线偏角判定；
- **`test/settings_theme_test.dart`**：设置项幂等读写与主题模式持久化校验；
- **`test/widget_test.dart`**：应用核心主流程加载与三栏工作台基础渲染断言。

---

## 📄 开源许可证

本项目基于 [MIT License](LICENSE) 开源发布。

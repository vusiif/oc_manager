# OC Manager (二创与原创角色人设管理工作台)

<p align="center">
  <img src="https://img.shields.io/badge/Version-v2.2.0-6366F1?style=flat-square" alt="Version" />
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white&style=flat-square" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white&style=flat-square" alt="Dart" />
  <img src="https://img.shields.io/badge/Platform-Windows%20%7C%20Android-4CAF50?style=flat-square" alt="Platform" />
  <img src="https://img.shields.io/badge/Database-SQLite%20%2F%20Drift%20v15-003B57?logo=sqlite&logoColor=white&style=flat-square" alt="SQLite" />
  <img src="https://img.shields.io/badge/Tests-293%2F293%20Passed-brightgreen?style=flat-square" alt="Tests" />
  <img src="https://img.shields.io/badge/Security-Hardened%20(Atomic%20%26%20Isolation)-orange?style=flat-square" alt="Security" />
  <img src="https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square" alt="License" />
</p>

**OC Manager** 是一款专为小说创作者、漫画家、跑团（TRPG）玩家及二创爱好者打造的**本地优先、隐私安全、高颜值**的角色人设（Original Character）与世界观设定管理工作台。

界面深度参考 **AppFlowy** 式现代桌面三栏信息架构（移动端自适应抽屉），人物卡片汲取 **Milanote** 视觉展示语言，关系图谱对齐 **Obsidian Canvas** 交互体验，结合 **Notion** 多维矩阵与出版级设定集编译引擎，采用 **SQLite + Drift (Schema v15)** 强类型数据库保障数据底座的绝对安全。

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

### 9. 世界观全景百科实体库与知识网络 (Lore Encyclopedia & Knowledge Network · LORE-001 ~ LORE-007)
- **通用实体模型架构 (`LoreEntities` 表，Schema v14)**：突破单纯角色限制，扩展为包含地点、组织/阵营、种族、物品、能力/魔法、其他概念六大维度的通用知识库；
- **地点与组织树形层级 (LORE-001 & LORE-002)**：基于 `parentId` 实现多级地理辖区（国家/省/市/建筑）与分部架构，支持多级面包屑追溯导航；
- **势力外交拓扑与领袖识别 (LORE-003)**：基于 `LoreEntityRelations` 建模同盟、敌对、从属与贸易外交拓扑，领袖与关键职务置顶高亮排序；
- **物品与装备体系 (LORE-004)**：品阶稀有度、特效威能与使用代价卡片、当前持有者/锻造者置顶、随身装备与地缘存放关联；
- **种族与生物体系 (LORE-005)**：种族形态、平均寿命、生理外貌、生活习性与信仰文化，母种族与衍生亚种树形分支，角色血脉归属与发源故土栖息地关联；
- **能力与规则体系 (LORE-006)**：能力派系分类、威能阶位、生效方式、修行前置与反噬代价限制，基础体系与进阶禁咒体系技能树，掌握宗师置顶、法宝装备载体附魔与属性相生相克；
- **全域知识网络拓扑视图 (LORE-007 · `KnowledgeNetworkPage`)**：
  - 8类实体同构化聚合与统一 ID 隔离（`c_`, `l_`, `e_`），7类多维关联映射；
  - 星系轨道向心排布（Galaxy）、力导向物理弹簧模拟（Force）与度数环形排布（Radial）；
  - Canvas LOD 视口保护、超视口裁剪（Viewport Culling）与 Ego-network 聚焦高亮；
- **全景百科大厅 (`LoreEncyclopediaPage`)**：提供实时分类过滤 Chips、全域模糊搜索、自适应卡片流式网格与悬停微动效；
- **词条详情与交互弹窗 (`LoreEntityDetailDialog` & `LoreEntityDialog`)**：支持图鉴封面上传、分类切换、属性管理与设定正文撰写；
- **维基双链扩展 (`WikiLinkParser`)**：升级 `buildWikiSpans` 支持识别百科词条 `[[词条名]]`，以特异性分类图标与主题色胶囊渲染，点击瞬间弹出词条详情。

### 10. 设定一致性检查规则引擎与工作台 (Consistency Checker & Workbench · CONSIST-001 ~ CONSIST-005)
- **模块化确定性规则引擎 (`ConsistencyCheckerEngine` & `ConsistencyRuleRegistry`)**：
  - **抽象规则契约 (`ConsistencyRule`)**：具备稳定规则 ID、默认严重级别、触发依据数据 (`evidence`) 与针对性修复建议 (`suggestion`)；
  - **多粒度检查调度**：支持全世界观全量体检 (`checkWorld`) 与单角色极速定向诊断 (`checkCharacter`)；
  - **时间与年龄检查增强 (`TimelineDateParser` & `TimelineLifespanRule` · CONSIST-002)**：
    - 精确解析负数与 BCE/公元前纪元、星历等特殊纪年；
    - 模糊词（未知、不详、太古、神话）与数据不全时安全防护，杜绝武断断言；
    - 五维时序交叉诊断：生卒年逆序、生平事件超出逝世区间（自动放行追思追封纪念类事件）、生平事件早于出生年份（自动放行前尘先祖开天类事件）、存活人设状态与死亡事件记录矛盾、凡人超长寿命 (>200年且小传缺少仙神/长生/不朽等关键词) 友好提示；
  - **关系网矛盾与双链引用排查 (`RelationIntegrityRule` & `WikiLinkIntegrityRule` · CONSIST-003)**：
    - 排查自关联自环、端点不存在的失效幽灵关联、成对重复冗余关系与孤立家谱残留；
    - 排查维基双链坏链未命中，智能识别并警示跨世界观越界引用；
  - **设定完整度与智能留白识别 (`CompletenessRule` · CONSIST-004)**：
    - 自动识别带 `[留白]`、`【草稿】`、`(待定)`、`TBD`、`TODO` 等有意留白标记，免检放行；
    - 诊断空白孤岛角色、小传空白角色、明确立绘需求未配图与百科未分类/空词条；
  - **零副作用安全原则**：确定性只读检查，不依赖外部 AI，不自动篡改或静默改写创作者设定。
- **健康指数大盘与结果工作台 (`ConsistencyCheckerDialog` & `consistency_provider.dart` · CONSIST-005)**：
  - 动态计算 0~100 健康指数得分，支持待办与已处理分段切换（`SegmentedButton`）；
  - 支持创作者一键“忽略”或“标记已解决”，已处理条目不扣减健康分，零源数据污染；
  - 弹窗内置规则启停配置（`_showRuleConfigDialog`），实时勾选/停用 5 大内置规则并动态响应。

### 11. 关系图多命名画布、撤销重做、小地图与矢量导出 (Graph Advanced Canvas · GRAPH-001 ~ GRAPH-005)
- **多命名画布管理 (Multiple Named Canvases · Schema v12)**：同一世界观支持家谱树、势力图、主角团等多套命名画布，独立保存节点布局排版、缩放比例、视口平移与高级过滤配置；
- **全命令模式撤销与重做 (`GraphHistoryManager` · Undo/Redo)**：支持节点单移/批量智能排版/增删节点/关系增删改全生命周期原子级回退与恢复，支持 `Ctrl+Z` / `Ctrl+Y` 快捷键，切换画布/世界观自动清理历史；
- **悬浮全局导览小地图 (`GraphMinimap`)**：等比缩放微缩拓扑、动态计算主视口范围框（Viewport Box）、支持点击/拖拽主视口居中漫游导航、支持小屏折叠展开；
- **纯 Dart W3C 标准 SVG 矢量图谱导出 (`GraphSvgExporter`)**：零平台依赖生成标准矢量文件，计算包围盒与内边距，多重二次贝塞尔弧线、单向/双向箭头、性别图形、深浅双色背景支持与 XML 防注入转义；AppBar 提供 PNG/SVG 双模式一键导出。
  - 单项条目直观呈现“触发依据数据”与“官方修复建议”，支持一键路由跳转定位对应实体。

### 11. 设定版本历史、全字段差异对比与安全恢复 (Revision History & Diff Workbench · HISTORY-001 ~ HISTORY-003)
- **全量结构化人设快照 (`CharacterSnapshot` · HISTORY-001)**：
  - 突破单一小传限制，记录基本信息（姓名、性别、年龄、立绘路径）、小传描述、自定义扩展属性键值对（`customFields`）与标签体系（`tags`）；
  - 采用安全 JSON 序列化，向下兼容旧版纯小传记录；
  - 支持手动快照、自动保存与回滚前归档来源标识，支持**重要里程碑标记 (⭐)**；
  - 智能保留策略：历史记录超出上限时，里程碑快照受永久保护防修剪淘汰。
- **全维度字段与长文本逐行 Diff 引擎 (`CharacterRevisionDiffEngine` & `TextDiffUtil` · HISTORY-002)**：
  - 基本信息变动：姓名、性别、年龄、立绘新旧值对照；
  - 扩展属性变动：键值对新增（绿）、删除（红）、修改（橙）；
  - 标签变动：新增与删除标签 Chips 标注；
  - 小传文本行级 Diff：基于纯 Dart 最长公共子序列（LCS）实现逐行红绿高亮与代码风格行号显示。
- **选择性安全恢复与回滚前自动归档 (HISTORY-003 · `RevisionHistoryDialog`)**：
  - 恢复弹窗支持创作者自由勾选恢复维度（小传/基本信息/自定义字段/标签）；
  - 恢复前系统自动强制生成当前状态全量安全备份快照，零数据丢失隐患；
  - 严格限定恢复边界：人物既有的社交关联、亲友关系与画廊相册绝对不被触碰破坏；
  - 在角色详情页顶栏与小传区域均可一键呼出历史工作台。

### 12. 关系图高级分析与智能布局 (Advanced Graph Analytics & Layouts)
- **BFS 最短人脉路径寻径 (`RelationPathFinder`)**：
  - 基于广度优先搜索 (BFS) 构建图邻接拓扑，严格区分单向与双向关系；
  - 精确计算任意两角色间的最短人脉穿透跃迁步数并输出完整路径；
- **三大智能自动排版引擎 (`GraphAutoLayoutEngine`)**：
  - **环形聚类布局 (Circular)**：度数最高核心人物居中，外围角色自适应辐射环绕；
  - **分层层级布局 (Hierarchical)**：分析入度拓扑自顶向下分层，适用于派系统领与亲缘家谱；
  - **紧凑矩阵网格 (Grid)**：自适应矩阵整齐排布，高密度整理大画幅；
- **坐标快照与一键撤销恢复**：排版前自动创建坐标快照，提供无损撤销与批量持久化；
- **画布视觉高亮与光晕联动**：
  - 最短路径连线加粗（3.5px）与品牌色发光光晕渲染，非路径关系边及标签自动降透明度；
  - 路径角色节点外圈渲染发光光晕，非关联角色以 25% 透明度淡出；
  - 画布右上角悬浮胶囊状态条实时展示跃迁步数，支持一键点击清除高亮。

### 13. 关系图多命名画布管理 (Multiple Named Canvases · GRAPH-001)
- **世界观多画布隔离**：同一世界观支持无限创建命名画布（主关系网、核心势力图、亲缘家谱、暗线羁绊等）；
- **视口与坐标独立持久化**：
  - 各画布独立保存节点坐标（`x, y`）、视口平移缩放（`viewportX, viewportY, zoomScale`）与过滤状态；
  - 角色与关系实体全局共享，严禁冗余复制或意外破坏；
- **全生命周期管理**：
  - 胶囊下拉选择器一键切换画布，切换时自动平滑持久化旧画布视口与加载目标视口；
  - 支持创建新画布、重命名、复制当前画布（完整继承节点坐标与视口配置）、设为默认画布；
  - 级联防灾删除保护：删除画布仅清理该画布内排版坐标，严格保护角色与关系实体安全；默认画布自动推举递补；
  - 回收站级联保护：世界观软删除与还原完整纳入多画布及其所属节点坐标。

### 14. 关系图命令模式撤销与重做 (Undo & Redo · GRAPH-002)
- **命令模式全操作覆盖 (`GraphHistoryManager`)**：
  - **节点拖拽移动**：拖动角色节点放下后自动捕获起始坐标与终点坐标，微小抖动智能过滤；
  - **智能排版算法**：环形、分层、网格自动排布前自动拍摄全量节点坐标快照，一键撤销恢复手工布局，并支持重做恢复排版；
  - **画布增删节点**：从侧栏向画布拖入角色、或从画布移回侧栏，撤销/重做无损联动数据库与视图；
  - **关系创建/编辑/删除**：包括单条关系添加、家谱亲子关系批量创建、关系双向/单向切换、反转方向、修改类型与备注、删除关系，撤销时保留原稳定主键 ID 原子还原；
- **历史栈安全隔离**：
  - 切换世界观或切换当前命名画布时，严格自动清空 Undo/Redo 历史栈，彻底杜绝跨画布或跨世界观污染；
- **双端快捷交互**：
  - 顶部导航栏提供动态响应式“撤销 / 重做”图标按钮，实时呈现当前可撤销动作名称气泡（Tooltip）与置灰禁用态；
  - 桌面端全键盘无缝支持：`Ctrl+Z` / `Cmd+Z` 撤销，`Ctrl+Y` / `Ctrl+Shift+Z` / `Cmd+Shift+Z` 重做，智能规避文本输入框焦点冲突。

### 15. 关系图全局导览小地图与 SVG 矢量导出 (Mini-map & SVG Export · GRAPH-005)
- **悬浮全局导览小地图 (`GraphMinimap`)**：
  - **微缩全景投影**：实时按主图所有节点的凸包边界（Bounding Box）进行等比缩放渲染，呈现所有角色节点与关系骨架；
  - **视口范围指示框 (Viewport Box)**：基于主画布逆矩阵动态投影出当前可见屏幕区域，支持深浅色模式与主题色微光渲染；
  - **双向平滑导航**：支持直接在小地图上单击或拖曳，主画布视口瞬间以目标世界坐标为中心平滑对齐；
  - **灵活折叠与展开**：支持一键将小地图收折为精致圆角浮动按钮，彻底释放紧凑屏幕或移动端的操作空间；
- **W3C 标准 SVG 矢量图谱导出 (`GraphSvgExporter`)**：
  - **纯 Dart 零依赖**：基于数学几何与标准 XML 字符串生成规范标准的矢量文件，零原生平台依赖；
  - **多重弧线与箭头 Marker**：多条关系连线自适应对称贝塞尔曲线（Q 曲线），有向单向连线绘制精确箭头 marker，双向关系连线平滑展示；
  - **丰富语义图形**：按性别区分方形（男）、圆形（女）、菱形（其他/未知），已故角色灰色渲染；
  - **关系药丸气泡**：关系类型自动居中并绘制圆角胶囊背景；
  - **安全与防护**：内置 XML 实体防注入转义（XSS 防护），全面适配深浅色背景；
- **双模式导出切换**：
  - 顶部导航栏提供集成式导出菜单，支持自由选择“导出为高清图片 (PNG)”与“导出为矢量图谱 (SVG)”。

---

## 🛠️ 技术栈

| 分层 | 技术选型 | 说明 |
| :--- | :--- | :--- |
| **UI 框架** | Flutter 3.x (Stable) | 深度适配 Windows 桌面端，兼顾 Android |
| **状态管理** | Flutter Riverpod 2.6+ | 声明式响应流与全局依赖解耦 |
| **数据持久化** | Drift 2.22+ & SQLite3 | 强类型 ORM，支持异步事务、DAO 模块化与安全迁移 (Schema v12) |
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

### 6. 世界观百科实体库与全景知识网 (World Lore Encyclopedia & Entities)
- **通用实体模型架构**：突破单纯“人物卡”局限，将世界观扩展为囊括 **地点 (Location) / 组织阵营 (Faction) / 种族物种 (Race) / 物品道具 (Item) / 魔法能力 (Ability) / 核心概念 (Other)** 六大维度的多态实体库；
- **结构化专有属性**：采用轻量灵活的 JSON 键值对扩展存储各类专有属性（如：地点气候坐标、组织首领、物品品级、能力消耗等）；
- **全景百科大厅 (`LoreEncyclopediaPage`)**：
  - 支持按分类芯片过滤、搜索框全字段即时检索；
  - 呈现卡片流式网格，支持悬停光晕动效与沙盒封面图自适应渲染；
  - 提供实体详情全屏弹窗，展示分类徽标、摘要、专有属性、标签与富文本正文；
- **全网状维基双链打通 (`WikiLinkParser`)**：
  - 在人物小传及各百科正文中键入 `[[词条名]]`，智能识别并呈现具有分类专属色调与图标的微标胶囊；
  - 点击即可直达词条详情弹窗穿梭预览，实现真正的网状世界观知识网络。

---

### 7. 设定一致性检查器与逻辑体检 (`ConsistencyCheckerEngine`)
- **纯本地规则引擎**：不依赖外部在线 AI，毫秒级快速扫描整个世界观的核心数据；
- **五维诊断体系**：
  1. **时间轴矛盾**：检测出生年份晚于逝世年份、事件发生时间超出角色生卒年区间；
  2. **关系网矛盾**：检测自我指向自环连线、同一对角色同时标记矛盾关系（如恋人 vs 宿敌）；
  3. **双向链接断裂**：扫描人设小传与百科正文中引用的 `[[失效对象]]` 并标红；
  4. **多媒体文件完整性**：检测头像、相册画廊与百科封面在沙盒磁盘上的丢失状态；
  5. **设定完整度建议**：智能识别无描述无关系的孤岛角色与空词条；
- **健康指数大盘 (`ConsistencyCheckerDialog`)**：
  - 动态计算健康指数得分（0~100）并划分自洽级别；
  - 提供严重度过滤 Chip 条（严重矛盾 / 逻辑警告 / 完善建议）、具体证据切片与一键路由跳转定位。

---

### 8. 故事创作工坊、效率交互与模板生态
- **故事工坊 (`StoryWorkbenchPage`)**：支持按世界观隔离的多作品/分卷/分镜场景管理、POV 视点与登场角色统计、故事线时间一致性检查，以及 HTML/Markdown/ZIP 剧本导出；
- **关系图谱 2.0 进阶交互**：支持空白处框选（`Shift+拖拽` 或框选模式）、多节点同步平移、6 种对齐/等距分布、关系线发光选中与左下角轻量属性检查面板；
- **效率与模板体系**：`Ctrl+K` 全局命令面板、`F1` 全应用快捷键指南、最近访问与固定收藏、纯字段模板 JSON 分享与 5 套官方预设模板、以及空状态一键体验示例世界观。

---

## 🧪 自动化测试验证 (293 项全绿)

项目配置有严密的单元测试、安全沙盒防御、状态隔离与几何运算断言套件，采用内存数据库沙盒隔离，避免污染生产数据：

- **`test/consistency_timeline_age_test.dart`**：**时间与年龄一致性检查 (CONSIST-002)**，验证 `TimelineDateParser` 正负数与公元前/BCE/星历解析、模糊词条（太古/未知）安全避让不误断言、生卒年时序矛盾诊断、出生前事件与逝世后事件时序交叉验证（放行先祖开天与追思追封纪念类事件）、存活人设状态与死亡事件记录矛盾、以及凡人极端寿命提示；
- **`test/consistency_rule_engine_test.dart`**：**设定一致性规则引擎基础 (CONSIST-001)**，验证 `ConsistencyRule` 抽象规则契约、`ConsistencyRuleRegistry` 规则注册与动态启停过滤、纯内存 `ConsistencyContext` 零依赖评估、修复建议与依据数据生成、以及 `checkCharacter` 单角色精准定向诊断；
- **`test/graph_navigation_export_test.dart`**：**关系图全局导览与矢量导出 (GRAPH-005)**，验证纯 Dart W3C SVG 矢量图谱渲染、XML 转义防注入、单线与多重贝塞尔弧线、有向箭头与双向线断言、性别图形与已故状态颜色渲染、小地图折叠展开状态切换、以及单击/拖动坐标映射到视口中心平移逻辑；
- **`test/graph_history_test.dart`**：**关系图撤销与重做 (GRAPH-002)**，验证单节点移动坐标回滚与重做、自动排版全量节点批量恢复、画布放置/移回双向栈还原、关系增删改与家谱亲子创建逆向事务回溯、历史栈上限修剪、切画布/切世界观历史安全隔离、以及顶部工具栏 Undo/Redo 按钮动态响应断言；
- **`test/graph_canvas_test.dart`**：**关系图多命名画布管理 (GRAPH-001)**，验证默认画布自动创建、无 `canvasId` 历史数据迁移归并、画布间节点独立隔离排版、视口平移缩放与过滤状态持久化、画布克隆完整复制、级联删除保护不伤及角色与关系实体、默认画布动态推举与选择器组件树断言；
- **`test/consistency_checker_test.dart`**：**设定一致性检查器 (P2-02)**，验证生卒年时序矛盾诊断、事件超出生存区间告警、自环与矛盾关系识别、坏链断链检测与健康分数；
- **`test/character_revision_history_test.dart`**：**设定版本历史与全维度差异恢复 (HISTORY-001 ~ HISTORY-003)**，验证全量结构化快照、里程碑修剪保护、全字段与小传行级 Diff 引擎、选择性恢复与回滚前强制自动备份；
- **`test/revision_history_test.dart`**：**设定版本历史与快照回滚 (P2-03)**，验证快照 CRUD、内容去重、滚动修剪与恢复；
- **`test/lore_race_and_ability_test.dart`**：**种族生物与能力规则体系 (LORE-005 & LORE-006)**，验证种族亚种分支与法系进阶技能树层级、结构化模板、血脉归属与掌握宗师置顶排序、发源栖息地与附魔相克实体关系、详情弹窗卡片徽章与角色归属展示；
- **`test/knowledge_network_test.dart`**：**全域知识网络视图 (LORE-007)**，验证 8 类实体同构化聚合、统一 ID 前缀隔离、Galaxy/Force/Radial 排布引擎、Painter LOD 与超视口裁剪、Ego-network 聚焦与工作台 UI 交互；
- **`test/lore_item_equipment_test.dart`**：**物品与装备管理体系 (LORE-004)**，验证装备品阶/特效/代价结构化属性、持有者与锻造工匠置顶、地缘存放与归属组织关联、详情弹窗渲染及角色随身装备展示；
- **`test/lore_faction_relation_test.dart`**：**组织势力管理与外交拓扑 (LORE-003)**，验证 Schema v14 `LoreEntityRelations` 外交关系迁移、同盟/敌对/从属/贸易关系、领袖置顶识别与角色详情页组织归属；
- **`test/lore_hierarchy_relation_test.dart`**：**地点树形空间与人物稳定关联 (LORE-001 & LORE-002)**，验证 `parentId` 地理辖区嵌套、多级面包屑追溯与角色常驻关联；
- **`test/lore_entity_test.dart`**：**世界观百科实体库 (P2-01)**，验证通用实体 CRUD、专有属性 JSON 键值对序列化、跨世界观数据强隔离、按分类过滤、全域搜索与双链词条识别；
- **`test/relation_validation_test.dart`**：**关系图业务约束与去重 (P1-04)**，验证自指向连线拦截、跨世界观连线拦截、家谱父子环拦截、历史坐标脏数据清理与批量事务 upsert；
- **`test/search_page_test.dart`**：**全局深度搜索与竞态防护 (P1-03)**，验证姓名/人设小传/自定义字段/标签/阵营全域深度搜索、世界观与状态组合过滤、250ms 防抖；
- **`test/project_backup_test.dart`**：**双轨备份与演练恢复 (P1-02)**，验证 SQLite 原生一致性快照导出、包含完整媒体库的 ZIP 项目包、SHA-256 校验和防灾还原点与损坏回滚；
- **`test/booklet_export_test.dart`**：出版级 HTML 设定集生成、纯 SVG 矢量雷达图多边形顶点计算、Markdown 文档树打包及 **XSS 恶意脚本载荷过滤免疫**验证；
- **`test/oc_package_test.dart`**：`.ocpkg` 归档预检、**文件系统与数据库事务原子性 (P1-01)**、导入异常沙盒孤儿图片自动清理回滚、目标世界观同名精准消歧与家谱关系组 ID 导入映射；
- **`test/image_storage_security_test.dart`**：**沙盒越界防御测试**，验证绝对路径拦截与 `../../` 路径穿越拒绝；
- **`test/world_analytics_test.dart`**：度中心性 (Degree Centrality) 排名与归一化计算、网络紧密度公式、`DonutChart` 自绘与大盘弹窗断言；
- **`test/kanban_and_table_test.dart`**：泳道看板按状态/阵营分列与跨列拖拽、多维表格列排序与过滤断言；
- **`test/wiki_link_test.dart`**：`[[角色名]]` 胶囊标记生成、未命中虚线警示、小传富文本渲染与反向引用聚合计算；
- **`test/timeline_test.dart`**：大事件增删改查、重要度分级高亮、分类芯片过滤与个人生平时间线同步；
- **`test/character_poster_test.dart`**：4 大主题长图海报布局与无损渲染断言；
- **`test/character_gallery_test.dart`**：差分画廊 CRUD、封面原子联动与调色板主色提取算法；
- **`test/character_stats_test.dart`**：六维雷达图属性预设、增删改查与极值边界防除零保护；
- **`test/trash_and_isolation_test.dart`**：跨世界观数据隔离、软删除全量子表级联快照还原、**单角色删除关系快照与恢复自愈 (P0-03)**、以及**原世界观被物理删除后的孤儿角色安全降级恢复**；
- **`test/relation_logic_test.dart`**：关系对配对唯一性、外框精确相交射线算法（圆形/矩形/菱形）及切线偏角判定；
- **`test/settings_theme_test.dart`**：设置项幂等读写与主题模式持久化校验；
- **`test/widget_test.dart`**：应用核心主流程加载与三栏工作台基础渲染断言。

---

## 📄 开源许可证

本项目基于 [MIT License](LICENSE) 开源发布。

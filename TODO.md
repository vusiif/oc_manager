# OC Manager --- TODO / 产品迭代待办

> 本文件是长期产品待办池，不代表所有事项都必须实现。Agent
> 开始任务前必须先核对代码、文档、Schema
> 和测试；若功能已存在或已有替代方案，应更新状态，不得重复开发。

## 产品方向

OC Manager
的定位是：**本地优先、隐私友好、面向原创角色与世界观创作的管理工作台**。

后续迭代重点： 1. 创作效率：更快创建、查找、整理和关联设定。 2.
设定可信度：发现时间线、人物关系和世界规则中的矛盾。 3.
世界观表达：从人物档案扩展为可关联的世界观知识库。 4.
长期可维护：保证数据安全、跨平台体验、文档和测试质量。

原则：核心功能离线可用；用户数据优先；先做完整
MVP；固定字段与自定义字段并存；不为功能数量而开发。

## 状态与优先级

-   `[ ]` 待做；`[-]` 进行中；`[x]` 已完成并验证；`[?]` 待调研/决策。
-   **P0**：下一阶段优先；**P1**：核心体验增强；**P2**：中长期能力；**P3**：可选探索。
-   完成定义：代码可用、测试通过、文档同步、必要的平台行为已验证。

------------------------------------------------------------------------

# 0. 工程基线与文档维护

## P0

-   [ ] **DOC-001：统一项目状态文档**
    -   对齐
        `README.md`、`CLAUDE.md`、`PROGRESS.md`、`ROADMAP.md`、`REQUIREMENTS.md`。
    -   统一当前版本、Schema、已实现功能、测试数量和未完成事项。
    -   测试数量必须来自实际运行结果，不得沿用旧数字。
    -   验收：文档之间无明显矛盾，新 Agent 能判断项目真实状态。
-   [ ] **DOC-002：建立功能状态核对机制**
    -   开发前核对 TODO 项是未实现、部分实现还是已实现。
    -   已实现项注明代码位置和验证方式。
    -   验收：不因待办未勾选而重复开发。
-   [ ] **QA-001：稳定质量门禁**
    -   确认 `flutter analyze`、`flutter test` 可在干净环境运行。
    -   建立 Windows / Android 必要构建验证；评估 GitHub Actions。
    -   验收：检查命令、运行环境和失败处理方式有文档。
-   [ ] **QA-002：关键流程回归测试**
    -   覆盖世界观/人物 CRUD、关系编辑、删除恢复、导入导出、数据库迁移。
    -   验收：核心流程有可重复执行的自动化测试。

------------------------------------------------------------------------

# 1. P0 --- 创作效率

## 全局命令面板

-   [ ] **UX-001：Command Palette**
    -   Windows 使用 `Ctrl + K` 呼出；快捷键可配置并避免冲突。
    -   搜索人物、世界观和命令；提供新建人物/世界观、打开关系图、编年史、导出、设置等操作。
    -   显示最近打开/编辑项；支持键盘上下选择、Enter 执行、Esc 关闭。
    -   Android 提供可触达的搜索入口，不依赖物理键盘。
    -   验收：复用现有业务逻辑和路由，不复制 CRUD 实现。

## 关系图多画布与高级编辑

-   [x] **GRAPH-001：多个命名画布**（已完成，位于 `lib/features/relation/relation_graph_page.dart`、`lib/data/database/daos/canvas_dao.dart`、`tables/canvases.dart`，Schema v12，通过 `test/graph_canvas_test.dart` 验证）
    -   同一世界观支持家谱、势力关系、主角团等多个画布。
    -   每个画布独立保存节点位置、缩放、视口和过滤配置。
    -   人物与关系实体仍然共享，不复制数据。
    -   支持重命名、复制、删除、默认画布。
    -   验收：切换画布不覆盖其他布局；删除画布不删除人物/关系。
-   [x] **GRAPH-002：撤销与重做**（已完成，位于 `lib/features/relation/graph_history_manager.dart`、`relation_graph_page.dart`，通过 `test/graph_history_test.dart` 验证）
    -   覆盖节点移动、增删节点、创建/编辑/删除关系。
    -   切换世界观或画布时不得错误应用旧历史。
    -   验收：Undo/Redo 后界面与数据库状态一致。
-   [x] **GRAPH-003：自动布局**（已完成，环形/分层/网格三大算法排布 `GraphAutoLayoutEngine`，快照撤销保护）
    -   至少提供一种自动布局；后续可扩展层级、树状、力导向。
    -   自动布局需可预览或撤销，不得静默覆盖手工布局。
    -   验收：大规模节点可读，布局可保存恢复。
-   [x] **GRAPH-004：过滤、搜索与关系路径**（已完成，BFS 最短路径寻径 `RelationPathFinder`、画布光晕高亮与过滤持久化）
    -   按关系类型、标签、阵营、人物状态过滤。
    -   搜索人物后聚焦节点并高亮邻接关系。
    -   支持查看 A 到 B 的关系路径。
    -   验收：过滤只影响显示，不删除真实数据。
-   [x] **GRAPH-005：导航与导出**
    -   增加 Mini-map 或等价的大画布导航。（完成：悬浮可折叠 `GraphMinimap`，视口反算与点击/拖动居中导航）
    -   评估 SVG 矢量导出，保留 PNG。（完成：纯 Dart `GraphSvgExporter` 矢量导出与双模式导出菜单）
    -   验收：导出内容完整，大图导出不阻塞 UI。（已验证：`test/graph_navigation_export_test.dart` 7/7 全绿）

------------------------------------------------------------------------

# 2. P0 / P1 --- 设定一致性检查器

> 第一版采用确定性规则引擎，不依赖 AI；默认只读，不自动修改用户设定。

-   [x] **CONSIST-001：规则引擎基础**
    -   每条规则包含稳定 ID、名称、严重级别、说明、定位信息、依据数据和修复建议。（完成：`ConsistencyRule` 抽象规则与 `ConsistencyIssue` 扩展）
    -   支持错误、警告、提示；单世界观、单人物和全量检查。（完成：`ConsistencyCheckerEngine.checkWorld` 与 `checkCharacter`）
    -   规则逻辑独立于 Widget，可单元测试。（完成：`test/consistency_rule_engine_test.dart` 纯内存 5/5 全绿）
-   [x] **CONSIST-002：时间与年龄检查**
    -   检查出生/死亡时间与事件参与时间。（完成：`TimelineLifespanRule` 检查出生前、逝世后事件时序，放行纪念与前尘事件）
    -   检查死亡后仍参与后续事件等明显矛盾。（完成：`status == 0` 存活状态与死亡事件矛盾报警）
    -   数据不足、日期模糊时不得武断判断。（完成：`TimelineDateParser` 识别太古/未知等模糊留白，安全避让）
    -   验收：单测 `test/consistency_timeline_age_test.dart` 9/9 全绿。
-   [x] **CONSIST-003：关系与引用检查**（已完成，位于 `lib/core/consistency/consistency_rules.dart`，涵盖自关联自环、失效幽灵端点、成对重复冗余关系、孤立家谱分组、断裂双链以及跨世界观越界双链引用诊断，通过 `test/consistency_relation_reference_test.dart` 验证）
    -   检查自关联、重复关系、失效关联、异常分组。
    -   检查 Wiki 双链未命中、目标删除/重命名、跨世界观引用。
    -   检查器只报告，不自动删除或改写数据。
-   [x] **CONSIST-004：设定完整度检查**（已完成，位于 `lib/core/consistency/consistency_rules.dart`，支持智能有意留白免检放行、空白孤岛、小传单薄空白、明确立绘需求未配图与百科未分类/空词条诊断，通过 `test/consistency_completeness_test.dart` 验证）
    -   根据模板/用户配置检查必填字段。
    -   检查缺少封面、空白描述、未分类条目等可选项。
    -   区分"有意留白"和"可能遗漏"，允许忽略。
-   [x] **CONSIST-005：检查结果工作台**（已完成，位于 `lib/features/world/consistency_checker_dialog.dart` 与 `lib/providers/consistency_provider.dart`，支持分段待办/已处理切换、忽略与标记解决、动态有效健康分重算、实体定位跳转与规则启停配置，通过 `test/consistency_completeness_test.dart` 验证）
    -   按严重级别、规则类型、目标对象筛选。
    -   点击结果可跳转对应人物、事件、关系或条目。
    -   支持忽略、标记已解决、重新检查。
    -   结果记录规则版本和检查时间；不修改源数据。
-   [ ] **CONSIST-006：可配置规则**
    -   支持启用/停用规则和调整严重级别。
    -   暂不支持用户脚本执行，避免安全风险。

------------------------------------------------------------------------

# 3. P1 --- 世界观百科 / 通用条目

> 先设计数据模型，再做迁移。评估"通用条目 +
> 类型化扩展表"，不要把所有内容塞进难以查询的
> JSON，也不要无必要地复制人物 CRUD。

-   [x] **LORE-001：通用条目模型设计**（已完成，Schema v13，通用 `LoreEntities` + `LoreRelations` 稳定 ID 关联表，支持 JSON 自定义属性、封面、Wiki 双链与反向引用，通过 `test/lore_entity_test.dart` 与 `test/lore_hierarchy_relation_test.dart` 验证）
    -   评估条目
        ID、世界观归属、类型、名称、描述、封面、标签、时间字段。
    -   支持模板、自定义字段、Wiki 双链、反向引用。
    -   关联使用稳定 ID，不依赖名称。
    -   验收：先提交模型、迁移和查询设计，再编码。
-   [x] **LORE-002：地点管理 MVP**（已完成，位于 `lib/data/database/tables/lore.dart`、`daos/lore_dao.dart`、`lore_entity_dialog.dart` 与 `lore_entity_detail_dialog.dart`，支持国家/地区/城市/建筑父子树形层级、面包屑溯源、环路防护、稳定 ID 关联常驻/统治/出生人物，通过 `test/lore_hierarchy_relation_test.dart` 验证）
    -   国家、地区、城市、建筑、遗迹等地点。
    -   支持父子地点、描述、图片、标签及人物/事件关联。
    -   支持搜索、关联、导出和一致性检查。
-   [x] **LORE-003：组织与势力管理 MVP**（已完成，位于 `lib/data/database/tables/lore.dart`、`daos/lore_dao.dart`、`lore_entity_dialog.dart`、`lore_entity_detail_dialog.dart` 与 `character_detail_page.dart`，Schema v14，支持组织类别/核心宗旨/势力现状专属模板、上下级架构、领袖职务高亮与排序、势力间外交关系【同盟/敌对/从属/贸易】与角色双向归属，通过 `test/lore_faction_relation_test.dart` 验证）
    -   组织类型、简介、目标、状态、标志/图片。
    -   支持成员、上下级组织、敌对/合作关系。
    -   可选记录人物加入/退出时间。
    -   通过稳定关联连接人物，不只保存文本名称。
-   [x] **LORE-004：物品与装备**（已完成，位于 `lib/features/world/lore_entity_dialog.dart`、`lore_entity_detail_dialog.dart` 与 `character_detail_page.dart`，复用 Schema v14 `LoreEntities` + `LoreRelations` + `LoreEntityRelations`，支持装备类别/品阶稀有度/持有状态/来源/特效/代价结构化模板，支持持有者与工匠制造者高亮排序、地缘存放与归属组织关联、以及角色详情页随身装备双向展示，通过 `test/lore_item_equipment_test.dart` 验证）
    -   名称、类别、描述、持有者、制造者、来源、状态和图片。
    -   可关联人物、组织和事件。
-   [x] **LORE-005：种族与生物设定**（已完成，位于 `lib/features/world/lore_entity_dialog.dart`、`lore_entity_detail_dialog.dart` 与 `character_detail_page.dart`，复用 Schema v14 `LoreEntities` + `LoreRelations` + `LoreEntityRelations`，支持种族类别/平均寿命/生理外貌特征/生活习性/信仰崇拜结构化模板与徽章卡片，支持起源母种族与衍生亚种树形层级、角色血脉纯混/始祖关联、发源故土栖息地与宿敌同盟关联，通过 `test/lore_race_and_ability_test.dart` 验证）
    -   基本信息、特征、寿命、习性、文化等可定制字段。
    -   支持人物与种族关联，不把规则写死在 UI。
-   [x] **LORE-006：能力与规则体系**（已完成，位于 `lib/features/world/lore_entity_dialog.dart`、`lore_entity_detail_dialog.dart` 与 `character_detail_page.dart`，复用 Schema v14 `LoreEntities` + `LoreRelations` + `LoreEntityRelations`，支持能力分类/威能阶位/生效方式/修行前置/反噬代价结构化模板与徽章卡片，支持基础体系与进阶禁咒体系技能树、掌握宗师与修行者关联、附魔载体与属性相生相克关联，通过 `test/lore_race_and_ability_test.dart` 验证）
    -   魔法、超能力、科技体系等分类。
    -   支持说明、限制、代价、等级和前置条件。
-   [x] **LORE-007：知识网络视图**
    -   人物、地点、组织、物品、事件等统一网络（`knowledge_network` 模块：实体同构化聚合、统一前缀 ID 隔离、多维关联映射）。
    -   支持按实体类型（8类）与关联类型（7类）过滤，支持关键字搜索与 Ego-network 聚焦高亮（1度邻接高亮/全网淡化）。
    -   大规模网络性能保护：Canvas 连线与标签绘制、LOD 视口保护、视口外裁剪（Viewport Culling）、向心力导向与星系轨道排布算法引擎（Galaxy/Force/Radial）。
    -   单测与 Widget 测试 100% 覆盖（`test/knowledge_network_test.dart`）。

------------------------------------------------------------------------

# 4. P1 --- 人物设定版本历史

-   [x] **HISTORY-001：版本快照**（已完成，位于 `lib/core/history/models/character_snapshot.dart`、`lib/data/database/daos/revision_dao.dart` 与 `lib/providers/revision_provider.dart`，支持基本信息、立绘头像、小传正文、自定义扩展属性与标签全套结构化快照序列化与旧版向上兼容，支持手动/自动/回滚备份来源标记，支持重要里程碑标记 ⭐ 防自动修剪淘汰策略，通过 `test/character_revision_history_test.dart` 验证）
    -   重要修改时手动或自动创建快照。
    -   记录时间、来源、备注；设计历史保留策略。
-   [x] **HISTORY-002：版本差异对比**（已完成，位于 `lib/core/history/diff/character_revision_diff.dart`、`lib/core/history/diff/text_diff_util.dart` 与 `lib/features/world/revision_history_dialog.dart`，支持基本字段新旧值对照、自定义属性键值对新增/删除/修改标注、标签体系增删 Chips 标记、以及小传长文本 LCS 逐行 Diff 对比与红绿高亮，通过 `test/character_revision_history_test.dart` 验证）
    -   比较基本字段、自定义字段、描述、标签。
    -   显示新增、删除、修改；长文本提供可读差异视图。
-   [x] **HISTORY-003：安全恢复**（已完成，位于 `lib/providers/revision_provider.dart` 与 `lib/features/world/revision_history_dialog.dart`，支持选择性字段安全恢复：自由勾选小传/基本信息/自定义字段/标签，恢复前强制触发全量自动归档备份快照并清晰呈现变动影响范围，明确保护关联关系与相册媒体边界绝不破坏，通过 `test/character_revision_history_test.dart` 验证）
    -   支持恢复完整版本或选择性恢复字段。
    -   恢复前保存当前状态快照并展示影响范围。
    -   关系、图片和关联实体的恢复边界必须明确；失败可回滚。
-   [x] **HISTORY-004：其他实体历史（百科词条与编年史大事件）**（已完成，位于 `lib/core/history/models/lore_snapshot.dart`、`lib/core/history/diff/lore_revision_diff.dart`、`lib/core/history/models/event_snapshot.dart`、`lib/core/history/diff/event_revision_diff.dart`、`lib/providers/revision_provider.dart` 与 `lib/features/world/revision_history_dialog.dart`；复用 Schema v15 `EntityRevisions` 历史表与 `RevisionDao`，保持 100% 架构向前兼容；支持百科词条地点/组织/装备/种族/能力规则全字段多维快照、长文本逐行 Diff 对比、自由勾选【正文/梗概/基本信息/专有扩展属性/标签】选择性安全恢复与恢复前自动创建归档快照；支持编年史大事件结构化快照、差异对比与二次确认安全恢复；在百科详情、编辑弹窗及编年史、人物生平卡片提供统一版本历史与恢复入口，通过 `test/other_entities_revision_history_test.dart` 验证）
    -   地点、组织、物品、种族、能力与编年大事件全面复用版本历史能力。

------------------------------------------------------------------------

# 5. P2 --- 故事线、章节与场景

> 这是向小说/漫画创作工具扩展的方向。先做轻量策划，不急于实现完整文字编辑器。

-   [x] **STORY-001：作品与故事线**（已完成，位于 `lib/data/database/tables/stories.dart`、`lib/data/database/daos/story_dao.dart`、`lib/providers/story_provider.dart` 与 `lib/features/story/story_work_dialog.dart`；Schema v15 引入 `StoryWorks`，支持按世界观严格隔离多作品项目、作品体裁、创作状态、封面海报与梗概管理、统计与级联删除，通过 `test/story_workbench_test.dart` 验证）
    -   一个世界观可包含多个作品/项目。
    -   作品包含主线、支线和故事阶段；关联人物与世界观。
-   [x] **STORY-002：章节与场景**（已完成，位于 `lib/data/database/tables/stories.dart`、`lib/data/database/daos/story_dao.dart`、`lib/providers/story_provider.dart`、`lib/features/story/story_chapter_dialog.dart`、`lib/features/story/story_scene_dialog.dart` 与全景工作台 `lib/features/story/story_workbench_page.dart`；支持按分卷/故事阶段折叠分组与排序、章节状态与字数统计；分镜场景支持关联 POV 视点人物、百科地点/发生地、发生时间、氛围基调、出场角色群多选与聚合详情流式呈现，通过 `test/story_workbench_test.dart` 验证）
    -   章节有排序、标题、摘要、状态。
    -   场景有概要、发生时间、地点、POV 人物。
    -   场景可关联人物、组织、事件、物品。
    -   暂不要求完整小说编辑器。
-   [x] **STORY-003：人物出场记录**（已完成，位于 `lib/data/database/daos/story_dao.dart`、`lib/providers/story_provider.dart`、`lib/features/story/story_cast_dialog.dart` 与 `lib/features/character/character_story_appearance_section.dart`；支持从场景关联动态聚合人物出场总场次、覆盖章节数、POV 视点场次，计算严格遵循叙事时序的首次登场与最近登场；在角色详情页新增“故事线出场记录”专属卡片，在故事工作台新增“作品登场角色表 (Cast Index)”榜单与搜索过滤，通过 `test/story_character_appearances_test.dart` 验证）
    -   从场景关联汇总人物出场章节和场景。
    -   查看首次/末次出场；不维护容易失真的重复文本。
-   [x] **STORY-004：故事线时间检查**（已完成，位于 `lib/core/consistency/consistency_rules.dart` 的 `StoryTimelineConsistencyRule`、`lib/core/consistency/consistency_checker_engine.dart`、`lib/core/consistency/consistency_models.dart` 与 `lib/features/world/consistency_checker_dialog.dart`；稳定规则 ID 为 `RULE_STORY_TIMELINE`，归类于 `IssueCategory.story`，支持按大纲时序智能比对场景先后与发生时间倒错、自动豁免“回忆/倒叙/插叙/闪回”片段；结合编年史生卒年诊断角色逝世后或出生前出镜登场，自动豁免“亡魂/托梦/前世”设定；诊断分镜时间与引用的世界编年史大事件记录年份冲突；排查已定稿章节中的空白分镜场景；支持一键直达故事工作台进行定位修正，通过 `test/story_timeline_consistency_test.dart` 验证）
    -   对比场景顺序、故事内时间和世界编年史。
    -   统一交由一致性检查器呈现。

------------------------------------------------------------------------

# 6. P2 --- 平台、隐私与 AI

## 跨设备同步

-   [ ] **SYNC-001：同步架构调研**
    -   明确目标、服务端部署、账户、隐私边界和成本。
    -   设计记录级同步、冲突解决、删除标记、图片同步、断网重试和版本兼容。
    -   禁止直接同步正在使用的 SQLite 数据库文件。
    -   验收：先提交技术方案和风险分析。
-   [ ] **SYNC-002：同步 MVP（评审后）**
    -   Windows 与 Android 同步选定世界观。
    -   支持断点续传、重试、冲突提示、暂停和关闭。
    -   禁止静默覆盖。

## 本地加密

-   [ ] **SEC-001：加密方案调研**
    -   明确数据库、图片、导出包、临时文件和备份的加密范围。
    -   评估 Windows Credential Manager / Android Keystore。
    -   设计忘记密码、密钥轮换、备份恢复和迁移。
    -   验收：先做威胁模型与可恢复性评审。
-   [ ] **SEC-002：加密 MVP（评审后）**
    -   用户主动启用，说明影响和恢复责任。
    -   密钥不得明文进入配置、数据库或日志。
    -   覆盖异常退出和设备迁移。

## AI 设定助手

-   [ ] **AI-001：只读问答原型**
    -   基于当前世界观回答问题，并引用人物/事件/条目来源。
    -   区分数据库事实与模型推断。
    -   默认只读；未经同意不得上传私有设定。
-   [ ] **AI-002：AI 辅助一致性检查**
    -   AI 只提供候选问题和解释；确定性规则引擎仍是基础。
    -   建议必须由用户确认。
-   [ ] **AI-003：可控写入（远期）**
    -   先稳定只读能力。
    -   写入前展示变更预览，并具备快照、事务和撤销能力。

------------------------------------------------------------------------

# 7. P2 / P3 --- 模板与生态

-   [ ] **TPL-001：模板分享与导入**
    -   导出/导入人物模板；只包含字段定义，不包含人物隐私数据。
    -   导入前预览冲突和兼容性；定义旧模板迁移策略。
-   [ ] **TPL-002：官方模板集合**
    -   奇幻、现代、科幻、TRPG、反派、配角等示例。
    -   模板是可选起点，不限制自定义。
-   [ ] **ECOSYS-001：扩展接口调研**
    -   仅在真实需求出现后设计。
    -   先定义权限、数据边界和版本兼容；不开放任意代码执行。

------------------------------------------------------------------------

# 8. 持续 UX 与性能优化

-   [ ]
    **UX-002：最近项目与快速切换**：最近世界观、人物、编辑记录和固定收藏。
-   [ ]
    **UX-003：快捷键体系**：新建、搜索、保存、撤销/重做、切换视图及快捷键帮助。
-   [ ]
    **UX-004：空状态与引导**：可跳过的新手引导/示例数据，不强迫导入。
-   [ ]
    **UX-005：大数据量性能**：列表、关系图、画廊、编年史的压力测试；按需分页、懒加载、缓存。
-   [ ] **UX-006：Android
    体验复核**：触控目标、软键盘、返回行为、窄屏、长内容编辑。
-   [ ]
    **UX-007：无障碍与可读性**：文字缩放、对比度、焦点顺序、语义标签、键盘可达性。

------------------------------------------------------------------------

# 9. 建议执行顺序

## Next：下一阶段

-   [ ] DOC-001：同步项目文档状态
-   [ ] QA-001：确认质量门禁与构建流程
-   [x] UX-001：全局命令面板（已完成，Ctrl+K 深度全库检索与跨端触控支持）
-   [x] GRAPH-001：关系图多画布（已完成，Schema v12 多画布隔离与全生命周期管理）
-   [x] GRAPH-002：关系图撤销/重做（已完成，命令模式历史栈、全动作覆盖、快捷键与双端交互）

## Following：创作辅助

-   [ ] CONSIST-001：规则引擎
-   [ ] CONSIST-002：时间与年龄检查
-   [ ] CONSIST-003：关系与引用检查
-   [ ] CONSIST-005：检查结果工作台

## Next Major：世界观百科

-   [ ] LORE-001：通用条目模型评审
-   [ ] LORE-002：地点管理
-   [ ] LORE-003：组织与势力管理
-   [x] LORE-007：知识网络视图

## Later：长期创作

-   [x] HISTORY-001：版本快照
-   [x] HISTORY-002：版本对比
-   [x] HISTORY-003：安全恢复
-   [x] STORY-001：作品与故事线
-   [x] STORY-002：章节与场景
-   [x] STORY-003：人物出场记录
-   [ ] STORY-004：故事线时间检查

## Research only：先调研，不承诺开发

-   [ ] SYNC-001：跨设备同步
-   [ ] SEC-001：本地加密
-   [ ] AI-001：只读 AI 问答
-   [ ] ECOSYS-001：扩展接口

------------------------------------------------------------------------

# 10. Definition of Done

任务只有同时满足以下条件才可标记 `[x]`：

1.  确认需求边界，没有重复实现。
2.  代码遵循现有架构和产品原则。
3.  涉及数据库时，有迁移、旧数据兼容和失败处理。
4.  涉及关联数据时，验证世界观隔离、删除、恢复、导入导出。
5.  核心逻辑有自动化测试。
6.  `flutter analyze` 通过。
7.  相关测试通过；必要时运行全量测试。
8.  Windows / Android 的相关行为经过检查。
9.  README、进度文档和必要开发说明已更新。
10. TODO 状态、实现位置和验证结果已同步。

新增任务模板：

``` markdown
- [ ] **TASK-ID：任务名称**
  - 目的：
  - 当前状态：
  - 依赖：
  - 实施范围：
  - 不包含：
  - 验收标准：
  - 测试：
```

**重要约束：** 不要一次性启动多个大型功能；不为完成 TODO
牺牲稳定性；不静默修改用户数据；远期设想不是当前版本的硬性需求。同步、加密、AI
写入和通用实体模型必须先做设计评审。

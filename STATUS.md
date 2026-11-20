# OC Manager 会话进度与系统状态同步简报 (STATUS.md)

> **[信源提示]** 本文档为不同 AI 会话与人类开发者之间的**跨会话进度与系统状态同步真实信源**。  
> **核心原则**：每次会话完成代码改动或功能推进时，**必须同步在此更新最新进度与验证结果**。

---

## 📌 1. 项目基准状态 (Current Benchmark)

| 维度 | 当前指标 / 状态 | 说明 |
| :--- | :--- | :--- |
| **应用版本** | `v1.8.0+5` | 最新稳定语义版本 |
| **底层数据库** | Drift SQLite **Schema v15** | 包含地点层级外键 `LoreEntities.parentId`、人物稳定关联 `LoreRelations`、实体相互关系 `LoreEntityRelations`、以及故事作品 `StoryWorks`、分卷章节 `StoryChapters`、场景分镜 `StoryScenes` |
| **测试套件状态** | **210 / 210 项全部通过 (100%)** | 覆盖百科词条与编年史大事件多维结构化快照、长文本逐行差异对比、选择性字段恢复与自动归档备份、故事分镜与大纲时序倒错智能诊断、回忆/倒叙/闪回自动豁免、角色生卒年死后与出生前出场矛盾检测、亡魂/托梦/前世自动豁免、分镜时间与编年史大事件记录冲突校验、定稿章节空白分镜排查、故事作品与故事线管理、分卷章节大纲与字数统计、场景分镜POV视点/地点/氛围/出场角色群关联与流式工作台、人物出场时序记录与演职榜单统计、人物设定版本快照与里程碑保护策略、多维度与行级差异比对、选择性安全恢复、种族与能力体系、知识网络拓扑、Canvas LOD绘制与视口裁剪、物品装备管理、组织势力外交等 |
| **代码静态分析** | **0 Issues Found** | `flutter analyze` 零错误、零警告 |
| **系统架构** | Flutter 3.x + Riverpod 2.6 + Drift | 本地优先（Local-First）、沙盒隔离 |

---

## 🔄 2. 最近会话变更记录 (Session Changelog)

### [2026-11-20] 阶段 AS：全库巨型单体源文件瘦身与高内聚组件化重构 (Codebase Slimming & Modularization)
- **重构原则与架构安全**：
  - 遵循“纯提取无损重构（Extract-Only Refactoring）”，不破坏任何已有逻辑、SQL 事务或界面行为；
  - 运用 Barrel Export 与向后兼容别名，保持对外调用 100% 透明无感；
- **核心文件瘦身数据与成果**：
  1. **`consistency_rules.dart` (1,335 行 -> 12 行，瘦身 99%)**：抽离至 `lib/core/consistency/rules/`（6 个规则独立拆分：完整性、图文关联、人物关系、生卒年死后矛盾、故事出场矛盾、百科双链等）；
  2. **`revision_history_dialog.dart` (2,429 行 -> 475 行，瘦身 80%)**：抽离至 `lib/features/world/revision/`（提取 5 个独立组件：人物预览工作区、词条预览工作区、事件预览工作区、选择性恢复弹窗、差异对比徽章）；
  3. **`lore_entity_detail_dialog.dart` (1,865 行 -> 378 行，瘦身 80%)**：抽离至 `lib/features/world/lore_details/`（提取 6 个独立卡片组件：专有属性、下级空间、人物流、实体外交关系网、顶栏徽章与添加关系弹窗）；
  4. **`character_detail_page.dart` (1,888 行 -> 563 行，瘦身 70%)**：抽离至 `lib/features/character/`（提取 3 个独立业务卡片：属性雷达图 `CharacterStatsSection`、百科归属 `CharacterLoreSection`、人物关系与分组选择器 `CharacterRelationSection` / `CharacterGroupSelector`）；
  5. **`booklet_export_service.dart` (1,202 行 -> 145 行，瘦身 88%)**：抽离至 `lib/core/export/booklet/`（提取 CSS 模板、SVG 雷达图生成器、通用文件辅助函数、HTML 导出生成器、Markdown ZIP 打包器）；
  6. **`story_workbench_page.dart` (1,174 行 -> 341 行，瘦身 71%)**：抽离出 `story_chapter_outline_panel.dart`（章节分卷大纲树与操作）与 `story_scene_flow_panel.dart`（分镜场景流时间线卡片）；
  7. **`relation_graph_page.dart` (3,641 行 -> 2,591 行，瘦身 29%)**：抽离出 `relation_graph_painters.dart`（`RelationPainter` 关系连线、`GridPainter`、`ConnectingLinePainter`、`calculateRelationLabelCenters`）与 `relation_graph_node.dart`（`DraggableNode`、`RelationSidebarItem`、`buildGenderShape`）；
- **全量回归验证**：
  - `flutter analyze` 保持 **0 issues found**；
  - `flutter test` **210 / 210 项 100% 全部通过 (Pass)**。

### [2026-11-20] 阶段 AR：HISTORY-004 其他实体历史（百科词条与编年史大事件）全字段快照与选择性恢复闭环
- **实体快照模型扩展与历史表架构复用**：
  - 复用已有的 `EntityRevisions` 历史表与 `RevisionDao`，保持 **Schema v15**，无需升级数据库 Schema，100% 向前兼容；
  - **`LoreSnapshot` 百科实体快照模型 (`lib/core/history/models/lore_snapshot.dart`)**：
    - 支持地点、组织势力、物品装备、种族生物、能力体系等全部百科分类；
    - 完整捕获实体名称、类别、简要梗概、长篇正文设定、封面图片、上级父节点、自定义专有扩展属性字典（如装备品阶/代价、种族寿命、能力反噬等）、标签体系、快照时间戳与重要里程碑星级标记 ⭐；
    - 支持 JSON 序列化、反序列化，并完全兼容早期仅存正文文本的历史遗留记录；
  - **`EventSnapshot` 编年史大事件快照模型 (`lib/core/history/models/event_snapshot.dart`)**：
    - 完整捕获纪元年份、大事件标题、详细描述正文、事件分类、重要度星级与关联角色等信息；
- **差异比对与选择性安全恢复引擎**：
  - **`LoreRevisionDiffEngine` 与 `LoreDiffResult` (`lib/core/history/diff/lore_revision_diff.dart`)**：
    - 支持基本信息（名称、分类、封面、上级节点）新旧值比对；
    - 梗概与专有扩展属性键值增删改标注；
    - 标签体系增删 Chips 标注；
    - 百科正文调用 `TextDiffUtil.computeLineDiff` 进行长文本 LCS 逐行差异分析与红绿高亮；
    - 提供 `countAffectedFields()` 供创作者直观预知影响范围；
  - **`LoreSelectiveRestoreOptions` 与选择性安全恢复 (`RevisionActions.restoreLoreSelective`)**：
    - 创作者可自由勾选恢复正文、梗概、基本信息、专有属性、标签体系中的任意部分；
    - 恢复前**强制自动创建 `restore_backup` 归档快照**，绝不丢失当前未保存状态；
    - 严格保持世界观隔离与外键关联安全；
  - **`EventRevisionDiffEngine` 与大事件安全恢复 (`RevisionActions.restoreEvent`)**：
    - 比较年份、标题、分类、星级及长篇描述差异，恢复前同样自动创建归档快照；
- **通用版本历史工作台升级 (`RevisionHistoryDialog`)**：
  - 扩展支持 `lore: LoreEntity` 与 `event: TimelineEvent` 参数；
  - 当传入词条时，右侧工作区分栏渲染“词条差异 (Diff)”与“快照内容”专属选项卡，点击恢复弹出选择性恢复多选弹窗；
  - 当传入大事件时，右侧渲染“事件差异 (Diff)”专属选项卡，点击恢复触发二次确认与快速回滚；
- **UI 交互与历史记录点接入**：
  - **百科条目详情与编辑 (`LoreEntityDetailDialog` & `LoreEntityDialog`)**：
    - 详情对话框顶栏提供“版本历史与快照恢复”入口；
    - 编辑条目保存时，自动比对内容变动并异步调用 `recordLoreSnapshot` 保存版本；
  - **编年史大事件与人物生平 (`ChroniclePage` & `CharacterTimelineSection`)**：
    - 事件卡片提供版本历史入口；
    - 编辑保存事件时，自动调用 `recordEventSnapshot` 留痕；
- **全自动化测试套件扩充**：
  - 新增全量测试套件 [`test/other_entities_revision_history_test.dart`](file:///c:/Users/IceLolly/Music/idea/oc_manager/test/other_entities_revision_history_test.dart)（覆盖 LoreSnapshot 序列化与旧版兼容、多维 Diff 计算、快照记录与里程碑防修剪淘汰、选择性恢复与恢复前安全归档、EventSnapshot 差异与回滚、UI 弹窗集成等 6 项测试全部通过）；
  - 全工程测试总数达 **210 / 210 项全部通过**，`flutter analyze` 保持 **0 issues found**。

### [2026-11-20] 阶段 AQ：STORY-004 故事线时间检查 全面闭环
- **故事分镜与编年时序一致性规则 (`StoryTimelineConsistencyRule`)**：
  - 稳定规则 ID 为 `RULE_STORY_TIMELINE`，归类于 `IssueCategory.story`（故事分镜时序，配备 `Icons.movie_creation_outlined`），默认级别 `IssueSeverity.warning`；
  - **1. 场景叙事时序与故事内时间倒错检查**：
    - 同一作品内场景按“分卷章节排序 -> 场景分镜序号”编排大纲顺序；
    - 若排在后面的分镜标注时间早于前序场景，报告 `IssueSeverity.warning`（分镜场景时序发生倒错）；
    - **合法倒叙/插叙智能豁免**：若场景标题、摘要、内容或章节名称包含“回忆、倒叙、插叙、昔日、当年、往昔、前尘、闪回、追忆、序曲、flashback、prelude、prologue”等关键词，自动放行不予报警；
  - **2. 角色死后与出生前年代出场矛盾诊断**：
    - 结合编年史中角色的确凿出生与逝世纪元年份；
    - 若场景标注时间晚于角色逝世年份，且出场名单（或 POV 视点人物）包含该角色，报告 `IssueSeverity.error`（角色于逝世后年代在场景中登场）；
    - **合法亡魂/托梦/英灵智能豁免**：若场景氛围或要点包含“亡魂、英灵、幽灵、托梦、幻象、幻影、残魂、追忆、回忆、重塑、复活、重生、死后、冥界”，自动放行不予报警；
    - 若场景标注时间早于角色出生年份，且出场名单包含该角色，报告 `IssueSeverity.error`（角色于出生前年代在场景中登场，支持“前世/前尘/起源/预言”豁免）；
    - 针对单角色定向检查模式（`checkCharacter`），自动定向过滤只针对该角色进行生卒年诊断；
  - **3. 场景提及世界编年史事件的时间锚点比对**：
    - 当分镜场景标题或内容引用世界编年史大事件（如 `[[苍穹裂隙战役]]` 或同名大事件）；
    - 自动比对分镜发生时间与该大事件记录年份，若存在冲突，报告 `IssueSeverity.warning`；
  - **4. 定稿章节中的空白分镜完整性排查**：
    - 当章节处于“已定稿”或“撰写中”状态，若场景未填写时间、地点、视点人物且无内容/摘要，报告 `IssueSeverity.info` 提示创作者补充设定；草稿章节不予打扰。
- **一致性架构集成与交互打通**：
  - `ConsistencyContext` 扩展只读强类型属性 `works`, `chapters`, `scenes`（默认空列表，100% 保持向前兼容）；
  - `ConsistencyCheckerEngine`：
    - `createDefaultRegistry()` 内置规则扩充至 6 条（新增 `StoryTimelineConsistencyRule`）；
    - `_buildContext` 自动异步加载世界观下的故事作品、章节与场景分镜；
  - `ConsistencyCheckerDialog`：
    - `_handleNavigate` 支持分类 `case 'story'`，点击一键跳转进入 `/world/:worldId/story` 故事工作台即时定位与修改。
- **DAO 批量检索能力扩充 (`StoryDao`)**：
  - 新增 `getChaptersByWorks(List<int> workIds)` 与 `getScenesByChapters(List<int> chapterIds)`，支持批量一次性加载。
- **全自动化测试套件扩充**：
  - 新增全量专项测试套件 [`test/story_timeline_consistency_test.dart`](file:///c:/Users/IceLolly/Music/idea/oc_manager/test/story_timeline_consistency_test.dart)（涵盖规则元数据、时序倒错诊断与回忆豁免、死后出场矛盾与亡魂豁免、出生前出场矛盾、编年史大事件冲突、定稿章节空白分镜排查、单角色模式定向过滤、引擎数据库集成测试等 9 项测试）；
  - 更新 `test/consistency_rule_engine_test.dart` 规则数量与注册过滤断言；
  - 全工程自动化测试总数达到 **204 / 204 项全部 100% 绿色通过**，`flutter analyze` 保持 **0 issues found**。

### [2026-11-20] 阶段 AP：STORY-003 人物出场记录与演职榜单 全面闭环
- **底层出场时序聚合引擎 (`StoryDao`)**：
  - **角色完整出场汇总 (`getCharacterAppearanceSummary`)**：
    - 针对指定角色动态检索其在世界观所有作品、分卷、章节与分镜场景中的出场轨迹；
    - 严格遵循多维叙事顺序（作品排序/创建时序 -> 分卷章节序号 -> 场景分镜序号）对场景严格排序，确保时序严密；
    - 汇总计算：出场总场景数（`totalScenes`）、覆盖章节数（`totalChapters`）、POV 视点场次（`totalPovScenes`）、分作品场景数映射字典；
    - 准确提取：**首次出场 (`firstAppearance`)** 与 **最近登场 (`lastAppearance`)** 的作品名称、章节标题、分镜标题、POV 标记与发生时间；
  - **作品演职角色榜单 (`getWorkCharacterCastStats`)**：
    - 统计指定作品下全部登场角色，按出场场景数倒序、POV 视点场次倒序、覆盖章节数倒序智能排行；
    - 提取每位演职成员的首次登场章节与分镜信息。
- **状态管理层集成 (`lib/providers/story_provider.dart`)**：
  - 导出 `characterAppearanceSummaryProvider` 与 `workCastStatsProvider`；
  - 在 `StoryActions` 执行场景创建、更新或删除时，自动化精确失效与重算相关缓存。
- **角色详情页故事线出场卡片 (`CharacterStoryAppearanceSection`)**：
  - 在 `CharacterDetailPage` 底部集成“故事线出场记录 (Story Appearances)”专属卡片；
  - **总览指标 Bar**：出场 X 场景、覆盖 Y 章节、POV 视点 Z 场；
  - **首末登场双卡片**：“首次登场”与“最近登场”独立卡片呈现，标明作品、分卷章节、场景名、POV 标识与时间节点；
  - **按作品分层轨迹**：Expandable 折叠面板展示该角色在各个作品下的场景清单与 POV/时间徽章；
  - **优雅空状态与跳转**：角色尚无出场时引导用户前往故事创作工作台，提供直达快捷按钮。
- **作品登场角色总览弹窗 (`StoryCastDialog`)**：
  - 在 `StoryWorkbenchPage` 顶部作品控制栏新增“作品登场角色表 (Cast Index)”入口；
  - 呈现作品登场角色的金银铜与序号排名徽章（#1 领衔主演等）；
  - 展示出场场次、覆盖章节数、POV 场次、首次登场定位；
  - 内置即时搜索框过滤角色名称，提供“查看角色档案”直达跳转。
- **验证结论**：新增全量专项测试套件 [`test/story_character_appearances_test.dart`](file:///c:/Users/IceLolly/Music/idea/oc_manager/test/story_character_appearances_test.dart)（5 项专项全流程测试 100% 通过），全工程自动化测试总数扩充至 **195 / 195 项全部 100% 绿灯通过**，`flutter analyze` 保持 **0 issues found**。

### [2026-11-20] 阶段 AO：STORY-001 作品与故事线 & STORY-002 章节与场景分镜 全面闭环
- **创作数据模型与底层架构 (STORY-001 & STORY-002 · `Schema v15`)**：
  - **作品与项目管理 (`StoryWorks`)**：`id`, `worldId`, `title`, `type`（小说/漫画/剧本/游戏企划/跑团模组/设定短篇）, `summary`, `status`（策划中/连载中/已完结/暂搁置）, `coverImagePath`, `sortOrder`, `createdAt`, `updatedAt`；
  - **分卷故事线与章节 (`StoryChapters`)**：`id`, `workId`, `arcName`（所属故事阶段/分卷名称，如“第一卷：风暴初临”、“支线番外”）, `title`, `summary`, `status`（大纲/撰写中/已定稿/待重构）, `sortOrder`, `wordCount`（预估/实际字数）, `createdAt`, `updatedAt`；
  - **场景分镜表 (`StoryScenes`)**：`id`, `chapterId`, `title`, `summary`, `content`（分镜要点/台词草稿）, `povCharacterId`（外键关联 `Characters.id`，标定视点人物）, `locationId`（外键关联 `LoreEntities.id`，关联世界百科地点）, `locationName`（发生地点名称）, `timelineTime`（发生时间节点）, `mood`（场景氛围基调/情感色彩）, `characterIds`（JSON 数组，出场角色群多选，天然支持 STORY-003 出场统计）, `sortOrder`, `createdAt`, `updatedAt`；
  - **数据安全与级联删除事务保护 (`StoryDao`)**：应用层删除作品级联清理所属所有章节与场景分镜，删除章节级联清理所有场景分镜，严格防止孤儿数据与外键约束报错；角色与百科地点实体受到绝对安全隔离保护。
- **全景故事创作工作台 (`StoryWorkbenchPage`)**：
  - **顶部作品切换栏**：实时切换当前世界观下的不同作品，动态呈现体裁 Badge、状态 Badge、以及包含章节数、场景数与总字数的高效聚合统计，提供“新建作品”、“编辑作品”、“删除作品”入口；
  - **左侧大纲与分卷故事线面板**：自动按 `arcName` 分卷折叠分组呈现，展示序号、章节标题、状态色块 Badge（大纲/撰写中/已定稿/待重构）、字数统计，支持一键“添加章节”与快捷编辑/删除；
  - **右侧场景分镜流与卡片排布**：
    - 章节信息条：分卷名称、章节序号、标题、大纲摘要倾斜引用框、以及“添加分镜场景”按钮；
    - 场景卡片流：展示场景序号、标题、氛围 Badge（如紧张压抑、史诗壮烈）、POV 视点人物头像与 POV 专属高亮、发生地点（绿标）、发生时间（时钟标）、场景概要提炼、分镜剧情推进要点；
    - **出场角色群栏 (Cast)**：展示出场角色头像群 Chips（标注 POV 标签），为后续角色出场频率与时序分析提供无损底层。
- **对话框组件与路由打通**：
  - `StoryWorkDialog`：支持封面图上传裁切（复用 `ImageStorageService` 本地沙盒）、作品标题、体裁下拉、创作状态、简介；
  - `StoryChapterDialog`：支持章节标题、分卷名称（带自动归组提示）、状态、预估字数、大纲摘要；
  - `StorySceneDialog`：支持标题、POV 人物下拉（同世界观角色动态拉取）、百科地点关联/自由文本地点、时间节点、氛围基调推荐 Chips、出场人物 FilterChips 多选、分镜剧情要点；
  - `lib/app.dart`：注册全局路由 `/world/:worldId/story`；
  - `WorldDetailPage`：顶栏动作区正式添加“故事创作与场景分镜”快捷图标入口（`Icons.movie_creation_outlined`）。
- **验证结论**：新增全量专项测试套件 [`test/story_workbench_test.dart`](file:///c:/Users/IceLolly/Music/idea/oc_manager/test/story_workbench_test.dart)（涵盖作品 CRUD 与世界观隔离、分卷分组与章节字数排序、场景 POV/地点/氛围/出场角色聚合解析、作品全量字数场景统计、级联删除安全保护、工作台 Widget 渲染、作品/章节/场景三弹窗表单交互 10 项全流程测试），全工程自动化测试总数扩充至 **190 / 190 项全部 100% 绿灯通过**，`flutter analyze` 保持 **0 issues found**。

### [2026-11-20] 阶段 AN：HISTORY-001 ~ HISTORY-003 人物设定版本历史与差异恢复 全面闭环
- **全量结构化人设快照模型与保留策略 (HISTORY-001 · `CharacterSnapshot` & `RevisionDao`)**：
  - 突破单一小传限制，构建包含基本信息（姓名、性别、年龄、立绘路径）、人设小传长文本、自定义扩展属性键值对（`customFields`）与标签体系（`tags`）的全套结构化快照模型；
  - 存储于 `EntityRevisions.content`（采用 `_snapshot_type: character_v1` JSON 序列化，零 Schema 破坏性迁移，旧版纯小传无缝向上兼容）；
  - 支持手动快照（`manual`）、自动保存（`auto`）与回滚备份（`restore_backup`）三维来源标记；
  - **重要里程碑标记 (⭐) 与保留策略**：支持一键将关键节点快照标记为里程碑；在触发 `maxRetain` 自动修剪时，里程碑快照受永久保护跳过淘汰，优先修剪普通记录。
- **全维度字段与长文本逐行差异对比引擎 (HISTORY-002 · `CharacterRevisionDiffEngine` & `TextDiffUtil`)**：
  - 基本信息比对：姓名、性别、年龄、立绘变更对照（原值 -> 新值）；
  - 扩展属性比对：键值对新增（绿色 `+新`）、删除（红色 `-删`）、修改（橙色 `改`）；
  - 标签体系比对：新增标签与移除标签 Chips 差异着色；
  - 小传长文本行级 Diff：基于 LCS 算法轻量化逐行对比，输出直观的绿色新增行、红色删除行与带行号未变行代码风格视图。
- **选择性安全恢复与回滚前自动归档 (HISTORY-003 · `SelectiveRestoreOptions` & `RevisionHistoryDialog`)**：
  - **选择性维度恢复**：创作者在恢复弹窗中可自由选择恢复小传正文、基本信息、自定义字段或标签体系，精确控制还原范围；
  - **回滚前自动归档备份**：在执行任何恢复前，系统强制自动为当前全量设定打下 `restore_backup` 安全快照，零数据丢失隐患；
  - **明确恢复边界**：人物现有的家庭/社交/组织关联与相册媒体绝对不被触碰破坏，事务性写入确保失败原子回滚；
  - **多端入口打通**：在 `CharacterDetailPage` 顶部更多菜单（`PopupMenuButton`）与 `CharacterDescriptionSection` 中均可直接呼出设定版本历史工作台。
- **验证结论**：新增全量测试套件 [`test/character_revision_history_test.dart`](file:///c:/Users/IceLolly/Music/idea/oc_manager/test/character_revision_history_test.dart)（涵盖结构化快照、里程碑修剪保护、全字段差异对比、选择性恢复与回滚前自动归档、UI 选项卡与恢复弹窗交互），连同原有 `test/revision_history_test.dart` 全部通过，全工程自动化测试达到 **180 / 180 项全部 100% 绿灯通过**，`flutter analyze` 保持 **0 issues found**。

### [2026-11-20] 阶段 AM：LORE-005 种族与生物设定 & LORE-006 能力与规则体系 全面闭环
- **底层关系网络全面映射 (`LoreEntities` + `LoreRelations` + `LoreEntityRelations`)**：
  - 充分复用 Schema v14 通用关系模型，无需任何数据库破坏性重构与数据迁移风险：
    - `LoreEntities.parentId` 天然承载种族的“母种族 / 衍生亚种分支”与能力的“基础体系 / 进阶法系禁咒”技能树层级；
    - `LoreRelations` 强类型关联承载角色的种族血脉归属（纯血统、混血后裔、先祖始祖等）与能力掌握境界（创造宗师、大成巅峰、核心修习、血脉传承等）；
    - `LoreEntityRelations` 承载种族的发源故土/栖息地关联（如高等精灵起源于奎尔萨拉斯）、种族宿敌同盟关系、以及能力与法宝装备的载体附魔、属性相生相克（如寒冰禁咒附魔于极冰法杖、冰火属性相克）。
- **专属结构化模板与属性编辑器 (`LoreEntityDialog`)**：
  - 种族词条专属模板：种族类别、平均寿命、生理外貌特征、生活习性、社会文化、信仰崇拜，图片上传提示自适应“种族特征/图鉴”；
  - 能力词条专属模板：能力分类、威能阶位、生效方式、前置修行条件、反噬代价限制，图片上传提示自适应“符文法阵/技能图鉴”；
  - 上级关联提示语自适应“所属起源母种族 / 祖族分支”与“所属前置基础体系 / 进阶法系”。
- **详情页专属卡片、特色徽章与始祖/宗师置顶 (`LoreEntityDetailDialog`)**：
  - **种族特色徽章与卡片**：琥珀色形态分类 Badge、寿命 Badge（`寿命: 2000-3000年`）、青绿色生理与外貌特征卡片、琥珀色生活习性与信仰崇拜卡片；
  - **能力特色徽章与卡片**：紫色威能阶位 Badge（如天灾禁咒）、派系体系 Badge、紫色生效方式与威能表现卡片、深红色修习前置与反噬代价限制卡片；
  - **始祖与宗师置顶排序**：`_isLeaderOrOwnerRole` 智能识别“始祖/先祖/纯血/宗师/大成/巅峰”，置顶排序并配备专属徽章；添加成员与添加实体关系弹窗自适应提供专属快捷职务与关系类型；
  - **下级与成员文案自适应**：下属分支自适应为“衍生亚种 / 枝族分支”与“进阶法系 / 衍生体系”，成员文案自适应为“族系角色与血脉成员”与“创造宗师与修习掌握者”。
- **角色详情页与知识网络多维联动 (`CharacterDetailPage` & `knowledge_network_provider.dart`)**：
  - `CharacterDetailPage` 中设定归属卡片全面涵盖“所属势力与地点归属 / 随身装备 / 种族与能力”，支持一键为角色配置种族血脉与修得能力；
  - `knowledge_network_provider.dart` 中将角色与种族映射为从属关系（membership）、与能力映射为持有关系（ownership），百科实体相互关系中种族映射为栖息地缘（residence）、能力映射为附魔载体（ownership），层级连线自适应为“衍生亚种”与“进阶体系”。
- **验证结论**：新增全量专项测试套件 [`test/lore_race_and_ability_test.dart`](file:///c:/Users/IceLolly/Music/idea/oc_manager/test/lore_race_and_ability_test.dart)（6 项全流程测试 100% 绿灯通过），全工程自动化测试总数扩充至 **176 / 176 项全部 100% 绿灯通过**，`flutter analyze` 保持 **0 issues found**。

### [2026-11-20] 阶段 AL：LORE-007 知识网络视图 (Knowledge Network View) 全景闭环
- **全域知识网络统一拓扑模型 (`knowledge_network_models.dart` & `knowledge_network_provider.dart`)**：
  - 整合八类实体节点（人物、地点、组织、物品、种族、能力、事件、其他）与七类多维关联边（社交关系、组织职务/从属、地理常驻/出身、装备持有/锻造、势力外交、空间层级、大事记参与）；
  - 采用统一 ID 前缀命名空间隔离策略（`c_` 角色、`l_` 百科、`e_` 历史事件），彻底杜绝跨数据表整型主键冲突；
  - 自动汇聚计算各实体度数（Degree），建立完备的邻接索引与多维过滤能力（按实体类型、关联类型、关键字搜索与聚焦网络 Ego-network）。
- **向心力导向与星系排布算法引擎 (`knowledge_network_layout_engine.dart`)**：
  - `galaxy`（星系向心同心圆排布）：内核心环排布势力组织与顶级地点，中环环绕关键人物，外层轨道分布武器法宝、种族特征与编年史大事件；
  - `force`（力导向物理弹簧模拟）：基于库仑斥力 + 胡克引力 + 向心力 + 温度退火冷却算法，实现图谱自然聚类防重叠；
  - `radial`（环形度数排布）：按实体度数高低顺次排布。
- **高性能 Canvas 绘制器 (`knowledge_network_painter.dart`)**：
  - **视口裁剪保护 (Viewport Culling)**：根据当前可视矩形自动剔除视口外连线与标签，极大降低大图谱 GPU 负担；
  - **LOD (Level of Detail) 视口保护**：缩放比例小于 0.45 时智能隐藏连线文本测量排版，维持高帧率平滑缩放；
  - **视觉层次分明**：空间层级虚线指示、方向性连线箭头、关系标签药丸胶囊、星系轨道辅助线底衬与聚焦光晕外发光。
- **全景工作台 UI 与交互 (`knowledge_network_page.dart`)**：
  - `InteractiveViewer` 支持 0.15x ~ 2.5x 平滑平移与缩放，节点支持手势任意拖拽重排与双击快捷聚焦；
  - 顶部浮动工具栏：世界观徽标、实时搜索框、排布模式切换、视口一键重置居中、维度过滤配置弹窗（节点类型与边类型 Chip 启停）；
  - 右侧/底部实体检视卡片（Inspector Card）：点击节点即时展开，展示详细信息、关联脉络列表（支持点击跳转邻接节点）、一键聚焦/取消聚焦、直达详情卡片（角色详情页 / 百科实体详情弹窗）。
- **路由注册与系统入口挂载 (`app.dart`, `world_detail_page.dart`, `lore_encyclopedia_page.dart`)**：
  - GoRouter 注册 `/world/:worldId/knowledge-network`；
  - 世界观详情页顶栏增加知识网络快捷入口（`Icons.hub_outlined`）；
  - 世界百科大厅顶栏增加“知识网络”入口按钮。
- **验证结论**：新增全量测试套件 [`test/knowledge_network_test.dart`](file:///c:/Users/IceLolly/Music/idea/oc_manager/test/knowledge_network_test.dart)（涵盖图谱模型过滤、Ego-network 聚焦提取、算法排布、Painter LOD 与视口裁剪、Provider 数据聚合与 Widget 工作台交互），全工程自动化测试达到 **170 / 170 项全部 100% 绿灯通过**，`flutter analyze` 保持 **No issues found!**。

### [2026-11-05] 阶段 AK：LORE-004 物品与装备管理闭环
- **底层模型复用与高扩展设计 (`LoreEntities` + `LoreRelations` + `LoreEntityRelations`)**：
  - 充分利用现有 Schema v14 的通用关系模型，无痛实现物品与装备系统：
    - `LoreRelations`：记录角色与物品的稳定关联（如“持有者”、“制造锻造者”、“初代佩戴者”、“守护使者”等）；
    - `LoreEntityRelations`：记录物品与百科其他实体的地缘与归属（如物品【存放于/封印地】某地点、物品【归属于/宗派圣物】某组织、物品之间【共鸣套装/羁绊】或【克制对立】）；
  - 零表结构变更、零数据迁移风险，完全保证数据向后兼容。
- **物品结构化模板与专属属性 (`LoreEntityDialog`)**：
  - 在创建/编辑 `item` 词条时提供“填入装备预设”快捷按钮（一键预设：物品类别、品阶稀有度、持有状态、来源出处、特殊效果、使用代价）；
  - 图片上传提示语自适应切换为“装备立绘/图鉴”。
- **详情页专属卡片展示与职务排序 (`LoreEntityDetailDialog`)**：
  - **品阶与状态徽章**：顶部标题旁自动渲染宝石粉品阶 Badge（如“传说 (Legendary)”、“神话 (Mythic)”）与当前状态指示；
  - **特效与代价高亮卡片**：在正文前提供“装备特效与威能”专属粉色卡片以及“使用代价与限制”专属警告卡片；
  - **持有者高亮置顶**：通过 `_isLeaderOrOwnerRole` 将当前持有者/佩戴者/契约者自动置顶并赋予钻石高亮标识；添加角色时自适应推荐常用职务（当前持有者、制造锻造者、守护使者等）；
  - **地缘存放与归属组织**：关系区块自适应展示存放地点、归属派系或套装共鸣，支持一键快捷建立或解除关联。
- **角色详情页反向归属多维度展示 (`CharacterDetailPage`)**：
  - `_CharacterLoreSection` 升级为“所属势力与地点归属 / 随身装备”区块，直观展示角色身处的势力、常驻的地点以及所持有的武器/法宝；
  - 点击物品条目可直接呼出物品百科详情弹窗；支持在角色详情页直接为角色添加佩戴装备。
- **验证结论**：新增专项测试 [`test/lore_item_equipment_test.dart`](file:///c:/Users/IceLolly/Music/idea/oc_manager/test/lore_item_equipment_test.dart)（涵盖物品结构化属性、持有者/工匠关联、存放地/圣物归属/对立克制关系、详情弹窗渲染及角色详情页随身装备展示），全工程自动化测试达到 **163 / 163 项全部 100% 绿灯通过**，`flutter analyze` 保持 **No issues found!**。

### [2026-11-02] 阶段 AJ：LORE-003 组织与势力管理 MVP 闭环
- **底层 Schema v14 平滑演进与外交关系模型 (`LoreEntityRelations`)**：
  - 新建 `LoreEntityRelations` 实体间关系表（`id, worldId, fromLoreId, toLoreId, relationType, isBidirectional, note, createdAt`），天然支持组织与组织间的同盟、敌对、从属/附属、贸易伙伴、中立休战等外交关系；
  - `onUpgrade` 增量迁移 `if (from < 14) await m.createTable(loreEntityRelations);`，杜绝旧数据丢失；
  - 外键与级联安全保障：在 `LoreDao.deleteEntity` 与 `deleteEntitiesByWorld` 中同步级联清理所有相关实体间关系，彻底杜绝悬空引用与外键约束报错。
- **组织架构与成员职务体系 (`LoreDao` & `LoreProvider`)**：
  - **领袖识别与置顶排序**：在组织成员展示中内置 `_isLeaderRole`，将“领袖/会长/团长/首领/宗主/掌门/元首”等关键领导层置顶并配备尊荣徽章（主色高亮与王冠星标标识）；
  - **常用职务预设**：添加成员时提供快捷职务芯片（领袖、副会长、元老、军团长、核心骨干、正式成员、见习生、情报特工等），一键填入；
  - **双向归属打通**：在 `CharacterDetailPage` 中无缝集成 `_CharacterLoreSection`（所属势力与常驻地点展示区块），支持点击跳转对应百科详情及快捷关联/解除关联。
- **组织专属特征与外交关系交互 (`LoreEntityDialog` & `LoreEntityDetailDialog`)**：
  - **组织专属预设模板**：在编辑 `faction` 词条时提供“填入组织预设”快捷按钮（组织类别、核心宗旨、势力现状、组织规模），徽章上传提示自适应为“组织徽记/纹章”；
  - **顶部组织现状 Badge**：若组织配置了“势力现状”（如活跃繁荣、隐秘潜伏、全面开战等），在标题旁醒目呈现彩色状态指示芯片；
  - **核心宗旨/信条卡片**：如果组织拥有核心宗旨或信条，在摘要下方自动渲染特色引言卡片；
  - **势力外交关系工作流**：支持一键弹出外交关系建立弹窗（选择同世界观其他组织、设定关系类型、配置双向生效、输入外交条约/备注），并在词条页以彩色芯片（同盟-绿、敌对-红、从属-蓝、贸易-黄）直观呈现，支持点击无缝跳转与一键解除。
- **验证结论**：新增 `test/lore_faction_relation_test.dart`（覆盖 Schema v14 迁移、外交同盟/敌对双向与单向、级联删除安全、领袖排序、详情弹窗渲染及角色详情页归属卡片），全工程自动化测试达到 **160 / 160 项全部 100% 绿灯通过**，`flutter analyze` 保持 **No issues found!**。

### [2026-11-02] 阶段 AI：LORE-001 通用条目模型演进与 LORE-002 地点管理 MVP 闭环
- **底层 Schema v13 平滑升级与关联模型 (`LoreEntities` & `LoreRelations`)**：
  - `LoreEntities` 扩展可空自引用外键 `parentId`，天然支持国家 -> 地区 -> 城市 -> 建筑/遗迹等树形父子层级空间；
  - 新建 `LoreRelations` 稳定 ID 关联表（`worldId, loreId, characterId, role, createdAt`），将地点/组织与人物的弱文本关联升级为强类型外键索引；
  - `onUpgrade` 无损增量迁移，旧数据 `parentId` 保持 null 零破坏。
- **层级空间管理与环路安全防护 (`LoreDao`)**：
  - **子级空间查询与监听**：`getChildEntities` / `watchChildEntities` 支持下钻查询下辖地理空间；
  - **层级面包屑向上追溯**：`getAncestors` 沿 `parentId` 向上回溯至顶级根节点，内置 `visited` 集合彻底阻断循环嵌套死链；
  - **候选父级环路拦截算法 (`getAvailableParents`)**：编辑时自动计算并排除当前节点及其所有子孙后代节点，确保树状 DAG 拓扑无环性；
  - **删除脱钩与外键级联保护**：删除父节点时自动将下属子节点的 `parentId` 置空脱钩，删除角色/世界观时优先清理 `LoreRelations`，彻底杜绝 SQLite 787 外键冲突。
- **UI 与交互全链路打通 (`LoreEntityDialog` & `LoreEntityDetailDialog`)**：
  - **编辑弹窗上级空间选择**：创建或编辑地点/组织时，支持下拉选择其所属上级地理空间（如“所属国家/大区”），下拉选项动态过滤自身与后代；
  - **详情弹窗层级面包屑**：顶部呈现优雅可点击的面包屑导航（如 `洛丹伦王国 > 提瑞斯法林地 > 洛丹伦王城`），支持一键跨层级跳转；
  - **下属空间卡片流**：直观展示下辖子地点/分支机构（如王城下的“王宫大殿”），点击直达子实体详情；
  - **稳定关联人物与职务卡片**：展示常驻/统治/出生人物列表，包含头像 (`OcAvatar`)、姓名与职务胶囊（如“国王”、“成员”），支持一键呼出弹窗添加关联与移除关联。
- **验证结论**：新增 `test/lore_hierarchy_relation_test.dart`（5 项单测与 Widget 交互测试），全工程自动化测试达到 **156 / 156 项全部 100% 绿灯通过**，`flutter analyze` 保持 **No issues found!**。

### [2026-11-02] 阶段 AH：CONSIST-004 设定完整度检查与 CONSIST-005 检查结果工作台闭环
- **设定完整度与智能留白识别 (`CompletenessRule`)**：
  - **智能识别创作者有意留白 (`isIntentionalBlank`)**：自动识别带 `[留白]`、`【草稿】`、`(待定)`、`TBD`、`TODO`、`WIP`、`暂缺` 等显式标记的角色与百科条目，安全免检放行，严守 AGENTS.md 7.1“缺少信息不自动等同于矛盾”；
  - **空白孤岛角色诊断**：精准识别既无小传描述、也无任何社会关系纽带的孤岛角色（`completeness_isolated_empty`，`info` 级别）；
  - **角色人设小传空白**：已有社会关系网纽带但生平描述完全空白的角色，提醒丰富人物背景；
  - **意向立绘与头像追踪**：针对明确表达了立绘/约稿/插画意图但尚未配置头像与画廊切片的人物，精准生成视觉资产补充建议，杜绝对纯文字创作者造成视觉绑架；
  - **百科词条未明确分类与空内容**：自动诊断处于未分类（`uncategorized`/`default`）或正文摘要全空的图鉴条目。
- **只读工作台交互与规则启停 (`ConsistencyCheckerDialog` & `consistency_provider.dart`)**：
  - **忽略 (Ignore) 与标记已解决 (Resolve) 状态流转**：支持创作者一键将已知或暂不处理的条目放入已处理区，零源数据污染；
  - **自洽健康指数动态重算**：被忽略或标记解决的事项不再扣减自洽健康分，还原真实创作状态；
  - **待办与已处理分段切换 (`SegmentedButton`)**：支持随时在待办事项与已处理/已忽略事项之间切换与一键撤销恢复；
  - **规则配置抽屉 (`_showRuleConfigDialog` · CONSIST-006 雏形)**：支持实时勾选/停用 5 大内置诊断规则，响应式动态重新扫描。
- **验证结论**：新增 `test/consistency_completeness_test.dart`（6 项细分单测与 Widget 测试），全工程自动化测试达到 **151 / 151 项全部 100% 绿灯通过**，`flutter analyze` 保持 **No issues found!**。

### [2026-11-02] 阶段 AG：CONSIST-003 关系与引用一致性检查闭环
- **关系网结构完整性诊断 (`RelationIntegrityRule`)**：
  - **自环自关联排查**：检测 `fromCharacterId == toCharacterId` 的错误自环关系（`warning`）；
  - **失效幽灵关系排查**：检测端点角色在当前世界观已不复存在的孤儿关系（`error`）；
  - **成对重复冗余关系**：检测在同一方向或无向/双向意义上完全重复的 redundant 关系（`warning`）；
  - **孤立残留家谱分组**：当关系被标记为家谱/家族关系（`groupName` 包含家谱/家族/宗族/血亲），但角色在整个世界观中仅有单向孤立记录且无任何父母/子女/配偶双向印证时，触发温和提示（`info`）。
- **百科与 Wiki 双链跨界引用排查 (`WikiLinkIntegrityRule`)**：
  - **断裂双链诊断**：正文中出现的 `[[实体]]` 在当前世界观所有角色与词条中均无匹配时触发 `error`；
  - **跨世界观越界引用诊断**：当 `[[实体]]` 在当前世界观未命中，但在作者名下的其他世界观中存在同名实体时，智能识别并触发跨世界观越界警告（`warning`），提示可能存在世界观混淆或导入漏带。
- **验证结论**：新增 `test/consistency_relation_reference_test.dart`（5 项集成单测），全工程自动化测试达到 **145 / 145 项全部 100% 绿灯通过**，`flutter analyze` 保持 **No issues found!**。

### [2026-11-02] 阶段 AF：CONSIST-002 时间与年龄一致性检查闭环
- **纪元时间解析与模糊安全判定 (`TimelineDateParser`)**：
  - 提取独立工具 `TimelineDateParser`，精准识别正负纪元年份、公元前/BCE、星历年号等异构格式；
  - 自动识别“未知/不详/太古/远古/神话时代/???”等不可比较的留白词汇，安全返回 `isAmbiguous: true`，严格杜绝向创作者虚构报错。
- **生卒年与活动时序全维度交叉验证 (`TimelineLifespanRule`)**：
  - **生卒年逆序颠倒**：出生晚于逝世触发 `error`，列出生卒年切片并提供明确修改建议；
  - **逝世后生平事件**：触发 `warning`，智能放行追思、追封、冥诞、纪念与遗产类事件；
  - **出生前生平事件**：触发 `warning`，智能放行前尘、前世、先祖、起源与开天类前置背景事件；
  - **存活状态与死亡事件矛盾**：角色人设标记为正常存活，但在编年史中有确凿逝世事件时触发 `warning`；
  - **凡人超常寿命/跨度提示**：寿命或活动跨度 > 200 年且小传中缺少仙神/长生/不朽/吸血鬼/机械等超凡关键词时触发 `info` 友好提示。
- **验证结论**：新增 `test/consistency_timeline_age_test.dart`（9 项细分单测），全工程自动化测试达到 **140 / 140 项全部 100% 绿灯通过**，`flutter analyze` 保持 **No issues found!**。

### [2026-11-02] 阶段 AE：CONSIST-001 设定一致性检查规则引擎基础闭环
- **抽象规则契约与注册中心 (`ConsistencyRule` & `ConsistencyRuleRegistry`)**：
  - 定义标准高内聚抽象类 `ConsistencyRule`（规则稳定 ID、名称、说明、所属分类 `IssueCategory`、默认严重级 `IssueSeverity`、以及只读评估方法 `evaluate(context)`）；
  - `ConsistencyRuleRegistry` 负责内置规则集中管理与外部规则动态扩展，支持根据 `enabledRuleIds` 启停过滤；
  - 默认加载 5 大确定性规则：时间轴与生卒年时序 (`TimelineLifespanRule`)、关系网矛盾与自环 (`RelationIntegrityRule`)、维基双链断裂 (`WikiLinkIntegrityRule`)、多媒体资源丢失 (`MediaFileIntegrityRule`)、设定孤岛与空词条 (`CompletenessRule`)。
- **依据数据与修复建议全面升级 (`evidence` & `suggestion`)**：
  - 严格落实 AGENTS.md 7.1 原则：每条触发的 Issue 明确附带**触发依据数据切片**（如“未命中双链语法: [[xxx]]”、“出生: 2050, 逝世: 2010”）和**针对性修复建议**（如“核实生卒纪元年份”）；
  - 升级 `ConsistencyCheckerDialog`：单项卡片优雅呈现依据数据与建议，极大提升创作者纠错体感。
- **全量体检与单人物定向诊断双模调度**：
  - `ConsistencyCheckerEngine` 升级支持全世界观 `checkWorld` 与单角色极速定向检查 `checkCharacter`，自动根据作用域剪裁无关百科与外部关系网；
  - `consistency_provider.dart` 补齐 `characterConsistencyIssuesProvider` 响应流。
- **验证结论**：新增 `test/consistency_rule_engine_test.dart`（5 项单测与定向诊断测试），全工程自动化测试达到 **131 / 131 项全部 100% 绿灯通过**，`flutter analyze` 保持 **No issues found!**。

### [2026-11-02] 阶段 AD：GRAPH-005 关系图大画布导览与矢量导出 (Mini-map & SVG Export) 闭环
- **纯 Dart 实现 W3C 标准 SVG 矢量图谱导出器 (`GraphSvgExporter`)**：
  - 基于数学几何与标准 XML 字符串生成规范标准的矢量文件，零原生平台依赖；
  - 精确计算画布所有节点的外包矩形（Bounding Box），预留安全内边距（Padding）；
  - 完整呈现关系连线：单关系直接生成直线 `L` 路径，同节点对多重关系自适应计算垂直法向偏移，生成二次贝塞尔 `Q` 路径；
  - 关系箭头 Marker、双向关系线与胶囊药丸文本气泡；
  - 支持节点性别形状呈现（方形男、圆形女、菱形未知/其他），已故角色灰色渲染；
  - 严格 XML 特殊字符防注入转义（`&`, `<`, `>`, `"`, `'`），支持深色与浅色双背景主题。
- **悬浮全局导览小地图组件 (`GraphMinimap`)**：
  - 世界坐标到小地图等比投影算法，实时绘制所有角色节点与关系微缩拓扑；
  - 动态计算主画布逆矩阵（`Matrix4.inverted`），在小地图上精确绘制视口可见范围指示框（Viewport Box）；
  - 支持点击或拖动交互：反向计算目标世界坐标并触发 `onNavigate`，主画布视口瞬间居中对齐目标位置；
  - 响应式折叠/展开：支持一键将小地图收折为精致圆角浮动按钮，兼顾小屏与移动端可用性。
- **界面集成与双格式导出**：
  - `RelationGraphPage` 挂载 `GraphMinimap` 于右下角浮动层，与缩放视口双向联动；
  - AppBar 导出按钮升级为 `PopupMenuButton`，支持“导出为高清图片 (PNG)”与“导出为矢量图谱 (SVG)”。
- **验证结论**：新增 `test/graph_navigation_export_test.dart`（7 项单测与 Widget 测试），全工程自动化测试达到 **126 / 126 项全部 100% 绿灯通过**，`flutter analyze` 保持 **No issues found!**。

### [2026-11-02] 阶段 AC：GRAPH-002 关系图命令模式撤销与重做 (Undo & Redo) 闭环
- **命令模式全链路架构 (`GraphHistoryManager`)**：
  - 设计高内聚、零 Flutter Widget 耦合的命令模式架构，支持单节点移动 (`MoveNodeCommand`)、全量智能排版恢复 (`BatchMoveCommand`)、画布增删节点 (`AddNodeCommand` / `RemoveNodeCommand`)、关系创建/编辑/删除 (`CreateRelationCommand` / `BatchCreateRelationsCommand` / `UpdateRelationCommand` / `DeleteRelationCommand`)；
  - 关系回滚原生保留原始自增主键 `Relation.id`（`RelationActions.restore`），确保关联链路完整且不产生脏数据；
  - 严格隔离与安全边界：切换世界观（`didUpdateWidget`）或切换命名画布（`_switchToCanvas`）时，自动触发 `_historyManager.clear()`，彻底杜绝跨画布或跨世界观历史回滚污染。
- **双端无缝交互与桌面端全键盘支持**：
  - 顶部导航栏新增响应式 Undo / Redo 图标按钮，直观展示实时动作描述 Tooltip（如“撤销: 移动角色【V】(Ctrl+Z)”）与置灰禁用态；
  - `CallbackShortcuts` 全局绑定 `Ctrl+Z` / `Cmd+Z`（撤销）与 `Ctrl+Y` / `Ctrl+Shift+Z` / `Cmd+Shift+Z`（重做），智能感知文本编辑框焦点，杜绝输入法与小传编辑冲突。
- **验证结论**：新增 `test/graph_history_test.dart`（6 项命令回滚、栈容量与 Widget 界面测试），全工程自动化测试达到 **119 / 119 项全部 100% 绿灯通过**，`flutter analyze` 保持 **No issues found!**。

### [2026-11-02] 阶段 AB：GRAPH-001 关系图多命名画布管理 (Multiple Named Canvases) 闭环
- **底层 Schema v12 平滑升级与 DAO 封装 (`CanvasDao`)**：
  - 新建 `GraphCanvases` 表（`id, worldId, name, description, isDefault, viewportX, viewportY, zoomScale, filterConfig, createdAt, updatedAt`）；
  - `GraphLayouts` 表拓展 `canvasId` 可空外键关联；`onUpgrade` 针对现有数据库无损迁移，并在启动时自动为历史布局数据补全默认“主画布”；
  - `CanvasDao` 实现完整生命周期：`ensureDefaultCanvas`、`createCanvas`、`updateCanvas`、`setDefaultCanvas`、`duplicateCanvas`（完整克隆坐标与视口）、`deleteCanvas`（级联删除所属坐标并动态推举新默认画布）、`updateViewport`、`updateFilterConfig`。
- **全生命周期数据保护与回收站级联**：
  - `TrashProvider` 世界观软删除/还原完整纳入 `GraphCanvases` 与 `canvasId`；清空回收站时遵循拓扑依赖优先清 `graphLayouts` 与 `graphCanvases`，严守 SQLite 外键安全；
  - 画布删除严格限制在仅清理当前画布内排版坐标，角色与关系全局共享实体绝对完好不损。
- **UI 与交互全生命周期响应 (`RelationGraphPage`)**：
  - 顶部导航栏新增沉浸式画布胶囊选择器：直观显示当前画布名称及“默认”角标，下拉支持切换画布、新建画布、克隆当前画布、重命名、设为默认、删除画布；
  - 切换画布与拖拽/缩放结束（`onInteractionEnd`）时自动持久化平移/缩放视口与高级过滤配置，切换至新画布时平滑恢复专属视口与过滤器；
  - 避免 `dispose()` 生命周期触碰 unmounted Riverpod `ref`，实现视口/过滤配置常态化静默持久化。
- **验证结论**：新增 `test/graph_canvas_test.dart`（7 项 DAO 业务与 Widget 交互测试），全工程自动化测试达到 **113 / 113 项全部 100% 绿灯通过**，`flutter analyze` 保持 **No issues found!**。

### [2026-11-02] 阶段 AA：UX-001 全局命令面板 (Command Palette · Ctrl+K) 闭环
- **全局快捷键与跨端触控支持**：
  - Windows / macOS `Ctrl+K` / `Cmd+K` 全局无冲突呼出浮动面板；
  - `MainShell` 的 AppBar 新增触控图标按钮 `Icons.terminal_rounded`（提示“全局命令面板 (Ctrl+K)”），Android 端无物理键盘亦可一键触达。
- **全库实体模糊检索与加权排布 (`CommandPaletteService`)**：
  - 聚合 17 项系统命令（新建世界观/角色、编年史、关系图、百科、全景大盘、一致性检查、设定集导出、.ocpkg 导入导出、主题切换等）；
  - 动态深度检索：支持检索全库世界观、深度检索人物角色（姓名/描述/标签/自定义字段）、百科条目；
  - 空输入智能引导：空查询下默认呈现常用动作、现存世界观以及最近编辑的角色。
- **全键盘流畅交互 (`CommandPaletteDialog`)**：
  - 支持键盘上下键 (`↑↓`) 循环选择、回车 (`↵`) 执行、`Esc` 退出、输入防抖（150ms）、分类 Filter Chips（全部 / 命令 / 世界观 / 角色 / 词条）快速筛选。
- **全局状态联动 (`activeWorldIdProvider`)**：
  - 全局管理当前活跃世界观，命令面板执行命令时自动推导或引导选择世界观，选择世界观后自动联动主界面。
- **验证结论**：新增 `test/command_palette_test.dart`（5 项单测与 Widget 测试），全工程测试达到 **106 / 106 项全部 100% 绿灯通过**，`flutter analyze` 保持 **No issues found!**。

### [2026-11-02] 阶段 Z：全工程深度严苛代码审查与外键拓扑加固 (Second Deep Audit)
- **底层外键强校验与级联清理拓扑序 (ARC-02 & COR-02)**：
  - 在 `AppDatabase.migration.beforeOpen` 中显式执行 `PRAGMA foreign_keys = ON;`，确保底层 SQLite 外键检查百分之百强制生效；
  - 调整 `TrashProvider.deleteWorld` 中的清理顺序：将存在外键引用 `characters.id` 的 `TimelineEvents`、`GraphLayouts`、`LoreEntities`、`EntityRevisions` 提前至 `Characters` 之前清理，彻底根除物理/软删除时的 SQLite 787 外键冲突隐患。
- **沙盒扩展名白名单与恶意文件阻断 (SEC-02 & SEC-03)**：
  - 加固 `ImageStorageService`：`saveAvatarImage` 与 `saveGalleryImage` 增加扩展名白名单过滤（仅放行 `.png, .jpg, .jpeg, .webp, .gif, .bmp`），非图片后缀自动安全清洗为 `.jpg`；在 `resolveImageFile` 与 `tryResolveSync` 相对路径中补齐扩展名强校验；
  - 加固 `OcPackageService`：解压数据包媒体文件时强校验扩展名白名单，过滤掉非图片扩展名文件；将包清单中的 `appVersion: '1.5.0'` 同步为当前语义版本 `'1.8.0'`。
- **UI 导航上下文生命周期加固 (ROB-02)**：
  - 优化 `LoreEntityDetailDialog` 编辑词条回调：在 `navigator.pop()` 前锁定上层活跃路由上下文 `navigator.context`，杜绝使用已解挂 context 造成的组件树警告与时序异常。
- **验证结论**：新增测试用例，全工程自动化测试达到 **101 / 101 项全部 100% 绿灯通过**，`flutter analyze` 保持 **No issues found!**。

### [2026-11-02] 阶段 Y：P2-04 关系图高级分析与智能布局闭环 (Advanced Graph Analytics & Layouts)
- **最短关系路径求解器 (`RelationPathFinder`)**：基于 BFS 构建图拓扑，区分有向/双向边，实现任意角色间最短路径推演与 `RelationPathDialog` 联动；
- **智能排版引擎 (`GraphAutoLayoutEngine`)**：支持环形聚类 (Circular)、分层树形 (Hierarchical)、紧凑网格 (Grid) 三套自动排布算法；
- **排版坐标快照与一键撤销**：执行排版前内存快照保护，支持 SnackBar 一键撤销恢复；
- **画布视觉高亮与光晕联动**：最短路径连线加粗（3.5px）品牌色发光渲染，关联角色外圈光晕凸显，非关联节点与边自动淡化；右上角悬浮胶囊状态条一键清除。

### [2026-11-02] 阶段 X：全工程代码审查问题 6 项加固全部闭环
- **安全与架构加固 (SEC-01 & ARC-01)**：`ProjectBackupService` 增加路径穿越与 Zip 炸弹防护，动态读取 Schema v11；
- **数据完整性 (COR-01)**：`TrashProvider` 纳入百科与历史快照级联归档与还原；
- **查询下推优化 (PERF-01)**：`ConsistencyCheckerEngine` 消除画廊跨世界全表扫描；
- **异步安全与生命周期 (ROB-01 & RES-01)**：补齐 `await` 与 `mounted` 保护，显式释放 Controllers。

---

## 📋 3. 核心功能矩阵状态 (Feature Status)

- [x] **多世界观与三维视图 (World Hub & Views)**：卡片流、泳道看板（Kanban）、多维表格（Table Matrix）
- [x] **六维属性与人设长图海报 (Radar & Posters)**：动态 3~8 维雷达图、4 套视觉海报无损导出
- [x] **专属画廊与色卡提取 (Gallery & Palette)**：差分立绘管理、Top 5 主题色 Hex 聚类提取
- [x] **关系图谱与外框几何算法 (Obsidian Canvas & Geometry)**：精确多边形相交切点、多重关系弧线、无损 PNG 导出
- [x] **关系图高级分析与智能布局 (Advanced Graph Analytics & Layouts)**：BFS 最短路径寻径、环形/分层/网格排版、一键撤销、画布高亮光晕
- [x] **纪元编年史与生平轴 (Chronicle & Timeline)**：6 大事件分类、生卒年关照、角色专属轨迹穿梭
- [x] **维基双链与反向引用 (Wiki Links & Backlinks)**：`[[角色]]` 与 `[[词条]]` 胶囊解析、反向引用上下文切片
- [x] **出版级单文件 HTML 设定集 (Booklet Export)**：脱机 Base64 内嵌、纯 SVG 雷达图、A4 打印优化、Markdown ZIP
- [x] **独立便携数据包 (`.ocpkg`)**：原子级沙盒暂存解压、三维冲突解决（renameCopy/overwrite/skip）、防 Zip 炸弹
- [x] **双轨备份与灾备恢复 (Dual-Track Backup)**：SQLite 原生 `VACUUM INTO` 快照、完整 ZIP 项目包、`.rollback_bak` 自动防灾还原点、路径穿越加固
- [x] **世界观全景百科库 (Lore Encyclopedia)**：地点/组织/种族/物品/能力/概念实体管理与 JSON 动态属性
- [x] **设定一致性检查规则引擎 (Consistency Rule Engine · CONSIST-001 & CONSIST-002)**：模块化确定性规则契约、规则注册与启停、时间与年龄全维度时序交叉检查、模糊纪元安全避让、依据数据切片与修复建议、全量与单人物定向诊断双模调度、五维逻辑诊断与健康指数大盘
- [x] **设定版本历史与快照恢复 (Revision History)**：幂等内容去重、时序滚动修剪、字数差值对比与安全回滚
- [x] **全局命令面板 (Command Palette · Ctrl+K)**：全局快捷呼出、全库实体与命令深度聚合、上下键循环导航与 Android 触控支持
- [x] **关系图多命名画布管理 (Multiple Named Canvases · GRAPH-001)**：同一世界观多画布隔离、独立坐标/视口/过滤持久化、画布克隆、防灾级联删除保护与动态默认推举
- [x] **关系图命令模式撤销与重做 (Undo & Redo · GRAPH-002)**：移动/排版/增删节点/关系增删改全命令覆盖、主键保真原子回滚、切画布/切世界观历史隔离、快捷键与双端交互
- [x] **关系图全局导览小地图与 SVG 矢量导出 (Mini-map & SVG Export · GRAPH-005)**：悬浮小地图微缩拓扑、视口范围指示框与点击居中导航、纯 Dart W3C 标准 SVG 矢量导出与双模式导出切换

---

## 🔍 4. 全工程代码审查问题追踪 (Review Issues Tracker)

| 编号 | 严重度 | 模块 | 问题描述 | 状态 |
| :--- | :---: | :--- | :--- | :--- | :---: |
| **SEC-01** | 🔴 高危 | `ProjectBackupService` | 项目完整备份恢复时缺失解压路径遍历（Path Traversal）与 Zip 炸弹防护 | **已修复 ✅** |
| **SEC-02** | 🟠 严重 | `ImageStorageService` | 相对路径缺少图片扩展名白名单校验，写入未对非常规后缀清洗过滤 | **已修复 ✅** |
| **SEC-03** | 🟠 严重 | `OcPackageService` | 解压数据包媒体文件时未校验扩展名白名单，存在恶意文件解压进沙盒风险 | **已修复 ✅** |
| **COR-01** | 🟠 严重 | `TrashProvider` | 世界观软删除/恢复未包含 `LoreEntities` 与 `EntityRevisions`，留有孤儿数据隐患 | **已修复 ✅** |
| **COR-02** | 🟠 严重 | `TrashProvider` | 删除世界观时删除 `Characters` 早于 `TimelineEvents`，在外键开启时导致 SQLite 787 报错 | **已修复 ✅** |
| **ARC-01** | 🟡 中度 | `ProjectBackupService` | 备份元数据 `schemaVersion: 9` 硬编码，未与当前 Schema v12 动态对齐 | **已修复 ✅** |
| **ARC-02** | 🟡 中度 | `AppDatabase` | SQLite 连接未在 `beforeOpen` 中显式设置 `PRAGMA foreign_keys = ON;` | **已修复 ✅** |
| **ARC-03** | 🔵 低度 | `OcPackageService` | 包清单导出时硬编码 `appVersion: 1.5.0`，存在版本漂移 | **已修复 ✅** |
| **PERF-01** | 🟡 中度 | `ConsistencyCheckerEngine` | 画廊立绘检查时全表扫描了全局所有世界观的画廊，未按当前世界观角色 ID 过滤 | **已修复 ✅** |
| **ROB-01** | 🔵 低度 | UI 异步回调 | `CharacterDetailPage` 与 `WorldListPage` 删除操作未加 `await`；部分弹窗异步后未检查 `mounted` | **已修复 ✅** |
| **ROB-02** | 🔵 低度 | `LoreEntityDetailDialog` | 弹窗在 `Navigator.pop(context)` 后使用已失活的 `context` 打开编辑弹窗 | **已修复 ✅** |
| **RES-01** | 🔵 低度 | `RelationGraphPage` | `_showAddRelationDialog` 局部 `TextEditingController` 弹窗关闭后未显式 `dispose()` | **已修复 ✅** |

---

## 🎯 5. 下一步行动建议 (Next Steps)

1. **生产级 Release 构建验证 (QA-001)**：执行 Windows / Android 平台 Release 编译验证，确认多端构建与打包畅通；
2. **设定一致性规则工作台增强 (CONSIST-005)**：为创作者提供更丰富的一致性规则自定义与诊断卡片联动；
3. **长线规划推进**：根据创作者日常体验反馈，开展下一阶段产品功能讨论（如跨端云同步、富文本编辑器升级等）。

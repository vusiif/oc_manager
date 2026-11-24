# OC Manager 2.0：UI、关系图与工程质量完整改造建议

> 项目：[vusiif/oc_manager](https://github.com/vusiif/oc_manager)  
> 整理日期：2026-10-16  
> 适用范围：现有 Flutter + Riverpod + Drift/SQLite 项目，优先考虑 Windows 桌面端，兼顾 Android。  
> 文档性质：**设计方向 + 技术选型 + 代码问题清单 + 分阶段实施计划 + 验收标准**。

## 0. 总结：下一阶段应该做什么

这个项目当前最需要的不是继续增加功能，而是把已经做出来的功能变成**好看、好用、稳定、不会丢数据的产品**。

### 结论

1. **UI 不要继续从零凭感觉设计。** 选择一个成熟产品作为整体布局参考，再用开源 Flutter UI 组件建立统一设计系统。建议：**主界面参考 AppFlowy，关系图交互参考 Obsidian Canvas，角色卡片参考 Milanote**。
2. **关系图不要继续无限堆手写 `CustomPainter + GestureDetector` 逻辑。** 现有实现有明确的连线刷新、方向、多关系与异步初始化问题。先做小范围修复，再用成熟 Flutter 图编辑器做技术验证。
3. **推荐首先评估 `diagram_editor` 1.0.0。** 它同时支持 Windows、Android、节点连接、拖拽、缩放与序列化。`node_flow` 可作为备选；`graphview` 更适合家谱或自动布局，不应直接当作完整可编辑画布的替代品。
4. **数据安全必须与 UI 改造同步推进。** 现有数据库备份直接复制活动中的 `.db` 文件、回收站未完整保存关联数据，这些风险比视觉问题更可能造成不可逆损失。
5. **先做好 Windows，再适配 Android。** 两端共享业务层和数据模型，但输入交互、导航和布局不必完全相同。

### 优先级总表

| 编号 | 优先级 | 工作项 | 为什么重要 | 完成标志 |
| --- | --- | --- | --- | --- |
| G-01 | P0 | 修复连线不跟随节点刷新 | 关系图核心错误 | 任意节点拖动时所有关联线实时更新 |
| G-02 | P0 | 修复反向边、多重关系和箭头 | 关系含义可能被画错 | A→B、B→A、双向、多条关系均正确 |
| G-03 | P0 | 修复已保存布局初始化竞态 | 可能出现打开图谱节点消失 | 重开页面总能恢复布局 |
| D-01 | P0 | 改造 SQLite 备份和恢复 | 数据丢失风险 | 备份可验证、恢复可回滚 |
| D-02 | P0 | 补齐回收站关联数据与事务 | 恢复内容可能不完整 | 删除/恢复前后数据等价 |
| F-01 | P1 | 选定 UI 参考并建立设计系统 | 统一视觉风格 | 核心页面共用组件与规范 |
| F-02 | P1 | 重做导航、人物卡片和详情页 | 改善第一印象与操作效率 | 可完成完整 OC 管理流程 |
| G-04 | P1 | 图编辑器 PoC 和替换方案 | 减少手写画布维护 | 缩放、拖拽、连线通过测试 |
| G-05 | P1 | 增加选中、多选、吸附、撤销等交互 | 消除拖动“别扭”的感觉 | 有统一交互规则 |
| B-01 | P1 | 修复搜索跳转路由 | 明确的功能性错误 | 点击搜索结果可打开人物 |
| B-02 | P1 | 世界观/分组/关系数据隔离 | 防止跨世界观脏数据 | 越界操作被拒绝 |
| Q-01 | P1 | 核心单测、Widget 测试、回归测试 | 防止每次迭代引入旧 bug | CI 持续运行通过 |
| R-01 | P2 | README、截图、构建与发布流程 | 产品可被理解和安装 | 一次提交可复现构建 |
| E-01 | P3 | 图片管理、导出、时间线等增强 | 建立差异化 | 核心质量稳定后再开发 |
| E-02 | P3 | 跨设备同步、自动备份、真正的数据加密 | 复杂度高，依赖稳定数据层 | 有专门设计和迁移方案 |

> **P0 是阻断性修复，P1 是下一阶段主线，P2 是交付完善，P3 是后续增强。**  
> UI 是当前最明显的产品体验问题；数据备份是最高级别的工程风险。两者不应互相挤占。

---

## 1. UI：找一套成熟设计来借鉴

### 1.1 参考产品怎么选

| 产品 / 资源 | 重点借鉴 | 不适合照搬的部分 | 链接 |
| --- | --- | --- | --- |
| **AppFlowy（首选主界面参考）** | 左侧工作区导航、内容区层级、编辑器布局、资料管理工作流 | 不要复制全部 Notion 式复杂功能；其主项目采用 AGPLv3，代码复用需认真评估许可证 | [官网](https://appflowy.com/) · [GitHub](https://github.com/AppFlowy-IO/AppFlowy) |
| **Obsidian Canvas（首选关系图交互参考）** | 画布拖动、缩放、节点连接、连线标签、选中、多选、分组、快捷键、撤销、图谱导出 | 它面向笔记而不是 OC 语义，关系和家谱的数据模型仍需自己设计 | [官方 Canvas 说明](https://obsidian.md/help/plugins/canvas) |
| **Milanote（卡片/创作氛围参考）** | 人物立绘、参考图、色板、灵感板、可视化创作卡片 | 不必把整个 OC 数据库做成自由白板 | [官网](https://milanote.com/) |
| **Linear（视觉细节参考）** | 导航密度、对齐、层级、面板分割、按钮和状态反馈 | 不必模仿任务管理业务流程 | [官方 UI 改版文章](https://linear.app/now/how-we-redesigned-the-linear-ui) |
| **Anytype（内容模型参考）** | 对象、属性、关联、空间隔离与本地优先思路 | 它的同步/加密架构不适合直接移植 | [官网](https://anytype.io/) · [文档](https://doc.anytype.io/) |

**明确选择：** 不要平均拼凑五套风格。建议以 **AppFlowy 式的桌面信息架构**作为主模板；只把 Obsidian Canvas 的画布交互和 Milanote 的视觉内容展示嫁接进来。

### 1.2 可以直接使用的 Flutter UI 基础设施

| 方案 | 使用建议 | 注意事项 |
| --- | --- | --- |
| [`shadcn_ui`](https://pub.dev/packages/shadcn_ui) | **优先做 PoC**；现代桌面风格的按钮、弹窗、菜单、输入框、标签等，MIT 许可证 | 不要未经试验就全量替换 `MaterialApp`；检查主题、焦点、弹窗层与 Flutter 版本兼容 |
| [`fluent_ui`](https://pub.dev/packages/fluent_ui) | 备选；若长期专注 Windows 原生视觉很合适，BSD-3-Clause | 大规模迁移成本可能较高，也不能解决自定义关系图 |
| [`flex_color_scheme`](https://pub.dev/packages/flex_color_scheme) | 如果保留 Material 3，可辅助统一色彩和组件主题 | 新版本可能要求较新的 Flutter 版本；先确认项目实际 SDK |
| Flutter 原生 `ThemeData` + 自建小组件库 | **最低风险的落地方式**；可逐页迁移 | 必须有统一 tokens，否则容易再次变成各页面自行设计 |

本项目现有主题文件基本只是 `Material 3 + 蓝色种子色`，因此目前“简陋”的一部分原因是缺少系统性的视觉规范，而不是 Flutter 天生难看。

**建议实施路线：** 先保留 Flutter 原生应用骨架，建立 `DesignTokens`、`AppTheme` 和统一业务组件；挑选 `shadcn_ui` 的常用组件验证兼容性，再决定替换范围。不要为引入一套 UI 库而重新改写全项目路由与状态管理。

### 1.3 统一设计系统：必须先定规则

设计系统至少要明确：

- **色彩：** 页面背景、侧栏背景、浮层、边框、正文、次要文字、主操作、危险操作、成功/警告状态，全部由语义色定义。支持完整浅色/深色两套。
- **字体层级：** 页面标题、区块标题、正文、辅助说明、标签、按钮；固定字重及间距。
- **尺寸与间距：** 使用统一间距阶梯，不再在各页面散布任意 `SizedBox` 数值。
- **组件：** 页面容器、搜索框、导航项、OC 卡片、世界观卡片、信息字段行、表单分组、弹窗、右键菜单、工具栏、空状态、加载和错误状态。
- **状态：** 正常、悬停、按下、选中、禁用、拖动、拖动目标高亮、保存中、保存成功、失败。
- **图标：** 统一风格和尺寸；人物身份、关系类型尽量用语义图标/颜色组合，不再主要依赖性别决定几何形状。
- **无障碍：** 键盘焦点可见、文本对比度、系统缩放、高 DPI、文字溢出和长中文角色名。
- **交互反馈：** 编辑保存提示、危险操作二次确认、撤销入口、空列表引导。

可先建立：

```text
lib/core/design/
  design_tokens.dart
  app_theme.dart
  components/
    app_sidebar.dart
    app_toolbar.dart
    oc_card.dart
    world_card.dart
    detail_field.dart
    empty_state.dart
    confirmation_dialog.dart
```

### 1.4 建议重做的主要页面

#### A. 世界观首页

- 世界观以封面卡片展示：名称、简介、角色数、最近编辑、主题色。
- 顶部放搜索与“新建世界观”，其余低频操作收进菜单。
- 提供最近打开、收藏和快捷进入人物列表/关系图。
- 空状态展示“创建世界观 → 添加人物 → 创建关系”的引导。

#### B. 主工作台

采用桌面常见的 **左导航 + 主内容 + 可折叠详情面板**：

```text
┌──────────────────────────────────────────────────────────────┐
│ 世界观名称 / 面包屑          搜索          新建 / 更多操作      │
├──────────────┬─────────────────────────────────┬─────────────┤
│ 世界观切换   │ 人物 / 关系图 / 模板 / 世界设定    │ 选中项详情  │
│ 收藏         │                                 │ 属性        │
│ 分组树       │   主内容区                       │ 标签        │
│ 人物列表     │                                 │ 关联关系    │
│ 回收站       │                                 │ 快捷编辑    │
└──────────────┴─────────────────────────────────┴─────────────┘
```

- 左栏负责导航，不要把每个操作都做成独立的顶栏按钮。
- 主内容支持卡片/列表切换和筛选、排序。
- 右侧详情面板优先展示选中对象信息，必要时展开为完整编辑页。
- 大屏优先提高内容可见面积；小屏改用抽屉或单页流转，不强行保留三栏。

#### C. 人物详情

- 头像/立绘成为视觉中心，但不喧宾夺主。
- 资料采用“基本信息 / 背景故事 / 自定义属性 / 标签 / 关系 / 图片”的清晰分组。
- 自定义字段支持排序、隐藏、模板和字段类型（文本、数字、日期、选项、多行文本等，按实际需求渐进增加）。
- 减少一整屏纯表单的感觉：阅读态和编辑态明确区分。
- 从关系图选中人物时，右侧直接显示该人物的关键资料和关系列表。

#### D. 关系图页面

- 延续全应用设计语言，图节点优先使用紧凑的**人物头像/立绘 + 姓名 + 关系高亮**卡片。
- 图谱工具栏提供：选择、连接、自动排版、适应画布、重置缩放、筛选关系、撤销/重做、导出。
- 右侧显示选中人物或连线的属性。
- 图例解释关系颜色与箭头，不依赖用户猜测。

### 1.5 “抄 UI”的边界

可以学习**布局规律、信息层级、通用操作模式和交互细节**；不要原样复制别人的品牌标识、插画、专有图标、完整页面素材、商业设计资源或未经许可的源代码。

- AppFlowy 主项目是 **AGPLv3**：研究架构和视觉可以，直接复制代码可能带来相应开源义务。
- `shadcn_ui` 为 **MIT**，`fluent_ui` 为 **BSD-3-Clause**，使用时保留许可证要求。
- Figma Community 标记为“免费”的资源也不等于无限制商用；逐项确认授权范围。参考 [Figma 官方资源许可](https://www.figma.com/legal/community-free-resource-license/)。
- 最佳实践：**借鉴设计系统与交互，不做一比一像素克隆；实现自己的 OC 产品识别度。**

---

## 2. 关系图：明确问题、修复方法与成熟方案

### 2.1 源码中已经可以定位的问题

集中在 [`lib/features/relation/relation_graph_page.dart`](https://github.com/vusiif/oc_manager/blob/main/lib/features/relation/relation_graph_page.dart)。当前文件包含页面、节点交互、网格、连线几何和家谱绘制等多种职责，维护成本较高。

#### G-01：节点拖动后，连线可能不及时重绘（高优先级）

证据：

- 页面保留一个可变的 `_positions` Map；
- 拖动时直接原地改写 `_positions[character.id]`；
- `_RelationPainter.shouldRepaint` 比较 `old.positions != positions`。

代码位置：[拖动更新](https://github.com/vusiif/oc_manager/blob/main/lib/features/relation/relation_graph_page.dart#L571-L579) · [重绘判断](https://github.com/vusiif/oc_manager/blob/main/lib/features/relation/relation_graph_page.dart#L1180-L1182)

Dart 的普通 `Map` 默认按对象身份比较。旧 Painter 和新 Painter 都拿到同一张原地修改的 Map，比较结果仍可能为 `false`。**这与“节点动了，线没正确跟着动”的表现高度吻合。**

处理建议：

1. **立刻止血：** 用明确的 `layoutRevision` / `graphRevision` 来触发绘制，或让 `CustomPainter(repaint: listenable)` 订阅位置变化。
2. **长期治理：** 节点位置改成独立的图谱状态，由 Controller 管理，画布只消费状态；避免 Widget 与 Painter 共享可变 Map 却没有变更通知。
3. **不要只把 `Map` 浅拷贝当成最终方案：** 那可能变成每次父节点重建都重绘全部边，正确性提高但性能仍不可控。
4. 拖动回归测试要同时断言**节点位置**和**连线端点**发生变化。

#### G-02：反向关系、多重关系可能画错方向（高优先级）

代码中 `_pairKey(a,b)` 把 A→B 和 B→A 归为同一无向人物对；但 `_drawNormalGroup` 只从 `group.first` 读取起点与终点，其后所有边沿用这个基准画线和箭头。

证据：[无向分组](https://github.com/vusiif/oc_manager/blob/main/lib/features/relation/relation_graph_page.dart#L926-L939) · [组内统一起终点](https://github.com/vusiif/oc_manager/blob/main/lib/features/relation/relation_graph_page.dart#L1059-L1089)

处理建议：

- 分组只负责决定“并行线需要占用哪条车道”；
- **每条边仍必须使用自己的** `fromCharacterId`、`toCharacterId`、`isBidirectional`；
- 根据该条曲线的真实切线方向绘制箭头；
- 多条同向边、反向边、双向边都使用稳定而对称的偏移；
- 不允许相同 ID 但不同语义的关系被渲染层无声合并。

#### G-03：已保存布局存在异步加载竞态（高优先级）

`_initPositions` 在第一次执行时立即把 `_initialized` 设为 `true`；但是页面从 `layoutsAsync.valueOrNull ?? []` 取数据。若人物先加载、布局后加载，第一次初始化可能拿到空布局，后续真实布局到达也不会再次初始化。

证据：[初始化](https://github.com/vusiif/oc_manager/blob/main/lib/features/relation/relation_graph_page.dart#L29-L39) · [数据读取](https://github.com/vusiif/oc_manager/blob/main/lib/features/relation/relation_graph_page.dart#L414-L457)

处理建议：

- 等人物、关系、布局三个必要数据源进入可用状态后再做首次布局合并。
- 对角色新增/删除/移出画布采用**增量同步**，不要用一个永不重置的布尔值控制全部后续变化。
- 新用户首次打开和老用户恢复保存位置分开处理。

#### G-04：节点端点几何被写死（高优先级）

连线使用固定 `nodeRadius = 28.0`，而节点形状有方形、圆形、旋转菱形，外面还存在文字标签。固定半径并不能保证连接点真正落在可见边缘。

证据：[固定半径](https://github.com/vusiif/oc_manager/blob/main/lib/features/relation/relation_graph_page.dart#L911-L921) · [节点结构](https://github.com/vusiif/oc_manager/blob/main/lib/features/relation/relation_graph_page.dart#L833-L870)

处理建议：

- 由节点布局输出真实 `Rect` 或 `ShapeGeometry`；
- 按圆/矩形/圆角矩形/菱形的边界求射线交点；
- 端点与箭头只落在节点外边缘，不穿透头像/卡片；
- 连线与节点共享同一套几何和坐标变换；
- 重叠、极近、不同尺寸节点单独处理。

#### G-05：家谱绘制算法的边界情况不完整（高优先级）

现有 `_drawFamilyGroup` 把主要绘制逻辑放在 `parents.length >= 2` 条件之内。**当家谱组只有一个父/母节点时，组内关系可能没有任何连线显示。**

证据：[家谱绘制条件](https://github.com/vusiif/oc_manager/blob/main/lib/features/relation/relation_graph_page.dart#L953-L1055)

处理建议：

- 支持单亲、多亲、多代、多个子女、子女位置高于父母、节点交叉等情况；
- 亲属关系与“家族组合节点/婚配连接点”分离，不要把复杂超边强行当普通 A→B 线；
- 优先做**独立的家谱视图**，可自动分层布局；自由关系图继续允许任意拖放。

#### G-06：缩放和拖拽的职责边界不清（体验问题）

当前画布是 `InteractiveViewer + Stack + CustomPaint + Positioned GestureDetector`，节点拖动用 `details.delta` 累加；侧栏放置又用另一路坐标逆变换。

证据：[画布与放置坐标](https://github.com/vusiif/oc_manager/blob/main/lib/features/relation/relation_graph_page.dart#L48-L55) · [画布嵌套](https://github.com/vusiif/oc_manager/blob/main/lib/features/relation/relation_graph_page.dart#L516-L571) · [节点拖动](https://github.com/vusiif/oc_manager/blob/main/lib/features/relation/relation_graph_page.dart#L833-L852)

这种结构很容易在缩放、平移、侧栏宽度变化或不同输入设备下出现坐标和手势冲突。不能仅凭静态代码断定每一个缩放比例都有错误，需要用实机测试确认，但**应统一坐标系统**：

```text
global/screen coordinates
        ↓ (viewport inverse transform)
scene coordinates
        ↓
node positions / edge geometry / hit testing / saved layout
```

建议：

- 保存**场景坐标**，不要保存屏幕坐标；
- 所有拖动、放置、连线命中都使用同一个 `toScene` 转换入口；
- 拖动时只更新图编辑器状态；拖动结束时再落库；
- 拖动一次记为一个撤销步骤；
- 画布平移与节点拖动区分手势，并允许拖动边缘自动滚动画布。

#### G-07：其他画布缺陷与体验缺口

- 曲线箭头方向应使用真实曲线切线，而不是用不完全一致的控制点近似。
- 关系文字背景硬编码偏浅，暗色主题下可能显得突兀。
- 线没有明确的选中、悬停高亮、直接编辑和命中区域。
- 缺少多选、对齐/分布、吸附、撤销/重做、框选、视图适应与小地图等成熟交互。
- 全图作为单个页面状态频繁 `setState`，大图时需评估重建范围。
- 画布大小主要由固定下限控制，应考虑真正的大画布和内容边界管理。
- 使用性别区分几何形状不一定适合所有 OC 类型；建议改为可选图形/头像，关系属性用线型与颜色表达。

### 2.2 成熟技术方案对比

| 方案 | 适用场景 | 优点 | 局限与风险 | 建议 |
| --- | --- | --- | --- | --- |
| **[`diagram_editor` 1.0.0](https://pub.dev/packages/diagram_editor)** | Windows + Android 可编辑人物关系画布 | MIT；自定义节点、连线、端点策略、平移缩放、线控制点和序列化；支持项目目标平台 | 需要验证多重边、反向边、标签、关系语义和性能；家谱仍需自定义 | **首选 PoC** |
| [`node_flow`](https://pub.dev/packages/node_flow) | 类 React Flow 的可编辑节点画布 | MIT；节点拖动、连线、框选、对齐吸附、小地图等现代交互；跨平台 | 相对较新，业务接入和长期维护风险需测试；偏端口式工作流 | **第二候选** |
| [`graphview` 1.5.1](https://pub.dev/packages/graphview) | 家谱、层级图、自动布局 | 多种树形/分层/环形/力导向布局，适合自动排版 | 官方定位侧重图显示和布局，不是完整关系编辑器 | **家谱布局优先评估** |
| [`fl_nodes_v2`](https://pub.dev/packages/fl_nodes_v2) | 功能复杂的桌面节点编辑器 | 多选、连接、撤销、快捷键、小地图、布局接口等较完整 | 当前 pub.dev 平台清单未列 Android，且“输入输出端口”与 OC 人物关系概念有差异 | **仅桌面方向备选** |
| [`interactive_viewer_2`](https://pub.dev/packages/interactive_viewer_2) | 保留自绘画布，仅改善导航与缩放 | 能改善缩放和滚轮行为 | **不负责关系边、几何、命中和拖拽状态** | 只能辅助，不是完整替代 |

> **不要为了使用“成熟方案”就改写为 Electron + React Flow。** 当前 Flutter + Drift 基础已经建立；应先在 Flutter 内验证可行性。只有 Flutter 生态方案无法满足核心交互需求时，才重新讨论跨技术栈的成本。

### 2.3 推荐的图谱架构

采用“**业务数据**”与“**编辑器显示状态**”分层：

```text
Drift 数据库
  ├─ Character（人物）
  ├─ Relation（关系语义、方向、备注、分组）
  ├─ RelationGroup（家谱组合语义）
  └─ GraphLayout（不同视图中的坐标）
          ↓
GraphRepository / GraphAdapter
          ↓
GraphDocument（节点、边、视觉样式、场景坐标、连接几何）
          ↓
GraphController（选中、拖动、连线、缩放、撤销）
          ↓
Canvas Renderer（节点组件、线绘制、命中测试、工具栏）
```

**约束：**

- `Relation.id` 是业务事实；编辑器的 `edge.id` 应保留稳定映射，不能只凭两端人物 ID 推断一条边。
- 区分 `directed`、`bidirectional` 和 `undirected`；不能把双向关系随意拆成两条可分别误删的业务记录。
- 家谱中“夫妻/父母组合→多个孩子”可使用**仅用于显示的虚拟连接点**，不必污染人物数据库。
- 节点坐标持久化建议增加 `worldId + graphViewId + characterId` 的唯一约束，为以后多种布局做准备。
- 选中状态、缩放位置、拖动中预览通常无需每帧写数据库；布局保存要有明确边界。
- 自动排版提供预览、应用、撤销；不应未经确认覆盖所有人工布局。

建议把 1000 多行页面逐步拆为：

```text
lib/features/relation/
  graph/
    graph_page.dart
    graph_controller.dart
    graph_adapter.dart
    graph_models.dart
    graph_geometry.dart
    graph_theme.dart
    widgets/
      character_node.dart
      graph_toolbar.dart
      relation_inspector.dart
      graph_minimap.dart
  family/
    family_layout.dart
    family_graph_view.dart
```

实际目录可根据最终选用的库调整；**不要一边重构一边丢掉原数据库中的关系和坐标**。

### 2.4 建议的交互规则（向 Obsidian Canvas 对齐）

**Windows：**

- 左键点击节点：选中；拖动节点：移动；拖动空白画布：平移或框选（提供明确模式/按键提示）。
- 鼠标中键或 `Space + 拖动`：平移画布。
- 鼠标滚轮、`Ctrl + 滚轮`、触控板缩放行为采用一套固定且可配置的规则，不允许各页面不同。
- 在人物节点边缘出现连接手柄；从手柄拖到另一人物创建关系；松开后确认关系类型和方向。
- 点击关系线：选中并高亮；双击标签：修改关系；右键：删除或调整方向。
- `Ctrl+Z / Ctrl+Y`：撤销与重做；`Delete`：删除选中对象；`Ctrl+A`：全选（仅画布焦点下）。
- 多选、拖动选中组、吸附、对齐、适应全部节点、聚焦选中节点。
- 鼠标悬停时显示工具提示，拖动过程中显示清楚的目标反馈。

**Android：**

- 单指在空白处平移，两指缩放；节点长按后移动或进入编辑模式；
- 点击节点后用可见的操作按钮创建关系，不能强制要求精细点击极小的端口；
- 提供底部工具栏、撤销、适应视图和编辑入口；
- 手指命中区域要明显大于线本身的笔画宽度。

**最重要的体验目标：** 用户不会因为放大了画布就感觉节点移动速度失常；不会误把平移当作移动节点；线始终粘着节点边缘。

### 2.5 图编辑器 PoC：必须跑的测试

不要仅比较组件的截图。用同一套真实 OC 测试数据验证两个候选库，至少覆盖：

- [ ] 一条 A→B 单向关系，箭头正确。
- [ ] 一条 A↔B 双向关系，语义和渲染正确。
- [ ] 同一对人物同时存在 A→B 与 B→A。
- [ ] 同一对人物有多种关系，曲线和标签能够区分。
- [ ] 没有任何关系的孤立节点；节点完全重合或非常接近。
- [ ] 单亲、多亲、多子女、多代家谱；环形/复杂人物关系。
- [ ] 不同节点宽高、头像/立绘、长角色名、不同形状。
- [ ] 多档缩放下拖动、平移、从侧栏放置节点、连线端点跟随。
- [ ] 节点或连线点击/悬停/框选/删除/撤销。
- [ ] 重新进入页面后位置、关系、线型恢复一致。
- [ ] 浅色、深色、窗口大小变化、高 DPI 显示。
- [ ] Windows 鼠标与触控板；Android 触摸屏。
- [ ] 大量节点和关系时仍可稳定操作，使用 **Flutter DevTools** 记录帧时间、重绘与内存。

**PoC 的通过条件：** 功能完整性、手感、性能、可扩展性、Android 可用性均达到要求，才能迁移生产代码。若候选库在“任意人物连任意人物”或多重边方面有严重硬约束，应尽早淘汰。

---

## 3. 数据安全与业务正确性：必须补齐的底座

### D-01. 重新实现数据库备份

当前设置页核心逻辑是直接 `dbFile.copy(result)`，而数据库使用活动 SQLite 文件。这在 WAL 和并发写入场景下不能保证形成完整一致的备份。

代码证据：[settings_page.dart：备份](https://github.com/vusiif/oc_manager/blob/main/lib/features/settings/settings_page.dart#L184-L219)

正确方向：

- 使用 SQLite **Online Backup API** 或 **`VACUUM INTO`** 生成一致的数据库快照，而不是直接复制正在写入的主文件。
- 备份到临时路径后验证，再交付目标文件；记录 Schema 版本、应用版本和备份时间。
- 执行 `PRAGMA integrity_check`，必要时做表记录数量和关联完整性校验。
- 备份与恢复都要包含头像/立绘等外部文件；数据库中若保存绝对图片路径，跨设备导出时必须转换为可移植引用。
- 恢复前验证文件和版本，自动创建现有数据的恢复点；确保数据库连接关闭、WAL/SHM 状态处理正确，再原子替换并重新打开。
- 恢复失败必须保留旧数据，不得把数据库留在半恢复状态。
- 用创建数据→备份→修改/删除→恢复→逐项核对的自动化用例验证。

官方依据：[SQLite Online Backup API](https://www.sqlite.org/backup.html)。

### D-02. 回收站必须恢复完整对象，而不只是主记录

当前角色回收站快照包含人物部分基本字段，但没有完整保存自定义字段、标签、分组成员、人物关系和布局等关联数据。

代码证据：[trash_provider.dart](https://github.com/vusiif/oc_manager/blob/main/lib/providers/trash_provider.dart#L19-L95)

建议：

- 删除世界观/人物时，以数据库事务保存**完整的对象快照或软删除状态**；
- 明确哪些关联应跟随恢复、哪些关系因另一端人物已永久删除而无法恢复；
- 处理 ID 冲突与恢复到不存在世界观的情况；
- 图片等文件资产引用不能因为回收站操作而意外失效；
- “恢复成功”必须意味着主记录和预期关联均恢复。

### B-01. 修复搜索跳转路由

搜索结果执行的地址是 `/world/:worldId/character/:characterId`，但在已检查的 `app.dart` 路由表中未注册对应路径。

代码证据：[search_page.dart](https://github.com/vusiif/oc_manager/blob/main/lib/features/search/search_page.dart#L103-L105) · [app.dart](https://github.com/vusiif/oc_manager/blob/main/lib/app.dart#L13-L51)

解决办法可选：

1. 注册人物详情路由并处理参数与不存在的人物；
2. 搜索后回到主工作台，按 `worldId + characterId` 选中对应世界观和人物。

无论哪种，都要补点击搜索结果的 Widget/导航测试。

### B-02. 世界观与分组数据隔离

目前 `GroupDao.addCharacterToGroup` 主要按两个 ID 插入，缺乏人物与分组必须属于同一世界观的校验；批量设置分组时也缺少完整事务边界。

代码证据：[group_dao.dart](https://github.com/vusiif/oc_manager/blob/main/lib/data/database/daos/group_dao.dart#L52-L76)。

建议：

- 在 Repository/Service 层验证 `character.worldId == group.worldId`；
- 创建人物关系时同样校验参与人物是否属于允许的世界观；
- 使用事务完成“清理旧关联 + 写入新关联”；
- 检查 `FOREIGN KEY` 定义及 SQLite 连接是否真正启用了外键检查；
- 设计级联删除与恢复语义，并对多世界观数据进行回归测试。

### B-03. 世界观加锁与隐私保护

`pubspec.yaml` 中 `local_auth` 目前被注释为暂时移除。世界观数据存在 `isLocked` 字段，但不能仅凭该字段认定应用已实现真正的访问保护。

代码证据：[pubspec.yaml](https://github.com/vusiif/oc_manager/blob/main/pubspec.yaml#L473-L476)。

建议：

- 未完成前不应向用户宣传真正的“隐私锁”；
- 若做普通 UI 锁，应标注它仅阻止随手浏览，不代表磁盘数据已加密；
- 如果要承诺隐私安全，需单独设计本地加密、密钥管理、备份加密和忘记密码处理流程；
- Android 生物识别、Windows 解锁方式应分别评估，不要只靠一个插件覆盖所有场景。

### B-04. 数据库迁移与版本兼容

现有数据库 `schemaVersion` 为 6，存在逐版本迁移逻辑。升级到新图库或增设多布局时，需要明确旧版数据如何平滑迁移。

代码证据：[app_database.dart](https://github.com/vusiif/oc_manager/blob/main/lib/data/database/app_database.dart#L49-L75)。

建议：

- 对每个已有 Schema 版本构建迁移测试样本；
- 升级前备份、升级失败不损坏原文件；
- 不在无迁移工具的情况下更改主键、关系方向或 GraphLayouts 含义；
- 新旧应用版本的恢复策略要明确，禁止悄悄加载无法理解的数据结构。

---

## 4. 架构、代码质量和测试建议

### 4.1 保留合理的技术栈

现有 Flutter + Riverpod + Drift/SQLite + go_router 的基础方向适合本地优先的 OC 管理工具，**不建议为了好看重写成另一套技术栈**。

保留：

- Flutter：Windows/Android 跨平台 UI；
- Riverpod：状态管理与依赖注入；
- Drift + SQLite：结构化人物、关系和标签数据；
- go_router：应用导航。

加强：

- UI 层 /业务 Service 层 / Repository 层职责分离；
- 图谱交互专用 Controller 与不可变显示状态；
- 复杂数据库操作使用事务；
- 错误统一处理、可恢复提示、异步操作取消与重复提交防护；
- 路由常量或 typed routes，避免到处拼接字符串路径。

### 4.2 测试：目前基础测试还远远不够

公开 `test/widget_test.dart` 主要测试应用渲染，无法覆盖数据迁移、关系方向或图谱交互。

代码证据：[widget_test.dart](https://github.com/vusiif/oc_manager/blob/main/test/widget_test.dart)。

建议新增：

| 测试层级 | 关键测试 |
| --- | --- |
| 纯逻辑单测 | 有向边/双向边/多重边、曲线端点、坐标转换、布局数据合并 |
| Repository 测试 | 人物/关系/标签/分组操作、跨世界观隔离、事务 |
| 数据库迁移测试 | 各历史 Schema 升级、外键与约束、失败回滚 |
| 备份恢复测试 | WAL 场景、并发写入、数据损坏、不同版本、图片资产 |
| Widget 测试 | 搜索跳转、OC 编辑、拖放、关系菜单、暗色主题 |
| 集成测试 | 完整创建世界观→角色→关系→导出→重新打开 |
| 性能测试 | 大图拖拽与缩放的帧时间、节点/连线重绘成本 |

建议 CI 至少包含：

```text
flutter pub get
flutter analyze
flutter test
```

随后逐步补上 Windows 构建、Android APK/AAB 构建、发布产物存档与安装测试。

### 4.3 文档与发布工程

当前 README 仍带有 Flutter 默认新项目模板文字，维护文档部分内容也与源码进度不完全同步。

应补：

- README：项目定位、目标用户、功能图、真实应用截图、安装与使用指南；
- 功能状态：已实现 / 部分实现 / 规划中，避免“代码有了但文档还说没做”；
- 开发指南：Flutter 版本、依赖安装、数据库代码生成、构建步骤；
- 许可证与第三方依赖说明；
- CHANGELOG、版本号和 Release Notes；
- GitHub Issues 模板、Bug 复现模板、截图与日志说明；
- CI 构建、发布包签名/完整性与升级提示。

---

## 5. 后续值得做，但不要抢当前优先级的功能

### 产品体验增强

- 角色头像与立绘管理：多图、封面、裁剪、缩略图与本地资产整理。
- 角色信息模板：更适合小说、漫画、跑团、游戏不同类型的 OC。
- 人物关系筛选：只显示亲属、恋人、敌对等类别。
- 图谱搜索与聚焦：输入人物名快速定位，突出一阶/二阶关系。
- 多种图谱布局：自由视图、家谱视图、以人物为中心的关系视图。
- 关系图导出：PNG/SVG（依实现能力选择），可设背景、分辨率、图例。
- 世界设定扩展：地点、组织、事件、阵营以及时间线，但要在人物基础模型稳定后再加。
- 可移植导出：包含数据库、立绘和清单文件的完整项目包。

### 长期能力

- 自动备份与备份轮换；
- 跨 Windows/Android 同步、冲突合并与断网恢复；
- 真正的本地加密；
- 可扩展插件或模板分享。

**暂不优先：** AI 生成人设、社区、在线协作和复杂云端服务。当前核心关系图尚未稳定，引入更多系统只会扩大维护面。

---

## 6. 可直接执行的分阶段开发计划

### 阶段 A：止血与建立基线（必须先过）

- [ ] 为当前可运行版本打一个可回退的 Git Tag；保存真实测试数据库。
- [ ] 修复 G-01：连线绘制状态与重绘通知。
- [ ] 修复 G-02：反向边和多关系语义。
- [ ] 修复 G-03：布局数据异步初始化竞态。
- [ ] 修复 G-05：单亲家谱至少能够正确显示。
- [ ] 修复 B-01：搜索结果跳转。
- [ ] 实现安全备份/恢复，并补实际恢复测试。
- [ ] 明确回收站完整恢复方案，至少阻止误报恢复成功。
- [ ] 建立 `flutter analyze` / `flutter test` 的基础 CI。

**验收门槛：** 不再出现关键连线方向错误、保存布局丢失、错误导航；备份可以从头到尾实际恢复。

### 阶段 B：UI 设计定稿与组件库

- [ ] 选定 AppFlowy 风格作为主界面参考，整理真实截图和页面对应关系。
- [ ] 制作世界观页、人物列表、人物详情、关系图四类高保真界面。
- [ ] 定义主题、色彩、排版、尺寸、导航、弹窗及暗色模式。
- [ ] 实现 5–10 个全局高复用 UI 组件（数量为实施目标，可按需要调整）。
- [ ] 完成 Windows 常用窗口尺寸与高 DPI 验证。
- [ ] 验证 `shadcn_ui` 试点组件与现有 Material、Riverpod、导航的兼容性。

**验收门槛：** 新页面不再出现各自一套字号、间距和菜单样式；用户可以在统一的视觉框架下完成角色管理。

### 阶段 C：成熟关系图编辑器 PoC 与迁移

- [ ] 用相同 OC 数据分别搭建 `diagram_editor` 与 `node_flow` 的最小可运行演示。
- [ ] 完成第 2.5 节全部边界用例。
- [ ] 评估自由图与家谱图是否应该分开布局/渲染。
- [ ] 实现旧 `Relation`、`GraphLayouts` 到新显示模型的无损适配。
- [ ] 完成快捷键、框选、连接手柄、拖拽、缩放、撤销与保存。
- [ ] Windows/Android 实机交互测试；性能未达标不得直接替换老页面。
- [ ] 删除被新系统取代的旧 Painter 和重复坐标逻辑。

**验收门槛：** 连线始终正确跟随、缩放状态不影响手感、任意关系可编辑、保存后重开不丢布局，且不牺牲已有功能。

### 阶段 D：数据与产品完整性

- [ ] 回收站事务和关联数据恢复。
- [ ] 世界观、分组、关系数据的权限/隔离校验。
- [ ] 数据库迁移测试和外键处理。
- [ ] 完整导入/导出（含图片资产），支持版本兼容检查。
- [ ] 人物资料、封面图与关系图视觉打磨。
- [ ] 完成 README、开发文档、截图、安装包、CI Release。
- [ ] 收集真实用户使用问题，再决定自动备份、时间线和同步优先级。

**验收门槛：** 一个没有阅读源码的用户能安装、开始创建 OC、管理关系、可靠备份并恢复资料。

---

## 7. 重点验收清单（适合直接转成 GitHub Issues）

### UI

- [ ] 界面有明确的信息层级，不需要在多个相似图标中猜操作。
- [ ] 浅色/深色配色、字号、边框、菜单、输入框统一。
- [ ] 中文长名称、空白状态、加载失败、窗口缩放都有处理。
- [ ] 世界观→角色列表→角色详情→关系图的路径顺畅。
- [ ] Windows 的右键、悬停、键盘导航可用；Android 提供等效触摸操作。

### 关系图

- [ ] 节点每一次移动，相关连线都实时更新。
- [ ] 任意缩放/平移后，节点跟随鼠标或手指，无明显偏移。
- [ ] 新增人物拖入画布不会落到意外位置。
- [ ] A→B、B→A、A↔B 以及多重边箭头正确。
- [ ] 端点位于节点可见边缘，箭头不钻进节点内部。
- [ ] 标签不严重遮挡节点，也不在暗色主题下使用刺眼的硬编码白底。
- [ ] 可选中、编辑、删除连线；操作可以撤销。
- [ ] 家谱支持单亲、多亲、多子女并可自动整理。
- [ ] 页面重开、应用重启后布局和关系一致。

### 数据

- [ ] 活动数据库能安全备份，且备份文件通过完整性校验。
- [ ] 备份可恢复到原状态，恢复失败不会损坏现有数据。
- [ ] 图谱布局、人物自定义字段、标签、分组和关系均能正常恢复。
- [ ] 跨世界观添加关系或分组会被阻止。
- [ ] 旧数据库升级到新版本不丢失数据。
- [ ] 图像/立绘不会因为更换电脑或备份恢复而变成失效路径。

### 工程

- [ ] `flutter analyze` 通过。
- [ ] `flutter test` 通过，含关系几何与数据库回归用例。
- [ ] Windows / Android 构建可复现。
- [ ] README 中的功能、截图、安装说明与 Release 一致。

---

## 8. 参考与源码索引

### 当前项目

- 仓库：https://github.com/vusiif/oc_manager
- 关系图页面：https://github.com/vusiif/oc_manager/blob/main/lib/features/relation/relation_graph_page.dart
- 搜索页面：https://github.com/vusiif/oc_manager/blob/main/lib/features/search/search_page.dart
- 路由：https://github.com/vusiif/oc_manager/blob/main/lib/app.dart
- 设置/备份：https://github.com/vusiif/oc_manager/blob/main/lib/features/settings/settings_page.dart
- 回收站：https://github.com/vusiif/oc_manager/blob/main/lib/providers/trash_provider.dart
- 分组 DAO：https://github.com/vusiif/oc_manager/blob/main/lib/data/database/daos/group_dao.dart
- 数据库迁移：https://github.com/vusiif/oc_manager/blob/main/lib/data/database/app_database.dart
- 当前主题：https://github.com/vusiif/oc_manager/blob/main/lib/core/theme/app_theme.dart
- 测试样例：https://github.com/vusiif/oc_manager/blob/main/test/widget_test.dart

### UI 与图编辑器

- AppFlowy：https://appflowy.com/ — https://github.com/AppFlowy-IO/AppFlowy
- Obsidian Canvas：https://obsidian.md/help/plugins/canvas
- Milanote：https://milanote.com/
- Linear 设计文章：https://linear.app/now/how-we-redesigned-the-linear-ui
- Anytype：https://anytype.io/
- Flutter shadcn_ui：https://pub.dev/packages/shadcn_ui
- Flutter fluent_ui：https://pub.dev/packages/fluent_ui
- Flutter diagram_editor：https://pub.dev/packages/diagram_editor
- Flutter node_flow：https://pub.dev/packages/node_flow
- Flutter graphview：https://pub.dev/packages/graphview
- Flutter fl_nodes_v2：https://pub.dev/packages/fl_nodes_v2
- Flutter interactive_viewer_2：https://pub.dev/packages/interactive_viewer_2

### 可靠性与授权

- SQLite Online Backup API：https://www.sqlite.org/backup.html
- SQLite 外键说明：https://www.sqlite.org/foreignkeys.html
- Figma Community 免费资源许可证：https://www.figma.com/legal/community-free-resource-license/
- AppFlowy 项目许可证：https://github.com/AppFlowy-IO/AppFlowy/blob/main/LICENSE
- diagram_editor MIT 许可证：https://pub.dev/packages/diagram_editor/license
- shadcn_ui MIT 许可证：https://pub.dev/packages/shadcn_ui/license

---

## 9. 最后一条建议

**先修正确性，再换引擎；先确定设计参考，再统一组件；先让现有数据可靠，再扩展功能。**

如果只能集中精力做一轮升级，最值得完成的是：

> **一个统一且成熟的 Windows 主界面 + 一个线条正确、拖动自然的关系图 + 一个真正可靠的数据库备份/恢复系统。**

这三件事做好，OC Manager 的体验和可信度就会明显改善。

---

*备注：以上基于截至 2026-10-16 可访问的公开仓库源码和相关项目文档进行静态分析。已定位的代码逻辑问题与待实机验证的体验风险已分别标注；尚未完成 Flutter 桌面/Android 真机运行与完整基准测试。第三方包版本、兼容性及授权在正式接入前需以届时官方文档为准。*

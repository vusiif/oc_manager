import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/empty_state.dart';
import '../../core/design/components/oc_card.dart';
import '../../core/design/design_tokens.dart';
import '../../data/database/app_database.dart';
import '../../providers/character_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/world_provider.dart';
import '../character/character_dialog.dart';
import 'booklet_export_dialog.dart';
import 'consistency_checker_dialog.dart';
import 'oc_package_dialogs.dart';
import 'views/world_kanban_view.dart';
import 'views/world_table_view.dart';
import 'world_analytics_dialog.dart';

enum WorldViewMode { cards, kanban, table }

class WorldDetailPage extends ConsumerStatefulWidget {
  final int worldId;
  final int? selectedGroupId;
  final void Function(int characterId)? onCharacterSelected;

  const WorldDetailPage({
    super.key,
    required this.worldId,
    this.selectedGroupId,
    this.onCharacterSelected,
  });

  @override
  ConsumerState<WorldDetailPage> createState() => _WorldDetailPageState();
}

class _WorldDetailPageState extends ConsumerState<WorldDetailPage> {
  WorldViewMode _viewMode = WorldViewMode.cards;

  @override
  Widget build(BuildContext context) {
    final worldAsync = ref.watch(worldByIdProvider(widget.worldId));
    final charactersAsync = ref.watch(
      charactersByWorldProvider(widget.worldId),
    );
    final groupsAsync = ref.watch(groupsByWorldProvider(widget.worldId));
    final filteredCharactersAsync = widget.selectedGroupId != null
        ? ref.watch(charactersByGroupProvider(widget.selectedGroupId!))
        : null;

    final allCharacters = charactersAsync.valueOrNull ?? [];
    final allGroups = groupsAsync.valueOrNull ?? [];
    final isWide = MediaQuery.sizeOf(context).width >= 880;

    return Scaffold(
      appBar: AppBar(
        title: worldAsync.when(
          data: (world) => Text(world.name),
          loading: () => const Text('加载中'),
          error: (err, stack) => const Text('错误'),
        ),
        actions: [
          if (widget.selectedGroupId == null) ...[
            SegmentedButton<WorldViewMode>(
              segments: const [
                ButtonSegment(
                  value: WorldViewMode.cards,
                  icon: Icon(Icons.grid_view_rounded, size: 16),
                  tooltip: '经典卡片视图',
                ),
                ButtonSegment(
                  value: WorldViewMode.kanban,
                  icon: Icon(Icons.view_kanban_rounded, size: 16),
                  tooltip: '泳道看板视图',
                ),
                ButtonSegment(
                  value: WorldViewMode.table,
                  icon: Icon(Icons.table_chart_rounded, size: 16),
                  tooltip: '多维表格视图',
                ),
              ],
              selected: {_viewMode},
              onSelectionChanged: (set) =>
                  setState(() => _viewMode = set.first),
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (isWide) ...[
            IconButton(
              icon: const Icon(Icons.history_edu_rounded),
              tooltip: '编年史大事件',
              onPressed: () =>
                  context.push('/world/${widget.worldId}/chronicle'),
            ),
            IconButton(
              icon: const Icon(Icons.movie_creation_outlined),
              tooltip: '故事创作与场景分镜 (Story & Scenes)',
              onPressed: () => context.push('/world/${widget.worldId}/story'),
            ),
            IconButton(
              icon: const Icon(Icons.auto_stories_rounded),
              tooltip: '世界百科 (Lore)',
              onPressed: () => context.push('/world/${widget.worldId}/lore'),
            ),
            IconButton(
              icon: const Icon(Icons.hub_outlined),
              tooltip: '知识网络视图 (Knowledge Network)',
              onPressed: () =>
                  context.push('/world/${widget.worldId}/knowledge-network'),
            ),
          ],
          _buildToolsMenu(context, worldAsync.valueOrNull, isWide),
          const SizedBox(width: 8),
        ],
      ),
      body: widget.selectedGroupId != null
          ? _buildGroupCharacters(context, filteredCharactersAsync)
          : _buildAllCharactersWithViewMode(
              context,
              charactersAsync,
              allCharacters,
              allGroups,
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('新建人物'),
      ),
    );
  }

  Widget _buildToolsMenu(BuildContext context, World? world, bool isWide) {
    return PopupMenuButton<String>(
      tooltip: '工具与更多操作',
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (value) => _handleMenuAction(context, world, value),
      itemBuilder: (context) => [
        if (!isWide) ...[
          _menuItem('chronicle', Icons.history_edu_rounded, '编年史大事件'),
          _menuItem('story', Icons.movie_creation_outlined, '故事创作与场景分镜'),
          _menuItem('lore', Icons.auto_stories_rounded, '世界百科 (Lore)'),
          _menuItem('network', Icons.hub_outlined, '知识网络视图'),
          const PopupMenuDivider(),
        ],
        _menuItem('analytics', Icons.insights_rounded, '全景数据大盘'),
        _menuItem('consistency', Icons.fact_check_outlined, '设定一致性检查器'),
        const PopupMenuDivider(),
        _menuItem('booklet', Icons.menu_book_rounded, '生成世界设定集 (Booklet)'),
        _menuItem('export_ocpkg', Icons.archive_outlined, '导出数据分享包 (.ocpkg)'),
        _menuItem('import_ocpkg', Icons.unarchive_outlined, '导入数据分享包 (.ocpkg)'),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 19),
          const SizedBox(width: 12),
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, World? world, String value) {
    switch (value) {
      case 'chronicle':
        context.push('/world/${widget.worldId}/chronicle');
      case 'story':
        context.push('/world/${widget.worldId}/story');
      case 'lore':
        context.push('/world/${widget.worldId}/lore');
      case 'network':
        context.push('/world/${widget.worldId}/knowledge-network');
      case 'analytics':
        showDialog(
          context: context,
          builder: (_) => WorldAnalyticsDialog(
            worldId: widget.worldId,
            worldName: world?.name ?? '世界观',
          ),
        );
      case 'consistency':
        ConsistencyCheckerDialog.show(
          context,
          worldId: widget.worldId,
          worldName: world?.name ?? '世界观',
        );
      case 'booklet':
        if (world != null) BookletExportDialog.show(context, world);
      case 'export_ocpkg':
        if (world != null) OcPackageExportDialog.show(context, world);
      case 'import_ocpkg':
        if (world != null) {
          OcPackageImportDialog.show(context, targetWorldId: world.id);
        }
    }
  }

  Widget _buildAllCharactersWithViewMode(
    BuildContext context,
    AsyncValue<List<Character>> charactersAsync,
    List<Character> allCharacters,
    List<Group> allGroups,
  ) {
    return charactersAsync.when(
      data: (characters) {
        if (characters.isEmpty) {
          return EmptyStateView(
            icon: Icons.person_add_alt_1_outlined,
            title: '还没有任何人物设定',
            description: '创建属于你的第一个角色（OC），记录基本信息、附加设定与专属关系。',
            primaryActionLabel: '创建第一个人物',
            onPrimaryAction: () => _showCreateDialog(context),
          );
        }

        switch (_viewMode) {
          case WorldViewMode.kanban:
            return WorldKanbanView(
              worldId: widget.worldId,
              characters: allCharacters,
              groups: allGroups,
              onCharacterSelected: widget.onCharacterSelected,
            );
          case WorldViewMode.table:
            return WorldTableView(
              worldId: widget.worldId,
              characters: allCharacters,
              onCharacterSelected: widget.onCharacterSelected,
            );
          case WorldViewMode.cards:
            return _buildClassicCards(context, characters);
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('错误: $error')),
    );
  }

  Widget _buildClassicCards(BuildContext context, List<Character> characters) {
    final pinned = characters.where((c) => c.isPinned).toList();
    final normal = characters
        .where((c) => !c.isPinned && c.status == 0)
        .toList();
    final drafts = characters.where((c) => c.status == 1).toList();
    final others = characters
        .where((c) => !c.isPinned && c.status > 1)
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 780 ? 2 : 1;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (pinned.isNotEmpty)
                    _buildCharacterSection(
                      '置顶 (${pinned.length})',
                      Icons.push_pin_rounded,
                      pinned,
                      columns,
                      iconColor: AppColors.brand,
                    ),
                  if (normal.isNotEmpty)
                    _buildCharacterSection(
                      pinned.isNotEmpty ? '细化中角色' : null,
                      null,
                      normal,
                      columns,
                    ),
                  if (drafts.isNotEmpty)
                    _buildCharacterSection(
                      '构思草稿 (${drafts.length})',
                      Icons.lightbulb_outline_rounded,
                      drafts,
                      columns,
                    ),
                  if (others.isNotEmpty)
                    _buildCharacterSection(
                      '定稿与归档 (${others.length})',
                      Icons.inventory_2_outlined,
                      others,
                      columns,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCharacterSection(
    String? title,
    IconData? icon,
    List<Character> list,
    int columns, {
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: iconColor ?? Colors.grey),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          _buildResponsiveCardGrid(list, columns),
        ],
      ),
    );
  }

  Widget _buildResponsiveCardGrid(List<Character> list, int columns) {
    if (columns == 1) {
      return Column(children: list.map(_buildOcCard).toList());
    }
    final rows = <Widget>[];
    for (var i = 0; i < list.length; i += 2) {
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildOcCard(list[i])),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: i + 1 < list.length
                  ? _buildOcCard(list[i + 1])
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildOcCard(Character c) {
    return OcCard(
      character: c,
      onTap: () => widget.onCharacterSelected?.call(c.id),
      onFavoriteToggle: () =>
          ref.read(characterActionsProvider).toggleFavorite(c),
      onPinToggle: () => ref.read(characterActionsProvider).togglePin(c),
    );
  }

  Widget _buildGroupCharacters(
    BuildContext context,
    AsyncValue<List<Character>>? charactersAsync,
  ) {
    if (charactersAsync == null) return const SizedBox.shrink();

    return charactersAsync.when(
      data: (characters) {
        if (characters.isEmpty) {
          return EmptyStateView(
            icon: Icons.group_off_outlined,
            title: '该分组下暂无人物',
            description: '可以从左侧侧栏直接拖拽人物到此分组，或者直接在此创建新人物。',
            primaryActionLabel: '创建人物',
            onPrimaryAction: () => _showCreateDialog(context),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 780 ? 2 : 1;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: _buildResponsiveCardGrid(characters, columns),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('错误: $error')),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CharacterDialog(worldId: widget.worldId),
    );
  }
}

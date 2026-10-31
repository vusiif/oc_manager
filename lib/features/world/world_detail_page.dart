import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/world_provider.dart';
import '../../providers/character_provider.dart';
import '../../providers/group_provider.dart';
import '../../data/database/app_database.dart';
import '../../core/design/components/empty_state.dart';
import '../../core/design/components/oc_card.dart';
import '../../core/design/design_tokens.dart';
import '../character/character_dialog.dart';
import 'views/world_kanban_view.dart';
import 'views/world_table_view.dart';
import 'world_analytics_dialog.dart';
import 'booklet_export_dialog.dart';
import 'oc_package_dialogs.dart';

enum WorldViewMode {
  cards,
  kanban,
  table,
}

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
    final charactersAsync =
        ref.watch(charactersByWorldProvider(widget.worldId));
    final groupsAsync = ref.watch(groupsByWorldProvider(widget.worldId));

    // 根据选中的分组过滤人物
    final filteredCharactersAsync = widget.selectedGroupId != null
        ? ref.watch(charactersByGroupProvider(widget.selectedGroupId!))
        : null;

    final allCharacters = charactersAsync.valueOrNull ?? [];
    final allGroups = groupsAsync.valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: worldAsync.when(
          data: (world) => Text(world.name),
          loading: () => const Text('加载中'),
          error: (err, stack) => const Text('错误'),
        ),
        actions: [
          // 视图切换器（仅在全域世界视图下生效）
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
              onSelectionChanged: (set) {
                setState(() => _viewMode = set.first);
              },
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            icon: const Icon(Icons.insights_rounded),
            tooltip: '全景数据大盘与人际网络分析',
            onPressed: () {
              final world = worldAsync.valueOrNull;
              showDialog(
                context: context,
                builder: (_) => WorldAnalyticsDialog(
                  worldId: widget.worldId,
                  worldName: world?.name ?? '世界观',
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history_edu_rounded),
            tooltip: '编年史大事件',
            onPressed: () =>
                context.push('/world/${widget.worldId}/chronicle'),
          ),
          IconButton(
            icon: const Icon(Icons.menu_book_rounded),
            tooltip: '生成世界设定集 (Booklet)',
            onPressed: () {
              final world = worldAsync.valueOrNull;
              if (world != null) {
                BookletExportDialog.show(context, world);
              }
            },
          ),
          PopupMenuButton<String>(
            tooltip: '数据分享包与更多',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              final world = worldAsync.valueOrNull;
              if (world == null) return;
              if (value == 'export_ocpkg') {
                OcPackageExportDialog.show(context, world);
              } else if (value == 'import_ocpkg') {
                OcPackageImportDialog.show(context, targetWorldId: world.id);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_ocpkg',
                child: Row(
                  children: [
                    Icon(Icons.archive_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('导出数据分享包 (.ocpkg)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import_ocpkg',
                child: Row(
                  children: [
                    Icon(Icons.unarchive_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('导入数据分享包 (.ocpkg)'),
                  ],
                ),
              ),
            ],
          ),
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

  // 根据当前视图模式渲染
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

  // 经典卡片流视图
  Widget _buildClassicCards(
      BuildContext context, List<Character> characters) {
    final pinned = characters.where((c) => c.isPinned).toList();
    final normal =
        characters.where((c) => !c.isPinned && c.status == 0).toList();
    final drafts = characters.where((c) => c.status == 1).toList();
    final others =
        characters.where((c) => !c.isPinned && c.status > 1).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (pinned.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.push_pin_rounded,
                  size: 16, color: AppColors.brand),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '置顶 (${pinned.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...pinned.map((c) => OcCard(
                character: c,
                onTap: () => widget.onCharacterSelected?.call(c.id),
                onFavoriteToggle: () {
                  ref.read(characterActionsProvider).toggleFavorite(c);
                },
                onPinToggle: () {
                  ref.read(characterActionsProvider).togglePin(c);
                },
              )),
          const SizedBox(height: AppSpacing.md),
        ],
        if (normal.isNotEmpty) ...[
          if (pinned.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                '细化中角色',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
          ...normal.map((c) => OcCard(
                character: c,
                onTap: () => widget.onCharacterSelected?.call(c.id),
                onFavoriteToggle: () {
                  ref.read(characterActionsProvider).toggleFavorite(c);
                },
                onPinToggle: () {
                  ref.read(characterActionsProvider).togglePin(c);
                },
              )),
        ],
        if (drafts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded,
                  size: 16, color: Colors.grey),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '构思草稿 (${drafts.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...drafts.map((c) => OcCard(
                character: c,
                onTap: () => widget.onCharacterSelected?.call(c.id),
                onFavoriteToggle: () {
                  ref.read(characterActionsProvider).toggleFavorite(c);
                },
                onPinToggle: () {
                  ref.read(characterActionsProvider).togglePin(c);
                },
              )),
        ],
        if (others.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined,
                  size: 16, color: Colors.grey),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '定稿与归档 (${others.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...others.map((c) => OcCard(
                character: c,
                onTap: () => widget.onCharacterSelected?.call(c.id),
                onFavoriteToggle: () {
                  ref.read(characterActionsProvider).toggleFavorite(c);
                },
                onPinToggle: () {
                  ref.read(characterActionsProvider).togglePin(c);
                },
              )),
        ],
      ],
    );
  }

  // 显示分组下的人物
  Widget _buildGroupCharacters(BuildContext context,
      AsyncValue<List<Character>>? charactersAsync) {
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

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: characters
              .map((c) => OcCard(
                    character: c,
                    onTap: () => widget.onCharacterSelected?.call(c.id),
                    onFavoriteToggle: () {
                      ref.read(characterActionsProvider).toggleFavorite(c);
                    },
                    onPinToggle: () {
                      ref.read(characterActionsProvider).togglePin(c);
                    },
                  ))
              .toList(),
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

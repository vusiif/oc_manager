import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design/design_tokens.dart';
import '../core/services/recent_items_service.dart';
import '../providers/character_provider.dart';
import '../providers/group_provider.dart';
import '../providers/world_provider.dart';
import 'character/character_detail_page.dart';
import 'command_palette/command_palette_dialog.dart';
import 'shell/shortcuts_help_dialog.dart';
import 'shell/workspace_hub_view.dart';
import 'shell/workspace_recent_section.dart';
import 'sidebar/tree_sidebar.dart';
import 'world/world_analytics_dialog.dart';
import 'world/world_detail_page.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int? _selectedWorldId;
  int? _selectedGroupId;
  int? _selectedCharacterId;
  bool _sidebarVisible = true;

  @override
  void initState() {
    super.initState();
    _selectedWorldId = ref.read(activeWorldIdProvider);
  }

  bool get _canPopRoot =>
      _selectedCharacterId == null && _selectedWorldId == null;

  void _handleBackNavigation() {
    if (_selectedCharacterId != null) {
      setState(() => _selectedCharacterId = null);
    } else if (_selectedWorldId != null) {
      ref.read(activeWorldIdProvider.notifier).state = null;
      setState(() {
        _selectedWorldId = null;
        _selectedGroupId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int?>(activeWorldIdProvider, (previous, next) {
      if (next != _selectedWorldId) {
        setState(() {
          _selectedWorldId = next;
          _selectedGroupId = null;
          _selectedCharacterId = null;
        });
      }
    });

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCompact = MediaQuery.sizeOf(context).width < 720;

    return PopScope(
      canPop: _canPopRoot,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBackNavigation();
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: isCompact
            ? Drawer(
                width: 280,
                child: SafeArea(
                  child: _buildTreeSidebar(closeDrawerOnSelect: true),
                ),
              )
            : null,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              isCompact
                  ? Icons.menu
                  : (_sidebarVisible ? Icons.menu_open : Icons.menu),
            ),
            tooltip: isCompact ? '打开导航侧栏' : (_sidebarVisible ? '收起侧栏' : '展开侧栏'),
            onPressed: () {
              if (isCompact) {
                _scaffoldKey.currentState?.openDrawer();
              } else {
                setState(() => _sidebarVisible = !_sidebarVisible);
              }
            },
          ),
          title: _buildBreadcrumbs(ref),
          actions: [
            if (_selectedWorldId != null && !isCompact) ...[
              IconButton(
                icon: const Icon(Icons.history_edu_rounded),
                tooltip: '世界编年史',
                onPressed: () =>
                    context.push('/world/$_selectedWorldId/chronicle'),
              ),
              IconButton(
                icon: const Icon(Icons.hub_outlined),
                tooltip: '关系图谱',
                onPressed: () => context.push('/world/$_selectedWorldId/graph'),
              ),
              IconButton(
                icon: const Icon(Icons.insights_rounded),
                tooltip: '全景数据大盘与网络分析',
                onPressed: () {
                  final world = ref
                      .read(worldByIdProvider(_selectedWorldId!))
                      .valueOrNull;
                  showDialog(
                    context: context,
                    builder: (_) => WorldAnalyticsDialog(
                      worldId: _selectedWorldId!,
                      worldName: world?.name ?? '世界观',
                    ),
                  );
                },
              ),
            ],
            RecentQuickSwitchButton(onOpenItem: _openRecentItem),
            if (!isCompact)
              IconButton(
                icon: const Icon(Icons.terminal_rounded),
                tooltip: '全局命令面板 (Ctrl+K)',
                onPressed: () => showCommandPalette(context),
              ),
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: '全局搜索',
              onPressed: () => context.push('/search'),
            ),
            _buildMoreMenu(context, isCompact),
          ],
        ),
        body: Row(
          children: [
            if (!isCompact)
              ClipRect(
                child: AnimatedAlign(
                  alignment: Alignment.centerLeft,
                  heightFactor: 1.0,
                  widthFactor: _sidebarVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  child: ExcludeFocus(
                    excluding: !_sidebarVisible,
                    child: IgnorePointer(
                      ignoring: !_sidebarVisible,
                      child: SizedBox(width: 260, child: _buildTreeSidebar()),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Container(
                color: isDark ? AppColors.darkBg : AppColors.lightBg,
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreeSidebar({bool closeDrawerOnSelect = false}) {
    void maybeCloseDrawer() {
      if (closeDrawerOnSelect && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }

    return TreeSidebar(
      selectedWorldId: _selectedWorldId,
      selectedGroupId: _selectedGroupId,
      selectedCharacterId: _selectedCharacterId,
      onWorldSelected: (worldId) {
        _selectWorld(worldId);
        maybeCloseDrawer();
      },
      onGroupSelected: (groupId) {
        setState(() {
          _selectedGroupId = groupId;
          _selectedCharacterId = null;
        });
        maybeCloseDrawer();
      },
      onCharacterSelected: (characterId) {
        _selectCharacter(characterId);
        maybeCloseDrawer();
      },
    );
  }

  Widget _buildMoreMenu(BuildContext context, bool isCompact) {
    return PopupMenuButton<String>(
      tooltip: '更多功能',
      itemBuilder: (context) => [
        if (isCompact && _selectedWorldId != null) ...[
          const PopupMenuItem(
            value: 'graph',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.hub_outlined),
              title: Text('关系图谱'),
            ),
          ),
          const PopupMenuItem(
            value: 'chronicle',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.history_edu_rounded),
              title: Text('世界编年史'),
            ),
          ),
          const PopupMenuDivider(),
        ],
        const PopupMenuItem(
          value: 'tags',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.label_outline),
            title: Text('标签管理'),
          ),
        ),
        const PopupMenuItem(
          value: 'templates',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.description_outlined),
            title: Text('模板管理'),
          ),
        ),
        const PopupMenuItem(
          value: 'drafts',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.drafts_outlined),
            title: Text('草稿箱'),
          ),
        ),
        const PopupMenuItem(
          value: 'trash',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.delete_outline),
            title: Text('回收站'),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'shortcuts',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.keyboard_rounded),
            title: Text('快捷键指南 (F1)'),
          ),
        ),
        const PopupMenuItem(
          value: 'settings',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.settings_outlined),
            title: Text('设置'),
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'graph':
            if (_selectedWorldId != null) {
              context.push('/world/$_selectedWorldId/graph');
            }
          case 'chronicle':
            if (_selectedWorldId != null) {
              context.push('/world/$_selectedWorldId/chronicle');
            }
          case 'tags':
            context.push('/tags');
          case 'templates':
            context.push('/templates');
          case 'drafts':
            context.push('/drafts');
          case 'trash':
            context.push('/trash');
          case 'shortcuts':
            showShortcutsHelpDialog(context);
          case 'settings':
            context.push('/settings');
        }
      },
    );
  }

  Widget _buildBreadcrumbs(WidgetRef ref) {
    if (_selectedWorldId == null) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 18, color: AppColors.brand),
          SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              'OC Manager',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    }

    final worldAsync = ref.watch(worldByIdProvider(_selectedWorldId!));
    final worldName = worldAsync.valueOrNull?.name ?? '世界观';
    final groupName = _selectedGroupId != null
        ? ref.watch(groupByIdProvider(_selectedGroupId!)).valueOrNull?.name
        : null;
    final charName = _selectedCharacterId != null
        ? ref
              .watch(characterByIdProvider(_selectedCharacterId!))
              .valueOrNull
              ?.name
        : null;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          InkWell(
            borderRadius: AppRadius.radiusSm,
            onTap: () {
              ref.read(activeWorldIdProvider.notifier).state = null;
              setState(() {
                _selectedWorldId = null;
                _selectedGroupId = null;
                _selectedCharacterId = null;
              });
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                '工作台',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ),
          const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          InkWell(
            borderRadius: AppRadius.radiusSm,
            onTap: () => setState(() {
              _selectedGroupId = null;
              _selectedCharacterId = null;
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                worldName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      _selectedCharacterId == null && _selectedGroupId == null
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
          if (groupName != null) ...[
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            InkWell(
              borderRadius: AppRadius.radiusSm,
              onTap: () => setState(() => _selectedCharacterId = null),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  groupName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: _selectedCharacterId == null
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
          if (charName != null) ...[
            const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                charName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brand,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedWorldId == null) {
      return WorkspaceHubView(
        onSelectWorld: (id) => _selectWorld(id),
        onOpenRecentItem: _openRecentItem,
      );
    }

    if (_selectedCharacterId != null) {
      return CharacterDetailPage(
        key: ValueKey(_selectedCharacterId),
        worldId: _selectedWorldId!,
        characterId: _selectedCharacterId!,
        onDeleted: () => setState(() => _selectedCharacterId = null),
      );
    }

    return WorldDetailPage(
      worldId: _selectedWorldId!,
      selectedGroupId: _selectedGroupId,
      onCharacterSelected: _selectCharacter,
    );
  }

  void _selectWorld(int? worldId) {
    ref.read(activeWorldIdProvider.notifier).state = worldId;
    setState(() {
      _selectedWorldId = worldId;
      _selectedGroupId = null;
      _selectedCharacterId = null;
    });
    if (worldId != null) {
      ref.read(recentItemsProvider.notifier).recordWorldById(worldId);
    }
  }

  void _selectCharacter(int? characterId) {
    setState(() => _selectedCharacterId = characterId);
    final wId = _selectedWorldId;
    if (wId != null && characterId != null) {
      ref
          .read(recentItemsProvider.notifier)
          .recordCharacterById(wId, characterId);
    }
  }

  void _openRecentItem(RecentItem item) {
    ref.read(activeWorldIdProvider.notifier).state = item.worldId;
    setState(() {
      _selectedWorldId = item.worldId;
      _selectedGroupId = null;
      _selectedCharacterId = item.type == RecentItemType.character
          ? item.id
          : null;
    });
    final notifier = ref.read(recentItemsProvider.notifier);
    if (item.type == RecentItemType.world) {
      notifier.recordWorld(worldId: item.id, worldName: item.title);
    } else {
      notifier.recordCharacter(
        characterId: item.id,
        worldId: item.worldId,
        characterName: item.title,
        worldName: item.subtitle,
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design/components/empty_state.dart';
import '../core/design/design_tokens.dart';
import '../providers/character_provider.dart';
import '../providers/group_provider.dart';
import '../providers/world_provider.dart';
import 'character/character_detail_page.dart';
import 'sidebar/tree_sidebar.dart';
import 'world/world_detail_page.dart';
import 'world/world_dialog.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int? _selectedWorldId;
  int? _selectedGroupId;
  int? _selectedCharacterId;
  bool _sidebarVisible = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(_sidebarVisible ? Icons.menu_open : Icons.menu),
          tooltip: _sidebarVisible ? '收起侧栏' : '展开侧栏',
          onPressed: () {
            setState(() {
              _sidebarVisible = !_sidebarVisible;
            });
          },
        ),
        title: _buildBreadcrumbs(ref),
        actions: [
          if (_selectedWorldId != null)
            IconButton(
              icon: const Icon(Icons.hub_outlined),
              tooltip: '关系图谱',
              onPressed: () =>
                  context.push('/world/$_selectedWorldId/graph'),
            ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '全局搜索',
            onPressed: () => context.push('/search'),
          ),
          PopupMenuButton<String>(
            tooltip: '更多功能',
            itemBuilder: (context) => [
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
                case 'tags':
                  context.push('/tags');
                  break;
                case 'templates':
                  context.push('/templates');
                  break;
                case 'drafts':
                  context.push('/drafts');
                  break;
                case 'trash':
                  context.push('/trash');
                  break;
                case 'settings':
                  context.push('/settings');
                  break;
              }
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // 侧栏 (平滑收起/展开过渡动画)
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
                  child: SizedBox(
                    width: 260,
                    child: TreeSidebar(
                      selectedWorldId: _selectedWorldId,
                      selectedGroupId: _selectedGroupId,
                      selectedCharacterId: _selectedCharacterId,
                      onWorldSelected: (worldId) {
                        setState(() {
                          _selectedWorldId = worldId;
                          _selectedGroupId = null;
                          _selectedCharacterId = null;
                        });
                      },
                      onGroupSelected: (groupId) {
                        setState(() {
                          _selectedGroupId = groupId;
                          _selectedCharacterId = null;
                        });
                      },
                      onCharacterSelected: (characterId) {
                        setState(() {
                          _selectedCharacterId = characterId;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 主内容区
          Expanded(
            child: Container(
              color: isDark ? AppColors.darkBg : AppColors.lightBg,
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  /// 面包屑导航指示器
  Widget _buildBreadcrumbs(WidgetRef ref) {
    if (_selectedWorldId == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 18, color: AppColors.brand),
          const SizedBox(width: AppSpacing.sm),
          const Text('OC Manager', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      );
    }

    final worldAsync = ref.watch(worldByIdProvider(_selectedWorldId!));
    final worldName = worldAsync.valueOrNull?.name ?? '世界观';

    String? groupName;
    if (_selectedGroupId != null) {
      final groupAsync = ref.watch(groupByIdProvider(_selectedGroupId!));
      groupName = groupAsync.valueOrNull?.name;
    }

    String? charName;
    if (_selectedCharacterId != null) {
      final charAsync =
          ref.watch(characterByIdProvider(_selectedCharacterId!));
      charName = charAsync.valueOrNull?.name;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          InkWell(
            borderRadius: AppRadius.radiusSm,
            onTap: () {
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
            onTap: () {
              setState(() {
                _selectedGroupId = null;
                _selectedCharacterId = null;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                worldName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: _selectedCharacterId == null && _selectedGroupId == null
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
              onTap: () {
                setState(() {
                  _selectedCharacterId = null;
                });
              },
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
    // 未选中世界观时显示工作区 Hub 首页
    if (_selectedWorldId == null) {
      return _buildWorkspaceHub();
    }

    // 选中了人物，显示人物详情
    if (_selectedCharacterId != null) {
      return CharacterDetailPage(
        key: ValueKey(_selectedCharacterId),
        worldId: _selectedWorldId!,
        characterId: _selectedCharacterId!,
        onDeleted: () {
          setState(() {
            _selectedCharacterId = null;
          });
        },
      );
    }

    // 选中了世界观或分组，显示人物列表
    return WorldDetailPage(
      worldId: _selectedWorldId!,
      selectedGroupId: _selectedGroupId,
      onCharacterSelected: (characterId) {
        setState(() {
          _selectedCharacterId = characterId;
        });
      },
    );
  }

  /// 现代工作区中心主页 (Workspace Hub)
  Widget _buildWorkspaceHub() {
    final worldsAsync = ref.watch(worldsProvider);

    return worldsAsync.when(
      data: (worlds) {
        if (worlds.isEmpty) {
          return EmptyStateView(
            icon: Icons.public,
            title: '开启你的 OC 创作世界',
            description:
                '世界观是管理人物与关系的顶层容器。创建你的第一个世界观，开始构建丰富的人设立绘与复杂关系网吧！',
            primaryActionLabel: '创建新世界观',
            onPrimaryAction: () => _showCreateWorldDialog(context),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            // 欢迎 Banner
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.brand.withValues(alpha: 0.85),
                    AppColors.brandHover,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppRadius.radiusLg,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '欢迎回到 OC Manager 2.0',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '当前共有 ${worlds.length} 个世界观。请在左侧侧栏或从下方卡片选择进入。',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.brand,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.radiusMd,
                      ),
                    ),
                    onPressed: () => _showCreateWorldDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('新建世界观'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // 世界观卡片网格
            const Text(
              '我的世界观',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 800 ? 3 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: worlds.length,
                  itemBuilder: (context, index) {
                    final world = worlds[index];
                    return Card(
                      child: InkWell(
                        borderRadius: AppRadius.radiusMd,
                        onTap: () {
                          setState(() {
                            _selectedWorldId = world.id;
                            _selectedGroupId = null;
                            _selectedCharacterId = null;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.brandLight,
                                    child: const Icon(
                                      Icons.public,
                                      size: 18,
                                      color: AppColors.brand,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      world.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (world.isLocked)
                                    const Icon(Icons.lock,
                                        size: 16, color: Colors.grey),
                                ],
                              ),
                              Text(
                                (world.description != null &&
                                        world.description!.isNotEmpty)
                                    ? world.description!
                                    : '暂无描述',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('加载失败: $error')),
    );
  }

  void _showCreateWorldDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const WorldDialog(),
    );
  }
}

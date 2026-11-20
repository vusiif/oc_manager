import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/database/app_database.dart';
import '../../providers/world_provider.dart';
import '../../providers/lore_provider.dart';
import '../../core/design/components/empty_state.dart';
import 'lore_entity_dialog.dart';
import 'lore_entity_detail_dialog.dart';
import 'lore_cover_image.dart';

class LoreEncyclopediaPage extends ConsumerStatefulWidget {
  final int worldId;

  const LoreEncyclopediaPage({super.key, required this.worldId});

  @override
  ConsumerState<LoreEncyclopediaPage> createState() =>
      _LoreEncyclopediaPageState();
}

class _LoreEncyclopediaPageState extends ConsumerState<LoreEncyclopediaPage> {
  String _selectedType = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final worldAsync = ref.watch(worldByIdProvider(widget.worldId));
    final loreAsync = ref.watch(loreEntitiesByWorldProvider(widget.worldId));

    final allEntities = loreAsync.valueOrNull ?? [];

    // Filter by type and search query
    final filteredEntities = allEntities.where((e) {
      if (_selectedType != 'all' && e.entityType != _selectedType) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = e.name.toLowerCase().contains(q);
        final matchesSummary = e.summary.toLowerCase().contains(q);
        final matchesTags = e.tags.toLowerCase().contains(q);
        final matchesContent = e.content.toLowerCase().contains(q);
        if (!matchesName &&
            !matchesSummary &&
            !matchesTags &&
            !matchesContent) {
          return false;
        }
      }
      return true;
    }).toList();

    // Counts per type
    final typeCounts = <String, int>{'all': allEntities.length};
    for (final type in LoreEntityType.values) {
      typeCounts[type.key] = allEntities
          .where((e) => e.entityType == type.key)
          .length;
    }

    return Scaffold(
      appBar: AppBar(
        title: worldAsync.when(
          data: (w) => Text('${w.name} · 世界百科 (Lore)'),
          loading: () => const Text('世界百科 (Lore)'),
          error: (err, stack) => const Text('世界百科 (Lore)'),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () =>
                context.push('/world/${widget.worldId}/knowledge-network'),
            icon: const Icon(Icons.hub_outlined, size: 18),
            label: const Text('知识网络'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => LoreEntityDialog.show(
              context,
              worldId: widget.worldId,
              initialType: _selectedType != 'all' ? _selectedType : null,
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('新建词条'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // 搜索与过滤工具栏
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.4,
                  ),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 搜索条
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索地点、组织、种族、物品、能力设定或标签...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
                const SizedBox(height: 12),

                // 分类 FilterChip
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        avatar: const Icon(Icons.apps_rounded, size: 16),
                        label: Text('全部 (${typeCounts['all'] ?? 0})'),
                        selected: _selectedType == 'all',
                        onSelected: (_) =>
                            setState(() => _selectedType = 'all'),
                      ),
                      const SizedBox(width: 8),
                      ...LoreEntityType.values.map((type) {
                        final isSelected = _selectedType == type.key;
                        final count = typeCounts[type.key] ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            avatar: Icon(
                              type.icon,
                              size: 16,
                              color: isSelected ? Colors.white : type.color,
                            ),
                            label: Text('${type.label} ($count)'),
                            selected: isSelected,
                            selectedColor: type.color,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            onSelected: (_) =>
                                setState(() => _selectedType = type.key),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 实体卡片列表/网格
          Expanded(
            child: loreAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('加载百科失败：$err')),
              data: (_) {
                if (filteredEntities.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.menu_book_rounded,
                    title: _searchQuery.isNotEmpty
                        ? '未找到匹配 “$_searchQuery” 的设定'
                        : '暂无百科词条',
                    description: _searchQuery.isNotEmpty
                        ? '尝试更换关键词或清除筛选条件'
                        : '点击右上角“新建词条”，记录地理疆域、势力组织、种族物种或奇珍异宝！',
                    primaryActionLabel: _searchQuery.isEmpty
                        ? '立即创建第一篇百科'
                        : null,
                    onPrimaryAction: _searchQuery.isEmpty
                        ? () => LoreEntityDialog.show(
                            context,
                            worldId: widget.worldId,
                            initialType: _selectedType != 'all'
                                ? _selectedType
                                : null,
                          )
                        : null,
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = (constraints.maxWidth / 320)
                        .floor()
                        .clamp(1, 4);
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 210,
                      ),
                      itemCount: filteredEntities.length,
                      itemBuilder: (context, index) {
                        final entity = filteredEntities[index];
                        return _LoreEntityCard(
                          entity: entity,
                          onTap: () => LoreEntityDetailDialog.show(
                            context,
                            entity: entity,
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LoreEntityCard extends StatefulWidget {
  final LoreEntity entity;
  final VoidCallback onTap;

  const _LoreEntityCard({required this.entity, required this.onTap});

  @override
  State<_LoreEntityCard> createState() => _LoreEntityCardState();
}

class _LoreEntityCardState extends State<_LoreEntityCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entity = widget.entity;
    final typeConfig = LoreEntityType.fromKey(entity.entityType);

    final tags = entity.tags
        .split(RegExp(r'[,，]'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .take(3)
        .toList();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered
                  ? typeConfig.color.withValues(alpha: 0.8)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: _isHovered ? 1.5 : 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: typeConfig.color.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 封面图或彩色头部
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(13),
                ),
                child: SizedBox(
                  height: 90,
                  width: double.infinity,
                  child: entity.coverImagePath != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            LoreCoverImage(
                              imagePath: entity.coverImagePath,
                              fallback: _DefaultHeader(typeConfig: typeConfig),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.45),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : _DefaultHeader(typeConfig: typeConfig),
                ),
              ),

              // 卡片内容
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: typeConfig.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  typeConfig.icon,
                                  size: 12,
                                  color: typeConfig.color,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  typeConfig.label,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: typeConfig.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entity.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // 摘要
                      Expanded(
                        child: Text(
                          entity.summary.isNotEmpty
                              ? entity.summary
                              : (entity.content.isNotEmpty
                                    ? entity.content
                                    : '暂无详细描述'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // 底部标签与信息
                      if (tags.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          children: tags.map((t) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                '#$t',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DefaultHeader extends StatelessWidget {
  final LoreEntityType typeConfig;

  const _DefaultHeader({required this.typeConfig});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            typeConfig.color.withValues(alpha: 0.25),
            typeConfig.color.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          typeConfig.icon,
          size: 36,
          color: typeConfig.color.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

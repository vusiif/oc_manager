import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/database/app_database.dart';
import '../../providers/timeline_provider.dart';
import '../../providers/world_provider.dart';
import '../../providers/character_provider.dart';
import '../../core/design/components/oc_avatar.dart';

/// 世界编年史全景页面
class ChroniclePage extends ConsumerStatefulWidget {
  final int worldId;

  const ChroniclePage({
    super.key,
    required this.worldId,
  });

  @override
  ConsumerState<ChroniclePage> createState() => _ChroniclePageState();
}

class _ChroniclePageState extends ConsumerState<ChroniclePage> {
  String? _selectedCategory; // null = 全部
  int _minImportance = 1; // 1 = 全部, 2 = 关键及以上, 3 = 仅史诗
  int? _selectedCharacterFilter; // null = 全部, -1 = 仅独立世界大事件, >0 = 指定角色

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final worldAsync = ref.watch(worldByIdProvider(widget.worldId));
    final eventsAsync = ref.watch(worldTimelineEventsProvider(widget.worldId));
    final charactersAsync =
        ref.watch(charactersByWorldProvider(widget.worldId));

    final characters = charactersAsync.valueOrNull ?? [];
    final charMap = {for (final c in characters) c.id: c};

    return Scaffold(
      appBar: AppBar(
        title: worldAsync.when(
          data: (w) => Text('${w.name} · 编年史大事件'),
          loading: () => const Text('世界编年史'),
          error: (_, _) => const Text('世界编年史'),
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => _openEventDialog(context, ref, characters: characters),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('新撰纪事'),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // 顶部筛选器
          _buildFilterBar(context, characters),
          const Divider(height: 1),

          // 事件列表区域
          Expanded(
            child: eventsAsync.when(
              data: (allEvents) {
                // 执行多维过滤
                final filtered = allEvents.where((ev) {
                  if (_selectedCategory != null &&
                      ev.category != _selectedCategory) {
                    return false;
                  }
                  if (ev.importance < _minImportance) {
                    return false;
                  }
                  if (_selectedCharacterFilter != null) {
                    if (_selectedCharacterFilter == -1) {
                      if (ev.characterId != null) return false;
                    } else if (ev.characterId != _selectedCharacterFilter) {
                      return false;
                    }
                  }
                  return true;
                }).toList();

                if (allEvents.isEmpty) {
                  return _buildEmptyState(context, characters);
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_alt_off_rounded,
                          size: 48,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '没有符合当前筛选条件的事件',
                          style: TextStyle(
                            fontSize: 15,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = null;
                              _minImportance = 1;
                              _selectedCharacterFilter = null;
                            });
                          },
                          child: const Text('重置筛选条件'),
                        ),
                      ],
                    ),
                  );
                }

                return _buildChronicleView(
                  context,
                  filtered,
                  charMap,
                  characters,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text(
                  '加载编年史失败: $err',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, List<Character> characters) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分类标签过滤
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('全部类型'),
                  selected: _selectedCategory == null,
                  onSelected: (sel) {
                    setState(() => _selectedCategory = null);
                  },
                ),
                const SizedBox(width: 8),
                for (final cat in TimelineCategoryConfig.all) ...[
                  FilterChip(
                    avatar: Icon(cat.icon, size: 14, color: cat.color),
                    label: Text(cat.label),
                    selected: _selectedCategory == cat.key,
                    onSelected: (sel) {
                      setState(() {
                        _selectedCategory = sel ? cat.key : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 重要度与角色筛选
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // 重要度分级
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '重要度: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 4),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 1, label: Text('全部')),
                      ButtonSegment(value: 2, label: Text('关键 (★★+)')),
                      ButtonSegment(value: 3, label: Text('史诗 (★★★)')),
                    ],
                    selected: {_minImportance},
                    onSelectionChanged: (set) {
                      setState(() => _minImportance = set.first);
                    },
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),

              // 角色筛选下拉
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '关联角色: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 4),
                  DropdownButton<int?>(
                    value: _selectedCharacterFilter,
                    hint: const Text('全域视角'),
                    underline: const SizedBox.shrink(),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('全域视角 (含人物与世界)'),
                      ),
                      const DropdownMenuItem<int?>(
                        value: -1,
                        child: Text('仅世界宏观事件 (无人物绑定)'),
                      ),
                      for (final c in characters)
                        DropdownMenuItem<int?>(
                          value: c.id,
                          child: Text('人物: ${c.name}'),
                        ),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedCharacterFilter = val);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, List<Character> characters) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories_rounded,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              '编年史长卷尚待书写',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '记录世界的创世纪元、文明更迭、重大灾变，或将人物的英雄传说编织进宏大的历史脉络之中。',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () =>
                  _openEventDialog(context, ref, characters: characters),
              icon: const Icon(Icons.history_edu_rounded),
              label: const Text('撰写第一部纪事'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChronicleView(
    BuildContext context,
    List<TimelineEvent> events,
    Map<int, Character> charMap,
    List<Character> characters,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final ev = events[index];
        final isFirst = index == 0;
        final isLast = index == events.length - 1;
        final cat = TimelineCategoryConfig.find(ev.category);
        final boundChar = ev.characterId != null ? charMap[ev.characterId] : null;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 时间轴节点轴线
              SizedBox(
                width: 48,
                child: Column(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(
                        width: 2.5,
                        color: isFirst
                            ? Colors.transparent
                            : cat.color.withValues(alpha: 0.35),
                      ),
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: cat.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cat.color,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: cat.color.withValues(alpha: 0.2),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(cat.icon, size: 18, color: cat.color),
                    ),
                    Expanded(
                      flex: 3,
                      child: Container(
                        width: 2.5,
                        color: isLast
                            ? Colors.transparent
                            : cat.color.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // 主体卡片
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _ChronicleEventCard(
                    event: ev,
                    category: cat,
                    character: boundChar,
                    worldId: widget.worldId,
                    onEdit: () => _openEventDialog(
                      context,
                      ref,
                      event: ev,
                      characters: characters,
                    ),
                    onDelete: () => _confirmDelete(context, ref, ev),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openEventDialog(
    BuildContext context,
    WidgetRef ref, {
    TimelineEvent? event,
    required List<Character> characters,
  }) {
    showDialog(
      context: context,
      builder: (context) => _ChronicleEventEditDialog(
        worldId: widget.worldId,
        event: event,
        characters: characters,
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TimelineEvent event,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除纪事'),
        content: Text('确定要删除纪事“${event.title}”吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(timelineActionsProvider).deleteEvent(event.id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }
}

class _ChronicleEventCard extends StatelessWidget {
  final TimelineEvent event;
  final TimelineCategoryConfig category;
  final Character? character;
  final int worldId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ChronicleEventCard({
    required this.event,
    required this.category,
    this.character,
    required this.worldId,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEpic = event.importance >= 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEpic
              ? category.color.withValues(alpha: 0.6)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isEpic ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部：纪元年份 + 分类 + 关联人物胶囊 + 操作
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  event.year,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: category.color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                category.label,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),

              // 星级重要度
              if (event.importance > 1)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    event.importance,
                    (i) => const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ),

              const Spacer(),

              // 关联角色胶囊
              if (character != null)
                InkWell(
                  onTap: () {
                    context.push('/world/$worldId/character/${character!.id}');
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OcAvatar(
                          avatarPath: character!.avatarPath,
                          name: character!.name,
                          gender: character!.gender,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          character!.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '世界宏观纪事',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 17),
                tooltip: '编辑',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 17),
                tooltip: '删除',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 事件大标题
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),

          // 事件详细描述
          if (event.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              event.description,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.6,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 编年史新增/编辑弹窗
class _ChronicleEventEditDialog extends ConsumerStatefulWidget {
  final int worldId;
  final TimelineEvent? event;
  final List<Character> characters;

  const _ChronicleEventEditDialog({
    required this.worldId,
    this.event,
    required this.characters,
  });

  @override
  ConsumerState<_ChronicleEventEditDialog> createState() =>
      _ChronicleEventEditDialogState();
}

class _ChronicleEventEditDialogState
    extends ConsumerState<_ChronicleEventEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _yearController;
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _sortController;

  late String _category;
  late int _importance;
  int? _characterId;

  @override
  void initState() {
    super.initState();
    final ev = widget.event;
    _yearController = TextEditingController(text: ev?.year ?? '');
    _titleController = TextEditingController(text: ev?.title ?? '');
    _descController = TextEditingController(text: ev?.description ?? '');
    _sortController =
        TextEditingController(text: (ev?.sortOrder ?? 0.0).toString());
    _category = ev?.category ?? 'general';
    _importance = ev?.importance ?? 1;
    _characterId = ev?.characterId;
  }

  @override
  void dispose() {
    _yearController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _sortController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final year = _yearController.text.trim();
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final sort = double.tryParse(_sortController.text.trim()) ?? 0.0;

    final actions = ref.read(timelineActionsProvider);
    if (widget.event == null) {
      await actions.createEvent(
        worldId: widget.worldId,
        characterId: _characterId,
        year: year,
        sortOrder: sort,
        title: title,
        description: desc,
        category: _category,
        importance: _importance,
      );
    } else {
      await actions.updateEvent(
        id: widget.event!.id,
        worldId: widget.worldId,
        characterId: _characterId,
        year: year,
        sortOrder: sort,
        title: title,
        description: desc,
        category: _category,
        importance: _importance,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.event != null;

    return AlertDialog(
      title: Text(isEditing ? '修撰编年史纪事' : '新撰编年史纪事'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 关联人物选择
                DropdownButtonFormField<int?>(
                  initialValue: _characterId,
                  decoration: const InputDecoration(
                    labelText: '关联角色 (可选)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('无角色绑定（世界宏观大事件）'),
                    ),
                    for (final c in widget.characters)
                      DropdownMenuItem<int?>(
                        value: c.id,
                        child: Text(c.name),
                      ),
                  ],
                  onChanged: (val) {
                    setState(() => _characterId = val);
                  },
                ),
                const SizedBox(height: 12),

                // 纪元 / 年份
                TextFormField(
                  controller: _yearController,
                  decoration: const InputDecoration(
                    labelText: '纪元 / 年份 *',
                    hintText: '例如：帝国历 1024 年、创世纪、第三纪元初期',
                    prefixIcon: Icon(Icons.calendar_month_rounded, size: 20),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return '请输入纪元或年份';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // 标题
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '事件大标题 *',
                    hintText: '例如：星落浩劫、王都政变、神降契约缔结',
                    prefixIcon: Icon(Icons.subtitles_rounded, size: 20),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return '请输入纪事大标题';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // 分类与重要度
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: const InputDecoration(
                          labelText: '事件分类',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                        ),
                        items: TimelineCategoryConfig.all.map((c) {
                          return DropdownMenuItem<String>(
                            value: c.key,
                            child: Row(
                              children: [
                                Icon(c.icon, size: 16, color: c.color),
                                const SizedBox(width: 8),
                                Text(c.label),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _category = val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        initialValue: _importance,
                        decoration: const InputDecoration(
                          labelText: '重要度',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                        ),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('常规记事 (★)')),
                          DropdownMenuItem(value: 2, child: Text('重大转折 (★★)')),
                          DropdownMenuItem(value: 3, child: Text('史诗浩劫 (★★★)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _importance = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 排序辅助权重
                TextFormField(
                  controller: _sortController,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  decoration: const InputDecoration(
                    labelText: '排序权重 (可选)',
                    hintText: '数字越小排在越前，支持小数 (如 1.0, 2.5)',
                    prefixIcon: Icon(Icons.sort_rounded, size: 20),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // 详细描述
                TextFormField(
                  controller: _descController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: '长卷详细记载',
                    hintText: '叙述该事件的历史背景、各方势力交锋过程与长远历史影响…',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? '保存修改' : '确认收录'),
        ),
      ],
    );
  }
}

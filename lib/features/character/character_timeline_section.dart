import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../providers/timeline_provider.dart';

/// 角色详情页中的个人生平时间线卡片
class CharacterTimelineSection extends ConsumerWidget {
  final int worldId;
  final int characterId;

  const CharacterTimelineSection({
    super.key,
    required this.worldId,
    required this.characterId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final eventsAsync = ref.watch(characterTimelineEventsProvider(characterId));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Row(
              children: [
                Icon(
                  Icons.history_edu_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  '生平大事记与时间线',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                eventsAsync.when(
                  data: (events) => events.isEmpty
                      ? const SizedBox.shrink()
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${events.length} 个纪元节点',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: () => _openEventDialog(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('记录生平'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // 时间线主体
            eventsAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return _buildEmptyState(context, ref);
                }
                return _buildTimelineList(context, ref, events);
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    '加载生平事件失败: $err',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 36,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 8),
          Text(
            '暂无生平纪事记录',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '记录角色的出生觉醒、关键战役或命运转折，构建独一无二的生平编年史',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _openEventDialog(context, ref),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('添加第一条生平节点'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineList(
    BuildContext context,
    WidgetRef ref,
    List<TimelineEvent> events,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final isFirst = index == 0;
        final isLast = index == events.length - 1;
        final categoryConfig = TimelineCategoryConfig.find(event.category);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 时间轴节点与贯穿线
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    // 上半部分连接线
                    Expanded(
                      flex: 1,
                      child: Container(
                        width: 2,
                        color: isFirst
                            ? Colors.transparent
                            : categoryConfig.color.withValues(alpha: 0.3),
                      ),
                    ),
                    // 节点徽标
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: categoryConfig.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: categoryConfig.color,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        categoryConfig.icon,
                        size: 14,
                        color: categoryConfig.color,
                      ),
                    ),
                    // 下半部分连接线
                    Expanded(
                      flex: 2,
                      child: Container(
                        width: 2,
                        color: isLast
                            ? Colors.transparent
                            : categoryConfig.color.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // 事件卡片
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _EventCard(
                    event: event,
                    categoryConfig: categoryConfig,
                    onEdit: () => _openEventDialog(
                      context,
                      ref,
                      event: event,
                    ),
                    onDelete: () => _confirmDelete(context, ref, event),
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
  }) {
    showDialog(
      context: context,
      builder: (context) => _TimelineEventEditDialog(
        worldId: worldId,
        characterId: characterId,
        event: event,
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
        title: const Text('删除生平事件'),
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

class _EventCard extends StatelessWidget {
  final TimelineEvent event;
  final TimelineCategoryConfig categoryConfig;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EventCard({
    required this.event,
    required this.categoryConfig,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: event.importance >= 3
              ? categoryConfig.color.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: event.importance >= 3 ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部：年份 + 分类 + 重要度 + 更多操作
          Row(
            children: [
              // 年份纪元胶囊
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: categoryConfig.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  event.year,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: categoryConfig.color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 分类名
              Text(
                categoryConfig.label,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 6),
              // 重要度星标
              if (event.importance > 1)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    event.importance,
                    (i) => const Icon(
                      Icons.star_rounded,
                      size: 13,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ),
              const Spacer(),
              // 操作按钮
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 16),
                tooltip: '编辑',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                tooltip: '删除',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 事件标题
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),

          // 详细描述
          if (event.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              event.description,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 创建或编辑时间线事件对话框
class _TimelineEventEditDialog extends ConsumerStatefulWidget {
  final int worldId;
  final int? characterId;
  final TimelineEvent? event;

  const _TimelineEventEditDialog({
    required this.worldId,
    this.characterId,
    this.event,
  });

  @override
  ConsumerState<_TimelineEventEditDialog> createState() =>
      _TimelineEventEditDialogState();
}

class _TimelineEventEditDialogState
    extends ConsumerState<_TimelineEventEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _yearController;
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _sortController;

  late String _category;
  late int _importance;

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
        characterId: widget.characterId,
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
        characterId: widget.characterId,
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
      title: Text(isEditing ? '编辑生平事件' : '新增生平事件'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 年份 / 纪元
                TextFormField(
                  controller: _yearController,
                  decoration: const InputDecoration(
                    labelText: '纪元 / 年份 *',
                    hintText: '例如：光历 742 年、18岁、第三纪元',
                    prefixIcon: Icon(Icons.date_range_rounded, size: 20),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return '请输入纪元年份或阶段';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // 标题
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '事件标题 *',
                    hintText: '例如：觉醒暗夜异能、参与苍穹决战',
                    prefixIcon: Icon(Icons.title_rounded, size: 20),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return '请输入事件标题';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // 事件类别与重要度
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
                          DropdownMenuItem(value: 1, child: Text('常规轶事 (★)')),
                          DropdownMenuItem(value: 2, child: Text('关键转折 (★★)')),
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
                    labelText: '事件详细记载',
                    hintText: '记录此时刻的故事背景、起因发展、涉及的宿敌或关键后果…',
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
          child: Text(isEditing ? '保存修改' : '确认添加'),
        ),
      ],
    );
  }
}

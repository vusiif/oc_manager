import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../providers/revision_provider.dart';
import '../../../providers/timeline_provider.dart';

/// Dialog for creating or editing a timeline event.
class TimelineEventEditDialog extends ConsumerStatefulWidget {
  final int worldId;
  final int? characterId;
  final TimelineEvent? event;

  const TimelineEventEditDialog({
    super.key,
    required this.worldId,
    this.characterId,
    this.event,
  });

  @override
  ConsumerState<TimelineEventEditDialog> createState() =>
      _TimelineEventEditDialogState();
}

class _TimelineEventEditDialogState
    extends ConsumerState<TimelineEventEditDialog> {
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
    _sortController = TextEditingController(
      text: (ev?.sortOrder ?? 0.0).toString(),
    );
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

    try {
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
        final ev = widget.event!;
        final hasChanged =
            ev.title != title ||
            ev.year != year ||
            ev.description != desc ||
            ev.category != _category ||
            ev.importance != _importance ||
            ev.sortOrder != sort;

        if (hasChanged) {
          await ref
              .read(revisionActionsProvider)
              .recordEventSnapshot(event: ev, source: 'auto');
        }
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存事件失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
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
                  maxLength: 50,
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
                  maxLength: 100,
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
                            horizontal: 12,
                            vertical: 14,
                          ),
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
                            horizontal: 12,
                            vertical: 14,
                          ),
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
                    decimal: true,
                    signed: true,
                  ),
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
                  maxLength: 2000,
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

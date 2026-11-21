import '../../providers/revision_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../providers/timeline_provider.dart';

class ChronicleEventEditDialog extends ConsumerStatefulWidget {
  final int worldId;
  final TimelineEvent? event;
  final List<Character> characters;

  const ChronicleEventEditDialog({
    super.key,
    required this.worldId,
    this.event,
    required this.characters,
  });

  @override
  ConsumerState<ChronicleEventEditDialog> createState() =>
      _ChronicleEventEditDialogState();
}

class _ChronicleEventEditDialogState
    extends ConsumerState<ChronicleEventEditDialog> {
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
    _sortController = TextEditingController(
      text: (ev?.sortOrder ?? 0.0).toString(),
    );
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
      final ev = widget.event!;
      final hasChanged =
          ev.title != title ||
          ev.year != year ||
          ev.description != desc ||
          ev.category != _category ||
          ev.importance != _importance ||
          ev.characterId != _characterId ||
          ev.sortOrder != sort;

      if (hasChanged) {
        await ref
            .read(revisionActionsProvider)
            .recordEventSnapshot(event: ev, source: 'auto');
      }
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
                      DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
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

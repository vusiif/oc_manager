import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../providers/story_provider.dart';

class StoryChapterDialog extends ConsumerStatefulWidget {
  final int workId;
  final StoryChapter? chapter;
  final String? defaultArcName;
  final int? nextSortOrder;

  const StoryChapterDialog({
    super.key,
    required this.workId,
    this.chapter,
    this.defaultArcName,
    this.nextSortOrder,
  });

  static Future<int?> show(
    BuildContext context, {
    required int workId,
    StoryChapter? chapter,
    String? defaultArcName,
    int? nextSortOrder,
  }) {
    return showDialog<int>(
      context: context,
      builder: (_) => StoryChapterDialog(
        workId: workId,
        chapter: chapter,
        defaultArcName: defaultArcName,
        nextSortOrder: nextSortOrder,
      ),
    );
  }

  @override
  ConsumerState<StoryChapterDialog> createState() => _StoryChapterDialogState();
}

class _StoryChapterDialogState extends ConsumerState<StoryChapterDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _arcNameController;
  late final TextEditingController _summaryController;
  late final TextEditingController _wordCountController;

  late String _status;
  bool _saving = false;

  final List<String> _statusOptions = ['大纲', '撰写中', '已定稿', '待重构'];

  @override
  void initState() {
    super.initState();
    final c = widget.chapter;
    _titleController = TextEditingController(text: c?.title ?? '');
    _arcNameController = TextEditingController(
      text: c?.arcName ?? widget.defaultArcName ?? '正卷',
    );
    _summaryController = TextEditingController(text: c?.summary ?? '');
    _wordCountController = TextEditingController(
      text: (c?.wordCount ?? 0) > 0 ? c!.wordCount.toString() : '',
    );
    _status = c?.status ?? '大纲';
    if (!_statusOptions.contains(_status)) {
      _statusOptions.add(_status);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _arcNameController.dispose();
    _summaryController.dispose();
    _wordCountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final wordCount = int.tryParse(_wordCountController.text.trim()) ?? 0;
    final arcName = _arcNameController.text.trim().isEmpty
        ? '正卷'
        : _arcNameController.text.trim();

    try {
      final actions = ref.read(storyActionsProvider);
      if (widget.chapter == null) {
        final id = await actions.createChapter(
          workId: widget.workId,
          title: _titleController.text.trim(),
          arcName: arcName,
          summary: _summaryController.text.trim(),
          status: _status,
          sortOrder: widget.nextSortOrder ?? 0,
          wordCount: wordCount,
        );
        if (mounted) Navigator.of(context).pop(id);
      } else {
        await actions.updateChapter(
          id: widget.chapter!.id,
          workId: widget.workId,
          title: _titleController.text.trim(),
          arcName: arcName,
          summary: _summaryController.text.trim(),
          status: _status,
          sortOrder: widget.chapter!.sortOrder,
          wordCount: wordCount,
        );
        if (mounted) Navigator.of(context).pop(widget.chapter!.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存章节失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.chapter != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
              child: Row(
                children: [
                  Icon(
                    isEdit
                        ? Icons.edit_note_rounded
                        : Icons.bookmark_add_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEdit ? '编辑章节' : '添加新章节',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Form Body
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: '章节标题 *',
                        hintText: '如：第一章 暴风雨的序曲',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.menu_book_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入章节标题';
                        }
                        if (value.trim().length > 100) {
                          return '章节标题不能超过 100 个字符';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Arc / Phase / Volume
                    TextFormField(
                      controller: _arcNameController,
                      maxLength: 50,
                      decoration: const InputDecoration(
                        labelText: '所属故事阶段 / 分卷',
                        hintText: '如：正卷、第一卷：风暴初临、支线：游侠身世',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.folder_special_outlined),
                        helperText: '同卷名称的章节将在大纲列表中自动归类分组',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status & WordCount Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _status,
                            decoration: const InputDecoration(
                              labelText: '章节状态',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.check_circle_outline),
                            ),
                            items: _statusOptions
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _status = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _wordCountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '预估 / 实际字数',
                              hintText: '如：3500',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(
                                Icons.format_list_numbered_rounded,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Summary
                    TextFormField(
                      controller: _summaryController,
                      maxLines: 5,
                      maxLength: 2000,
                      decoration: const InputDecoration(
                        labelText: '本章大纲摘要 / 核心冲突',
                        hintText: '描述本章的核心剧情转折、人物行动目标、悬念铺设或结局走向...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(_saving ? '保存中...' : '确定'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

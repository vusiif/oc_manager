import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/storage/image_storage_service.dart';
import '../../data/database/app_database.dart';
import '../../providers/story_provider.dart';
import '../world/lore_cover_image.dart';

class StoryWorkDialog extends ConsumerStatefulWidget {
  final int worldId;
  final StoryWork? work;

  const StoryWorkDialog({super.key, required this.worldId, this.work});

  static Future<int?> show(
    BuildContext context, {
    required int worldId,
    StoryWork? work,
  }) {
    return showDialog<int>(
      context: context,
      builder: (_) => StoryWorkDialog(worldId: worldId, work: work),
    );
  }

  @override
  ConsumerState<StoryWorkDialog> createState() => _StoryWorkDialogState();
}

class _StoryWorkDialogState extends ConsumerState<StoryWorkDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _summaryController;

  late String _type;
  late String _status;
  String? _coverImagePath;
  bool _saving = false;

  final List<String> _typeOptions = ['小说', '漫画', '剧本', '游戏企划', '跑团模组', '设定短篇'];

  final List<String> _statusOptions = ['策划中', '连载中', '已完结', '暂搁置'];

  @override
  void initState() {
    super.initState();
    final w = widget.work;
    _titleController = TextEditingController(text: w?.title ?? '');
    _summaryController = TextEditingController(text: w?.summary ?? '');
    _type = w?.type ?? '小说';
    if (!_typeOptions.contains(_type)) {
      _typeOptions.add(_type);
    }
    _status = w?.status ?? '策划中';
    if (!_statusOptions.contains(_status)) {
      _statusOptions.add(_status);
    }
    _coverImagePath = w?.coverImagePath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    try {
      final savedRelativePath = await ImageStorageService.instance
          .saveAvatarImage(sourcePath: picked.path);
      setState(() {
        _coverImagePath = savedRelativePath;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('选择图片失败: $e')));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final actions = ref.read(storyActionsProvider);
      if (widget.work == null) {
        final id = await actions.createWork(
          worldId: widget.worldId,
          title: _titleController.text.trim(),
          type: _type,
          summary: _summaryController.text.trim(),
          status: _status,
          coverImagePath: _coverImagePath,
        );
        if (mounted) Navigator.of(context).pop(id);
      } else {
        await actions.updateWork(
          id: widget.work!.id,
          worldId: widget.worldId,
          title: _titleController.text.trim(),
          type: _type,
          summary: _summaryController.text.trim(),
          status: _status,
          coverImagePath: _coverImagePath,
        );
        if (mounted) Navigator.of(context).pop(widget.work!.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存作品失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.work != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
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
                        : Icons.auto_stories_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEdit ? '编辑故事作品' : '新建故事作品',
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
                    // Cover Image Picker
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 130,
                            height: 170,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _coverImagePath != null
                                ? LoreCoverImage(
                                    imagePath: _coverImagePath,
                                    fit: BoxFit.cover,
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.auto_stories_outlined,
                                        size: 40,
                                        color: theme.colorScheme.outline,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '作品封面',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.outline,
                                            ),
                                      ),
                                    ],
                                  ),
                          ),
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: theme.colorScheme.primary,
                              child: IconButton(
                                iconSize: 18,
                                icon: Icon(
                                  _coverImagePath == null
                                      ? Icons.add_photo_alternate_rounded
                                      : Icons.edit_rounded,
                                  color: theme.colorScheme.onPrimary,
                                ),
                                onPressed: _pickCoverImage,
                                tooltip: '选择封面图',
                              ),
                            ),
                          ),
                          if (_coverImagePath != null)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  iconSize: 16,
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                  onPressed: () =>
                                      setState(() => _coverImagePath = null),
                                  tooltip: '移除封面',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: '作品标题 *',
                        hintText: '如：《风暴王座》、《双生纪元》',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入作品标题';
                        }
                        if (value.trim().length > 100) {
                          return '作品标题长度不能超过 100 个字符';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Type & Status Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _type,
                            decoration: const InputDecoration(
                              labelText: '作品体裁',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: _typeOptions
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _type = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _status,
                            decoration: const InputDecoration(
                              labelText: '创作状态',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.flag_outlined),
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
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Summary
                    TextFormField(
                      controller: _summaryController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: '作品简介 / 核心梗概',
                        hintText: '描述故事背景、主线冲突、核心主题或一句话立意...',
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

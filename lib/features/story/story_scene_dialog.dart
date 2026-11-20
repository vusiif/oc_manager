import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/components/oc_avatar.dart';
import '../../data/database/app_database.dart';
import '../../providers/character_provider.dart';
import '../../providers/lore_provider.dart';
import '../../providers/story_provider.dart';

class StorySceneDialog extends ConsumerStatefulWidget {
  final int worldId;
  final int chapterId;
  final StoryScene? scene;
  final int? nextSortOrder;

  const StorySceneDialog({
    super.key,
    required this.worldId,
    required this.chapterId,
    this.scene,
    this.nextSortOrder,
  });

  static Future<int?> show(
    BuildContext context, {
    required int worldId,
    required int chapterId,
    StoryScene? scene,
    int? nextSortOrder,
  }) {
    return showDialog<int>(
      context: context,
      builder: (_) => StorySceneDialog(
        worldId: worldId,
        chapterId: chapterId,
        scene: scene,
        nextSortOrder: nextSortOrder,
      ),
    );
  }

  @override
  ConsumerState<StorySceneDialog> createState() => _StorySceneDialogState();
}

class _StorySceneDialogState extends ConsumerState<StorySceneDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _summaryController;
  late final TextEditingController _contentController;
  late final TextEditingController _timelineTimeController;
  late final TextEditingController _locationNameController;
  late final TextEditingController _moodController;

  int? _povCharacterId;
  int? _locationId;
  final Set<int> _selectedCharacterIds = {};
  bool _saving = false;

  final List<String> _moodSuggestions = [
    '紧张压抑',
    '史诗壮烈',
    '轻松日常',
    '悲怆决绝',
    '悬疑惊悚',
    '暗潮涌动',
    '浪漫温情',
    '热血激昂',
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.scene;
    _titleController = TextEditingController(text: s?.title ?? '');
    _summaryController = TextEditingController(text: s?.summary ?? '');
    _contentController = TextEditingController(text: s?.content ?? '');
    _timelineTimeController = TextEditingController(
      text: s?.timelineTime ?? '',
    );
    _locationNameController = TextEditingController(
      text: s?.locationName ?? '',
    );
    _moodController = TextEditingController(text: s?.mood ?? '');

    _povCharacterId = s?.povCharacterId;
    _locationId = s?.locationId;

    if (s?.characterIds != null) {
      try {
        final dynamic parsed = jsonDecode(s!.characterIds);
        if (parsed is List) {
          for (final item in parsed) {
            final id = int.tryParse(item.toString());
            if (id != null) _selectedCharacterIds.add(id);
          }
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    _timelineTimeController.dispose();
    _locationNameController.dispose();
    _moodController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final actions = ref.read(storyActionsProvider);
      final characterIdsList = _selectedCharacterIds.toList();

      if (widget.scene == null) {
        final id = await actions.createScene(
          chapterId: widget.chapterId,
          title: _titleController.text.trim(),
          summary: _summaryController.text.trim(),
          content: _contentController.text.trim(),
          povCharacterId: _povCharacterId,
          locationId: _locationId,
          locationName: _locationNameController.text.trim(),
          timelineTime: _timelineTimeController.text.trim(),
          mood: _moodController.text.trim(),
          characterIds: characterIdsList,
          sortOrder: widget.nextSortOrder ?? 0,
        );
        if (mounted) Navigator.of(context).pop(id);
      } else {
        await actions.updateScene(
          id: widget.scene!.id,
          chapterId: widget.chapterId,
          title: _titleController.text.trim(),
          summary: _summaryController.text.trim(),
          content: _contentController.text.trim(),
          povCharacterId: _povCharacterId,
          locationId: _locationId,
          locationName: _locationNameController.text.trim(),
          timelineTime: _timelineTimeController.text.trim(),
          mood: _moodController.text.trim(),
          characterIds: characterIdsList,
          sortOrder: widget.scene!.sortOrder,
        );
        if (mounted) Navigator.of(context).pop(widget.scene!.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存场景失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.scene != null;

    final charactersAsync = ref.watch(
      charactersByWorldProvider(widget.worldId),
    );
    final locationsAsync = ref.watch(
      loreEntitiesByTypeProvider((
        worldId: widget.worldId,
        entityType: 'location',
      )),
    );

    final characters = charactersAsync.valueOrNull ?? [];
    final locations = locationsAsync.valueOrNull ?? [];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
              child: Row(
                children: [
                  Icon(
                    isEdit ? Icons.movie_edit : Icons.movie_creation_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEdit ? '编辑场景分镜' : '添加场景分镜',
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
                    // Scene Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: '场景标题 *',
                        hintText: '如：旧城废墟的秘密接头、暴风雨之夜的决裂',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入场景标题';
                        }
                        if (value.trim().length > 100) {
                          return '场景标题不能超过 100 个字符';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // POV Character Dropdown
                    DropdownButtonFormField<int?>(
                      initialValue: _povCharacterId,
                      decoration: const InputDecoration(
                        labelText: 'POV 视点人物',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.visibility_outlined),
                        helperText: '该场景主要通过谁的视角与心理感知展开',
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('无指定 / 全知第三人称视角'),
                        ),
                        ...characters.map(
                          (c) => DropdownMenuItem<int?>(
                            value: c.id,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OcAvatar(
                                  avatarPath: c.avatarPath,
                                  name: c.name,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(c.name),
                              ],
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _povCharacterId = val;
                          if (val != null) {
                            _selectedCharacterIds.add(val);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Location Selection (Dropdown with Lore Location + Free Text)
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            initialValue: _locationId,
                            decoration: const InputDecoration(
                              labelText: '关联百科地点',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('无关联 / 手动输入地点'),
                              ),
                              ...locations.map(
                                (loc) => DropdownMenuItem<int?>(
                                  value: loc.id,
                                  child: Text(loc.name),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _locationId = val;
                                if (val != null) {
                                  final selectedLoc = locations.firstWhere(
                                    (l) => l.id == val,
                                  );
                                  _locationNameController.text =
                                      selectedLoc.name;
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _locationNameController,
                            decoration: const InputDecoration(
                              labelText: '发生地点名称',
                              hintText: '如：王都东郊酒馆地下室',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.place_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Timeline Time & Mood
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _timelineTimeController,
                            decoration: const InputDecoration(
                              labelText: '发生时间',
                              hintText: '如：大陆历734年夏末 黄昏',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.schedule_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _moodController,
                            decoration: const InputDecoration(
                              labelText: '氛围基调 / 情感色彩',
                              hintText: '如：紧张压抑、史诗对决',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.palette_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Mood suggestions chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _moodSuggestions.map((m) {
                        return ActionChip(
                          label: Text(m, style: const TextStyle(fontSize: 12)),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            setState(() => _moodController.text = m);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Cast / Characters Multi-select (STORY-003 Ready)
                    Text(
                      '出场角色群 (Cast)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (characters.isEmpty)
                      Text(
                        '当前世界观下暂无角色，可先在角色大厅创建角色',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: characters.map((c) {
                            final isSelected = _selectedCharacterIds.contains(
                              c.id,
                            );
                            final isPov = _povCharacterId == c.id;
                            return FilterChip(
                              avatar: OcAvatar(
                                avatarPath: c.avatarPath,
                                name: c.name,
                                size: 20,
                              ),
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(c.name),
                                  if (isPov) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'POV',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: theme.colorScheme.onPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              selected: isSelected,
                              onSelected: (val) {
                                setState(() {
                                  if (val) {
                                    _selectedCharacterIds.add(c.id);
                                  } else {
                                    if (isPov) {
                                      // If user deselects POV character, clear POV
                                      _povCharacterId = null;
                                    }
                                    _selectedCharacterIds.remove(c.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Scene Summary
                    TextFormField(
                      controller: _summaryController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: '场景概要 / 一句话提炼',
                        hintText: '提炼该场景发生的主要事件与冲突结果...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Scene Content / Beats
                    TextFormField(
                      controller: _contentController,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: '分镜要点 / 剧情推进与台词草稿',
                        hintText:
                            '1. 主角步入密室，察觉到空气中残留的法术残光\n2. 发现被篡改的羊皮卷宗\n3. 门外传来铠甲碰撞的脚步声，做出隐匿选择...',
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

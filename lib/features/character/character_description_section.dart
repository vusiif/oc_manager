import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/database/app_database.dart';
import '../../core/design/components/oc_avatar.dart';
import '../../core/util/wiki_link_parser.dart';
import '../../providers/character_provider.dart';
import '../../providers/backlink_provider.dart';

/// 角色详情页中的详细描述卡片（支持维基双向链接与反向引用）
class CharacterDescriptionSection extends ConsumerStatefulWidget {
  final int worldId;
  final Character character;

  const CharacterDescriptionSection({
    super.key,
    required this.worldId,
    required this.character,
  });

  @override
  ConsumerState<CharacterDescriptionSection> createState() =>
      _CharacterDescriptionSectionState();
}

class _CharacterDescriptionSectionState
    extends ConsumerState<CharacterDescriptionSection> {
  late final TextEditingController _controller;
  bool _isEditing = false;
  bool _isBacklinksExpanded = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.character.description);
  }

  @override
  void didUpdateWidget(covariant CharacterDescriptionSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.character.id != widget.character.id) {
      _controller.text = widget.character.description;
      _isEditing = false;
    } else if (oldWidget.character.description != widget.character.description &&
        !_isEditing) {
      _controller.text = widget.character.description;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveDescription() async {
    final newText = _controller.text;
    if (newText != widget.character.description) {
      await ref.read(characterActionsProvider).update(
            widget.character.copyWith(description: newText),
          );
      ref.invalidate(characterByIdProvider(widget.character.id));
    }
    if (mounted) {
      setState(() => _isEditing = false);
    }
  }

  void _insertCharacterLink(String name) {
    final text = _controller.text;
    final selection = _controller.selection;
    final tag = '[[$name]]';

    if (selection.isValid && selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, tag);
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + tag.length),
      );
    } else {
      final newText = '$text $tag';
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }

  void _showInsertLinkDialog(List<Character> allChars) {
    final candidates =
        allChars.where((c) => c.id != widget.character.id).toList();

    showDialog(
      context: context,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = candidates.where((c) {
              if (query.isEmpty) return true;
              return c.name.toLowerCase().contains(query.toLowerCase());
            }).toList();

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.link_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('插入双向人名链接'),
                ],
              ),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: '搜索角色姓名…',
                        prefixIcon: Icon(Icons.search, size: 18),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        setDialogState(() => query = val.trim());
                      },
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: filtered.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('无匹配角色'),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final char = filtered[index];
                                return ListTile(
                                  dense: true,
                                  leading: OcAvatar(
                                    avatarPath: char.avatarPath,
                                    name: char.name,
                                    gender: char.gender,
                                    size: 28,
                                  ),
                                  title: Text(char.name),
                                  trailing: const Icon(Icons.add_rounded,
                                      size: 18),
                                  onTap: () {
                                    Navigator.of(ctx).pop();
                                    _insertCharacterLink(char.name);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('取消'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allCharsAsync = ref.watch(charactersByWorldProvider(widget.worldId));
    final allChars = allCharsAsync.valueOrNull ?? [];
    final charMap = {for (final c in allChars) c.name: c};

    // 反向引用查询
    final backlinks = ref.watch(characterBacklinksProvider(
      BacklinkQuery(
        worldId: widget.worldId,
        characterId: widget.character.id,
        characterName: widget.character.name,
      ),
    ));

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
            // 顶栏：标题 + 操作工具栏
            Row(
              children: [
                Icon(
                  Icons.auto_stories_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  '详细设定与小传',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_isEditing) ...[
                  TextButton.icon(
                    onPressed: () => _showInsertLinkDialog(allChars),
                    icon: const Icon(Icons.link_rounded, size: 16),
                    label: const Text('插入双向链接'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _saveDescription,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('完成'),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ] else ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: '编辑描述',
                    onPressed: () => setState(() => _isEditing = true),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // 主内容区域（编辑模式 vs 浏览模式）
            if (_isEditing)
              _buildEditMode(context, allChars)
            else
              _buildViewMode(context, charMap),

            // 反向引用（Backlinks 面板）
            if (backlinks.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildBacklinksSection(context, backlinks),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditMode(BuildContext context, List<Character> allChars) {
    final otherCandidates =
        allChars.where((c) => c.id != widget.character.id).take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          maxLines: null,
          minLines: 6,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '书写人物的出身背景、宿命纠葛或关键故事…（可输入 [[人物姓名]] 建立双向互通链接）',
            border: OutlineInputBorder(),
          ),
          style: const TextStyle(fontSize: 14, height: 1.6),
        ),
        if (otherCandidates.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '快捷提及: ',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final oc in otherCandidates) ...[
                        ActionChip(
                          avatar: const Icon(Icons.add_link_rounded, size: 13),
                          label: Text(oc.name),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          labelStyle: const TextStyle(fontSize: 11.5),
                          onPressed: () => _insertCharacterLink(oc.name),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildViewMode(
      BuildContext context, Map<String, Character> charMap) {
    final text = _controller.text.trim();
    final theme = Theme.of(context);

    if (text.isEmpty) {
      return InkWell(
        onTap: () => setState(() => _isEditing = true),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.edit_note_rounded,
                size: 32,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 6),
              Text(
                '暂无详细小传，点击此处开始记录',
                style: TextStyle(
                  fontSize: 13.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final spans = WikiLinkParser.buildWikiSpans(
      text: text,
      nameToCharacterMap: charMap,
      context: context,
      onCharacterTap: (target) {
        context.push('/world/${widget.worldId}/character/${target.id}');
      },
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Text.rich(
        TextSpan(children: spans),
        style: const TextStyle(fontSize: 14, height: 1.65),
      ),
    );
  }

  Widget _buildBacklinksSection(
      BuildContext context, List<BacklinkItem> backlinks) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 反向引用栏折叠头部
          InkWell(
            onTap: () {
              setState(() {
                _isBacklinksExpanded = !_isBacklinksExpanded;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.bubble_chart_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '反向引用 (Backlinks) · 被 ${backlinks.length} 位角色提及',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isBacklinksExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // 展开的被引用列表
          if (_isBacklinksExpanded) ...[
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8),
              itemCount: backlinks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final item = backlinks[index];
                final other = item.sourceCharacter;

                return InkWell(
                  onTap: () {
                    context.push('/world/${widget.worldId}/character/${other.id}');
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OcAvatar(
                          avatarPath: other.avatarPath,
                          name: other.name,
                          gender: other.gender,
                          size: 26,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    other.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '查看档案 ›',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              if (item.snippets.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                for (final snippet in item.snippets.take(2))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      '“$snippet”',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

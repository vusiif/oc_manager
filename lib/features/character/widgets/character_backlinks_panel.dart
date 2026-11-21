import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/components/oc_avatar.dart';
import '../../../providers/backlink_provider.dart';

/// Collapsible backlinks panel displaying mentions of this character in other bios.
class CharacterBacklinksPanel extends StatefulWidget {
  final int worldId;
  final List<BacklinkItem> backlinks;

  const CharacterBacklinksPanel({
    super.key,
    required this.worldId,
    required this.backlinks,
  });

  @override
  State<CharacterBacklinksPanel> createState() =>
      _CharacterBacklinksPanelState();
}

class _CharacterBacklinksPanelState extends State<CharacterBacklinksPanel> {
  bool _isBacklinksExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backlinks = widget.backlinks;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
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
                    context.push(
                      '/world/${widget.worldId}/character/${other.id}',
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.4,
                        ),
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
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
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

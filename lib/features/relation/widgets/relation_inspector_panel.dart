import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../data/database/app_database.dart';
import '../painters/relation_style_helper.dart';
import 'relation_node_avatar.dart';

/// Lightweight Obsidian Canvas-style Inspector Card for selected relation.
/// Allows instant property inspection, direction switching, quick-type reassignment,
/// note editing, and deletion without blocking the entire canvas with a modal dialog.
class RelationInspectorPanel extends StatelessWidget {
  final Relation relation;
  final Character fromCharacter;
  final Character toCharacter;
  final VoidCallback onClose;
  final VoidCallback onOpenFullDialog;
  final void Function(Relation newRel, String description) onUpdateRelation;
  final VoidCallback onDeleteRelation;

  const RelationInspectorPanel({
    super.key,
    required this.relation,
    required this.fromCharacter,
    required this.toCharacter,
    required this.onClose,
    required this.onOpenFullDialog,
    required this.onUpdateRelation,
    required this.onDeleteRelation,
  });

  static const List<String> _quickTypes = [
    '朋友',
    '恋人',
    '亲属',
    '敌对',
    '师徒',
    '同僚',
    '盟友',
  ];

  void _cycleDirection() {
    if (relation.isBidirectional) {
      // 双向 -> 单向 (from -> to)
      final updated = relation.copyWith(isBidirectional: false);
      onUpdateRelation(
        updated,
        '设置【${fromCharacter.name}】到【${toCharacter.name}】为单向',
      );
    } else {
      // 单向 -> 恢复双向
      final updated = relation.copyWith(isBidirectional: true);
      onUpdateRelation(
        updated,
        '设置【${fromCharacter.name}】与【${toCharacter.name}】为双向',
      );
    }
  }

  void _reverseDirection() {
    final updated = relation.copyWith(
      fromCharacterId: relation.toCharacterId,
      toCharacterId: relation.fromCharacterId,
      isBidirectional: false,
    );
    onUpdateRelation(
      updated,
      '反转关系方向为【${toCharacter.name}】➔【${fromCharacter.name}】',
    );
  }

  Future<void> _editNote(BuildContext context) async {
    final controller = TextEditingController(text: relation.note ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑关系备注', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '输入关系背景、恩怨成因或细节...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final text = controller.text.trim();
      final updated = relation.copyWith(
        note: Value(text.isEmpty ? null : text),
      );
      onUpdateRelation(updated, '更新关系备注');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final relColor = RelationStyleHelper.getRelationColor(
      relation.relationType,
      isBidirectional: relation.isBidirectional,
      isDark: isDark,
    );

    return RepaintBoundary(
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(14),
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.94)
            : Colors.white.withValues(alpha: 0.96),
        child: Container(
          width: 320,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 顶栏：类型名称徽章 + 方向状态 + 关闭按钮
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: relColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    relation.relationType,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: relColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      relation.isBidirectional ? '双向' : '单向',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: relColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    tooltip: '取消选中',
                    visualDensity: VisualDensity.compact,
                    onPressed: onClose,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 2. 两端人物展示与方向切换操作
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black12,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // 起点角色
                    _buildCharacterMini(fromCharacter, isDark),
                    const Spacer(),
                    // 方向切换按钮
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                relation.isBidirectional
                                    ? Icons.swap_horiz
                                    : Icons.arrow_forward,
                                color: relColor,
                                size: 20,
                              ),
                              tooltip: relation.isBidirectional
                                  ? '切换为单向关系'
                                  : '切换为双向关系',
                              visualDensity: VisualDensity.compact,
                              onPressed: _cycleDirection,
                            ),
                            if (!relation.isBidirectional)
                              IconButton(
                                icon: const Icon(
                                  Icons.sync_alt,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                tooltip: '反转单向箭头方向',
                                visualDensity: VisualDensity.compact,
                                onPressed: _reverseDirection,
                              ),
                          ],
                        ),
                        Text(
                          relation.isBidirectional ? '双向连线' : '单向箭头',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // 终点角色
                    _buildCharacterMini(toCharacter, isDark),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // 3. 快捷类型切换 Chips
              const Text(
                '快捷类型',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _quickTypes.map((type) {
                  final isCurrent = (type == relation.relationType);
                  final chipColor = RelationStyleHelper.getRelationColor(
                    type,
                    isBidirectional: relation.isBidirectional,
                    isDark: isDark,
                  );

                  return InkWell(
                    onTap: () {
                      if (!isCurrent) {
                        final updated = relation.copyWith(relationType: type);
                        onUpdateRelation(updated, '修改关系为【$type】');
                      }
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? chipColor.withValues(alpha: 0.22)
                            : (isDark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: 0.04)),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isCurrent ? chipColor : Colors.transparent,
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isCurrent
                              ? chipColor
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              // 4. 备注展示与快捷编辑
              InkWell(
                onTap: () => _editNote(context),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notes, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          (relation.note != null &&
                                  relation.note!.trim().isNotEmpty)
                              ? relation.note!
                              : '点击添加关系备注...',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle:
                                (relation.note == null ||
                                    relation.note!.trim().isEmpty)
                                ? FontStyle.italic
                                : FontStyle.normal,
                            color:
                                (relation.note == null ||
                                    relation.note!.trim().isEmpty)
                                ? Colors.grey
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.edit, size: 12, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 5. 底栏操作按钮（详细编辑 + 删除）
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.tune, size: 14),
                    label: const Text('详细设置', style: TextStyle(fontSize: 11)),
                    onPressed: onOpenFullDialog,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    tooltip: '删除此关系',
                    visualDensity: VisualDensity.compact,
                    onPressed: onDeleteRelation,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterMini(Character char, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildCharacterAvatar(
          character: char,
          size: 28,
          color: char.status == 1 ? Colors.grey : AppColors.brand,
        ),
        const SizedBox(height: 3),
        SizedBox(
          width: 60,
          child: Text(
            char.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/components/radar_chart.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/character_provider.dart';

/// 底部弹出常用属性预设选择器
void showStatPresetPicker(
  BuildContext context, {
  required ValueChanged<StatPreset> onSelect,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_fix_high_rounded),
                  const SizedBox(width: 8),
                  Text(
                    '套用常用属性预设',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '选择预设将替换当前角色的属性维度列表，各维度可在套用后自由调节数值。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              for (final preset in StatPreset.builtInPresets)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.primary,
                    child: Icon(preset.icon, size: 20),
                  ),
                  title: Text(
                    preset.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(preset.description),
                  trailing: Text(
                    '${preset.dimensions.length} 维 (满分 ${preset.maxValue.toInt()})',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onSelect(preset);
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// 添加属性维度弹窗
void showAddStatDialog(
  BuildContext context, {
  required int characterId,
  required int currentCount,
  required WidgetRef ref,
}) {
  final labelCtrl = TextEditingController();
  final valueCtrl = TextEditingController(text: '70');
  final maxCtrl = TextEditingController(text: '100');

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('添加属性维度'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: labelCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '维度名称',
              hintText: '如：攻击力、意志、灵力',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: valueCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '初始数值'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: maxCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '满值上限'),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () async {
            final label = labelCtrl.text.trim();
            if (label.isEmpty) return;
            final val = double.tryParse(valueCtrl.text) ?? 60.0;
            final max = double.tryParse(maxCtrl.text) ?? 100.0;

            await ref
                .read(characterActionsProvider)
                .addStat(
                  CharacterStatsCompanion.insert(
                    characterId: characterId,
                    label: label,
                    value: Value(val),
                    maxValue: Value(max > 0 ? max : 100.0),
                    sortOrder: Value(currentCount),
                  ),
                );
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('添加'),
        ),
      ],
    ),
  );
}

/// 修改属性维度与上限弹窗
void showEditStatDialog(
  BuildContext context, {
  required CharacterStat stat,
  required WidgetRef ref,
}) {
  final labelCtrl = TextEditingController(text: stat.label);
  final maxCtrl = TextEditingController(text: stat.maxValue.toInt().toString());

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('修改属性维度'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: labelCtrl,
            autofocus: true,
            decoration: const InputDecoration(labelText: '维度名称'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: maxCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '满值上限'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () async {
            final label = labelCtrl.text.trim();
            if (label.isEmpty) return;
            final max = double.tryParse(maxCtrl.text) ?? stat.maxValue;

            await ref
                .read(characterActionsProvider)
                .updateStat(
                  CharacterStatsCompanion(
                    id: Value(stat.id),
                    characterId: Value(stat.characterId),
                    label: Value(label),
                    value: Value(stat.value > max ? max : stat.value),
                    maxValue: Value(max > 0 ? max : 100.0),
                    sortOrder: Value(stat.sortOrder),
                  ),
                );
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('保存'),
        ),
      ],
    ),
  );
}

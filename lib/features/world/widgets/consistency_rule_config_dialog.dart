import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/consistency/consistency_checker_engine.dart';
import '../../../providers/consistency_provider.dart';

/// Dialog for enabling/disabling consistency diagnostic rules and customizing severity per world (CONSIST-006).
class ConsistencyRuleConfigDialog extends ConsumerWidget {
  final int worldId;

  const ConsistencyRuleConfigDialog({super.key, required this.worldId});

  static Future<void> show(BuildContext context, {required int worldId}) {
    return showDialog(
      context: context,
      builder: (_) => ConsistencyRuleConfigDialog(worldId: worldId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(consistencyEngineProvider);
    final ruleConfigs = ref.watch(worldRuleConfigsProvider(worldId));
    final notifier = ref.read(worldRuleConfigsProvider(worldId).notifier);
    final allRules = engine.registry.allRules;
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.tune_rounded, color: theme.colorScheme.primary, size: 22),
          const SizedBox(width: 8),
          const Text('诊断规则启停配置'),
        ],
      ),
      content: SizedBox(
        width: 580,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '可根据世界观创作成熟度，自由启用/停用规则，或针对当前世界观自定义严重级别。停用的规则将不再扫描，亦不扣减自洽健康分。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              ...allRules.map((rule) {
                final config =
                    ruleConfigs[rule.ruleId] ?? const RuleConfig(enabled: true);
                final isEnabled = config.enabled;
                final effectiveSeverity =
                    config.customSeverity ?? rule.defaultSeverity;
                final isCustom = config.customSeverity != null;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isEnabled
                          ? theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.25)
                          : theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isEnabled
                            ? theme.colorScheme.outlineVariant.withValues(
                                alpha: 0.4,
                              )
                            : Colors.transparent,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isEnabled,
                          onChanged: (_) {
                            notifier.toggleRule(rule.ruleId);
                          },
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    rule.category.icon,
                                    size: 15,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      rule.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isEnabled
                                            ? null
                                            : theme.colorScheme.outline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${rule.category.label} · ${rule.description}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Severity Selector Popup Menu
                        PopupMenuButton<IssueSeverity?>(
                          tooltip: '调整该规则在当前世界观的严重度',
                          enabled: isEnabled,
                          onSelected: (newSeverity) {
                            notifier.setRuleSeverity(rule.ruleId, newSeverity);
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<IssueSeverity?>(
                              value: null,
                              child: Row(
                                children: [
                                  Icon(
                                    rule.defaultSeverity.icon,
                                    color: rule.defaultSeverity.color,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text('默认级别 (${rule.defaultSeverity.label})'),
                                  if (!isCustom) ...[
                                    const Spacer(),
                                    const Icon(Icons.check, size: 16),
                                  ],
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            ...IssueSeverity.values.map((s) {
                              final isSelected = config.customSeverity == s;
                              return PopupMenuItem<IssueSeverity?>(
                                value: s,
                                child: Row(
                                  children: [
                                    Icon(s.icon, color: s.color, size: 16),
                                    const SizedBox(width: 8),
                                    Text(s.label),
                                    if (isSelected) ...[
                                      const Spacer(),
                                      const Icon(Icons.check, size: 16),
                                    ],
                                  ],
                                ),
                              );
                            }),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: effectiveSeverity.color.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: effectiveSeverity.color.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  effectiveSeverity.icon,
                                  size: 14,
                                  color: effectiveSeverity.color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  effectiveSeverity.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: effectiveSeverity.color,
                                  ),
                                ),
                                if (isCustom) ...[
                                  const SizedBox(width: 2),
                                  Text(
                                    '*',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: effectiveSeverity.color,
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.arrow_drop_down,
                                  size: 14,
                                  color: effectiveSeverity.color,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            notifier.resetDefaults();
          },
          child: const Text('重置全部启用与默认级别'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('完成'),
        ),
      ],
    );
  }
}

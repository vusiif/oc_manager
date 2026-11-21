import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import 'knowledge_network_models.dart';

class KnowledgeNetworkFilterDialog {
  KnowledgeNetworkFilterDialog._();

  static void show({
    required BuildContext context,
    required bool isDark,
    required KnowledgeNetworkFilterState filterState,
    required ValueChanged<KnowledgeNetworkFilterState> onFilterChanged,
  }) {
    KnowledgeNetworkFilterState currentFilter = filterState;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.filter_alt_rounded, color: AppColors.brand),
                  const SizedBox(width: 8),
                  const Text('网络维度过滤'),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 节点类型过滤
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '实体类型 (Nodes)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                final all = Set<NetworkNodeType>.from(
                                  NetworkNodeType.values,
                                );
                                final isAll =
                                    currentFilter.enabledNodeTypes.length ==
                                    all.length;
                                setDialogState(() {
                                  currentFilter = currentFilter.copyWith(
                                    enabledNodeTypes: isAll ? {} : all,
                                  );
                                });
                              });
                            },
                            child: Text(
                              currentFilter.enabledNodeTypes.length ==
                                      NetworkNodeType.values.length
                                  ? '取消全选'
                                  : '全选',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          for (final t in NetworkNodeType.values)
                            FilterChip(
                              avatar: Icon(t.icon, size: 14, color: t.color),
                              label: Text(t.label),
                              selected: currentFilter.enabledNodeTypes.contains(
                                t,
                              ),
                              selectedColor: t.color.withValues(alpha: 0.2),
                              onSelected: (selected) {
                                setDialogState(() {
                                  final newSet = Set<NetworkNodeType>.from(
                                    currentFilter.enabledNodeTypes,
                                  );
                                  if (selected) {
                                    newSet.add(t);
                                  } else {
                                    newSet.remove(t);
                                  }
                                  setDialogState(() {
                                    currentFilter = currentFilter.copyWith(
                                      enabledNodeTypes: newSet,
                                    );
                                  });
                                });
                              },
                            ),
                        ],
                      ),

                      const Divider(height: 24),

                      // 边类型过滤
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '关联类型 (Edges)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                final all = Set<NetworkEdgeType>.from(
                                  NetworkEdgeType.values,
                                );
                                final isAll =
                                    currentFilter.enabledEdgeTypes.length ==
                                    all.length;
                                setDialogState(() {
                                  currentFilter = currentFilter.copyWith(
                                    enabledEdgeTypes: isAll ? {} : all,
                                  );
                                });
                              });
                            },
                            child: Text(
                              currentFilter.enabledEdgeTypes.length ==
                                      NetworkEdgeType.values.length
                                  ? '取消全选'
                                  : '全选',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          for (final et in NetworkEdgeType.values)
                            FilterChip(
                              label: Text(et.label),
                              selected: currentFilter.enabledEdgeTypes.contains(
                                et,
                              ),
                              selectedColor: et.color.withValues(alpha: 0.2),
                              onSelected: (selected) {
                                setDialogState(() {
                                  final newSet = Set<NetworkEdgeType>.from(
                                    currentFilter.enabledEdgeTypes,
                                  );
                                  if (selected) {
                                    newSet.add(et);
                                  } else {
                                    newSet.remove(et);
                                  }
                                  setDialogState(() {
                                    currentFilter = currentFilter.copyWith(
                                      enabledEdgeTypes: newSet,
                                    );
                                  });
                                });
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      currentFilter = const KnowledgeNetworkFilterState();
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('重置全部'),
                ),
                FilledButton(
                  onPressed: () {
                    onFilterChanged(currentFilter);
                    Navigator.pop(ctx);
                  },
                  child: const Text('完成'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

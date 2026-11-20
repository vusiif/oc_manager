import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/consistency/consistency_checker_engine.dart';
import '../../providers/consistency_provider.dart';

class ConsistencyCheckerDialog extends ConsumerStatefulWidget {
  final int worldId;
  final String worldName;

  const ConsistencyCheckerDialog({
    super.key,
    required this.worldId,
    required this.worldName,
  });

  static Future<void> show(
    BuildContext context, {
    required int worldId,
    required String worldName,
  }) {
    return showDialog(
      context: context,
      builder: (_) =>
          ConsistencyCheckerDialog(worldId: worldId, worldName: worldName),
    );
  }

  @override
  ConsumerState<ConsistencyCheckerDialog> createState() =>
      _ConsistencyCheckerDialogState();
}

class _ConsistencyCheckerDialogState
    extends ConsumerState<ConsistencyCheckerDialog> {
  IssueSeverity? _selectedSeverity; // null 表示全部严重级别
  IssueCategory? _selectedCategory; // null 表示全部分类
  bool _showResolvedOrIgnored = false; // 是否查看已处理/已忽略的项

  void _handleNavigate(ConsistencyIssue issue) {
    Navigator.pop(context); // 关闭检查器弹窗
    switch (issue.targetType) {
      case 'character':
        context.push('/world/${widget.worldId}/character/${issue.targetId}');
        break;
      case 'lore':
        context.push('/world/${widget.worldId}/lore');
        break;
      case 'timeline':
        context.push('/world/${widget.worldId}/chronicle');
        break;
      case 'relation':
        context.push('/world/${widget.worldId}/graph');
        break;
    }
  }

  /// 打开规则启停配置弹窗 (CONSIST-006)
  void _showRuleConfigDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Consumer(
        builder: (context, ref, _) {
          final engine = ref.watch(consistencyEngineProvider);
          final enabledRules = ref.watch(
            worldEnabledRulesProvider(widget.worldId),
          );
          final allRules = engine.registry.allRules;
          final theme = Theme.of(context);

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text('诊断规则启停配置'),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '可根据世界观创作成熟度，自由启用或停用指定规则。停用的规则将不再扫描，亦不扣减自洽健康分。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    ...allRules.map((rule) {
                      final isEnabled = enabledRules.contains(rule.ruleId);
                      return CheckboxListTile(
                        value: isEnabled,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          rule.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${rule.category.label} · ${rule.description}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        onChanged: (val) {
                          ref
                              .read(
                                worldEnabledRulesProvider(
                                  widget.worldId,
                                ).notifier,
                              )
                              .toggleRule(rule.ruleId);
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  ref
                      .read(worldEnabledRulesProvider(widget.worldId).notifier)
                      .resetDefaults();
                },
                child: const Text('重置全部启用'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('完成'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reportAsync = ref.watch(consistencyReportProvider(widget.worldId));
    final issueStatusMap = ref.watch(worldIssueStatusProvider(widget.worldId));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 800),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶栏：标题、规则配置与操作
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.fact_check_rounded,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '世界设定一致性检查器',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.worldName} · 逻辑自洽体检与工作台',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune_rounded),
                    tooltip: '规则配置',
                    onPressed: () => _showRuleConfigDialog(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: '重新扫描检查',
                    onPressed: () => ref.invalidate(
                      consistencyReportProvider(widget.worldId),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: reportAsync.when(
                  loading: () => const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('正在执行规则引擎诊断与跨链扫描...'),
                      ],
                    ),
                  ),
                  error: (err, _) => Center(child: Text('检查过程发生错误：$err')),
                  data: (report) {
                    // 分流：活跃待办 vs 已处理 (已忽略 / 标记解决)
                    final activeIssues = report.issues.where((i) {
                      final status = issueStatusMap[i.id];
                      return status == null ||
                          status == IssueHandlingStatus.active;
                    }).toList();

                    final processedIssues = report.issues.where((i) {
                      final status = issueStatusMap[i.id];
                      return status == IssueHandlingStatus.ignored ||
                          status == IssueHandlingStatus.resolved;
                    }).toList();

                    // 计算有效健康分 (已忽略与已标记解决的问题不扣减健康分)
                    int activeHealthScore = 100;
                    for (final i in activeIssues) {
                      switch (i.severity) {
                        case IssueSeverity.error:
                          activeHealthScore -= 15;
                          break;
                        case IssueSeverity.warning:
                          activeHealthScore -= 5;
                          break;
                        case IssueSeverity.info:
                          activeHealthScore -= 1;
                          break;
                      }
                    }
                    if (activeHealthScore < 0) activeHealthScore = 0;

                    final currentScopeIssues = _showResolvedOrIgnored
                        ? processedIssues
                        : activeIssues;

                    // 复合过滤条件 (严重度 + 规则分类)
                    final filteredIssues = currentScopeIssues.where((i) {
                      if (_selectedSeverity != null &&
                          i.severity != _selectedSeverity) {
                        return false;
                      }
                      if (_selectedCategory != null &&
                          i.category != _selectedCategory) {
                        return false;
                      }
                      return true;
                    }).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 健康总览大盘卡片
                        _buildHealthOverviewCard(
                          context,
                          report: report,
                          activeScore: activeHealthScore,
                          activeCount: activeIssues.length,
                          processedCount: processedIssues.length,
                        ),
                        const SizedBox(height: 14),

                        // 状态切换 (待办事项 vs 已处理) 与过滤栏
                        Row(
                          children: [
                            SegmentedButton<bool>(
                              segments: [
                                ButtonSegment<bool>(
                                  value: false,
                                  label: Text('待办事项 (${activeIssues.length})'),
                                  icon: const Icon(
                                    Icons.pending_actions_rounded,
                                    size: 16,
                                  ),
                                ),
                                ButtonSegment<bool>(
                                  value: true,
                                  label: Text(
                                    '已处理/忽略 (${processedIssues.length})',
                                  ),
                                  icon: const Icon(
                                    Icons.done_all_rounded,
                                    size: 16,
                                  ),
                                ),
                              ],
                              selected: {_showResolvedOrIgnored},
                              onSelectionChanged: (set) {
                                setState(() {
                                  _showResolvedOrIgnored = set.first;
                                });
                              },
                            ),
                            const Spacer(),
                            if (_selectedCategory != null ||
                                _selectedSeverity != null)
                              TextButton.icon(
                                onPressed: () => setState(() {
                                  _selectedCategory = null;
                                  _selectedSeverity = null;
                                }),
                                icon: const Icon(Icons.clear_rounded, size: 14),
                                label: const Text('重置筛选'),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // 严重级别与分类过滤 Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              FilterChip(
                                label: Text(
                                  '全部 (${currentScopeIssues.length})',
                                ),
                                selected: _selectedSeverity == null,
                                onSelected: (_) => setState(() {
                                  _selectedSeverity = null;
                                }),
                              ),
                              const SizedBox(width: 8),
                              ...IssueSeverity.values.map((sev) {
                                final count = currentScopeIssues
                                    .where((i) => i.severity == sev)
                                    .length;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    avatar: Icon(
                                      sev.icon,
                                      size: 14,
                                      color: sev.color,
                                    ),
                                    label: Text('${sev.label} ($count)'),
                                    selected: _selectedSeverity == sev,
                                    onSelected: (_) => setState(() {
                                      _selectedSeverity =
                                          _selectedSeverity == sev ? null : sev;
                                    }),
                                  ),
                                );
                              }),
                              const VerticalDivider(width: 16),
                              FilterChip(
                                label: const Text('所有分类'),
                                selected: _selectedCategory == null,
                                onSelected: (_) => setState(() {
                                  _selectedCategory = null;
                                }),
                              ),
                              const SizedBox(width: 8),
                              ...IssueCategory.values.map((cat) {
                                final count = currentScopeIssues
                                    .where((i) => i.category == cat)
                                    .length;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text('${cat.label} ($count)'),
                                    selected: _selectedCategory == cat,
                                    onSelected: (_) => setState(() {
                                      _selectedCategory =
                                          _selectedCategory == cat ? null : cat;
                                    }),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 问题卡片列表
                        Expanded(
                          child: filteredIssues.isEmpty
                              ? _buildEmptyState(
                                  context,
                                  isScopeEmpty: currentScopeIssues.isEmpty,
                                )
                              : ListView.builder(
                                  itemCount: filteredIssues.length,
                                  itemBuilder: (context, index) {
                                    final issue = filteredIssues[index];
                                    final status =
                                        issueStatusMap[issue.id] ??
                                        IssueHandlingStatus.active;
                                    return _buildIssueTile(
                                      context,
                                      issue,
                                      status: status,
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthOverviewCard(
    BuildContext context, {
    required ConsistencyReport report,
    required int activeScore,
    required int activeCount,
    required int processedCount,
  }) {
    final theme = Theme.of(context);

    Color scoreColor;
    String scoreStatus;
    if (activeScore >= 90) {
      scoreColor = const Color(0xFF10B981);
      scoreStatus = '自洽优秀';
    } else if (activeScore >= 65) {
      scoreColor = const Color(0xFFF59E0B);
      scoreStatus = '存在隐患';
    } else {
      scoreColor = const Color(0xFFEF4444);
      scoreStatus = '矛盾较多';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scoreColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // 分数徽标
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: scoreColor, width: 2),
            ),
            child: Center(
              child: Text(
                '$activeScore',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '自洽健康指数：$scoreStatus',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '待办 $activeCount 项 · 已处理 $processedCount 项',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '覆盖时间生卒时序、人物社会关系闭环、维基双链断裂、沙盒资源完整性与设定完整度。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool isScopeEmpty}) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isScopeEmpty
                  ? Icons.verified_rounded
                  : Icons.filter_list_off_rounded,
              size: 54,
              color: isScopeEmpty
                  ? const Color(0xFF10B981)
                  : theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              isScopeEmpty
                  ? (_showResolvedOrIgnored ? '暂无已忽略或已解决事项' : '设定严密自洽，零待办矛盾！')
                  : '当前筛选条件下无匹配事项',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isScopeEmpty
                  ? '所有检查规则均已达标，未发现生卒年逆序、失效关联、坏链或严重遗漏。'
                  : '请尝试切换或重置上方严重度与分类筛选标签。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueTile(
    BuildContext context,
    ConsistencyIssue issue, {
    required IssueHandlingStatus status,
  }) {
    final theme = Theme.of(context);
    final isProcessed = status != IssueHandlingStatus.active;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isProcessed
              ? theme.colorScheme.outlineVariant
              : issue.severity.color.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color:
                    (isProcessed
                            ? theme.colorScheme.outline
                            : issue.severity.color)
                        .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isProcessed
                    ? Icons.check_circle_outline_rounded
                    : issue.severity.icon,
                color: isProcessed
                    ? theme.colorScheme.outline
                    : issue.severity.color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isProcessed
                                      ? theme.colorScheme.outline
                                      : issue.severity.color)
                                  .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isProcessed
                              ? (status == IssueHandlingStatus.ignored
                                    ? '已忽略'
                                    : '已解决')
                              : issue.severity.label,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: isProcessed
                                ? theme.colorScheme.outline
                                : issue.severity.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          issue.category.label,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          issue.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            decoration: isProcessed
                                ? TextDecoration.lineThrough
                                : null,
                            color: isProcessed
                                ? theme.colorScheme.outline
                                : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    issue.description,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: isProcessed
                          ? theme.colorScheme.outline
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (issue.evidence != null || issue.suggestion != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (issue.evidence != null)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '依据: ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    issue.evidence!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          if (issue.evidence != null &&
                              issue.suggestion != null)
                            const SizedBox(height: 3),
                          if (issue.suggestion != null)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '建议: ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isProcessed
                                        ? theme.colorScheme.outline
                                        : theme.colorScheme.primary,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    issue.suggestion!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isProcessed
                                          ? theme.colorScheme.outline
                                          : theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // 操作按钮组
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: () => _handleNavigate(issue),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                  label: const Text('定位'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                if (!isProcessed)
                  PopupMenuButton<String>(
                    tooltip: '更多操作',
                    icon: const Icon(Icons.more_horiz_rounded, size: 18),
                    onSelected: (val) {
                      if (val == 'ignore') {
                        ref
                            .read(
                              worldIssueStatusProvider(widget.worldId).notifier,
                            )
                            .ignore(issue.id);
                      } else if (val == 'resolve') {
                        ref
                            .read(
                              worldIssueStatusProvider(widget.worldId).notifier,
                            )
                            .resolve(issue.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'ignore',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_off_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('忽略此提示'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'resolve',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, size: 16),
                            SizedBox(width: 8),
                            Text('标记为已解决'),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  TextButton.icon(
                    onPressed: () {
                      ref
                          .read(
                            worldIssueStatusProvider(widget.worldId).notifier,
                          )
                          .reset(issue.id);
                    },
                    icon: const Icon(Icons.undo_rounded, size: 14),
                    label: const Text('恢复待办'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

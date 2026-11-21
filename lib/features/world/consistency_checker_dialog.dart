import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/consistency/consistency_checker_engine.dart';
import '../../providers/consistency_provider.dart';
import 'widgets/consistency_health_dashboard.dart';
import 'widgets/consistency_issue_tile.dart';
import 'widgets/consistency_rule_config_dialog.dart';

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
      case 'story':
        context.push('/world/${widget.worldId}/story');
        break;
    }
  }

  /// 打开规则启停与严重级别配置弹窗 (CONSIST-006)
  void _showRuleConfigDialog(BuildContext context) {
    ConsistencyRuleConfigDialog.show(context, worldId: widget.worldId);
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
                        ConsistencyHealthDashboard(
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
                                    return ConsistencyIssueTile(
                                      issue: issue,
                                      status: status,
                                      onNavigate: _handleNavigate,
                                      onIgnore: (id) {
                                        ref
                                            .read(
                                              worldIssueStatusProvider(
                                                widget.worldId,
                                              ).notifier,
                                            )
                                            .ignore(id);
                                      },
                                      onResolve: (id) {
                                        ref
                                            .read(
                                              worldIssueStatusProvider(
                                                widget.worldId,
                                              ).notifier,
                                            )
                                            .resolve(id);
                                      },
                                      onReset: (id) {
                                        ref
                                            .read(
                                              worldIssueStatusProvider(
                                                widget.worldId,
                                              ).notifier,
                                            )
                                            .reset(id);
                                      },
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
}

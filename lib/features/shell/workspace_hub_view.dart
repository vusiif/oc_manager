import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/components/empty_state.dart';
import '../../core/design/components/world_card.dart';
import '../../core/design/design_tokens.dart';
import '../../core/services/recent_items_service.dart';
import '../../core/services/sample_world_service.dart';
import '../../providers/world_provider.dart';
import '../world/world_dialog.dart';
import 'workspace_recent_section.dart';

/// Workspace Hub view displayed when no world is currently selected.
/// Adapts across desktop multi-column grids and narrow mobile viewports.
class WorkspaceHubView extends ConsumerWidget {
  final ValueChanged<int> onSelectWorld;
  final ValueChanged<RecentItem> onOpenRecentItem;

  const WorkspaceHubView({
    super.key,
    required this.onSelectWorld,
    required this.onOpenRecentItem,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worldsAsync = ref.watch(worldsProvider);

    return worldsAsync.when(
      data: (worlds) {
        if (worlds.isEmpty) {
          return EmptyStateView(
            icon: Icons.public,
            title: '开启你的 OC 创作世界',
            description: '世界观是管理人物与关系的顶层容器。创建空白世界观，或导入官方示例世界观立即体验！',
            primaryActionLabel: '创建新世界观',
            onPrimaryAction: () => _showCreateWorldDialog(context),
            secondaryActionLabel: '体验示例世界观',
            onSecondaryAction: () async {
              final id = await SampleWorldService.createAndRefresh(ref);
              onSelectWorld(id);
            },
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 560;
            final crossAxisCount = constraints.maxWidth >= 900
                ? 3
                : (constraints.maxWidth >= 560 ? 2 : 1);

            return SingleChildScrollView(
              padding: EdgeInsets.all(isNarrow ? AppSpacing.md : AppSpacing.xl),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildWelcomeBanner(context, worlds.length, isNarrow),
                      const SizedBox(height: AppSpacing.xl),
                      WorkspaceRecentSection(onOpenItem: onOpenRecentItem),
                      const Text(
                        '我的世界观',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                          mainAxisExtent: 126,
                        ),
                        itemCount: worlds.length,
                        itemBuilder: (context, index) {
                          final world = worlds[index];
                          return WorldCard(
                            world: world,
                            onTap: () => onSelectWorld(world.id),
                            onEdit: () => showDialog(
                              context: context,
                              builder: (_) => WorldDialog(world: world),
                            ),
                            onDelete: () => showDialog(
                              context: context,
                              builder: (_) => WorldDialog(world: world),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('加载失败: $error')),
    );
  }

  Widget _buildWelcomeBanner(
    BuildContext context,
    int worldCount,
    bool isNarrow,
  ) {
    final textBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '欢迎回到 OC Manager 2.0',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '当前共有 $worldCount 个世界观。请在侧栏或从下方卡片选择进入。',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13,
          ),
        ),
      ],
    );

    final createBtn = FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brand,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
      ),
      onPressed: () => _showCreateWorldDialog(context),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('新建世界观'),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brand.withValues(alpha: 0.85),
            AppColors.brandHover,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.radiusLg,
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isNarrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                textBlock,
                const SizedBox(height: AppSpacing.md),
                createBtn,
              ],
            )
          : Row(
              children: [
                Expanded(child: textBlock),
                const SizedBox(width: AppSpacing.md),
                createBtn,
              ],
            ),
    );
  }

  void _showCreateWorldDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const WorldDialog());
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/design_tokens.dart';
import '../../core/services/recent_items_service.dart';

/// Displays pinned favorites and recently accessed worlds/characters
/// on the Workspace Hub with one-click navigation.
class WorkspaceRecentSection extends ConsumerWidget {
  final ValueChanged<RecentItem> onOpenItem;

  const WorkspaceRecentSection({super.key, required this.onOpenItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(recentItemsProvider);
    if (items.isEmpty) return const SizedBox.shrink();

    final pinned = items.where((e) => e.isPinned).toList();
    final recent = items.where((e) => !e.isPinned).take(8).toList();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pinned.isNotEmpty) ...[
          _sectionHeader(
            context,
            icon: Icons.push_pin_rounded,
            title: '固定收藏',
            iconColor: AppColors.brand,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: pinned
                .map((item) => _buildChipCard(context, ref, item, isDark))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (recent.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionHeader(
                context,
                icon: Icons.history_rounded,
                title: '最近访问',
              ),
              TextButton(
                onPressed: () =>
                    ref.read(recentItemsProvider.notifier).clearUnpinned(),
                child: const Text('清空记录', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: recent
                .map((item) => _buildChipCard(context, ref, item, isDark))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ],
    );
  }

  Widget _sectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    Color? iconColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: iconColor ?? AppColors.brand),
        const SizedBox(width: AppSpacing.xs + 2),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildChipCard(
    BuildContext context,
    WidgetRef ref,
    RecentItem item,
    bool isDark,
  ) {
    final isWorld = item.type == RecentItemType.world;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Material(
      color: bg,
      borderRadius: AppRadius.radiusMd,
      child: InkWell(
        borderRadius: AppRadius.radiusMd,
        onTap: () => onOpenItem(item),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 240),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 4,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.radiusMd,
            border: Border.all(
              color: item.isPinned
                  ? AppColors.brand.withValues(alpha: 0.45)
                  : border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isWorld ? Icons.public_rounded : Icons.person_outline_rounded,
                size: 16,
                color: isWorld ? AppColors.brand : AppColors.info,
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.subtitle.isNotEmpty)
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => ref
                    .read(recentItemsProvider.notifier)
                    .togglePin(item.uniqueKey),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    item.isPinned
                        ? Icons.push_pin_rounded
                        : Icons.push_pin_outlined,
                    size: 14,
                    color: item.isPinned
                        ? AppColors.brand
                        : (isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// AppBar dropdown button for quick-switching recent worlds and characters.
class RecentQuickSwitchButton extends ConsumerWidget {
  final ValueChanged<RecentItem> onOpenItem;

  const RecentQuickSwitchButton({super.key, required this.onOpenItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(recentItemsProvider);
    if (items.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<RecentItem>(
      tooltip: '最近访问与快速切换',
      icon: const Icon(Icons.history_rounded),
      onSelected: onOpenItem,
      itemBuilder: (context) => items.take(10).map((item) {
        final isWorld = item.type == RecentItemType.world;
        return PopupMenuItem<RecentItem>(
          value: item,
          child: Row(
            children: [
              Icon(
                isWorld ? Icons.public_rounded : Icons.person_outline_rounded,
                size: 18,
                color: isWorld ? AppColors.brand : AppColors.info,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.isPinned) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.push_pin_rounded,
                  size: 13,
                  color: AppColors.brand,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

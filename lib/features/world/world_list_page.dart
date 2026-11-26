import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/components/confirmation_dialog.dart';
import '../../core/design/components/empty_state.dart';
import '../../core/design/components/world_card.dart';
import '../../core/design/design_tokens.dart';
import '../../data/database/app_database.dart';
import '../../providers/world_provider.dart';
import 'world_dialog.dart';

class WorldListPage extends ConsumerWidget {
  const WorldListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worldsAsync = ref.watch(worldsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('世界观'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '全局搜索',
            onPressed: () => context.push('/search'),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'tags',
                child: ListTile(
                  leading: Icon(Icons.label_outlined),
                  title: Text('标签管理'),
                ),
              ),
              const PopupMenuItem(
                value: 'drafts',
                child: ListTile(
                  leading: Icon(Icons.drafts_outlined),
                  title: Text('草稿箱'),
                ),
              ),
              const PopupMenuItem(
                value: 'trash',
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('回收站'),
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('设置'),
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'tags') {
                context.push('/tags');
              } else if (value == 'drafts') {
                context.push('/drafts');
              } else if (value == 'trash') {
                context.push('/trash');
              } else if (value == 'settings') {
                context.push('/settings');
              }
            },
          ),
        ],
      ),
      body: worldsAsync.when(
        data: (worlds) {
          if (worlds.isEmpty) {
            return EmptyStateView(
              icon: Icons.public_rounded,
              title: '还没有世界观',
              description: '创建你的第一个原创世界观，开始管理人物档案、百科设定与关系网络。',
              primaryActionLabel: '创建世界观',
              onPrimaryAction: () => _showCreateDialog(context),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width >= 1020 ? 3 : (width >= 640 ? 2 : 1);

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisExtent: 132,
                    ),
                    itemCount: worlds.length,
                    itemBuilder: (context, index) {
                      final world = worlds[index];
                      return RepaintBoundary(
                        child: WorldCard(
                          world: world,
                          onTap: () => context.push('/world/${world.id}'),
                          onEdit: () => _showEditDialog(context, world),
                          onDelete: () => _confirmDelete(context, ref, world),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('错误: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('新建世界观'),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const WorldDialog());
  }

  void _showEditDialog(BuildContext context, World world) {
    showDialog(
      context: context,
      builder: (context) => WorldDialog(world: world),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    World world,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: '删除世界观',
      content: '确定要删除"${world.name}"吗？\n该世界观下的所有人物与设定也会移入回收站。',
      confirmLabel: '删除',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(worldActionsProvider).delete(world.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除世界观失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/world_provider.dart';
import '../../providers/character_provider.dart';
import '../../providers/group_provider.dart';
import '../../data/database/app_database.dart';
import '../../core/design/components/empty_state.dart';
import '../../core/design/components/oc_card.dart';
import '../../core/design/design_tokens.dart';
import '../character/character_dialog.dart';

class WorldDetailPage extends ConsumerWidget {
  final int worldId;
  final int? selectedGroupId;
  final void Function(int characterId)? onCharacterSelected;

  const WorldDetailPage({
    super.key,
    required this.worldId,
    this.selectedGroupId,
    this.onCharacterSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worldAsync = ref.watch(worldByIdProvider(worldId));
    final charactersAsync = ref.watch(charactersByWorldProvider(worldId));
    final groupsAsync = ref.watch(groupsByWorldProvider(worldId));

    // 根据选中的分组过滤人物
    final filteredCharactersAsync = selectedGroupId != null
        ? ref.watch(charactersByGroupProvider(selectedGroupId!))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: worldAsync.when(
          data: (world) => Text(world.name),
          loading: () => const Text('加载中'),
          error: (_, __) => const Text('错误'),
        ),
      ),
      body: selectedGroupId != null
          ? _buildGroupCharacters(context, ref, filteredCharactersAsync)
          : _buildAllCharacters(context, ref, charactersAsync, groupsAsync),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('新建人物'),
      ),
    );
  }

  // 显示分组下的人物
  Widget _buildGroupCharacters(BuildContext context, WidgetRef ref,
      AsyncValue<List<Character>>? charactersAsync) {
    if (charactersAsync == null) return const SizedBox.shrink();

    return charactersAsync.when(
      data: (characters) {
        if (characters.isEmpty) {
          return EmptyStateView(
            icon: Icons.group_off_outlined,
            title: '该分组下暂无人物',
            description: '可以从左侧侧栏直接拖拽人物到此分组，或者直接在此创建新人物。',
            primaryActionLabel: '创建人物',
            onPrimaryAction: () => _showCreateDialog(context, ref),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: characters
              .map((c) => OcCard(
                    character: c,
                    onTap: () => onCharacterSelected?.call(c.id),
                    onFavoriteToggle: () {
                      ref.read(characterActionsProvider).toggleFavorite(c);
                    },
                    onPinToggle: () {
                      ref.read(characterActionsProvider).togglePin(c);
                    },
                  ))
              .toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('错误: $error')),
    );
  }

  // 显示所有人物（世界观视图）
  Widget _buildAllCharacters(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Character>> charactersAsync,
    AsyncValue<List<Group>> groupsAsync,
  ) {
    return charactersAsync.when(
      data: (characters) {
        if (characters.isEmpty) {
          return EmptyStateView(
            icon: Icons.person_add_alt_1_outlined,
            title: '还没有任何人物设定',
            description: '创建属于你的第一个角色（OC），记录基本信息、附加设定与专属关系。',
            primaryActionLabel: '创建第一个人物',
            onPrimaryAction: () => _showCreateDialog(context, ref),
          );
        }

        final pinned = characters.where((c) => c.isPinned).toList();
        final normal =
            characters.where((c) => !c.isPinned && c.status == 0).toList();
        final drafts = characters.where((c) => c.status == 1).toList();

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (pinned.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.push_pin_rounded,
                      size: 16, color: AppColors.brand),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '置顶 (${pinned.length})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ...pinned.map((c) => OcCard(
                    character: c,
                    onTap: () => onCharacterSelected?.call(c.id),
                    onFavoriteToggle: () {
                      ref.read(characterActionsProvider).toggleFavorite(c);
                    },
                    onPinToggle: () {
                      ref.read(characterActionsProvider).togglePin(c);
                    },
                  )),
              const SizedBox(height: AppSpacing.md),
            ],
            if (normal.isNotEmpty) ...[
              if (pinned.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    '角色列表',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ...normal.map((c) => OcCard(
                    character: c,
                    onTap: () => onCharacterSelected?.call(c.id),
                    onFavoriteToggle: () {
                      ref.read(characterActionsProvider).toggleFavorite(c);
                    },
                    onPinToggle: () {
                      ref.read(characterActionsProvider).togglePin(c);
                    },
                  )),
            ],
            if (drafts.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const Icon(Icons.edit_note, size: 16, color: Colors.grey),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '草稿 (${drafts.length})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ...drafts.map((c) => OcCard(
                    character: c,
                    onTap: () => onCharacterSelected?.call(c.id),
                    onFavoriteToggle: () {
                      ref.read(characterActionsProvider).toggleFavorite(c);
                    },
                    onPinToggle: () {
                      ref.read(characterActionsProvider).togglePin(c);
                    },
                  )),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('错误: $error')),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => CharacterDialog(worldId: worldId),
    );
  }
}

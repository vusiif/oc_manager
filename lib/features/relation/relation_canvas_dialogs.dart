import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../providers/relation_provider.dart';

/// Dialogs for managing relation graph canvases: create, duplicate, rename, delete, set default.
class RelationCanvasDialogs {
  RelationCanvasDialogs._();

  static Future<void> showNewCanvasDialog({
    required BuildContext context,
    required WidgetRef ref,
    required int worldId,
    required Future<void> Function(GraphCanvas) onCanvasSwitched,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController();
    final descController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建命名画布'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '画布名称',
                hintText: '如：主角团羁绊、主要势力派系、家族谱系...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: '画布描述 (可选)',
                hintText: '简要说明该画布的用途与视角',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );

    final name = controller.text.trim();
    final desc = descController.text.trim().isEmpty
        ? null
        : descController.text.trim();
    controller.dispose();
    descController.dispose();

    if (result == true && name.isNotEmpty && context.mounted) {
      final newCanvas = await ref
          .read(canvasActionsProvider)
          .create(worldId, name, description: desc);
      if (context.mounted) {
        await onCanvasSwitched(newCanvas);
        messenger.showSnackBar(SnackBar(content: Text('已创建并切换至画布【$name】')));
      }
    }
  }

  static Future<void> showDuplicateCanvasDialog({
    required BuildContext context,
    required WidgetRef ref,
    required GraphCanvas currentCanvas,
    required Matrix4 transformMatrix,
    required Future<void> Function(GraphCanvas) onCanvasSwitched,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController(
      text: '${currentCanvas.name} (副本)',
    );
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('复制当前画布'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '新画布名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('复制'),
          ),
        ],
      ),
    );

    final name = controller.text.trim();
    controller.dispose();

    if (result == true && name.isNotEmpty && context.mounted) {
      await ref
          .read(canvasActionsProvider)
          .saveViewport(
            currentCanvas.id,
            transformMatrix.getTranslation().x,
            transformMatrix.getTranslation().y,
            transformMatrix.getMaxScaleOnAxis(),
          );
      final newCanvas = await ref
          .read(canvasActionsProvider)
          .duplicate(currentCanvas.id, name);
      if (context.mounted) {
        await onCanvasSwitched(newCanvas);
        messenger.showSnackBar(
          SnackBar(content: Text('已成功复制画布【$name】，节点位置与视口已完整继承')),
        );
      }
    }
  }

  static Future<void> showRenameCanvasDialog({
    required BuildContext context,
    required WidgetRef ref,
    required GraphCanvas currentCanvas,
    required VoidCallback onRenamed,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController(text: currentCanvas.name);
    final descController = TextEditingController(
      text: currentCanvas.description ?? '',
    );
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名画布'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: '画布名称'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: '描述 (可选)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );

    final newName = controller.text.trim();
    final newDesc = descController.text.trim().isEmpty
        ? null
        : descController.text.trim();
    controller.dispose();
    descController.dispose();

    if (result == true && newName.isNotEmpty && context.mounted) {
      await ref
          .read(canvasActionsProvider)
          .rename(currentCanvas.id, newName, newDesc: newDesc);
      if (context.mounted) {
        onRenamed();
        messenger.showSnackBar(SnackBar(content: Text('画布已重命名为【$newName】')));
      }
    }
  }

  static Future<void> setDefaultCanvas({
    required BuildContext context,
    required WidgetRef ref,
    required int worldId,
    required GraphCanvas canvas,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(canvasActionsProvider).setDefault(worldId, canvas.id);
    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text('已将【${canvas.name}】设为默认画布')),
      );
    }
  }

  static Future<void> showDeleteCanvasDialog({
    required BuildContext context,
    required WidgetRef ref,
    required GraphCanvas canvas,
    required List<GraphCanvas> allCanvases,
    required Future<void> Function(GraphCanvas) onCanvasSwitched,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    if (allCanvases.length <= 1) {
      messenger.showSnackBar(const SnackBar(content: Text('不能删除唯一的画布')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('删除画布【${canvas.name}】？'),
        content: const Text(
          '此操作将移除该画布下的节点位置与视口排版，但绝不会删除世界观中的任何人物档案和角色关系数据。\n\n确认删除吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final remaining = allCanvases.where((c) => c.id != canvas.id).toList();
      final nextCanvas = remaining.firstWhere(
        (c) => c.isDefault,
        orElse: () => remaining.first,
      );

      await ref.read(canvasActionsProvider).delete(canvas.id);

      if (context.mounted) {
        await onCanvasSwitched(nextCanvas);
        messenger.showSnackBar(
          SnackBar(content: Text('画布【${canvas.name}】已安全删除，人物与关系数据已保留')),
        );
      }
    }
  }
}

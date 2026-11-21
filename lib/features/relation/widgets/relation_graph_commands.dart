import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../providers/relation_provider.dart';
import '../graph_history_manager.dart';
import '../relation_advanced_analysis.dart';

/// Runner for node and layout command operations with undo/redo history tracking.
class RelationGraphCommands {
  /// Places a character on the canvas at screen coordinates and records AddNodeCommand.
  static void dropCharacter({
    required WidgetRef ref,
    required int worldId,
    required int? canvasId,
    required int characterId,
    required String characterName,
    required Offset screenDropPos,
    required Matrix4 transformMatrix,
    required GraphHistoryManager historyManager,
    required void Function(int id, Offset pos) onAddMemory,
    required void Function(int id) onRemoveMemory,
  }) {
    final inverse = Matrix4.inverted(transformMatrix);
    final canvasPos = MatrixUtils.transformPoint(inverse, screenDropPos);
    onAddMemory(characterId, canvasPos);

    ref
        .read(graphLayoutActionsProvider)
        .savePosition(
          worldId,
          characterId,
          canvasPos.dx,
          canvasPos.dy,
          canvasId: canvasId,
        );

    historyManager.record(
      AddNodeCommand(
        characterId: characterId,
        characterName: characterName.isEmpty
            ? 'ID:$characterId'
            : characterName,
        pos: canvasPos,
        onAddMemory: onAddMemory,
        onRemoveMemory: onRemoveMemory,
        onPersistAdd: (id, pos) async {
          await ref
              .read(graphLayoutActionsProvider)
              .savePosition(worldId, id, pos.dx, pos.dy, canvasId: canvasId);
        },
        onPersistRemove: (id) async {
          await ref
              .read(graphLayoutActionsProvider)
              .removePosition(worldId, id, canvasId: canvasId);
        },
      ),
    );
  }

  /// Removes a character node from the canvas and records RemoveNodeCommand.
  static void removeCharacter({
    required WidgetRef ref,
    required int worldId,
    required int? canvasId,
    required int characterId,
    required String characterName,
    required Offset currentPos,
    required GraphHistoryManager historyManager,
    required void Function(int id, Offset pos) onAddMemory,
    required void Function(int id) onRemoveMemory,
  }) {
    onRemoveMemory(characterId);
    ref
        .read(graphLayoutActionsProvider)
        .removePosition(worldId, characterId, canvasId: canvasId);

    historyManager.record(
      RemoveNodeCommand(
        characterId: characterId,
        characterName: characterName.isEmpty
            ? 'ID:$characterId'
            : characterName,
        pos: currentPos,
        onAddMemory: onAddMemory,
        onRemoveMemory: onRemoveMemory,
        onPersistAdd: (id, pos) async {
          await ref
              .read(graphLayoutActionsProvider)
              .savePosition(worldId, id, pos.dx, pos.dy, canvasId: canvasId);
        },
        onPersistRemove: (id) async {
          await ref
              .read(graphLayoutActionsProvider)
              .removePosition(worldId, id, canvasId: canvasId);
        },
      ),
    );
  }

  /// Records MoveNodeCommand when a node is dragged to a new position.
  static void recordNodeMove({
    required WidgetRef ref,
    required int worldId,
    required int? canvasId,
    required int characterId,
    required String characterName,
    required Offset oldPos,
    required Offset newPos,
    required GraphHistoryManager historyManager,
    required void Function(int id, Offset pos) onUpdateMemory,
  }) {
    ref
        .read(graphLayoutActionsProvider)
        .savePosition(
          worldId,
          characterId,
          newPos.dx,
          newPos.dy,
          canvasId: canvasId,
        );

    if ((oldPos.dx - newPos.dx).abs() > 0.5 ||
        (oldPos.dy - newPos.dy).abs() > 0.5) {
      historyManager.record(
        MoveNodeCommand(
          characterId: characterId,
          characterName: characterName,
          oldPos: oldPos,
          newPos: newPos,
          onUpdateMemory: onUpdateMemory,
          onPersist: (id, pos) async {
            await ref
                .read(graphLayoutActionsProvider)
                .savePosition(worldId, id, pos.dx, pos.dy, canvasId: canvasId);
          },
        ),
      );
    }
  }

  /// Executes automatic layout computation, records BatchMoveCommand, and shows SnackBar.
  static void applyAutoLayout({
    required BuildContext context,
    required WidgetRef ref,
    required int worldId,
    required int? canvasId,
    required AutoLayoutMode mode,
    required List<Character> characters,
    required List<Relation> relations,
    required Map<int, Offset> currentPositions,
    required GraphHistoryManager historyManager,
    required void Function(Map<int, Offset> newPositions) onPositionsUpdated,
    required VoidCallback onFitCanvas,
  }) {
    if (characters.isEmpty) return;

    final oldPositions = Map<int, Offset>.of(currentPositions);
    final newLayout = GraphAutoLayoutEngine.computeLayout(
      mode: mode,
      characters: characters,
      relations: relations,
    );

    final mergedPositions = Map<int, Offset>.of(currentPositions)
      ..addAll(newLayout);
    onPositionsUpdated(mergedPositions);

    ref
        .read(graphLayoutActionsProvider)
        .batchSavePositions(worldId, newLayout, canvasId: canvasId);

    historyManager.record(
      BatchMoveCommand(
        descriptionText: '应用【${mode.label}】',
        oldPositions: oldPositions,
        newPositions: Map<int, Offset>.of(mergedPositions),
        onUpdateMemory: onPositionsUpdated,
        onPersist: (posMap) async {
          await ref
              .read(graphLayoutActionsProvider)
              .batchSavePositions(worldId, posMap, canvasId: canvasId);
        },
      ),
    );

    onFitCanvas();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已应用【${mode.label}】'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: '撤销排版',
          textColor: Colors.amberAccent,
          onPressed: () {
            if (historyManager.canUndo) {
              historyManager.undo();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('已撤销自动排版')));
            }
          },
        ),
      ),
    );
  }

  /// Records UpdateRelationCommand with undo/redo support.
  static void recordUpdateRelation({
    required WidgetRef ref,
    required int worldId,
    required Relation oldRel,
    required Relation newRel,
    required String desc,
    required GraphHistoryManager historyManager,
  }) {
    historyManager.record(
      UpdateRelationCommand(
        oldRelation: oldRel,
        newRelation: newRel,
        descriptionText: desc,
        onUpdate: (rel) async {
          await ref.read(relationActionsProvider).update(rel);
          ref.invalidate(relationsByWorldProvider(worldId));
        },
      ),
    );
  }

  /// Records DeleteRelationCommand with undo/redo support.
  static void recordDeleteRelation({
    required WidgetRef ref,
    required int worldId,
    required Relation rel,
    required String desc,
    required GraphHistoryManager historyManager,
  }) {
    historyManager.record(
      DeleteRelationCommand(
        deletedRelation: rel,
        descriptionText: desc,
        onDelete: (id) async {
          await ref.read(relationActionsProvider).delete(id);
          ref.invalidate(relationsByWorldProvider(worldId));
        },
        onRestore: (r) async {
          await ref.read(relationActionsProvider).restore(r);
          ref.invalidate(relationsByWorldProvider(worldId));
        },
      ),
    );
  }
}

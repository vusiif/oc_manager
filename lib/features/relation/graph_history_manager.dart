import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:oc_manager/data/database/app_database.dart';

/// Base command interface for relation graph Undo/Redo stack.
abstract class GraphCommand {
  /// User-friendly description of the command (e.g. "Move node [Alice]", "Add relation [Friend]").
  String get description;

  /// Reverts the command effect both in UI memory and in SQLite persistence.
  Future<void> undo();

  /// Re-applies the command effect both in UI memory and in SQLite persistence.
  Future<void> redo();
}

/// Command for moving a single node on the active canvas.
class MoveNodeCommand implements GraphCommand {
  final int characterId;
  final String characterName;
  final Offset oldPos;
  final Offset newPos;
  final void Function(int id, Offset pos) onUpdateMemory;
  final Future<void> Function(int id, Offset pos) onPersist;

  MoveNodeCommand({
    required this.characterId,
    required this.characterName,
    required this.oldPos,
    required this.newPos,
    required this.onUpdateMemory,
    required this.onPersist,
  });

  @override
  String get description => '移动角色【$characterName】';

  @override
  Future<void> undo() async {
    onUpdateMemory(characterId, oldPos);
    await onPersist(characterId, oldPos);
  }

  @override
  Future<void> redo() async {
    onUpdateMemory(characterId, newPos);
    await onPersist(characterId, newPos);
  }
}

/// Command for batch moving multiple nodes (e.g., auto layout or manual layout reset).
class BatchMoveCommand implements GraphCommand {
  final String descriptionText;
  final Map<int, Offset> oldPositions;
  final Map<int, Offset> newPositions;
  final void Function(Map<int, Offset> positions) onUpdateMemory;
  final Future<void> Function(Map<int, Offset> positions) onPersist;

  BatchMoveCommand({
    required this.descriptionText,
    required this.oldPositions,
    required this.newPositions,
    required this.onUpdateMemory,
    required this.onPersist,
  });

  @override
  String get description => descriptionText;

  @override
  Future<void> undo() async {
    onUpdateMemory(oldPositions);
    await onPersist(oldPositions);
  }

  @override
  Future<void> redo() async {
    onUpdateMemory(newPositions);
    await onPersist(newPositions);
  }
}

/// Command for adding a character node onto the canvas.
class AddNodeCommand implements GraphCommand {
  final int characterId;
  final String characterName;
  final Offset pos;
  final void Function(int id, Offset pos) onAddMemory;
  final void Function(int id) onRemoveMemory;
  final Future<void> Function(int id, Offset pos) onPersistAdd;
  final Future<void> Function(int id) onPersistRemove;

  AddNodeCommand({
    required this.characterId,
    required this.characterName,
    required this.pos,
    required this.onAddMemory,
    required this.onRemoveMemory,
    required this.onPersistAdd,
    required this.onPersistRemove,
  });

  @override
  String get description => '将角色【$characterName】放置到画布';

  @override
  Future<void> undo() async {
    onRemoveMemory(characterId);
    await onPersistRemove(characterId);
  }

  @override
  Future<void> redo() async {
    onAddMemory(characterId, pos);
    await onPersistAdd(characterId, pos);
  }
}

/// Command for removing a character node from the canvas.
class RemoveNodeCommand implements GraphCommand {
  final int characterId;
  final String characterName;
  final Offset pos;
  final void Function(int id, Offset pos) onAddMemory;
  final void Function(int id) onRemoveMemory;
  final Future<void> Function(int id, Offset pos) onPersistAdd;
  final Future<void> Function(int id) onPersistRemove;

  RemoveNodeCommand({
    required this.characterId,
    required this.characterName,
    required this.pos,
    required this.onAddMemory,
    required this.onRemoveMemory,
    required this.onPersistAdd,
    required this.onPersistRemove,
  });

  @override
  String get description => '从画布移出角色【$characterName】';

  @override
  Future<void> undo() async {
    onAddMemory(characterId, pos);
    await onPersistAdd(characterId, pos);
  }

  @override
  Future<void> redo() async {
    onRemoveMemory(characterId);
    await onPersistRemove(characterId);
  }
}

/// Command for creating a new relation between two characters.
class CreateRelationCommand implements GraphCommand {
  final Relation relation;
  final String descriptionText;
  final Future<void> Function(int id) onDelete;
  final Future<void> Function(Relation rel) onRestore;

  CreateRelationCommand({
    required this.relation,
    required this.descriptionText,
    required this.onDelete,
    required this.onRestore,
  });

  @override
  String get description => '添加关系【$descriptionText】';

  @override
  Future<void> undo() async {
    await onDelete(relation.id);
  }

  @override
  Future<void> redo() async {
    await onRestore(relation);
  }
}

/// Command for batch creating relations (e.g. family relations or group ties).
class BatchCreateRelationsCommand implements GraphCommand {
  final List<Relation> relations;
  final String descriptionText;
  final Future<void> Function(int id) onDelete;
  final Future<void> Function(Relation rel) onRestore;

  BatchCreateRelationsCommand({
    required this.relations,
    required this.descriptionText,
    required this.onDelete,
    required this.onRestore,
  });

  @override
  String get description => descriptionText;

  @override
  Future<void> undo() async {
    for (final rel in relations) {
      await onDelete(rel.id);
    }
  }

  @override
  Future<void> redo() async {
    for (final rel in relations) {
      await onRestore(rel);
    }
  }
}

/// Command for editing an existing relation.
class UpdateRelationCommand implements GraphCommand {
  final Relation oldRelation;
  final Relation newRelation;
  final String descriptionText;
  final Future<void> Function(Relation rel) onUpdate;

  UpdateRelationCommand({
    required this.oldRelation,
    required this.newRelation,
    required this.descriptionText,
    required this.onUpdate,
  });

  @override
  String get description => '修改关系【$descriptionText】';

  @override
  Future<void> undo() async {
    await onUpdate(oldRelation);
  }

  @override
  Future<void> redo() async {
    await onUpdate(newRelation);
  }
}

/// Command for deleting a relation.
class DeleteRelationCommand implements GraphCommand {
  final Relation deletedRelation;
  final String descriptionText;
  final Future<void> Function(int id) onDelete;
  final Future<void> Function(Relation rel) onRestore;

  DeleteRelationCommand({
    required this.deletedRelation,
    required this.descriptionText,
    required this.onDelete,
    required this.onRestore,
  });

  @override
  String get description => '删除关系【$descriptionText】';

  @override
  Future<void> undo() async {
    await onRestore(deletedRelation);
  }

  @override
  Future<void> redo() async {
    await onDelete(deletedRelation.id);
  }
}

/// Manages the Undo and Redo stacks for the Relation Graph.
/// Ensures canvas and world switching strictly purges previous history.
class GraphHistoryManager extends ChangeNotifier {
  final int maxHistory;
  final List<GraphCommand> _undoStack = [];
  final List<GraphCommand> _redoStack = [];
  bool _isPerforming = false;

  GraphHistoryManager({this.maxHistory = 30});

  bool get canUndo => _undoStack.isNotEmpty && !_isPerforming;
  bool get canRedo => _redoStack.isNotEmpty && !_isPerforming;
  bool get isPerforming => _isPerforming;

  int get undoCount => _undoStack.length;
  int get redoCount => _redoStack.length;

  String? get undoDescription =>
      _undoStack.isNotEmpty ? _undoStack.last.description : null;
  String? get redoDescription =>
      _redoStack.isNotEmpty ? _redoStack.last.description : null;

  /// Records an already-executed command into the undo history.
  void record(GraphCommand command) {
    _undoStack.add(command);
    if (_undoStack.length > maxHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
    notifyListeners();
  }

  /// Undoes the last recorded command.
  Future<bool> undo() async {
    if (!canUndo) return false;
    _isPerforming = true;
    notifyListeners();
    try {
      final command = _undoStack.removeLast();
      await command.undo();
      _redoStack.add(command);
      return true;
    } finally {
      _isPerforming = false;
      notifyListeners();
    }
  }

  /// Redoes the last undone command.
  Future<bool> redo() async {
    if (!canRedo) return false;
    _isPerforming = true;
    notifyListeners();
    try {
      final command = _redoStack.removeLast();
      await command.redo();
      _undoStack.add(command);
      return true;
    } finally {
      _isPerforming = false;
      notifyListeners();
    }
  }

  /// Clears the history stack. MUST be called whenever switching world or canvas.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }
}

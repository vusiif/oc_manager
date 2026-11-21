import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../graph_history_manager.dart';

/// Keyboard shortcuts wrapper for the relation graph canvas.
/// Supports Ctrl+Z/Cmd+Z (Undo), Ctrl+Y/Cmd+Shift+Z/Ctrl+Shift+Z (Redo),
/// while safely ignoring triggers during active text editing.
class RelationGraphShortcuts extends StatelessWidget {
  final GraphHistoryManager historyManager;
  final Widget child;

  const RelationGraphShortcuts({
    super.key,
    required this.historyManager,
    required this.child,
  });

  bool _isEditingText() {
    final focusedWidget = FocusManager.instance.primaryFocus?.context?.widget;
    return focusedWidget is EditableText;
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () {
          if (!_isEditingText() && historyManager.canUndo) {
            historyManager.undo();
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): () {
          if (!_isEditingText() && historyManager.canUndo) {
            historyManager.undo();
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): () {
          if (!_isEditingText() && historyManager.canRedo) {
            historyManager.redo();
          }
        },
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          control: true,
          shift: true,
        ): () {
          if (!_isEditingText() && historyManager.canRedo) {
            historyManager.redo();
          }
        },
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          meta: true,
          shift: true,
        ): () {
          if (!_isEditingText() && historyManager.canRedo) {
            historyManager.redo();
          }
        },
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}

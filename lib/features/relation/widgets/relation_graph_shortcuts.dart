import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../graph_history_manager.dart';

/// Keyboard shortcuts wrapper for the relation graph canvas.
/// Supports Ctrl+Z/Cmd+Z (Undo), Ctrl+Y/Cmd+Shift+Z/Ctrl+Shift+Z (Redo),
/// while safely ignoring triggers during active text editing.
class RelationGraphShortcuts extends StatelessWidget {
  final GraphHistoryManager historyManager;
  final VoidCallback? onDeleteSelected;
  final VoidCallback? onEscape;
  final VoidCallback? onSelectAll;
  final Widget child;

  const RelationGraphShortcuts({
    super.key,
    required this.historyManager,
    this.onDeleteSelected,
    this.onEscape,
    this.onSelectAll,
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
        const SingleActivator(LogicalKeyboardKey.delete): () {
          if (!_isEditingText()) {
            onDeleteSelected?.call();
          }
        },
        const SingleActivator(LogicalKeyboardKey.backspace): () {
          if (!_isEditingText()) {
            onDeleteSelected?.call();
          }
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (!_isEditingText()) {
            onEscape?.call();
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyA, control: true): () {
          if (!_isEditingText()) {
            onSelectAll?.call();
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyA, meta: true): () {
          if (!_isEditingText()) {
            onSelectAll?.call();
          }
        },
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}

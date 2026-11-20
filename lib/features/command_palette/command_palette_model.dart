import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Categories of items available in the Command Palette
enum CommandPaletteCategory {
  command('命令', Icons.terminal_rounded),
  world('世界观', Icons.public_rounded),
  character('角色', Icons.person_rounded),
  lore('词条', Icons.auto_stories_rounded);

  final String label;
  final IconData icon;

  const CommandPaletteCategory(this.label, this.icon);
}

typedef CommandAction =
    FutureOr<void> Function(BuildContext context, WidgetRef ref);

/// Represents an executable command or navigable entity item in the Command Palette
class CommandPaletteItem {
  final String id;
  final String title;
  final String? subtitle;
  final CommandPaletteCategory category;
  final IconData icon;
  final Color? iconColor;
  final String? shortcutLabel;
  final CommandAction onExecute;
  final List<String> keywords;

  const CommandPaletteItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.category,
    required this.icon,
    this.iconColor,
    this.shortcutLabel,
    required this.onExecute,
    this.keywords = const [],
  });

  /// Computes a fuzzy match score against a query string.
  /// Returns 0 if there is no match; returns > 0 when matched (higher is a better match).
  int matchScore(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return 1;

    final t = title.toLowerCase();
    final sub = (subtitle ?? '').toLowerCase();

    // 1. Exact title match
    if (t == q) return 100;

    // 2. Title starts with query
    if (t.startsWith(q)) return 85;

    // 3. Title contains query
    if (t.contains(q)) return 65;

    // 4. Keyword exact match
    for (final kw in keywords) {
      final k = kw.toLowerCase();
      if (k == q) return 75;
      if (k.startsWith(q)) return 60;
      if (k.contains(q)) return 45;
    }

    // 5. Subtitle contains query
    if (sub.contains(q)) return 30;

    return 0;
  }
}

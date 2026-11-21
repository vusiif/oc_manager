import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';

/// Horizontal category filter bar for the command palette.
class CommandCategoryFilterBar extends StatelessWidget {
  final String selectedCategory;
  final bool isDark;
  final ValueChanged<String> onSelectCategory;

  const CommandCategoryFilterBar({
    super.key,
    required this.selectedCategory,
    required this.isDark,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    final categories = [
      ('all', '全部', Icons.dashboard_outlined),
      ('command', '命令', Icons.terminal_rounded),
      ('world', '世界观', Icons.public_rounded),
      ('character', '角色', Icons.person_rounded),
      ('lore', '词条', Icons.auto_stories_rounded),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: categories.map((cat) {
          final isSelected = selectedCategory == cat.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              key: Key('chip_cat_${cat.$1}'),
              borderRadius: BorderRadius.circular(20),
              onTap: () => onSelectCategory(cat.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.brand
                      : isDark
                      ? const Color(0xFF334155).withAlpha(100)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.brand
                        : isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFFE2E8F0),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat.$3,
                      size: 14,
                      color: isSelected
                          ? Colors.white
                          : isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      cat.$2,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

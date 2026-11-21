import 'package:flutter/material.dart';

/// Bottom footer status and keyboard shortcut hints for the command palette.
class CommandPaletteFooter extends StatelessWidget {
  final int itemCount;
  final bool isDark;

  const CommandPaletteFooter({
    super.key,
    required this.itemCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '共 $itemCount 项可用操作',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
          Row(
            children: [
              _buildKeyBadge('↑↓', '导航', isDark),
              const SizedBox(width: 10),
              _buildKeyBadge('↵', '执行', isDark),
              const SizedBox(width: 10),
              _buildKeyBadge('ESC', '退出', isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyBadge(String keyText, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
              width: 0.8,
            ),
          ),
          child: Text(
            keyText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}

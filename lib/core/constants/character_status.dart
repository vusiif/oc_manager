import 'package:flutter/material.dart';

/// 角色创作生命周期状态
class CharacterCreationStatus {
  final int code;
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  final String description;

  const CharacterCreationStatus({
    required this.code,
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.description,
  });

  static const CharacterCreationStatus active = CharacterCreationStatus(
    code: 0,
    key: 'active',
    label: '细化中',
    icon: Icons.edit_note_rounded,
    color: Color(0xFF3B82F6),
    description: '基本设定已具备，正在丰富故事背景与关系网络',
  );

  static const CharacterCreationStatus draft = CharacterCreationStatus(
    code: 1,
    key: 'draft',
    label: '构思草稿',
    icon: Icons.lightbulb_outline_rounded,
    color: Color(0xFFF59E0B),
    description: '初步灵感闪现，仅有简单构思或粗略雏形',
  );

  static const CharacterCreationStatus finalized = CharacterCreationStatus(
    code: 2,
    key: 'finalized',
    label: '已定稿',
    icon: Icons.verified_outlined,
    color: Color(0xFF10B981),
    description: '人设、外貌、数值与关系网络均已完整定型',
  );

  static const CharacterCreationStatus archived = CharacterCreationStatus(
    code: 3,
    key: 'archived',
    label: '历史归档',
    icon: Icons.inventory_2_outlined,
    color: Color(0xFF6B7280),
    description: '已封存的早期设定或已退场人物',
  );

  /// 看板排列的建议展示顺序：草稿 -> 细化中 -> 已定稿 -> 归档
  static const List<CharacterCreationStatus> all = [
    draft,
    active,
    finalized,
    archived,
  ];

  static CharacterCreationStatus find(int code) {
    switch (code) {
      case 1:
        return draft;
      case 2:
        return finalized;
      case 3:
        return archived;
      case 0:
      default:
        return active;
    }
  }
}

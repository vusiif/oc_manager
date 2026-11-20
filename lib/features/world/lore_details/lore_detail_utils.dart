import 'package:flutter/material.dart';

/// 百科实体详情页工具函数
class LoreDetailUtils {
  /// 判定是否属于领袖、持有者、宗师或始祖角色 (LORE-002 ~ LORE-006)
  static bool isLeaderOrOwnerRole(String role) {
    final lower = role.toLowerCase();
    return role.contains('领袖') ||
        role.contains('会长') ||
        role.contains('团长') ||
        role.contains('首领') ||
        role.contains('宗主') ||
        role.contains('掌门') ||
        role.contains('元首') ||
        role.contains('司令') ||
        role.contains('持有') ||
        role.contains('佩戴') ||
        role.contains('契约') ||
        role.contains('主人') ||
        role.contains('锻造') ||
        role.contains('制造') ||
        role.contains('始祖') ||
        role.contains('先祖') ||
        role.contains('纯血') ||
        role.contains('皇室') ||
        role.contains('宗师') ||
        role.contains('大成') ||
        role.contains('巅峰') ||
        lower.contains('ancestor') ||
        lower.contains('pureblood') ||
        lower.contains('master') ||
        lower.contains('leader') ||
        lower.contains('owner') ||
        lower.contains('wielder') ||
        lower.contains('creator') ||
        lower.contains('chief') ||
        lower.contains('boss');
  }

  /// 获取关系类型对应主题色
  static Color getRelationColor(String relationType) {
    if (relationType.contains('同盟') || relationType.contains('盟友')) {
      return const Color(0xFF10B981);
    }
    if (relationType.contains('敌对') ||
        relationType.contains('交战') ||
        relationType.contains('宿敌') ||
        relationType.contains('克制')) {
      return const Color(0xFFEF4444);
    }
    if (relationType.contains('从属') ||
        relationType.contains('附属') ||
        relationType.contains('宗主') ||
        relationType.contains('归属') ||
        relationType.contains('圣物')) {
      return const Color(0xFF3B82F6);
    }
    if (relationType.contains('贸易') ||
        relationType.contains('商业') ||
        relationType.contains('合作')) {
      return const Color(0xFFF59E0B);
    }
    if (relationType.contains('发源') ||
        relationType.contains('栖息') ||
        relationType.contains('故土') ||
        relationType.contains('起源')) {
      return const Color(0xFF10B981);
    }
    if (relationType.contains('载体') ||
        relationType.contains('附魔') ||
        relationType.contains('衍生') ||
        relationType.contains('进阶') ||
        relationType.contains('相生')) {
      return const Color(0xFF8B5CF6);
    }
    if (relationType.contains('存放') ||
        relationType.contains('封印') ||
        relationType.contains('埋藏')) {
      return const Color(0xFF059669);
    }
    if (relationType.contains('共鸣') ||
        relationType.contains('套装') ||
        relationType.contains('羁绊')) {
      return const Color(0xFF8B5CF6);
    }
    return const Color(0xFF6B7280);
  }

  /// 获取关系类型对应图标
  static IconData getRelationIcon(String relationType) {
    if (relationType.contains('同盟') || relationType.contains('盟友')) {
      return Icons.handshake_outlined;
    }
    if (relationType.contains('敌对') ||
        relationType.contains('交战') ||
        relationType.contains('宿敌') ||
        relationType.contains('克制')) {
      return Icons.sports_kabaddi_outlined;
    }
    if (relationType.contains('从属') ||
        relationType.contains('附属') ||
        relationType.contains('宗主') ||
        relationType.contains('归属') ||
        relationType.contains('圣物')) {
      return Icons.account_tree_outlined;
    }
    if (relationType.contains('贸易') ||
        relationType.contains('商业') ||
        relationType.contains('合作')) {
      return Icons.store_mall_directory_outlined;
    }
    if (relationType.contains('发源') ||
        relationType.contains('栖息') ||
        relationType.contains('故土') ||
        relationType.contains('起源')) {
      return Icons.park_outlined;
    }
    if (relationType.contains('载体') ||
        relationType.contains('附魔') ||
        relationType.contains('衍生') ||
        relationType.contains('进阶') ||
        relationType.contains('相生')) {
      return Icons.auto_fix_high_rounded;
    }
    if (relationType.contains('存放') ||
        relationType.contains('封印') ||
        relationType.contains('埋藏')) {
      return Icons.location_on_outlined;
    }
    if (relationType.contains('共鸣') ||
        relationType.contains('套装') ||
        relationType.contains('羁绊')) {
      return Icons.auto_awesome;
    }
    return Icons.balance_outlined;
  }
}

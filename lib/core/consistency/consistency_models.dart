import 'package:flutter/material.dart';
import '../../data/database/app_database.dart';

/// 严重级别枚举
enum IssueSeverity {
  error('严重矛盾', Icons.error_rounded, Color(0xFFEF4444)),
  warning('逻辑警告', Icons.warning_amber_rounded, Color(0xFFF59E0B)),
  info('设定建议', Icons.info_outline_rounded, Color(0xFF3B82F6));

  final String label;
  final IconData icon;
  final Color color;

  const IssueSeverity(this.label, this.icon, this.color);
}

/// 规则与问题分类枚举
enum IssueCategory {
  timeline('编年时间轴', Icons.history_edu_rounded),
  relation('人物关系网', Icons.alt_route_rounded),
  link('双向链接', Icons.link_off_rounded),
  media('多媒体资源', Icons.broken_image_rounded),
  completeness('设定完善度', Icons.fact_check_outlined);

  final String label;
  final IconData icon;

  const IssueCategory(this.label, this.icon);
}

/// 单项一致性问题报告实体 (CONSIST-001)
class ConsistencyIssue {
  /// 问题实例唯一 ID
  final String id;

  /// 所属规则稳定 ID (如 'RULE_TIMELINE_LIFESPAN')
  final String ruleId;

  /// 分类
  final IssueCategory category;

  /// 严重度
  final IssueSeverity severity;

  /// 问题标题
  final String title;

  /// 问题详细描述
  final String description;

  /// 修复建议 (CONSIST-001)
  final String? suggestion;

  /// 依据数据/证据切片 (CONSIST-001 & AGENTS.md 7.1)
  final String? evidence;

  /// 目标实体类型: 'character', 'lore', 'timeline', 'relation'
  final String targetType;

  /// 目标实体 ID
  final int targetId;

  /// 目标实体名称
  final String targetName;

  const ConsistencyIssue({
    required this.id,
    required this.ruleId,
    required this.category,
    required this.severity,
    required this.title,
    required this.description,
    this.suggestion,
    this.evidence,
    required this.targetType,
    required this.targetId,
    required this.targetName,
  });
}

/// 规则评估上下文 (提供只读实体与目标作用域)
class ConsistencyContext {
  final int worldId;

  /// 若为非空，表示仅针对指定角色进行的定向检查
  final int? targetCharacterId;

  final List<Character> characters;
  final List<Relation> relations;
  final List<TimelineEvent> events;
  final List<LoreEntity> lores;
  final List<CharacterGallery> galleries;

  /// 其他世界观中存在的实体名称集合 (用于识别跨世界观双链越界引用 · CONSIST-003)
  final Set<String> otherWorldEntityNames;

  const ConsistencyContext({
    required this.worldId,
    this.targetCharacterId,
    required this.characters,
    required this.relations,
    required this.events,
    required this.lores,
    required this.galleries,
    this.otherWorldEntityNames = const {},
  });

  /// 是否为单角色定向检查模式
  bool get isSingleCharacterMode => targetCharacterId != null;
}

/// 一致性检查整体体检报告
class ConsistencyReport {
  final int worldId;
  final List<ConsistencyIssue> issues;
  final DateTime checkedAt;

  const ConsistencyReport({
    required this.worldId,
    required this.issues,
    required this.checkedAt,
  });

  int get errorCount =>
      issues.where((i) => i.severity == IssueSeverity.error).length;
  int get warningCount =>
      issues.where((i) => i.severity == IssueSeverity.warning).length;
  int get infoCount =>
      issues.where((i) => i.severity == IssueSeverity.info).length;

  /// 健康得分（满分 100 分，每个错误扣 15 分，每个警告扣 5 分，每个建议扣 1 分）
  int get healthScore {
    final penalty = (errorCount * 15) + (warningCount * 5) + (infoCount * 1);
    return (100 - penalty).clamp(0, 100);
  }
}

import 'package:oc_manager/data/database/app_database.dart';
import '../consistency_models.dart';
import '../consistency_rule.dart';

/// 2. 人物关系网矛盾与自环规则 (RULE_RELATION_INTEGRITY · CONSIST-003)
class RelationIntegrityRule extends ConsistencyRule {
  @override
  String get ruleId => 'RULE_RELATION_INTEGRITY';

  @override
  String get name => '人物关系网矛盾、自环与失效引用检查';

  @override
  String get description => '诊断自身指向自环关系、失效幽灵关系、重复冗余关系、情感矛盾以及家谱孤立关系分组。';

  @override
  IssueCategory get category => IssueCategory.relation;

  @override
  IssueSeverity get defaultSeverity => IssueSeverity.warning;

  @override
  Future<List<ConsistencyIssue>> evaluate(ConsistencyContext context) async {
    final issues = <ConsistencyIssue>[];
    final targetCharId = context.targetCharacterId;
    final validCharIds = {for (final c in context.characters) c.id};

    final relevantRelations = targetCharId != null
        ? context.relations
              .where(
                (r) =>
                    r.fromCharacterId == targetCharId ||
                    r.toCharacterId == targetCharId,
              )
              .toList()
        : context.relations;

    final pairRelations = <String, List<Relation>>{};
    final groupRelations = <String, List<Relation>>{};

    for (final rel in relevantRelations) {
      // 检查 1：失效幽灵关联（端点角色不存在）(CONSIST-003)
      final fromExists = validCharIds.contains(rel.fromCharacterId);
      final toExists = validCharIds.contains(rel.toCharacterId);

      if (!fromExists || !toExists) {
        issues.add(
          ConsistencyIssue(
            id: 'relation_dangling_${rel.id}',
            ruleId: ruleId,
            category: category,
            severity: IssueSeverity.error,
            title: '存在失效幽灵关系（引用的角色不存在）',
            description:
                '关系 ID #${rel.id} ("${rel.relationType}") 引用的端点角色在当前世界观中已不存在。',
            suggestion: '该关系引用的角色可能已被删除，建议清理该失效关系记录。',
            evidence:
                '关联角色 ID: from=#${rel.fromCharacterId} (${fromExists ? "存在" : "缺失"}), to=#${rel.toCharacterId} (${toExists ? "存在" : "缺失"})',
            targetType: 'relation',
            targetId: rel.id,
            targetName: rel.relationType,
          ),
        );
        // 跳过后续配对，避免对幽灵关系误报情感冲突
        continue;
      }

      // 检查 2：自环
      if (rel.fromCharacterId == rel.toCharacterId) {
        issues.add(
          ConsistencyIssue(
            id: 'relation_self_loop_${rel.id}',
            ruleId: ruleId,
            category: category,
            severity: IssueSeverity.error,
            title: '存在自我指向自环关系',
            description: '关系 ID #${rel.id} 的起始人物与目标人物均为同一角色。',
            suggestion: '请删除该自环关系，或将其端点重新连接至目标其他角色。',
            evidence: '关系起始 ID 与目标 ID 均为: #${rel.fromCharacterId}',
            targetType: 'relation',
            targetId: rel.id,
            targetName: rel.relationType,
          ),
        );
        continue;
      }

      final key = rel.fromCharacterId < rel.toCharacterId
          ? '${rel.fromCharacterId}_${rel.toCharacterId}'
          : '${rel.toCharacterId}_${rel.fromCharacterId}';
      pairRelations.putIfAbsent(key, () => []).add(rel);

      // 按关系分组归类 (CONSIST-003)
      if (rel.relationGroupId != null &&
          rel.relationGroupId!.trim().isNotEmpty) {
        groupRelations
            .putIfAbsent(rel.relationGroupId!.trim(), () => [])
            .add(rel);
      }
    }

    // 检查 3：成对重复冗余关系与情感矛盾 (CONSIST-003)
    final reportedDuplicatePairs = <String>{};

    for (final entry in pairRelations.entries) {
      final list = entry.value;
      if (list.length < 2) continue;

      // 3.1 检查重复定义 (Duplicate Relations)
      for (int i = 0; i < list.length; i++) {
        for (int j = i + 1; j < list.length; j++) {
          final r1 = list[i];
          final r2 = list[j];
          final type1 = r1.relationType.trim();
          final type2 = r2.relationType.trim();

          if (type1 == type2) {
            final isSameDirection =
                r1.fromCharacterId == r2.fromCharacterId &&
                r1.toCharacterId == r2.toCharacterId;
            final isBothBidi = r1.isBidirectional && r2.isBidirectional;

            if (isSameDirection || isBothBidi) {
              final dupKey = r1.id < r2.id
                  ? '${r1.id}_${r2.id}'
                  : '${r2.id}_${r1.id}';
              if (!reportedDuplicatePairs.contains(dupKey)) {
                reportedDuplicatePairs.add(dupKey);
                issues.add(
                  ConsistencyIssue(
                    id: 'relation_duplicate_$dupKey',
                    ruleId: ruleId,
                    category: category,
                    severity: IssueSeverity.warning,
                    title: '存在重复冗余关系',
                    description: '两角色之间重复录入了同类型的 “$type1” 关系定义。',
                    suggestion: '建议在关系图中删除多余的重复关系连线，保留一条即可。',
                    evidence: '重复关系记录: ID #${r1.id} 与 ID #${r2.id}',
                    targetType: 'relation',
                    targetId: r1.id,
                    targetName: type1,
                  ),
                );
              }
            }
          }
        }
      }

      // 3.2 检测情感矛盾
      final types = list.map((r) => r.relationType.trim()).toSet();
      final hasRomantic = types.any(
        (t) =>
            t.contains('恋人') ||
            t.contains('伴侣') ||
            t.contains('夫妻') ||
            t.contains('情侣'),
      );
      final hasHostile = types.any(
        (t) =>
            t.contains('仇') ||
            t.contains('死敌') ||
            t.contains('宿敌') ||
            t.contains('敌人'),
      );

      if (hasRomantic && hasHostile) {
        final rel = list.first;
        final romanticTypes = types
            .where((t) => t.contains('恋') || t.contains('伴') || t.contains('妻'))
            .join('/');
        final hostileTypes = types
            .where((t) => t.contains('仇') || t.contains('敌'))
            .join('/');

        issues.add(
          ConsistencyIssue(
            id: 'relation_conflict_${entry.key}',
            ruleId: ruleId,
            category: category,
            severity: IssueSeverity.warning,
            title: '人际关系存在情感矛盾',
            description:
                '同一对角色之间同时存在亲密关系 ($romanticTypes) 与敌对关系 ($hostileTypes)。',
            suggestion: '建议确认二者的确切关系定位，或在关系备注中阐明人物关系的阶段变迁。',
            evidence: '并存关系类型: ${types.join(', ')}',
            targetType: 'relation',
            targetId: rel.id,
            targetName: list.map((r) => r.relationType).join(' & '),
          ),
        );
      }
    }

    // 检查 4：异常关系分组残留 (CONSIST-003)
    if (!context.isSingleCharacterMode) {
      for (final groupEntry in groupRelations.entries) {
        final groupList = groupEntry.value;
        if (groupList.length == 1) {
          final rel = groupList.first;
          issues.add(
            ConsistencyIssue(
              id: 'relation_orphan_group_${rel.id}',
              ruleId: ruleId,
              category: category,
              severity: IssueSeverity.info,
              title: '家谱/关系分组孤立残留',
              description:
                  '关系 ID #${rel.id} ("${rel.relationType}") 所属的关联分组 (“${groupEntry.key}”) 仅存单条连线，对偶关系可能已缺失。',
              suggestion: '建议检查家谱关系的双向配对是否完整，或在关系属性中重新设定该关系组。',
              evidence: '所属关系组 ID: ${groupEntry.key}',
              targetType: 'relation',
              targetId: rel.id,
              targetName: rel.relationType,
            ),
          );
        }
      }
    }

    return issues;
  }
}

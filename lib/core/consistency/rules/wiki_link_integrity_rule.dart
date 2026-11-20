import 'package:oc_manager/core/util/wiki_link_parser.dart';
import '../consistency_models.dart';
import '../consistency_rule.dart';

/// 3. 维基双链有效性与断链检查规则 (RULE_WIKI_LINK_INTEGRITY · CONSIST-003)
class WikiLinkIntegrityRule extends ConsistencyRule {
  @override
  String get ruleId => 'RULE_WIKI_LINK_INTEGRITY';

  @override
  String get name => '维基双链有效性、断链与跨世界观引用检查';

  @override
  String get description =>
      '诊断人设小传或百科正文中 [[实体名]] 双链指向不存在实体的断链问题，以及越界引用其他世界观实体的逻辑隔离警告。';

  @override
  IssueCategory get category => IssueCategory.link;

  @override
  IssueSeverity get defaultSeverity => IssueSeverity.error;

  @override
  Future<List<ConsistencyIssue>> evaluate(ConsistencyContext context) async {
    final issues = <ConsistencyIssue>[];
    final charNames = {for (final c in context.characters) c.name.trim()};
    final loreNames = {for (final l in context.lores) l.name.trim()};
    final otherWorldNames = context.otherWorldEntityNames;

    final targetCharId = context.targetCharacterId;
    final targetCharacters = targetCharId != null
        ? context.characters.where((c) => c.id == targetCharId).toList()
        : context.characters;

    // 检查角色描述中的双链
    for (final char in targetCharacters) {
      if (char.description.isEmpty) continue;
      final targetNames = WikiLinkParser.extractTargetNames(char.description);
      for (final targetName in targetNames) {
        if (!charNames.contains(targetName) &&
            !loreNames.contains(targetName)) {
          // 区分：跨世界观引用 vs 彻底失效 (CONSIST-003)
          final isCrossWorld = otherWorldNames.contains(targetName);

          if (isCrossWorld) {
            issues.add(
              ConsistencyIssue(
                id: 'link_cross_world_char_${char.id}_$targetName',
                ruleId: ruleId,
                category: category,
                severity: IssueSeverity.warning,
                title: '检测到跨世界观双链越界引用',
                description:
                    '角色 “${char.name}” 的小传中引用的实体 “$targetName” 属于其他世界观，无法在当前世界观内直接解析。',
                suggestion: '系统遵循世界观独立隔离原则，双链无法跨世界观穿透。建议在当前世界观建立对应实体，或调整小传文本。',
                evidence: '引用的实体 “$targetName” 存在于外部世界观中',
                targetType: 'character',
                targetId: char.id,
                targetName: char.name,
              ),
            );
          } else {
            issues.add(
              ConsistencyIssue(
                id: 'link_broken_char_${char.id}_$targetName',
                ruleId: ruleId,
                category: category,
                severity: IssueSeverity.error,
                title: '双向链接失效（目标不存在）',
                description: '角色 “${char.name}” 的人设小传中引用了不存在的实体 “$targetName”。',
                suggestion: '检查被链接实体名称拼写是否准确，或为 “$targetName” 创建对应角色/词条。',
                evidence: '未命中双链语法: [[$targetName]]',
                targetType: 'character',
                targetId: char.id,
                targetName: char.name,
              ),
            );
          }
        }
      }
    }

    // 若非单人物模式，则检查全部百科词条正文
    if (!context.isSingleCharacterMode) {
      for (final lore in context.lores) {
        if (lore.content.isEmpty) continue;
        final targetNames = WikiLinkParser.extractTargetNames(lore.content);
        for (final targetName in targetNames) {
          if (!charNames.contains(targetName) &&
              !loreNames.contains(targetName)) {
            final isCrossWorld = otherWorldNames.contains(targetName);

            if (isCrossWorld) {
              issues.add(
                ConsistencyIssue(
                  id: 'link_cross_world_lore_${lore.id}_$targetName',
                  ruleId: ruleId,
                  category: category,
                  severity: IssueSeverity.warning,
                  title: '检测到跨世界观双链越界引用',
                  description:
                      '百科词条 “${lore.name}” 的正文中引用的实体 “$targetName” 属于其他世界观，无法在当前世界观内直接解析。',
                  suggestion:
                      '系统遵循世界观独立隔离原则，双链无法跨世界观穿透。建议在当前世界观建立对应实体，或调整词条文本。',
                  evidence: '引用的实体 “$targetName” 存在于外部世界观中',
                  targetType: 'lore',
                  targetId: lore.id,
                  targetName: lore.name,
                ),
              );
            } else {
              issues.add(
                ConsistencyIssue(
                  id: 'link_broken_lore_${lore.id}_$targetName',
                  ruleId: ruleId,
                  category: category,
                  severity: IssueSeverity.error,
                  title: '双向链接失效（目标不存在）',
                  description:
                      '百科词条 “${lore.name}” 的正文设定中引用了不存在的实体 “$targetName”。',
                  suggestion: '修正百科正文中的双链实体名称，或新建对应实体词条。',
                  evidence: '未命中双链语法: [[$targetName]]',
                  targetType: 'lore',
                  targetId: lore.id,
                  targetName: lore.name,
                ),
              );
            }
          }
        }
      }
    }

    return issues;
  }
}

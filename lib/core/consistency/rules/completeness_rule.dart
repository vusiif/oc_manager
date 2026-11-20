import '../consistency_models.dart';
import '../consistency_rule.dart';

/// 5. 设定孤岛与完整度规则 (RULE_COMPLETENESS · CONSIST-004)
class CompletenessRule extends ConsistencyRule {
  @override
  String get ruleId => 'RULE_COMPLETENESS';

  @override
  String get name => '设定完整度与孤立节点检查';

  @override
  String get description =>
      '检查角色人设小传空白、孤立无关系节点、缺少封面立绘、百科词条未分类或内容为空等完整度遗漏，智能区分有意留白与可能遗漏。';

  @override
  IssueCategory get category => IssueCategory.completeness;

  @override
  IssueSeverity get defaultSeverity => IssueSeverity.info;

  /// 智能判定是否为创作者有意留白 (Intentional Blank / WIP)
  static bool isIntentionalBlank({
    required String name,
    required String description,
    String? tags,
  }) {
    final cleanName = name.trim().toLowerCase();
    final cleanDesc = description.trim().toLowerCase();
    final cleanTags = (tags ?? '').toLowerCase();

    const blankKeywords = [
      '留白',
      '待补充',
      '待定',
      '草稿',
      'tbd',
      'todo',
      'wip',
      'draft',
      '暂缺',
      '占位',
      '未定',
    ];

    for (final kw in blankKeywords) {
      // 1. 标签中明确包含留白关键字
      if (cleanTags.contains(kw)) return true;

      // 2. 名称中带有留白标记（如 [待补充]、(草稿)、【留白】或名称本身就是留白词）
      if (cleanName == kw ||
          cleanName.contains('[$kw]') ||
          cleanName.contains('($kw)') ||
          cleanName.contains('【$kw】') ||
          cleanName.contains('（$kw）')) {
        return true;
      }

      // 3. 描述内容纯粹为留白占位符
      if (cleanDesc == kw ||
          cleanDesc == '[$kw]' ||
          cleanDesc == '【$kw】' ||
          cleanDesc == '($kw)') {
        return true;
      }
    }

    return false;
  }

  @override
  Future<List<ConsistencyIssue>> evaluate(ConsistencyContext context) async {
    final issues = <ConsistencyIssue>[];

    // 统计所有角色的关系纽带计数
    final relationCounts = <int, int>{};
    for (final r in context.relations) {
      relationCounts[r.fromCharacterId] =
          (relationCounts[r.fromCharacterId] ?? 0) + 1;
      relationCounts[r.toCharacterId] =
          (relationCounts[r.toCharacterId] ?? 0) + 1;
    }

    // 统计每个角色的画廊立绘切片数
    final galleryCounts = <int, int>{};
    for (final g in context.galleries) {
      galleryCounts[g.characterId] = (galleryCounts[g.characterId] ?? 0) + 1;
    }

    final targetCharId = context.targetCharacterId;
    final targetCharacters = targetCharId != null
        ? context.characters.where((c) => c.id == targetCharId).toList()
        : context.characters;

    // 1. 优先诊断人设小传空白与孤岛角色 (保证核心设定问题置顶)
    for (final char in targetCharacters) {
      final hasNoDesc = char.description.trim().isEmpty;
      final relCount = relationCounts[char.id] ?? 0;
      final isIsolated = relCount == 0;
      final intentionalBlank = isIntentionalBlank(
        name: char.name,
        description: char.description,
      );

      // (A) 空白孤岛角色检查 (既无小传也无任何关系)
      if (hasNoDesc && isIsolated) {
        if (!intentionalBlank) {
          issues.add(
            ConsistencyIssue(
              id: 'completeness_isolated_empty_${char.id}',
              ruleId: ruleId,
              category: category,
              severity: IssueSeverity.info,
              title: '空白孤岛角色',
              description: '角色 “${char.name}” 既无人设小传，也未建立任何社会关系纽带，建议补充设定。',
              suggestion:
                  '在角色详情中编写生平小传，或在关系图中将其与其他人物连线；若为有意留白，可在名称或标签中添加 “留白” 或 “草稿”。',
              evidence: '小传长度: 0 字, 关系连线数: 0 条',
              targetType: 'character',
              targetId: char.id,
              targetName: char.name,
            ),
          );
        }
      }
      // (B) 角色人设小传空白 (有社会关系但小传空白)
      else if (hasNoDesc && !isIsolated) {
        if (!intentionalBlank) {
          issues.add(
            ConsistencyIssue(
              id: 'completeness_character_desc_empty_${char.id}',
              ruleId: ruleId,
              category: category,
              severity: IssueSeverity.info,
              title: '角色人设小传空白',
              description: '角色 “${char.name}” 已与其他角色建立社会关系纽带，但尚未填写生平小传与背景。',
              suggestion: '在角色详情中补充性格、外貌特征或生平小传，丰富人物立体度。',
              evidence: '小传长度: 0 字, 关系纽带数: $relCount 条',
              targetType: 'character',
              targetId: char.id,
              targetName: char.name,
            ),
          );
        }
      }
    }

    // 2. 百科词条完整度检查 (全世界观模式下评估)
    if (!context.isSingleCharacterMode) {
      for (final lore in context.lores) {
        final intentionalBlank = isIntentionalBlank(
          name: lore.name,
          description: '${lore.summary} ${lore.content}',
        );

        // (C) 百科词条未明确分类 (CONSIST-004)
        final entityTypeStr = lore.entityType.trim();
        final isUncategorized =
            entityTypeStr.isEmpty ||
            const {
              'uncategorized',
              'default',
              '未分类',
              '其他',
              '未定',
            }.contains(entityTypeStr.toLowerCase());

        if (isUncategorized && !intentionalBlank) {
          issues.add(
            ConsistencyIssue(
              id: 'completeness_lore_uncategorized_${lore.id}',
              ruleId: ruleId,
              category: category,
              severity: IssueSeverity.info,
              title: '百科词条未明确分类',
              description: '百科实体 “${lore.name}” 目前处于未分类或默认状态，不利于多维度世界观知识索引。',
              suggestion: '在百科编辑中将其归入地点、组织、种族、物品、能力等专属分类。',
              evidence:
                  '当前分类: ${entityTypeStr.isEmpty ? '未填写' : entityTypeStr}',
              targetType: 'lore',
              targetId: lore.id,
              targetName: lore.name,
            ),
          );
        }

        // (D) 百科词条内容与摘要全空 (CONSIST-004)
        if (lore.summary.trim().isEmpty &&
            lore.content.trim().isEmpty &&
            !intentionalBlank) {
          issues.add(
            ConsistencyIssue(
              id: 'completeness_empty_lore_${lore.id}',
              ruleId: ruleId,
              category: category,
              severity: IssueSeverity.info,
              title: '百科词条内容为空',
              description: '百科实体 “${lore.name}” 缺少摘要与正文详述，建议丰富世界观背景。',
              suggestion: '在百科详情中补充摘要介绍或正文设定；若为规划中占位条目，可在名称或标签中注明 “待补充”。',
              evidence: '摘要与正文字数均为 0',
              targetType: 'lore',
              targetId: lore.id,
              targetName: lore.name,
            ),
          );
        }
      }
    }

    // 3. 角色与词条封面立绘按需检查 (CONSIST-004: 针对明确标记立绘/约稿/封面意图的实体进行精准检查，避免对纯文字创作者造成视觉噪音)
    for (final char in targetCharacters) {
      final intentionalBlank = isIntentionalBlank(
        name: char.name,
        description: char.description,
      );
      if (intentionalBlank) continue;

      final descLower = char.description.toLowerCase();
      final nameLower = char.name.toLowerCase();
      final hasVisualDemand =
          descLower.contains('立绘') ||
          descLower.contains('头像') ||
          descLower.contains('约稿') ||
          descLower.contains('插画') ||
          descLower.contains('待画') ||
          descLower.contains('需图') ||
          nameLower.contains('立绘') ||
          nameLower.contains('约稿') ||
          nameLower.contains('待画');

      final hasAvatar =
          char.avatarPath != null && char.avatarPath!.trim().isNotEmpty;
      final galCount = galleryCounts[char.id] ?? 0;

      if (hasVisualDemand && !hasAvatar && galCount == 0) {
        issues.add(
          ConsistencyIssue(
            id: 'completeness_character_avatar_missing_${char.id}',
            ruleId: ruleId,
            category: category,
            severity: IssueSeverity.info,
            title: '缺少形象立绘与头像',
            description: '角色 “${char.name}” 已标记立绘/约稿视觉意图，但尚未配置正面头像或画廊立绘。',
            suggestion: '在角色详情页点击头像上传正面立绘，或在画廊中上传差分图片。',
            evidence: '设定意图: 包含立绘/约稿需求, 主头像: 未设置, 专属画廊立绘: 0 张',
            targetType: 'character',
            targetId: char.id,
            targetName: char.name,
          ),
        );
      }
    }

    return issues;
  }
}

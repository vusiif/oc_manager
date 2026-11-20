import '../../core/storage/image_storage_service.dart';
import '../../core/util/wiki_link_parser.dart';
import '../../data/database/app_database.dart';
import 'consistency_models.dart';
import 'consistency_rule.dart';
import 'timeline_date_parser.dart';

/// 1. 时间轴与生卒年生死区规则 (RULE_TIMELINE_LIFESPAN · CONSIST-002)
class TimelineLifespanRule extends ConsistencyRule {
  @override
  String get ruleId => 'RULE_TIMELINE_LIFESPAN';

  @override
  String get name => '时间轴与生卒年生死区检查';

  @override
  String get description =>
      '诊断生卒年份时序颠倒、生平事件超出生死区间、存活状态与死亡事件冲突，以及凡人极端寿命提示。数据不足或模糊时不武断判断。';

  @override
  IssueCategory get category => IssueCategory.timeline;

  @override
  IssueSeverity get defaultSeverity => IssueSeverity.error;

  @override
  Future<List<ConsistencyIssue>> evaluate(ConsistencyContext context) async {
    final issues = <ConsistencyIssue>[];
    final targetCharId = context.targetCharacterId;

    final targetCharacters = targetCharId != null
        ? context.characters.where((c) => c.id == targetCharId).toList()
        : context.characters;

    for (final char in targetCharacters) {
      final charEvents = context.events
          .where((e) => e.characterId == char.id)
          .toList();
      if (charEvents.isEmpty) continue;

      int? birthYear;
      int? deathYear;
      TimelineEvent? deathEvent;
      int? maxEventYear;
      int? minEventYear;

      for (final ev in charEvents) {
        final parsed = TimelineDateParser.parseYear(ev.year);
        // 数据不足、日期模糊时不武断判断 (CONSIST-002)
        if (!parsed.hasExactYear) continue;

        final evYear = parsed.year!;
        minEventYear = minEventYear == null
            ? evYear
            : (evYear < minEventYear ? evYear : minEventYear);
        maxEventYear = maxEventYear == null
            ? evYear
            : (evYear > maxEventYear ? evYear : maxEventYear);

        final isBirth =
            ev.category == 'birth' ||
            ev.title.contains('出生') ||
            ev.title.contains('诞生') ||
            ev.title.contains('降生');
        final isDeath =
            ev.category == 'death' ||
            ev.title.contains('逝世') ||
            ev.title.contains('阵亡') ||
            ev.title.contains('牺牲') ||
            ev.title.contains('陨落') ||
            ev.title.contains('死亡');

        if (isBirth && (birthYear == null || evYear < birthYear)) {
          birthYear = evYear;
        }
        if (isDeath && (deathYear == null || evYear > deathYear)) {
          deathYear = evYear;
          deathEvent = ev;
        }
      }

      // 检查 1：出生年份晚于逝世年份 (严重矛盾 Error)
      if (birthYear != null && deathYear != null && birthYear > deathYear) {
        issues.add(
          ConsistencyIssue(
            id: 'timeline_lifespan_inverted_${char.id}',
            ruleId: ruleId,
            category: category,
            severity: IssueSeverity.error,
            title: '生卒年时序矛盾',
            description:
                '角色 “${char.name}” 的记录出生年份 ($birthYear) 晚于逝世年份 ($deathYear)。',
            suggestion: '核实并修正该角色的生卒纪元年份，确保出生年份早于逝世年份。',
            evidence: '出生年份: $birthYear, 逝世年份: $deathYear',
            targetType: 'character',
            targetId: char.id,
            targetName: char.name,
          ),
        );
      }

      // 检查 2：普通生平事件发生于逝世之后 (逻辑警告 Warning)
      if (deathYear != null) {
        for (final ev in charEvents) {
          final isBirth =
              ev.category == 'birth' ||
              ev.title.contains('出生') ||
              ev.title.contains('诞生');
          final isDeathOrLegacy =
              ev.category == 'death' ||
              ev.title.contains('逝世') ||
              ev.title.contains('阵亡') ||
              ev.title.contains('纪念') ||
              ev.title.contains('追思') ||
              ev.title.contains('追封') ||
              ev.title.contains('遗产') ||
              ev.title.contains('冥诞');
          if (isBirth || isDeathOrLegacy) continue;

          final parsed = TimelineDateParser.parseYear(ev.year);
          if (parsed.hasExactYear && parsed.year! > deathYear) {
            final evYear = parsed.year!;
            issues.add(
              ConsistencyIssue(
                id: 'timeline_event_after_death_${ev.id}',
                ruleId: ruleId,
                category: category,
                severity: IssueSeverity.warning,
                title: '生平事件超出生存区间',
                description:
                    '事件 “${ev.title}” ($evYear 年) 发生在角色 “${char.name}” 逝世 ($deathYear 年) 之后。',
                suggestion: '检查事件所属年份是否正确，或者将该事件分类更改为追思纪念类事件。',
                evidence: '事件年份: $evYear, 逝世年份: $deathYear',
                targetType: 'timeline',
                targetId: ev.id,
                targetName: ev.title,
              ),
            );
          }
        }
      }

      // 检查 3：普通生平事件发生于出生之前 (逻辑警告 Warning)
      if (birthYear != null) {
        for (final ev in charEvents) {
          final isBirth =
              ev.category == 'birth' ||
              ev.title.contains('出生') ||
              ev.title.contains('诞生');
          final isOriginOrPrequel =
              ev.title.contains('前尘') ||
              ev.title.contains('前世') ||
              ev.title.contains('先祖') ||
              ev.title.contains('起源') ||
              ev.title.contains('预言') ||
              ev.title.contains('开天');
          if (isBirth || isOriginOrPrequel) continue;

          final parsed = TimelineDateParser.parseYear(ev.year);
          if (parsed.hasExactYear && parsed.year! < birthYear) {
            final evYear = parsed.year!;
            issues.add(
              ConsistencyIssue(
                id: 'timeline_event_before_birth_${ev.id}',
                ruleId: ruleId,
                category: category,
                severity: IssueSeverity.warning,
                title: '生平事件早于出生时间',
                description:
                    '事件 “${ev.title}” ($evYear 年) 发生在角色 “${char.name}” 出生 ($birthYear 年) 之前。',
                suggestion: '检查事件所属年份是否早于出生年份，或者在事件说明中注明其前置背景属性。',
                evidence: '事件年份: $evYear, 出生年份: $birthYear',
                targetType: 'timeline',
                targetId: ev.id,
                targetName: ev.title,
              ),
            );
          }
        }
      }

      // 检查 4：角色状态为正常/存活，但在编年史中有确凿逝世事件 (逻辑警告 Warning)
      if (char.status == 0 && deathEvent != null) {
        issues.add(
          ConsistencyIssue(
            id: 'timeline_alive_with_death_event_${char.id}',
            ruleId: ruleId,
            category: category,
            severity: IssueSeverity.warning,
            title: '存活状态与死亡事件矛盾',
            description:
                '角色 “${char.name}” 当前人设状态标记为正常/存活，但编年史中记录了确凿逝世事件 “${deathEvent.title}”。',
            suggestion: '若该角色已在故事线中阵亡，建议将人设状态修改为“已故”；若属于假死或失踪，建议在事件或人设中补充说明。',
            evidence:
                '角色人设状态: 存活, 编年事件: “${deathEvent.title}” (${deathEvent.year})',
            targetType: 'character',
            targetId: char.id,
            targetName: char.name,
          ),
        );
      }

      // 检查 5：超常生存周期/事件跨度友好提示 (设定建议 Info)
      if (birthYear != null) {
        final endYear = deathYear ?? maxEventYear;
        if (endYear != null) {
          final span = endYear - birthYear;
          if (span > 200) {
            final desc = char.description.toLowerCase();
            final hasImmortalKeywords =
                desc.contains('神') ||
                desc.contains('仙') ||
                desc.contains('魔') ||
                desc.contains('龙') ||
                desc.contains('精灵') ||
                desc.contains('长生') ||
                desc.contains('不朽') ||
                desc.contains('吸血鬼') ||
                desc.contains('永生') ||
                desc.contains('机械') ||
                desc.contains('仿生') ||
                desc.contains('ai') ||
                desc.contains('转世') ||
                desc.contains('重生') ||
                desc.contains('时间');

            if (!hasImmortalKeywords) {
              issues.add(
                ConsistencyIssue(
                  id: 'timeline_extended_lifespan_${char.id}',
                  ruleId: ruleId,
                  category: category,
                  severity: IssueSeverity.info,
                  title: '角色活动时间跨度较长',
                  description:
                      '角色 “${char.name}” 的生命跨度达 $span 年 (约 $birthYear 年 ~ $endYear 年)，若设定为凡人可能存在笔误。',
                  suggestion:
                      '若该角色属于仙神、长生种或跨时代穿越者，建议在小传中补充寿命设定；若为普通人类，请核对纪元年份。',
                  evidence: '活动跨度: $span 年 (出生 $birthYear ~ 截止 $endYear)',
                  targetType: 'character',
                  targetId: char.id,
                  targetName: char.name,
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

/// 4. 多媒体沙盒本地文件有效性规则 (RULE_MEDIA_FILE_INTEGRITY)
class MediaFileIntegrityRule extends ConsistencyRule {
  @override
  String get ruleId => 'RULE_MEDIA_FILE_INTEGRITY';

  @override
  String get name => '多媒体本地资源存活检查';

  @override
  String get description => '诊断角色头像、画廊立绘切片及百科封面的沙盒本地文件是否缺失或损坏。';

  @override
  IssueCategory get category => IssueCategory.media;

  @override
  IssueSeverity get defaultSeverity => IssueSeverity.error;

  @override
  Future<List<ConsistencyIssue>> evaluate(ConsistencyContext context) async {
    final issues = <ConsistencyIssue>[];
    final storage = ImageStorageService.instance;
    final targetCharId = context.targetCharacterId;

    final targetCharacters = targetCharId != null
        ? context.characters.where((c) => c.id == targetCharId).toList()
        : context.characters;

    // 1. 检查角色头像
    for (final char in targetCharacters) {
      if (char.avatarPath != null && char.avatarPath!.isNotEmpty) {
        final file = await storage.resolveImageFile(char.avatarPath);
        if (file == null || !file.existsSync()) {
          issues.add(
            ConsistencyIssue(
              id: 'media_avatar_missing_${char.id}',
              ruleId: ruleId,
              category: category,
              severity: IssueSeverity.error,
              title: '角色主头像文件丢失',
              description: '角色 “${char.name}” 绑定的本地立绘头像在沙盒磁盘上已不存在。',
              suggestion: '请重新为该角色选择并上传头像，或清除已失效的头像引用。',
              evidence: '缺失文件相对路径: ${char.avatarPath}',
              targetType: 'character',
              targetId: char.id,
              targetName: char.name,
            ),
          );
        }
      }
    }

    // 2. 检查画廊立绘
    final targetCharIds = {for (final c in targetCharacters) c.id};
    final relevantGalleries = context.galleries
        .where((g) => targetCharIds.contains(g.characterId))
        .toList();

    for (final g in relevantGalleries) {
      final file = await storage.resolveImageFile(g.imagePath);
      if (file == null || !file.existsSync()) {
        issues.add(
          ConsistencyIssue(
            id: 'media_gallery_missing_${g.id}',
            ruleId: ruleId,
            category: category,
            severity: IssueSeverity.error,
            title: '角色画廊立绘丢失',
            description: '画廊 ID #${g.id} 对应的本地差分切片文件在沙盒磁盘上已不存在。',
            suggestion: '重新导入对应的立绘切片图片，或在画廊中删除无效切片。',
            evidence: '缺失画廊切片路径: ${g.imagePath}',
            targetType: 'character',
            targetId: g.characterId,
            targetName: '画廊立绘 #${g.id}',
          ),
        );
      }
    }

    // 3. 检查百科封面（仅在全量模式）
    if (!context.isSingleCharacterMode) {
      for (final lore in context.lores) {
        if (lore.coverImagePath != null && lore.coverImagePath!.isNotEmpty) {
          final file = await storage.resolveImageFile(lore.coverImagePath);
          if (file == null || !file.existsSync()) {
            issues.add(
              ConsistencyIssue(
                id: 'media_lore_cover_missing_${lore.id}',
                ruleId: ruleId,
                category: category,
                severity: IssueSeverity.error,
                title: '百科图鉴封面丢失',
                description: '百科实体 “${lore.name}” 关联的封面图片在沙盒磁盘上已不存在。',
                suggestion: '重新上传该词条的封面图，或在词条详情中移除封面。',
                evidence: '缺失封面路径: ${lore.coverImagePath}',
                targetType: 'lore',
                targetId: lore.id,
                targetName: lore.name,
              ),
            );
          }
        }
      }
    }

    return issues;
  }
}

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

import 'package:oc_manager/data/database/app_database.dart';
import '../consistency_models.dart';
import '../consistency_rule.dart';
import '../timeline_date_parser.dart';

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

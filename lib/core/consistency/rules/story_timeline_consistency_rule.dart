import 'dart:convert';
import 'package:oc_manager/data/database/app_database.dart';
import '../consistency_models.dart';
import '../consistency_rule.dart';
import '../timeline_date_parser.dart';

/// 6. 故事线与分镜场景时序规则 (RULE_STORY_TIMELINE · STORY-004)
class StoryTimelineConsistencyRule extends ConsistencyRule {
  @override
  String get ruleId => 'RULE_STORY_TIMELINE';

  @override
  String get name => '故事线分镜与编年时序检查';

  @override
  String get description =>
      '诊断故事分镜叙事时序与时间节点倒错、角色于死后或出生前年代在场景中登场、分镜时间与编年史大事件记录冲突，以及已定稿章节中的空白分镜。数据留白时不武断判断。';

  @override
  IssueCategory get category => IssueCategory.story;

  @override
  IssueSeverity get defaultSeverity => IssueSeverity.warning;

  // 倒叙/回忆/昔日/插叙/闪回等容错关键词（遇到时不视作顺序倒错）
  static const Set<String> _flashbackKeywords = {
    '回忆',
    '倒叙',
    '插叙',
    '昔日',
    '当年',
    '往昔',
    '前尘',
    '闪回',
    '追忆',
    '序曲',
    'flashback',
    'prelude',
    'prologue',
  };

  // 死后出场的豁免关键词（亡魂、托梦、幻象、复活等）
  static const Set<String> _posthumousKeywords = {
    '亡魂',
    '英灵',
    '幽灵',
    '托梦',
    '幻象',
    '幻影',
    '残魂',
    '追忆',
    '回忆',
    '重塑',
    '复活',
    '重生',
    '死后',
    '冥界',
  };

  bool _isFlashback(StoryScene scene, StoryChapter? chapter) {
    final text =
        '${scene.title} ${scene.summary} ${scene.content} ${scene.timelineTime} ${chapter?.title ?? ''} ${chapter?.arcName ?? ''}'
            .toLowerCase();
    return _flashbackKeywords.any((kw) => text.contains(kw));
  }

  bool _isPosthumousExempt(StoryScene scene) {
    final text =
        '${scene.title} ${scene.summary} ${scene.content} ${scene.mood}'
            .toLowerCase();
    return _posthumousKeywords.any((kw) => text.contains(kw));
  }

  List<int> _parseSceneCharacterIds(StoryScene scene) {
    final ids = <int>{};
    if (scene.povCharacterId != null) {
      ids.add(scene.povCharacterId!);
    }
    if (scene.characterIds.trim().isNotEmpty) {
      try {
        final dynamic parsed = jsonDecode(scene.characterIds);
        if (parsed is List) {
          for (final item in parsed) {
            final id = int.tryParse(item.toString());
            if (id != null && id > 0) ids.add(id);
          }
        }
      } catch (_) {}
    }
    return ids.toList();
  }

  @override
  Future<List<ConsistencyIssue>> evaluate(ConsistencyContext context) async {
    final issues = <ConsistencyIssue>[];
    if (context.scenes.isEmpty) return issues;

    final targetCharId = context.targetCharacterId;
    final isSingleChar = context.isSingleCharacterMode;

    final worksMap = {for (final w in context.works) w.id: w};
    final chaptersMap = {for (final c in context.chapters) c.id: c};
    final charsMap = {for (final c in context.characters) c.id: c};

    // 预解析角色的生卒年
    final birthYears = <int, int>{};
    final deathYears = <int, int>{};
    for (final char in context.characters) {
      final charEvents = context.events.where((e) => e.characterId == char.id);
      for (final ev in charEvents) {
        final parsed = TimelineDateParser.parseYear(ev.year);
        if (!parsed.hasExactYear) continue;

        final evYear = parsed.year!;
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

        if (isBirth &&
            (!birthYears.containsKey(char.id) ||
                evYear < birthYears[char.id]!)) {
          birthYears[char.id] = evYear;
        }
        if (isDeath &&
            (!deathYears.containsKey(char.id) ||
                evYear > deathYears[char.id]!)) {
          deathYears[char.id] = evYear;
        }
      }
    }

    // 1. 场景叙事时序与故事内时间倒错检查 (仅在非单人物检查模式时运行)
    if (!isSingleChar) {
      // 按作品分组
      final scenesByWork = <int, List<StoryScene>>{};
      for (final scene in context.scenes) {
        final ch = chaptersMap[scene.chapterId];
        if (ch == null) continue;
        scenesByWork.putIfAbsent(ch.workId, () => []).add(scene);
      }

      for (final entry in scenesByWork.entries) {
        final workId = entry.key;
        final workScenes = entry.value;
        final work = worksMap[workId];
        if (work == null) continue;

        // 场景按章节序号与分镜序号排序
        workScenes.sort((a, b) {
          final chA = chaptersMap[a.chapterId];
          final chB = chaptersMap[b.chapterId];
          final chSortA = chA?.sortOrder ?? 0;
          final chSortB = chB?.sortOrder ?? 0;
          if (chSortA != chSortB) return chSortA.compareTo(chSortB);
          final sSort = a.sortOrder.compareTo(b.sortOrder);
          if (sSort != 0) return sSort;
          return a.id.compareTo(b.id);
        });

        // 检查相邻有明确时间节点的场景是否出现时间倒错
        StoryScene? prevTimedScene;
        int? prevYear;

        for (final scene in workScenes) {
          final chapter = chaptersMap[scene.chapterId];
          if (scene.timelineTime.trim().isEmpty) continue;

          final parsed = TimelineDateParser.parseYear(scene.timelineTime);
          if (!parsed.hasExactYear) continue;

          final curYear = parsed.year!;
          if (prevTimedScene != null && prevYear != null) {
            if (curYear < prevYear) {
              // 出现时间倒流，检查是否为合法回忆/倒叙
              final isFlashbackCur = _isFlashback(scene, chapter);
              final isFlashbackPrev = _isFlashback(
                prevTimedScene,
                chaptersMap[prevTimedScene.chapterId],
              );
              if (!isFlashbackCur && !isFlashbackPrev) {
                issues.add(
                  ConsistencyIssue(
                    id: 'story_timeline_inverted_${scene.id}_${prevTimedScene.id}',
                    ruleId: ruleId,
                    category: category,
                    severity: IssueSeverity.warning,
                    title: '分镜场景时序发生倒错',
                    description:
                        '在作品《${work.title}》中，场景《${scene.title}》排在《${prevTimedScene.title}》之后，但发生时间(${scene.timelineTime})早于前序场景(${prevTimedScene.timelineTime})，疑似时间顺序倒错或缺少“回忆/倒叙”标记。',
                    suggestion:
                        '若该场景为插叙、昔日往事或倒叙片段，请在场景标题、分卷名或分镜要点中包含“回忆/倒叙”字样；否则请调整场景在大纲中的前后顺序。',
                    evidence:
                        '前序场景: 《${prevTimedScene.title}》(时间: ${prevTimedScene.timelineTime}) -> 本场景: 《${scene.title}》(时间: ${scene.timelineTime})',
                    targetType: 'story',
                    targetId: scene.id,
                    targetName: '《${work.title}》${scene.title}',
                  ),
                );
              }
            }
          }

          prevTimedScene = scene;
          prevYear = curYear;
        }
      }
    }

    // 2. 角色生卒年与场景出场时间校验 (出生前 / 逝世后)
    for (final scene in context.scenes) {
      if (scene.timelineTime.trim().isEmpty) continue;
      final parsed = TimelineDateParser.parseYear(scene.timelineTime);
      if (!parsed.hasExactYear) continue;
      final sceneYear = parsed.year!;

      final sceneCharIds = _parseSceneCharacterIds(scene);
      for (final charId in sceneCharIds) {
        if (targetCharId != null && charId != targetCharId) continue;
        final char = charsMap[charId];
        if (char == null) continue;

        // 检查逝世后登场
        final deathYear = deathYears[charId];
        if (deathYear != null && sceneYear > deathYear) {
          if (!_isPosthumousExempt(scene)) {
            issues.add(
              ConsistencyIssue(
                id: 'story_char_posthumous_${charId}_${scene.id}',
                ruleId: ruleId,
                category: category,
                severity: IssueSeverity.error,
                title: '角色于逝世后年代在场景中登场',
                description:
                    '角色【${char.name}】在编年史记录中已于 $deathYear 年逝世/阵亡，但仍在发生于 ${scene.timelineTime} 的场景《${scene.title}》中登场出镜。',
                suggestion: '若此处为亡魂托梦、回忆篇或遗物幻象，请在分镜要点或氛围中注明；否则请核对该场景时间或出场名单。',
                evidence:
                    '角色逝世年份: $deathYear (编年史) vs 场景发生时间: ${scene.timelineTime} (年份 $sceneYear)',
                targetType: 'character',
                targetId: char.id,
                targetName: char.name,
              ),
            );
          }
        }

        // 检查出生前登场
        final birthYear = birthYears[charId];
        if (birthYear != null && sceneYear < birthYear) {
          final isExempt =
              scene.title.contains('前世') ||
              scene.content.contains('前世') ||
              scene.summary.contains('前世');
          if (!isExempt) {
            issues.add(
              ConsistencyIssue(
                id: 'story_char_prebirth_${charId}_${scene.id}',
                ruleId: ruleId,
                category: category,
                severity: IssueSeverity.error,
                title: '角色于出生前年代在场景中登场',
                description:
                    '角色【${char.name}】于编年史中记录的出生年份为 $birthYear 年，但却提前在发生于 ${scene.timelineTime} 的场景《${scene.title}》中登场。',
                suggestion: '请核对该场景发生时间是否早于该角色降生年份，或检查出场名单是否错选该人物。',
                evidence:
                    '角色出生年份: $birthYear vs 场景发生时间: ${scene.timelineTime} (年份 $sceneYear)',
                targetType: 'character',
                targetId: char.id,
                targetName: char.name,
              ),
            );
          }
        }
      }
    }

    // 3. 场景提及世界编年史事件的时间锚点比对
    if (!isSingleChar && context.events.isNotEmpty) {
      final eventTitleMap = {
        for (final ev in context.events) ev.title.trim(): ev,
      };

      for (final scene in context.scenes) {
        if (scene.timelineTime.trim().isEmpty) continue;
        final sceneParsed = TimelineDateParser.parseYear(scene.timelineTime);
        if (!sceneParsed.hasExactYear) continue;

        // 提取场景文本中匹配的编年史大事件
        final fullText = '${scene.title} ${scene.summary} ${scene.content}';
        for (final entry in eventTitleMap.entries) {
          final eventTitle = entry.key;
          final event = entry.value;
          if (eventTitle.length < 2) continue;

          // 匹配 [[事件]] 或场景标题精确与事件同名
          final isMentioned =
              fullText.contains('[[$eventTitle]]') || scene.title == eventTitle;
          if (isMentioned) {
            final evParsed = TimelineDateParser.parseYear(event.year);
            if (evParsed.hasExactYear && evParsed.year != sceneParsed.year) {
              issues.add(
                ConsistencyIssue(
                  id: 'story_event_mismatch_${scene.id}_${event.id}',
                  ruleId: ruleId,
                  category: category,
                  severity: IssueSeverity.warning,
                  title: '分镜时间与关联编年史事件年份不符',
                  description:
                      '场景《${scene.title}》发生时间为(${scene.timelineTime})，但所描绘/引用的世界编年史大事件【${event.title}】的记录年份为(${event.year})，存在历史年份冲突。',
                  suggestion: '请核对分镜发生时间与世界编年史大事件的纪元年份，确保故事时间与编年史统一。',
                  evidence:
                      '分镜时间: ${scene.timelineTime} (年份 ${sceneParsed.year}) vs 编年史事件【${event.title}】时间: ${event.year} (年份 ${evParsed.year})',
                  targetType: 'story',
                  targetId: scene.id,
                  targetName: scene.title,
                ),
              );
            }
          }
        }
      }
    }

    // 4. 定稿章节中的空白分镜检查 (定稿状态下的设定完整性)
    if (!isSingleChar) {
      for (final scene in context.scenes) {
        final chapter = chaptersMap[scene.chapterId];
        if (chapter == null) continue;

        if (chapter.status == '已定稿' || chapter.status == '撰写中') {
          final hasContent =
              scene.content.trim().isNotEmpty ||
              scene.summary.trim().isNotEmpty;
          final hasContext =
              scene.timelineTime.trim().isNotEmpty ||
              scene.locationName.trim().isNotEmpty ||
              scene.povCharacterId != null;

          if (!hasContent && !hasContext) {
            issues.add(
              ConsistencyIssue(
                id: 'story_blank_scene_${scene.id}',
                ruleId: ruleId,
                category: category,
                severity: IssueSeverity.info,
                title: '定稿章节存在空分镜场景',
                description:
                    '章节《${chapter.title}》处于【${chapter.status}】阶段，但场景《${scene.title}》未填写时间、地点、视点人物或分镜要点。',
                suggestion: '建议补充该场景的发生时间、地点、POV 视角或剧情推进要点。',
                evidence: '章节状态: ${chapter.status} · 场景内容为空',
                targetType: 'story',
                targetId: scene.id,
                targetName: scene.title,
              ),
            );
          }
        }
      }
    }

    return issues;
  }
}

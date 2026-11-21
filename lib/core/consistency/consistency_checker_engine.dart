import '../../data/database/app_database.dart';
import 'consistency_models.dart';
import 'consistency_rule.dart';
import 'consistency_rules.dart';

export 'consistency_config_service.dart';
export 'consistency_models.dart';
export 'consistency_rule.dart';
export 'consistency_rules.dart';
export 'timeline_date_parser.dart';

/// 设定一致性检查引擎 (CONSIST-001 规则引擎基础)
class ConsistencyCheckerEngine {
  final AppDatabase db;
  final ConsistencyRuleRegistry registry;

  ConsistencyCheckerEngine(this.db, {ConsistencyRuleRegistry? registry})
    : registry = registry ?? createDefaultRegistry();

  /// 创建装载所有内置确定性规则的标准注册中心
  static ConsistencyRuleRegistry createDefaultRegistry() {
    final reg = ConsistencyRuleRegistry();
    reg.registerAll([
      TimelineLifespanRule(),
      RelationIntegrityRule(),
      WikiLinkIntegrityRule(),
      MediaFileIntegrityRule(),
      CompletenessRule(),
      StoryTimelineConsistencyRule(),
    ]);
    return reg;
  }

  /// 执行整套一致性逻辑规则检查（全世界观模式）
  Future<ConsistencyReport> checkWorld(
    int worldId, {
    Set<String>? enabledRuleIds,
    Map<String, RuleConfig>? ruleConfigs,
  }) async {
    final context = await _buildContext(worldId: worldId);
    final effectiveEnabled =
        enabledRuleIds ??
        ruleConfigs?.entries
            .where((e) => e.value.enabled)
            .map((e) => e.key)
            .toSet();
    final activeRules = registry.getActiveRules(effectiveEnabled);

    final allIssues = <ConsistencyIssue>[];
    for (final rule in activeRules) {
      final issues = await rule.evaluate(context);
      final customSeverity = ruleConfigs?[rule.ruleId]?.customSeverity;
      if (customSeverity != null) {
        allIssues.addAll(
          issues.map((i) => i.copyWith(severity: customSeverity)),
        );
      } else {
        allIssues.addAll(issues);
      }
    }

    return ConsistencyReport(
      worldId: worldId,
      issues: allIssues,
      checkedAt: DateTime.now(),
    );
  }

  /// 针对单个角色的轻量定向检查 (CONSIST-001: 单人物检查)
  Future<List<ConsistencyIssue>> checkCharacter(
    int worldId,
    int characterId, {
    Set<String>? enabledRuleIds,
    Map<String, RuleConfig>? ruleConfigs,
  }) async {
    final context = await _buildContext(
      worldId: worldId,
      targetCharacterId: characterId,
    );
    final effectiveEnabled =
        enabledRuleIds ??
        ruleConfigs?.entries
            .where((e) => e.value.enabled)
            .map((e) => e.key)
            .toSet();
    final activeRules = registry.getActiveRules(effectiveEnabled);

    final issues = <ConsistencyIssue>[];
    for (final rule in activeRules) {
      final ruleIssues = await rule.evaluate(context);
      final customSeverity = ruleConfigs?[rule.ruleId]?.customSeverity;
      if (customSeverity != null) {
        issues.addAll(
          ruleIssues.map((i) => i.copyWith(severity: customSeverity)),
        );
      } else {
        issues.addAll(ruleIssues);
      }
    }
    return issues;
  }

  /// 组装强类型检查上下文
  Future<ConsistencyContext> _buildContext({
    required int worldId,
    int? targetCharacterId,
  }) async {
    // 1. 加载世界观内所有角色
    final characters = await (db.select(
      db.characters,
    )..where((t) => t.worldId.equals(worldId))).get();

    final charIds = characters.map((c) => c.id).toSet();

    // 2. 加载关系网、编年事件、百科实体
    final relations = await db.relationDao.getRelationsByWorld(worldId);
    final events = await db.timelineDao.getEventsByWorld(worldId);
    final lores = await db.loreDao.getEntitiesByWorld(worldId);

    // 3. 加载角色画廊切片
    final galleries = charIds.isEmpty
        ? <CharacterGallery>[]
        : await (db.select(
            db.characterGalleries,
          )..where((t) => t.characterId.isIn(charIds))).get();

    // 4. 加载其他世界观实体名称 (识别跨世界观双链越界引用 · CONSIST-003)
    final otherChars =
        await (db.selectOnly(db.characters)
              ..addColumns([db.characters.name])
              ..where(db.characters.worldId.isNotValue(worldId)))
            .get();
    final otherLores =
        await (db.selectOnly(db.loreEntities)
              ..addColumns([db.loreEntities.name])
              ..where(db.loreEntities.worldId.isNotValue(worldId)))
            .get();

    final otherEntityNames = <String>{
      for (final row in otherChars) (row.read(db.characters.name) ?? '').trim(),
      for (final row in otherLores)
        (row.read(db.loreEntities.name) ?? '').trim(),
    }..remove('');

    // 5. 加载故事作品、章节与分镜场景 (STORY-004)
    final works = await db.storyDao.getWorksByWorld(worldId);
    final workIds = works.map((w) => w.id).toList();
    final chapters = await db.storyDao.getChaptersByWorks(workIds);
    final chapterIds = chapters.map((c) => c.id).toList();
    final scenes = await db.storyDao.getScenesByChapters(chapterIds);

    return ConsistencyContext(
      worldId: worldId,
      targetCharacterId: targetCharacterId,
      characters: characters,
      relations: relations,
      events: events,
      lores: lores,
      galleries: galleries,
      works: works,
      chapters: chapters,
      scenes: scenes,
      otherWorldEntityNames: otherEntityNames,
    );
  }
}

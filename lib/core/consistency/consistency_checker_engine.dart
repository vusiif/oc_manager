import '../../data/database/app_database.dart';
import 'consistency_models.dart';
import 'consistency_rule.dart';
import 'consistency_rules.dart';

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
    ]);
    return reg;
  }

  /// 执行整套一致性逻辑规则检查（全世界观模式）
  Future<ConsistencyReport> checkWorld(
    int worldId, {
    Set<String>? enabledRuleIds,
  }) async {
    final context = await _buildContext(worldId: worldId);
    final activeRules = registry.getActiveRules(enabledRuleIds);

    final allIssues = <ConsistencyIssue>[];
    for (final rule in activeRules) {
      final issues = await rule.evaluate(context);
      allIssues.addAll(issues);
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
  }) async {
    final context = await _buildContext(
      worldId: worldId,
      targetCharacterId: characterId,
    );
    final activeRules = registry.getActiveRules(enabledRuleIds);

    final issues = <ConsistencyIssue>[];
    for (final rule in activeRules) {
      final ruleIssues = await rule.evaluate(context);
      issues.addAll(ruleIssues);
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

    return ConsistencyContext(
      worldId: worldId,
      targetCharacterId: targetCharacterId,
      characters: characters,
      relations: relations,
      events: events,
      lores: lores,
      galleries: galleries,
      otherWorldEntityNames: otherEntityNames,
    );
  }
}

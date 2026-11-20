import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/consistency/consistency_checker_engine.dart';
import 'database_provider.dart';

final consistencyEngineProvider = Provider<ConsistencyCheckerEngine>((ref) {
  final db = ref.watch(databaseProvider);
  return ConsistencyCheckerEngine(db);
});

/// 规则启停配置管理 (CONSIST-006)
class WorldEnabledRulesNotifier extends StateNotifier<Set<String>> {
  WorldEnabledRulesNotifier()
    : super({
        'RULE_TIMELINE_LIFESPAN',
        'RULE_RELATION_INTEGRITY',
        'RULE_WIKI_LINK_INTEGRITY',
        'RULE_MEDIA_FILE_INTEGRITY',
        'RULE_COMPLETENESS',
      });

  void toggleRule(String ruleId) {
    if (state.contains(ruleId)) {
      state = Set<String>.from(state)..remove(ruleId);
    } else {
      state = Set<String>.from(state)..add(ruleId);
    }
  }

  void resetDefaults() {
    state = {
      'RULE_TIMELINE_LIFESPAN',
      'RULE_RELATION_INTEGRITY',
      'RULE_WIKI_LINK_INTEGRITY',
      'RULE_MEDIA_FILE_INTEGRITY',
      'RULE_COMPLETENESS',
    };
  }
}

final worldEnabledRulesProvider =
    StateNotifierProvider.family<WorldEnabledRulesNotifier, Set<String>, int>(
      (ref, worldId) => WorldEnabledRulesNotifier(),
    );

/// Issue 处理状态枚举 (CONSIST-005: 检查结果工作台)
enum IssueHandlingStatus {
  active, // 待处理
  ignored, // 已忽略 (不参与健康指数扣分)
  resolved, // 创作者标记已解决
}

/// 维护世界观维度 Issue 的忽略/解决状态 (只读工作台，零源数据污染)
class IssueStatusNotifier
    extends StateNotifier<Map<String, IssueHandlingStatus>> {
  IssueStatusNotifier() : super({});

  void setStatus(String issueId, IssueHandlingStatus status) {
    if (status == IssueHandlingStatus.active) {
      final updated = Map<String, IssueHandlingStatus>.from(state)
        ..remove(issueId);
      state = updated;
    } else {
      state = {...state, issueId: status};
    }
  }

  void ignore(String issueId) =>
      setStatus(issueId, IssueHandlingStatus.ignored);
  void resolve(String issueId) =>
      setStatus(issueId, IssueHandlingStatus.resolved);
  void reset(String issueId) => setStatus(issueId, IssueHandlingStatus.active);
  void clearAll() => state = {};
}

final worldIssueStatusProvider =
    StateNotifierProvider.family<
      IssueStatusNotifier,
      Map<String, IssueHandlingStatus>,
      int
    >((ref, worldId) => IssueStatusNotifier());

final consistencyReportProvider = FutureProvider.family<ConsistencyReport, int>(
  (ref, worldId) async {
    final engine = ref.watch(consistencyEngineProvider);
    final enabledRules = ref.watch(worldEnabledRulesProvider(worldId));
    return engine.checkWorld(worldId, enabledRuleIds: enabledRules);
  },
);

/// 单角色一致性问题诊断 Provider (CONSIST-001)
final characterConsistencyIssuesProvider =
    FutureProvider.family<
      List<ConsistencyIssue>,
      ({int worldId, int characterId})
    >((ref, arg) async {
      final engine = ref.watch(consistencyEngineProvider);
      final enabledRules = ref.watch(worldEnabledRulesProvider(arg.worldId));
      return engine.checkCharacter(
        arg.worldId,
        arg.characterId,
        enabledRuleIds: enabledRules,
      );
    });

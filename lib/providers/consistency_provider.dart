import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/consistency/consistency_checker_engine.dart';
import 'database_provider.dart';

final consistencyEngineProvider = Provider<ConsistencyCheckerEngine>((ref) {
  final db = ref.watch(databaseProvider);
  return ConsistencyCheckerEngine(db);
});

final consistencyConfigServiceProvider = Provider<ConsistencyConfigService>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  return ConsistencyConfigService(db);
});

/// 默认启用的全部诊断规则稳定 ID 集合 (CONSIST-001 ~ CONSIST-006)
const kDefaultEnabledRuleIds = {
  'RULE_TIMELINE_LIFESPAN',
  'RULE_RELATION_INTEGRITY',
  'RULE_WIKI_LINK_INTEGRITY',
  'RULE_MEDIA_FILE_INTEGRITY',
  'RULE_COMPLETENESS',
  'RULE_STORY_TIMELINE',
};

Map<String, RuleConfig> createDefaultRuleConfigs() => {
  for (final id in kDefaultEnabledRuleIds) id: const RuleConfig(enabled: true),
};

/// 规则偏好配置管理 (CONSIST-006: 规则启停与严重度定制持久化)
class WorldRuleConfigsNotifier extends StateNotifier<Map<String, RuleConfig>> {
  final ConsistencyConfigService? _service;
  final int? _worldId;

  WorldRuleConfigsNotifier({
    ConsistencyConfigService? service,
    int? worldId,
    Map<String, RuleConfig>? initialConfigs,
  }) : _service = service,
       _worldId = worldId,
       super(initialConfigs ?? createDefaultRuleConfigs()) {
    if (_service != null && _worldId != null && initialConfigs == null) {
      _loadFromDisk();
    }
  }

  Future<void> _loadFromDisk() async {
    if (_service == null || _worldId == null) return;
    final saved = await _service.loadRuleConfigs(_worldId);
    if (saved.isNotEmpty) {
      final merged = createDefaultRuleConfigs()..addAll(saved);
      state = merged;
    }
  }

  void toggleRule(String ruleId) {
    final current = state[ruleId] ?? const RuleConfig(enabled: true);
    final updated = Map<String, RuleConfig>.from(state);
    updated[ruleId] = current.copyWith(enabled: !current.enabled);
    state = updated;
    _persist();
  }

  void setRuleSeverity(String ruleId, IssueSeverity? customSeverity) {
    final current = state[ruleId] ?? const RuleConfig(enabled: true);
    final updated = Map<String, RuleConfig>.from(state);
    updated[ruleId] = current.copyWith(
      customSeverity: customSeverity,
      clearCustomSeverity: customSeverity == null,
    );
    state = updated;
    _persist();
  }

  void resetDefaults() {
    state = createDefaultRuleConfigs();
    _persist();
  }

  void _persist() {
    final service = _service;
    final worldId = _worldId;
    if (service != null && worldId != null) {
      service.saveRuleConfigs(worldId, state);
    }
  }
}

final worldRuleConfigsProvider =
    StateNotifierProvider.family<
      WorldRuleConfigsNotifier,
      Map<String, RuleConfig>,
      int
    >((ref, worldId) {
      final service = ref.watch(consistencyConfigServiceProvider);
      return WorldRuleConfigsNotifier(service: service, worldId: worldId);
    });

/// 规则启停配置管理兼容类 (CONSIST-006)
class WorldEnabledRulesNotifier extends StateNotifier<Set<String>> {
  WorldEnabledRulesNotifier([Set<String>? initial])
    : super(initial ?? Set<String>.from(kDefaultEnabledRuleIds));

  void toggleRule(String ruleId) {
    if (state.contains(ruleId)) {
      state = Set<String>.from(state)..remove(ruleId);
    } else {
      state = Set<String>.from(state)..add(ruleId);
    }
  }

  void resetDefaults() {
    state = Set<String>.from(kDefaultEnabledRuleIds);
  }
}

/// 导出启用的规则 ID 集合 Provider (派生自持久化的 worldRuleConfigsProvider)
final worldEnabledRulesProvider = Provider.family<Set<String>, int>((
  ref,
  worldId,
) {
  final configs = ref.watch(worldRuleConfigsProvider(worldId));
  return configs.entries
      .where((e) => e.value.enabled)
      .map((e) => e.key)
      .toSet();
});

/// Issue 处理状态枚举 (CONSIST-005: 检查结果工作台)
enum IssueHandlingStatus {
  active, // 待处理
  ignored, // 已忽略 (不参与健康指数扣分)
  resolved, // 创作者标记已解决
}

/// 维护世界观维度 Issue 的忽略/解决状态 (CONSIST-005 & CONSIST-006: 数据库持久化)
class IssueStatusNotifier
    extends StateNotifier<Map<String, IssueHandlingStatus>> {
  final ConsistencyConfigService? _service;
  final int? _worldId;

  IssueStatusNotifier({
    ConsistencyConfigService? service,
    int? worldId,
    Map<String, IssueHandlingStatus>? initialStatuses,
  }) : _service = service,
       _worldId = worldId,
       super(initialStatuses ?? {}) {
    if (_service != null && _worldId != null && initialStatuses == null) {
      _loadFromDisk();
    }
  }

  Future<void> _loadFromDisk() async {
    final service = _service;
    final worldId = _worldId;
    if (service == null || worldId == null) return;
    final saved = await service.loadIssueStatuses(worldId);
    if (saved.isNotEmpty) {
      state = saved;
    }
  }

  void setStatus(String issueId, IssueHandlingStatus status) {
    if (status == IssueHandlingStatus.active) {
      final updated = Map<String, IssueHandlingStatus>.from(state)
        ..remove(issueId);
      state = updated;
    } else {
      state = {...state, issueId: status};
    }
    _persist();
  }

  void ignore(String issueId) =>
      setStatus(issueId, IssueHandlingStatus.ignored);
  void resolve(String issueId) =>
      setStatus(issueId, IssueHandlingStatus.resolved);
  void reset(String issueId) => setStatus(issueId, IssueHandlingStatus.active);
  void clearAll() {
    state = {};
    _persist();
  }

  void _persist() {
    final service = _service;
    final worldId = _worldId;
    if (service != null && worldId != null) {
      service.saveIssueStatuses(worldId, state);
    }
  }
}

final worldIssueStatusProvider =
    StateNotifierProvider.family<
      IssueStatusNotifier,
      Map<String, IssueHandlingStatus>,
      int
    >((ref, worldId) {
      final service = ref.watch(consistencyConfigServiceProvider);
      return IssueStatusNotifier(service: service, worldId: worldId);
    });

final consistencyReportProvider = FutureProvider.family<ConsistencyReport, int>(
  (ref, worldId) async {
    final engine = ref.watch(consistencyEngineProvider);
    final configs = ref.watch(worldRuleConfigsProvider(worldId));
    return engine.checkWorld(worldId, ruleConfigs: configs);
  },
);

/// 单角色一致性问题诊断 Provider (CONSIST-001)
final characterConsistencyIssuesProvider =
    FutureProvider.family<
      List<ConsistencyIssue>,
      ({int worldId, int characterId})
    >((ref, arg) async {
      final engine = ref.watch(consistencyEngineProvider);
      final configs = ref.watch(worldRuleConfigsProvider(arg.worldId));
      return engine.checkCharacter(
        arg.worldId,
        arg.characterId,
        ruleConfigs: configs,
      );
    });

import 'consistency_models.dart';

/// 设定一致性规则抽象基类 (CONSIST-001)
abstract class ConsistencyRule {
  /// 规则稳定唯一 ID，例如 'RULE_TIMELINE_LIFESPAN'
  String get ruleId;

  /// 规则名称，例如 '时间轴与生卒年时序检查'
  String get name;

  /// 规则详细说明
  String get description;

  /// 规则所属领域分类
  IssueCategory get category;

  /// 规则默认严重级别
  IssueSeverity get defaultSeverity;

  /// 执行规则评估。纯计算逻辑，不产生副作用，不修改源数据。
  Future<List<ConsistencyIssue>> evaluate(ConsistencyContext context);
}

/// 规则注册表与调度中心 (CONSIST-001)
class ConsistencyRuleRegistry {
  final Map<String, ConsistencyRule> _rules = {};

  ConsistencyRuleRegistry();

  /// 注册规则
  void register(ConsistencyRule rule) {
    _rules[rule.ruleId] = rule;
  }

  /// 批量注册规则
  void registerAll(Iterable<ConsistencyRule> rules) {
    for (final r in rules) {
      register(r);
    }
  }

  /// 注销规则
  void unregister(String ruleId) {
    _rules.remove(ruleId);
  }

  /// 获取所有已注册规则
  List<ConsistencyRule> get allRules => _rules.values.toList();

  /// 根据 ID 获取单条规则
  ConsistencyRule? getRule(String ruleId) => _rules[ruleId];

  /// 根据启用的 ruleId 过滤规则列表；若 enabledRuleIds 为 null，返回全部规则
  List<ConsistencyRule> getActiveRules([Set<String>? enabledRuleIds]) {
    if (enabledRuleIds == null) {
      return allRules;
    }
    return _rules.values
        .where((rule) => enabledRuleIds.contains(rule.ruleId))
        .toList();
  }
}

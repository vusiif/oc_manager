import 'dart:convert';
import '../../data/database/app_database.dart';
import '../../providers/consistency_provider.dart' show IssueHandlingStatus;
import 'consistency_models.dart';

/// Service managing persistence of consistency rule preferences and issue statuses (CONSIST-006).
class ConsistencyConfigService {
  final AppDatabase db;

  const ConsistencyConfigService(this.db);

  /// Key format for storing rule preferences for a world in Settings table.
  static String ruleConfigsKey(int worldId) => 'consistency_rule_cfg_w$worldId';

  /// Key format for storing issue handling statuses for a world in Settings table.
  static String issueStatusesKey(int worldId) =>
      'consistency_issue_sts_w$worldId';

  /// Loads rule configs (enabled status & custom severity overrides) for a given [worldId].
  Future<Map<String, RuleConfig>> loadRuleConfigs(int worldId) async {
    final raw = await db.settingsDao.getValue(ruleConfigsKey(worldId));
    if (raw == null || raw.trim().isEmpty) {
      return {};
    }
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded.map(
          (k, v) => MapEntry(
            k,
            RuleConfig.fromJson(
              v is Map<String, dynamic> ? v : <String, dynamic>{},
            ),
          ),
        );
      }
    } catch (_) {}
    return {};
  }

  /// Persists rule configs for a given [worldId].
  Future<void> saveRuleConfigs(
    int worldId,
    Map<String, RuleConfig> configs,
  ) async {
    final map = configs.map((k, v) => MapEntry(k, v.toJson()));
    await db.settingsDao.setValue(ruleConfigsKey(worldId), jsonEncode(map));
  }

  /// Loads issue handling statuses (ignored / resolved) for a given [worldId].
  Future<Map<String, IssueHandlingStatus>> loadIssueStatuses(
    int worldId,
  ) async {
    final raw = await db.settingsDao.getValue(issueStatusesKey(worldId));
    if (raw == null || raw.trim().isEmpty) {
      return {};
    }
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final result = <String, IssueHandlingStatus>{};
        for (final entry in decoded.entries) {
          final status = IssueHandlingStatus.values.asNameMap()[entry.value];
          if (status != null && status != IssueHandlingStatus.active) {
            result[entry.key] = status;
          }
        }
        return result;
      }
    } catch (_) {}
    return {};
  }

  /// Persists issue handling statuses for a given [worldId].
  /// Only non-active statuses (ignored / resolved) are stored to conserve space.
  Future<void> saveIssueStatuses(
    int worldId,
    Map<String, IssueHandlingStatus> statuses,
  ) async {
    final filtered = <String, String>{};
    for (final entry in statuses.entries) {
      if (entry.value != IssueHandlingStatus.active) {
        filtered[entry.key] = entry.value.name;
      }
    }
    await db.settingsDao.setValue(
      issueStatusesKey(worldId),
      jsonEncode(filtered),
    );
  }

  /// Resets all rule configs and issue statuses for a given [worldId].
  Future<void> resetWorldConfigs(int worldId) async {
    await db.settingsDao.setValue(ruleConfigsKey(worldId), '{}');
    await db.settingsDao.setValue(issueStatusesKey(worldId), '{}');
  }
}

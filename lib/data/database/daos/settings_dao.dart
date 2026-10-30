import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/settings.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [Settings, BasicInfoFields])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  // 获取设置值（按最新 ID 降序，确保获取最新有效设置）
  Future<String?> getValue(String key) async {
    final query = select(settings)
      ..where((s) => s.key.equals(key))
      ..orderBy([(s) => OrderingTerm.desc(s.id)])
      ..limit(1);
    final rows = await query.get();
    return rows.isNotEmpty ? rows.first.value : null;
  }

  // 设置值（存在则更新最新记录并清理历史多余条目，不存在则插入新记录）
  Future<void> setValue(String key, String value) async {
    final existing = await (select(settings)
          ..where((s) => s.key.equals(key))
          ..orderBy([(s) => OrderingTerm.desc(s.id)]))
        .get();
    if (existing.isNotEmpty) {
      final latestId = existing.first.id;
      await (update(settings)..where((s) => s.id.equals(latestId))).write(
        SettingsCompanion(
          value: Value(value),
          updatedAt: Value(DateTime.now()),
        ),
      );
      if (existing.length > 1) {
        await (delete(settings)
              ..where((s) => s.key.equals(key) & s.id.isNotValue(latestId)))
            .go();
      }
    } else {
      await into(settings).insert(
        SettingsCompanion.insert(
          key: key,
          value: value,
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  // 获取所有设置
  Future<Map<String, String>> getAllSettings() async {
    final rows = await (select(settings)..orderBy([(s) => OrderingTerm.asc(s.id)])).get();
    final result = <String, String>{};
    for (final row in rows) {
      result[row.key] = row.value;
    }
    return result;
  }

  // 获取基本字段列表
  Future<List<BasicInfoField>> getBasicInfoFields() async {
    return (select(basicInfoFields)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();
  }

  // 更新基本字段
  Future<void> updateBasicInfoField(int id, {bool? isVisible, int? sortOrder}) async {
    await (update(basicInfoFields)..where((t) => t.id.equals(id))).write(
      BasicInfoFieldsCompanion(
        isVisible: isVisible != null ? Value(isVisible) : const Value.absent(),
        sortOrder: sortOrder != null ? Value(sortOrder) : const Value.absent(),
      ),
    );
  }

  // 添加基本字段
  Future<void> addBasicInfoField(String fieldName, {int sortOrder = 0}) async {
    await into(basicInfoFields).insert(
      BasicInfoFieldsCompanion.insert(
        fieldName: fieldName,
        sortOrder: Value(sortOrder),
      ),
    );
  }

  // 删除基本字段
  Future<void> deleteBasicInfoField(int id) async {
    await (delete(basicInfoFields)..where((t) => t.id.equals(id))).go();
  }

  // 初始化默认字段
  Future<void> initDefaultFields() async {
    final existing = await getBasicInfoFields();
    if (existing.isEmpty) {
      await batch((batch) {
        batch.insertAll(basicInfoFields, [
          BasicInfoFieldsCompanion.insert(fieldName: '名称', sortOrder: const Value(0)),
          BasicInfoFieldsCompanion.insert(fieldName: '性别', sortOrder: const Value(1)),
          BasicInfoFieldsCompanion.insert(fieldName: '状态', sortOrder: const Value(2)),
          BasicInfoFieldsCompanion.insert(fieldName: '创建时间', sortOrder: const Value(3)),
        ]);
      });
    }
  }
}

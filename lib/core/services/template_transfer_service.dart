import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../providers/database_provider.dart';
import '../../providers/template_provider.dart';

/// Conflict strategy when importing templates with matching names.
enum TemplateConflictPolicy { renameCopy, overwrite, skip }

/// Serializable field definition inside a template share bundle.
class TemplateFieldSpec {
  final String fieldName;
  final String fieldType;
  final String? defaultValue;
  final int sortOrder;

  const TemplateFieldSpec({
    required this.fieldName,
    required this.fieldType,
    this.defaultValue,
    this.sortOrder = 0,
  });

  static const supportedTypes = {
    'text',
    'number',
    'long_text',
    'select',
    'multi_select',
  };

  Map<String, dynamic> toJson() => {
    'fieldName': fieldName,
    'fieldType': fieldType,
    if (defaultValue != null) 'defaultValue': defaultValue,
    'sortOrder': sortOrder,
  };

  static TemplateFieldSpec? fromJson(Map<String, dynamic> map) {
    final rawName = (map['fieldName'] as String?)?.trim() ?? '';
    if (rawName.isEmpty) return null;
    final name = rawName.length > 50 ? rawName.substring(0, 50) : rawName;
    final rawType = (map['fieldType'] as String?) ?? 'text';
    final type = supportedTypes.contains(rawType) ? rawType : 'text';
    final defaultValue = map['defaultValue'] as String?;
    final sortOrder = (map['sortOrder'] as int?) ?? 0;

    return TemplateFieldSpec(
      fieldName: name,
      fieldType: type,
      defaultValue: defaultValue,
      sortOrder: sortOrder,
    );
  }
}

/// Serializable template definition (contains only schema, zero private OC data).
class TemplatePackageItem {
  final String name;
  final String description;
  final List<TemplateFieldSpec> fields;

  const TemplatePackageItem({
    required this.name,
    this.description = '',
    required this.fields,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    if (description.isNotEmpty) 'description': description,
    'fields': fields.map((f) => f.toJson()).toList(),
  };

  static TemplatePackageItem? fromJson(Map<String, dynamic> map) {
    final rawName = (map['name'] as String?)?.trim() ?? '';
    if (rawName.isEmpty) return null;
    final name = rawName.length > 100 ? rawName.substring(0, 100) : rawName;
    final rawFields = map['fields'];
    final fields = <TemplateFieldSpec>[];
    if (rawFields is List) {
      for (final f in rawFields) {
        if (f is Map) {
          final parsed = TemplateFieldSpec.fromJson(
            Map<String, dynamic>.from(f),
          );
          if (parsed != null) fields.add(parsed);
        }
      }
    }
    return TemplatePackageItem(
      name: name,
      description: (map['description'] as String?) ?? '',
      fields: fields,
    );
  }
}

/// Preview result produced before committing a template import.
class TemplateImportPreview {
  final int formatVersion;
  final List<TemplatePackageItem> templates;
  final Set<String> conflictingNames;

  const TemplateImportPreview({
    required this.formatVersion,
    required this.templates,
    required this.conflictingNames,
  });

  bool get hasConflicts => conflictingNames.isNotEmpty;
}

/// Pure transfer logic and official preset catalog for character templates.
class TemplateTransferService {
  static const int currentFormatVersion = 1;

  /// Official starter preset templates (TPL-002).
  static const List<TemplatePackageItem> officialPresets = [
    TemplatePackageItem(
      name: '奇幻冒险者档案',
      description: '适用于剑与魔法、异世界冒险或西幻设定角色',
      fields: [
        TemplateFieldSpec(
          fieldName: '种族 / 血统',
          fieldType: 'text',
          sortOrder: 0,
        ),
        TemplateFieldSpec(
          fieldName: '职业 / 位阶',
          fieldType: 'text',
          sortOrder: 1,
        ),
        TemplateFieldSpec(
          fieldName: '元素 / 魔力属性',
          fieldType: 'text',
          sortOrder: 2,
        ),
        TemplateFieldSpec(
          fieldName: '惯用武器 / 法器',
          fieldType: 'text',
          sortOrder: 3,
        ),
        TemplateFieldSpec(
          fieldName: '性格弱点与忌讳',
          fieldType: 'long_text',
          sortOrder: 4,
        ),
      ],
    ),
    TemplatePackageItem(
      name: '现代都市日常',
      description: '适用于现代群像、校园或都市悬疑题材角色',
      fields: [
        TemplateFieldSpec(fieldName: '年龄', fieldType: 'number', sortOrder: 0),
        TemplateFieldSpec(
          fieldName: '职业 / 学校',
          fieldType: 'text',
          sortOrder: 1,
        ),
        TemplateFieldSpec(
          fieldName: '身高 (cm)',
          fieldType: 'number',
          sortOrder: 2,
        ),
        TemplateFieldSpec(
          fieldName: '外貌与穿搭特征',
          fieldType: 'long_text',
          sortOrder: 3,
        ),
        TemplateFieldSpec(fieldName: '兴趣爱好', fieldType: 'text', sortOrder: 4),
      ],
    ),
    TemplatePackageItem(
      name: '科幻星际设定',
      description: '适用于赛博朋克、太空歌剧或近未来废土角色',
      fields: [
        TemplateFieldSpec(
          fieldName: '出身星系 / 地区',
          fieldType: 'text',
          sortOrder: 0,
        ),
        TemplateFieldSpec(
          fieldName: '义体 / 基因改造',
          fieldType: 'long_text',
          sortOrder: 1,
        ),
        TemplateFieldSpec(fieldName: '专精领域', fieldType: 'text', sortOrder: 2),
        TemplateFieldSpec(fieldName: '威胁评估等级', fieldType: 'text', sortOrder: 3),
      ],
    ),
    TemplatePackageItem(
      name: 'TRPG 跑团调查员',
      description: '适用于 CoC / D&D 等桌面跑团角色卡补充背景',
      fields: [
        TemplateFieldSpec(fieldName: '时代背景', fieldType: 'text', sortOrder: 0),
        TemplateFieldSpec(fieldName: '调查员职业', fieldType: 'text', sortOrder: 1),
        TemplateFieldSpec(
          fieldName: '核心特质与执念',
          fieldType: 'long_text',
          sortOrder: 2,
        ),
        TemplateFieldSpec(fieldName: '随身重要物品', fieldType: 'text', sortOrder: 3),
        TemplateFieldSpec(
          fieldName: '精神创伤 / 恐惧症',
          fieldType: 'text',
          sortOrder: 4,
        ),
      ],
    ),
    TemplatePackageItem(
      name: '核心反派 / 对立角色',
      description: '专门梳理反派人物的动机、资源与宿敌线',
      fields: [
        TemplateFieldSpec(
          fieldName: '核心动机',
          fieldType: 'long_text',
          sortOrder: 0,
        ),
        TemplateFieldSpec(
          fieldName: '行动准则与底线',
          fieldType: 'text',
          sortOrder: 1,
        ),
        TemplateFieldSpec(
          fieldName: '掌控资源与势力',
          fieldType: 'long_text',
          sortOrder: 2,
        ),
        TemplateFieldSpec(
          fieldName: '结局伏笔',
          fieldType: 'long_text',
          sortOrder: 3,
        ),
      ],
    ),
  ];

  /// Encodes templates into a portable JSON string.
  static String encodeBundle(List<TemplatePackageItem> items) {
    return const JsonEncoder.withIndent('  ').convert({
      'format': 'oc_manager_templates',
      'version': currentFormatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'templates': items.map((e) => e.toJson()).toList(),
    });
  }

  /// Parses JSON content and computes conflict preview against [existingNames].
  static TemplateImportPreview inspectJson(
    String rawJson,
    Set<String> existingNames,
  ) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map) {
      throw const FormatException('模板文件格式无效：根节点必须是 JSON 对象');
    }
    final version = (decoded['version'] as int?) ?? 1;
    final rawTemplates = decoded['templates'];
    if (rawTemplates is! List) {
      throw const FormatException('模板文件格式无效：缺少 templates 列表');
    }

    final parsed = <TemplatePackageItem>[];
    final conflicts = <String>{};
    for (final entry in rawTemplates) {
      if (entry is Map) {
        final item = TemplatePackageItem.fromJson(
          Map<String, dynamic>.from(entry),
        );
        if (item != null) {
          parsed.add(item);
          if (existingNames.contains(item.name)) {
            conflicts.add(item.name);
          }
        }
      }
    }
    if (parsed.isEmpty) {
      throw const FormatException('未在文件中解析到有效的人物模板');
    }

    return TemplateImportPreview(
      formatVersion: version,
      templates: parsed,
      conflictingNames: conflicts,
    );
  }

  /// Generates a unique copy name when [TemplateConflictPolicy.renameCopy] is used.
  static String resolveUniqueName(String baseName, Set<String> occupiedNames) {
    if (!occupiedNames.contains(baseName)) return baseName;
    var index = 1;
    while (true) {
      final candidate = index == 1 ? '$baseName (导入)' : '$baseName (导入 $index)';
      if (!occupiedNames.contains(candidate)) return candidate;
      index++;
    }
  }

  /// Imports [items] into global templates table under a single transaction.
  static Future<int> importTemplates({
    required WidgetRef ref,
    required List<TemplatePackageItem> items,
    required TemplateConflictPolicy policy,
  }) async {
    final db = ref.read(databaseProvider);
    final count = await importTemplatesToDb(
      db: db,
      items: items,
      policy: policy,
    );
    ref.invalidate(globalTemplatesProvider);
    return count;
  }

  /// Imports [items] directly into [db] without requiring a Riverpod [WidgetRef].
  static Future<int> importTemplatesToDb({
    required AppDatabase db,
    required List<TemplatePackageItem> items,
    required TemplateConflictPolicy policy,
  }) async {
    final dao = db.templateDao;
    final existing = await dao.getGlobalTemplates();
    final existingByName = {for (final t in existing) t.name: t};
    final occupiedNames = existingByName.keys.toSet();
    var importedCount = 0;

    await db.transaction(() async {
      for (final item in items) {
        final conflict = existingByName[item.name];
        if (conflict != null) {
          if (policy == TemplateConflictPolicy.skip) continue;
          if (policy == TemplateConflictPolicy.overwrite) {
            await dao.deleteAllTemplateFields(conflict.id);
            for (var i = 0; i < item.fields.length; i++) {
              final f = item.fields[i];
              await dao.createTemplateField(
                TemplateFieldsCompanion(
                  templateId: Value(conflict.id),
                  fieldName: Value(f.fieldName),
                  fieldType: Value(f.fieldType),
                  defaultValue: Value(f.defaultValue),
                  sortOrder: Value(f.sortOrder > 0 ? f.sortOrder : i),
                ),
              );
            }
            importedCount++;
            continue;
          }
        }

        final finalName = resolveUniqueName(item.name, occupiedNames);
        occupiedNames.add(finalName);
        final newId = await dao.createTemplate(
          TemplatesCompanion(name: Value(finalName)),
        );
        for (var i = 0; i < item.fields.length; i++) {
          final f = item.fields[i];
          await dao.createTemplateField(
            TemplateFieldsCompanion(
              templateId: Value(newId),
              fieldName: Value(f.fieldName),
              fieldType: Value(f.fieldType),
              defaultValue: Value(f.defaultValue),
              sortOrder: Value(f.sortOrder > 0 ? f.sortOrder : i),
            ),
          );
        }
        importedCount++;
      }
    });

    return importedCount;
  }
}

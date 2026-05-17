import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../data/database/app_database.dart';
import 'database_provider.dart';

final templatesByWorldProvider =
    FutureProvider.family<List<Template>, int>((ref, worldId) {
  return ref.watch(templateDaoProvider).getTemplatesByWorld(worldId);
});

final globalTemplatesProvider = FutureProvider<List<Template>>((ref) {
  return ref.watch(templateDaoProvider).getGlobalTemplates();
});

final templateFieldsProvider =
    FutureProvider.family<List<TemplateField>, int>((ref, templateId) {
  return ref.watch(templateDaoProvider).getTemplateFields(templateId);
});

final templateActionsProvider = Provider((ref) => TemplateActions(ref));

class TemplateActions {
  final Ref _ref;

  TemplateActions(this._ref);

  Future<int> create({
    required String name,
    int? worldId,
  }) async {
    return _ref.read(templateDaoProvider).createTemplate(
          TemplatesCompanion(
            name: Value(name),
            worldId: Value(worldId),
          ),
        );
  }

  Future<bool> update(int id, String name) async {
    final template = await _ref.read(templateDaoProvider).getTemplateById(id);
    return _ref.read(templateDaoProvider).updateTemplate(
          TemplatesCompanion(
            id: Value(id),
            name: Value(name),
            worldId: Value(template.worldId),
          ),
        );
  }

  Future<void> delete(int id) async {
    await _ref.read(templateDaoProvider).deleteAllTemplateFields(id);
    await _ref.read(templateDaoProvider).deleteTemplate(id);
  }

  Future<int> addField({
    required int templateId,
    required String fieldName,
    required String fieldType,
    String? defaultValue,
    int sortOrder = 0,
  }) async {
    return _ref.read(templateDaoProvider).createTemplateField(
          TemplateFieldsCompanion(
            templateId: Value(templateId),
            fieldName: Value(fieldName),
            fieldType: Value(fieldType),
            defaultValue: Value(defaultValue),
            sortOrder: Value(sortOrder),
          ),
        );
  }

  Future<void> removeField(int fieldId) async {
    await _ref.read(templateDaoProvider).deleteTemplateField(fieldId);
  }
}

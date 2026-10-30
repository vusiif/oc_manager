import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/templates.dart';

part 'template_dao.g.dart';

@DriftAccessor(tables: [Templates, TemplateFields])
class TemplateDao extends DatabaseAccessor<AppDatabase>
    with _$TemplateDaoMixin {
  TemplateDao(super.db);

  Future<List<Template>> getTemplatesByWorld(int worldId) =>
      (select(templates)..where((t) => t.worldId.equals(worldId))).get();

  Future<List<Template>> getGlobalTemplates() =>
      (select(templates)..where((t) => t.worldId.isNull())).get();

  Future<Template> getTemplateById(int id) =>
      (select(templates)..where((t) => t.id.equals(id))).getSingle();

  Future<int> createTemplate(TemplatesCompanion entry) =>
      into(templates).insert(entry);

  Future<bool> updateTemplate(TemplatesCompanion entry) =>
      update(templates).replace(entry);

  Future<int> deleteTemplate(int id) {
    return transaction(() async {
      await (delete(templateFields)..where((t) => t.templateId.equals(id))).go();
      return (delete(templates)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<List<TemplateField>> getTemplateFields(int templateId) =>
      (select(templateFields)
            ..where((t) => t.templateId.equals(templateId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Future<int> createTemplateField(TemplateFieldsCompanion entry) =>
      into(templateFields).insert(entry);

  Future<void> updateTemplateField(TemplateFieldsCompanion entry) =>
      update(templateFields).replace(entry);

  Future<int> deleteTemplateField(int id) =>
      (delete(templateFields)..where((t) => t.id.equals(id))).go();

  Future<void> deleteAllTemplateFields(int templateId) =>
      (delete(templateFields)
            ..where((t) => t.templateId.equals(templateId)))
          .go();
}

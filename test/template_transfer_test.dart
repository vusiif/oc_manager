import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oc_manager/core/services/template_transfer_service.dart';
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/features/template/template_management_page.dart';
import 'package:oc_manager/providers/database_provider.dart';

void main() {
  group('TemplateTransferService Unit Tests (TPL-001 & TPL-002)', () {
    test('officialPresets contains 5 valid starter templates', () {
      expect(TemplateTransferService.officialPresets.length, 5);
      for (final preset in TemplateTransferService.officialPresets) {
        expect(preset.name, isNotEmpty);
        expect(preset.fields, isNotEmpty);
        for (final f in preset.fields) {
          expect(
            TemplateFieldSpec.supportedTypes.contains(f.fieldType),
            isTrue,
          );
        }
      }
    });

    test('encodeBundle and inspectJson roundtrip with conflict detection', () {
      final raw = TemplateTransferService.encodeBundle(
        TemplateTransferService.officialPresets.take(2).toList(),
      );
      final preview = TemplateTransferService.inspectJson(raw, {'奇幻冒险者档案'});
      expect(preview.formatVersion, 1);
      expect(preview.templates.length, 2);
      expect(preview.hasConflicts, isTrue);
      expect(preview.conflictingNames, {'奇幻冒险者档案'});
    });

    test('resolveUniqueName generates non-colliding copy names', () {
      final occupied = {'测试模板', '测试模板 (导入)'};
      expect(
        TemplateTransferService.resolveUniqueName('测试模板', occupied),
        '测试模板 (导入 2)',
      );
      expect(
        TemplateTransferService.resolveUniqueName('全新模板', occupied),
        '全新模板',
      );
    });

    test('unknown legacy field types gracefully fallback to text', () {
      const legacyJson = '''
      {
        "version": 1,
        "templates": [
          {
            "name": "旧版兼容模板",
            "fields": [
              {"fieldName": "自定义未知类型", "fieldType": "rich_markdown_v9"}
            ]
          }
        ]
      }
      ''';
      final preview = TemplateTransferService.inspectJson(legacyJson, {});
      expect(preview.templates.single.fields.single.fieldType, 'text');
    });

    test(
      'importTemplatesToDb handles renameCopy, overwrite and skip in DB',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);

        const base = [
          TemplatePackageItem(
            name: '星际模板',
            fields: [TemplateFieldSpec(fieldName: '母星', fieldType: 'text')],
          ),
        ];
        await TemplateTransferService.importTemplatesToDb(
          db: db,
          items: base,
          policy: TemplateConflictPolicy.renameCopy,
        );

        // Skip policy does not add duplicate
        final skipped = await TemplateTransferService.importTemplatesToDb(
          db: db,
          items: base,
          policy: TemplateConflictPolicy.skip,
        );
        expect(skipped, 0);

        // RenameCopy creates '(导入)' copy
        await TemplateTransferService.importTemplatesToDb(
          db: db,
          items: base,
          policy: TemplateConflictPolicy.renameCopy,
        );
        var all = await db.templateDao.getGlobalTemplates();
        expect(all.map((t) => t.name).toSet(), {'星际模板', '星际模板 (导入)'});

        // Overwrite replaces existing fields
        const updated = [
          TemplatePackageItem(
            name: '星际模板',
            fields: [
              TemplateFieldSpec(fieldName: '舰队编号', fieldType: 'number'),
              TemplateFieldSpec(fieldName: '军衔', fieldType: 'text'),
            ],
          ),
        ];
        await TemplateTransferService.importTemplatesToDb(
          db: db,
          items: updated,
          policy: TemplateConflictPolicy.overwrite,
        );
        all = await db.templateDao.getGlobalTemplates();
        final original = all.firstWhere((t) => t.name == '星际模板');
        final fields = await db.templateDao.getTemplateFields(original.id);
        expect(fields.map((f) => f.fieldName).toList(), ['舰队编号', '军衔']);
      },
    );

    testWidgets(
      'TemplateManagementPage opens official presets dialog and imports to DB',
      (tester) async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(db)],
            child: const MaterialApp(home: TemplateManagementPage()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('浏览官方预设模板'), findsOneWidget);
        await tester.tap(find.text('浏览官方预设模板'));
        await tester.pumpAndSettle();

        expect(find.text('官方预设模板库'), findsOneWidget);
        await tester.tap(find.text('导入已选 (5)'));
        await tester.pumpAndSettle();

        final globals = await db.templateDao.getGlobalTemplates();
        expect(globals.length, 5);
        expect(find.text('奇幻冒险者档案'), findsOneWidget);
      },
    );
  });
}

import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oc_manager/core/export/story/story_script_export_models.dart';
import 'package:oc_manager/core/export/story/story_script_export_service.dart';
import 'package:oc_manager/core/export/story/story_script_html_builder.dart';
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/features/story/story_export_dialog.dart';
import 'package:oc_manager/providers/database_provider.dart';

void main() {
  group('Story Script & Outline Export Tests (EXPORT-002)', () {
    late AppDatabase db;
    late StoryScriptExportService service;
    late Directory tempDir;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      service = StoryScriptExportService(db);
      tempDir = Directory.systemTemp.createTempSync('story_export_test_');

      // 1. Create World
      await db
          .into(db.worlds)
          .insert(
            WorldsCompanion.insert(
              id: const drift.Value(1),
              name: '提瓦特大陆',
              description: const drift.Value('七种元素交汇的幻想世界'),
            ),
          );

      // 2. Create Characters
      await db
          .into(db.characters)
          .insert(
            CharactersCompanion.insert(
              id: const drift.Value(101),
              worldId: 1,
              name: '空 (Aether)',
              gender: const drift.Value('男'),
              description: const drift.Value('异界的旅行者，寻找失散的双亲与妹妹。'),
            ),
          );
      await db
          .into(db.characters)
          .insert(
            CharactersCompanion.insert(
              id: const drift.Value(102),
              worldId: 1,
              name: '派蒙 (Paimon)',
              gender: const drift.Value('女'),
              description: const drift.Value('最好的向导兼应急食品。'),
            ),
          );
      await db
          .into(db.characters)
          .insert(
            CharactersCompanion.insert(
              id: const drift.Value(103),
              worldId: 1,
              name: '琴 (Jean)',
              gender: const drift.Value('女'),
              description: const drift.Value('西风骑士团代理团长。'),
            ),
          );

      // 3. Create StoryWork
      await db
          .into(db.storyWorks)
          .insert(
            StoryWorksCompanion.insert(
              id: const drift.Value(1),
              worldId: 1,
              title: '风之歌与旅行者',
              type: const drift.Value('轻小说'),
              summary: const drift.Value('降临提瓦特大陆的少年与神秘向导的旅途序章。'),
              status: const drift.Value('连载中'),
            ),
          );

      // 4. Create Chapters
      await db
          .into(db.storyChapters)
          .insert(
            StoryChaptersCompanion.insert(
              id: const drift.Value(1),
              workId: 1,
              title: '坠落星空与海滩苏醒',
              arcName: const drift.Value('序章·捕风的异乡人'),
              summary: const drift.Value('旅行者在星落湖畔钓起了派蒙。'),
              status: const drift.Value('已完结'),
              wordCount: const drift.Value(3200),
              sortOrder: const drift.Value(1),
            ),
          );
      await db
          .into(db.storyChapters)
          .insert(
            StoryChaptersCompanion.insert(
              id: const drift.Value(2),
              workId: 1,
              title: '风起之地与巨龙黑影',
              arcName: const drift.Value('序章·捕风的异乡人'),
              summary: const drift.Value('首次遭遇特瓦林与绿色身影。'),
              status: const drift.Value('草稿'),
              wordCount: const drift.Value(2800),
              sortOrder: const drift.Value(2),
            ),
          );

      // 5. Create Scenes
      await db
          .into(db.storyScenes)
          .insert(
            StoryScenesCompanion.insert(
              id: const drift.Value(1),
              chapterId: 1,
              title: '沙滩初会',
              summary: const drift.Value('从星落湖将派蒙拉上岸。'),
              content: const drift.Value(
                '派蒙甩着水花：“差一点就被淹死了啦！多亏了你！”\n空微微一笑：“应急食品而已。”',
              ),
              locationName: const drift.Value('星落湖沙滩'),
              timelineTime: const drift.Value('清晨'),
              mood: const drift.Value('轻松欢快'),
              povCharacterId: const drift.Value(101),
              characterIds: const drift.Value('[101, 102]'),
              sortOrder: const drift.Value(1),
            ),
          );
      await db
          .into(db.storyScenes)
          .insert(
            StoryScenesCompanion.insert(
              id: const drift.Value(2),
              chapterId: 2,
              title: '低语森林的低吼',
              summary: const drift.Value('巨龙降临与神秘吟游诗人。'),
              content: const drift.Value('巨大的双翼遮蔽了树冠，狂风卷起红叶。深红的泪滴结晶落在苔藓上。'),
              locationName: const drift.Value('低语森林密径'),
              timelineTime: const drift.Value('黄昏'),
              mood: const drift.Value('神秘压抑'),
              povCharacterId: const drift.Value(101),
              characterIds: const drift.Value('[101, 102, 103]'),
              sortOrder: const drift.Value(1),
            ),
          );
    });

    tearDown(() async {
      await db.close();
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test(
      'Single Markdown Export produces accurate content hierarchy',
      () async {
        final outPath = '${tempDir.path}/script_full.md';
        await service.exportWorkScript(
          workId: 1,
          options: const StoryScriptExportOptions(
            format: StoryScriptExportFormat.singleMarkdown,
            includeSynopsis: true,
            includeCastTable: true,
            includeSceneCards: true,
            includeChapterContent: true,
            includeWordCountStats: true,
          ),
          outputPath: outPath,
        );

        final file = File(outPath);
        expect(file.existsSync(), isTrue);

        final content = file.readAsStringSync();
        expect(content, contains('# 风之歌与旅行者'));
        expect(content, contains('**类型**：轻小说'));
        expect(content, contains('## 📖 故事梗概'));
        expect(content, contains('降临提瓦特大陆的少年与神秘向导的旅途序章。'));
        expect(content, contains('## 👥 登场演职人员表 (Cast)'));
        expect(content, contains('空 (Aether)'));
        expect(content, contains('派蒙 (Paimon)'));
        expect(content, contains('琴 (Jean)'));
        expect(content, contains('### 📁 分卷：序章·捕风的异乡人'));
        expect(content, contains('#### 第 1 章：坠落星空与海滩苏醒'));
        expect(content, contains('沙滩初会'));
        expect(content, contains('星落湖沙滩'));
        expect(content, contains('应急食品而已'));
        expect(content, contains('#### 第 2 章：风起之地与巨龙黑影'));
        expect(content, contains('低语森林的低吼'));
      },
    );

    test('Single Markdown Export respects chapter filtering', () async {
      final outPath = '${tempDir.path}/script_filtered.md';
      await service.exportWorkScript(
        workId: 1,
        options: const StoryScriptExportOptions(
          format: StoryScriptExportFormat.singleMarkdown,
          selectedChapterIds: {2}, // Only chapter 2
        ),
        outputPath: outPath,
      );

      final content = File(outPath).readAsStringSync();
      expect(content, isNot(contains('第 1 章：坠落星空与海滩苏醒')));
      expect(content, contains('#### 第 1 章：风起之地与巨龙黑影'));
      expect(content, contains('低语森林密径'));
    });

    test(
      'HTML Export produces printable and standalone document with XSS safety',
      () async {
        final outPath = '${tempDir.path}/script_print.html';
        await service.exportWorkScript(
          workId: 1,
          options: const StoryScriptExportOptions(
            format: StoryScriptExportFormat.html,
            includeSynopsis: true,
            includeCastTable: true,
            includeSceneCards: true,
            includeChapterContent: true,
            includeWordCountStats: true,
          ),
          outputPath: outPath,
        );

        final file = File(outPath);
        expect(file.existsSync(), isTrue);

        final html = file.readAsStringSync(encoding: utf8);
        expect(html, contains('<!DOCTYPE html>'));
        expect(html, contains('<title>风之歌与旅行者 · 故事剧本大纲</title>'));
        expect(html, contains('@media print'));
        expect(html, contains('page-break-before: always'));
        expect(html, contains('降临提瓦特大陆的少年与神秘向导的旅途序章。'));
        expect(html, contains('空 (Aether)'));
        expect(html, contains('派蒙 (Paimon)'));
        expect(html, contains('星落湖沙滩'));
        expect(html, contains('沙滩初会'));
        expect(html, contains('应急食品而已'));

        // Test XSS escaping
        final safeEscaped = StoryScriptHtmlBuilder.buildHtmlString(
          work: StoryWork(
            id: 99,
            worldId: 1,
            title: 'Title <script>alert("hack")</script>',
            type: 'Novel',
            summary: 'Summary & <bold>',
            status: 'Draft',
            coverImagePath: null,
            sortOrder: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          chapters: [],
          chapterScenesMap: {},
          castStats: [],
          characterNameMap: {},
          options: const StoryScriptExportOptions(
            format: StoryScriptExportFormat.html,
          ),
        );
        expect(
          safeEscaped,
          contains('&lt;script&gt;alert(&quot;hack&quot;)&lt;&#47;script&gt;'),
        );
        expect(safeEscaped, contains('&amp; &lt;bold&gt;'));
        expect(safeEscaped, isNot(contains('<script>alert')));
      },
    );

    test(
      'Markdown ZIP Export generates well-structured archive hierarchy',
      () async {
        final outZipPath = '${tempDir.path}/story_project.zip';
        await service.exportWorkScript(
          workId: 1,
          options: const StoryScriptExportOptions(
            format: StoryScriptExportFormat.markdownZip,
            includeSynopsis: true,
            includeCastTable: true,
            includeSceneCards: true,
            includeChapterContent: true,
            includeWordCountStats: true,
          ),
          outputPath: outZipPath,
        );

        final zipFile = File(outZipPath);
        expect(zipFile.existsSync(), isTrue);

        final bytes = zipFile.readAsBytesSync();
        final archive = ZipDecoder().decodeBytes(bytes);

        final fileNames = archive.files.map((f) => f.name).toList();

        // 1. Root synopsis & cast file
        expect(fileNames.any((n) => n.endsWith('00_故事梗概与演职表.md')), isTrue);
        final summaryFile = archive.files.firstWhere(
          (f) => f.name.endsWith('00_故事梗概与演职表.md'),
        );
        final summaryContent = utf8.decode(summaryFile.content as List<int>);
        expect(summaryContent, contains('降临提瓦特大陆的少年与神秘向导的旅途序章。'));
        expect(summaryContent, contains('空 (Aether)'));
        expect(summaryContent, contains('派蒙 (Paimon)'));

        // 2. Arc subfolder chapter files
        expect(
          fileNames.any(
            (n) => n.contains('序章·捕风的异乡人') && n.contains('01_坠落星空与海滩苏醒.md'),
          ),
          isTrue,
        );
        expect(
          fileNames.any(
            (n) => n.contains('序章·捕风的异乡人') && n.contains('02_风起之地与巨龙黑影.md'),
          ),
          isTrue,
        );

        final ch1File = archive.files.firstWhere(
          (f) => f.name.contains('01_坠落星空与海滩苏醒.md'),
        );
        final ch1Content = utf8.decode(ch1File.content as List<int>);
        expect(ch1Content, contains('沙滩初会'));
        expect(ch1Content, contains('星落湖沙滩'));
        expect(ch1Content, contains('应急食品而已'));
      },
    );

    test('Throws informative exception if workId does not exist', () async {
      expect(
        () => service.exportWorkScript(
          workId: 9999,
          options: const StoryScriptExportOptions(
            format: StoryScriptExportFormat.singleMarkdown,
          ),
          outputPath: '${tempDir.path}/none.md',
        ),
        throwsA(isA<Exception>()),
      );
    });

    testWidgets('StoryExportDialog renders formats, options and chapters', (
      tester,
    ) async {
      final work = await db.storyDao.getWorkById(1);
      expect(work, isNotNull);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => StoryExportDialog.show(context, work!),
                  child: const Text('Open Export'),
                ),
              ),
            ),
          ),
        ),
      );

      // Tap open button
      await tester.tap(find.text('Open Export'));
      await tester.pumpAndSettle();

      // Verify Dialog Title & Formats
      expect(find.textContaining('导出剧本与分镜大纲'), findsOneWidget);
      expect(find.text('高颜值排版手册 (HTML/打印PDF)'), findsOneWidget);
      expect(find.text('单一剧本文档 (Markdown)'), findsOneWidget);
      expect(find.text('分章工程包 (Markdown ZIP)'), findsOneWidget);

      // Verify Chapters Loaded in selection list
      expect(find.textContaining('坠落星空与海滩苏醒'), findsOneWidget);
      expect(find.textContaining('风起之地与巨龙黑影'), findsOneWidget);

      // Verify toggle checkboxes
      expect(find.text('包含故事梗概与基础属性'), findsOneWidget);
      expect(find.text('包含演职人员登场统计表'), findsOneWidget);
      expect(find.text('包含分镜规划大纲 (POV/地点/时段/基调)'), findsOneWidget);

      // Close dialog cleanly
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}

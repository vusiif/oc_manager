import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oc_manager/core/export/booklet_export_service.dart';
import 'package:oc_manager/core/export/models/export_bundle.dart';
import 'package:oc_manager/data/database/app_database.dart';

void main() {
  group('BookletExportService Tests (Milestone 4.1)', () {
    late AppDatabase db;
    late BookletExportService service;
    late Directory tempDir;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      service = BookletExportService(db);
      tempDir = Directory.systemTemp.createTempSync('oc_booklet_test_');

      // Populate mock world
      await db.into(db.worlds).insert(WorldsCompanion.insert(
            id: const drift.Value(1),
            name: '卡美洛帝国',
            description: const drift.Value('剑与魔法并存的中世纪传奇大陆'),
          ));

      // Characters
      await db.into(db.characters).insert(CharactersCompanion.insert(
            id: const drift.Value(1),
            worldId: 1,
            name: '亚瑟',
            gender: const drift.Value('男'),
            description: const drift.Value('卡美洛之王，挚友是 [[兰斯洛特]]，受教于 [[梅林]]。'),
            status: const drift.Value(2),
            isFavorite: const drift.Value(true),
          ));

      await db.into(db.characters).insert(CharactersCompanion.insert(
            id: const drift.Value(2),
            worldId: 1,
            name: '兰斯洛特',
            gender: const drift.Value('男'),
            description: const drift.Value('湖上骑士，效忠于 [[亚瑟]]。'),
            status: const drift.Value(2),
          ));

      // Stats for radar chart
      await db.into(db.characterStats).insert(CharacterStatsCompanion.insert(
            characterId: 1,
            label: '力量',
            value: const drift.Value(90.0),
            maxValue: const drift.Value(100.0),
            sortOrder: const drift.Value(0),
          ));
      await db.into(db.characterStats).insert(CharacterStatsCompanion.insert(
            characterId: 1,
            label: '敏捷',
            value: const drift.Value(85.0),
            maxValue: const drift.Value(100.0),
            sortOrder: const drift.Value(1),
          ));
      await db.into(db.characterStats).insert(CharacterStatsCompanion.insert(
            characterId: 1,
            label: '统帅',
            value: const drift.Value(95.0),
            maxValue: const drift.Value(100.0),
            sortOrder: const drift.Value(2),
          ));

      // Group
      await db.into(db.groups).insert(GroupsCompanion.insert(
            id: const drift.Value(1),
            worldId: 1,
            name: '圆桌骑士团',
          ));
      await db.into(db.characterGroups).insert(CharacterGroupsCompanion.insert(
            characterId: 1,
            groupId: 1,
          ));

      // Timeline Event
      await db.into(db.timelineEvents).insert(TimelineEventsCompanion.insert(
            worldId: 1,
            characterId: const drift.Value(1),
            year: '纪元 500 年',
            title: '拔出石中剑',
            description: const drift.Value('亚瑟于王城中心拔出天命圣剑石中剑，即位为王。'),
            importance: const drift.Value(3),
            category: const drift.Value('传奇'),
          ));

      // Relation
      await db.into(db.relations).insert(RelationsCompanion.insert(
            fromCharacterId: 1,
            toCharacterId: 2,
            relationType: '君臣挚友',
            isBidirectional: const drift.Value(true),
            note: const drift.Value('生死托付'),
          ));
    });

    tearDown(() async {
      await db.close();
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    test('should export standalone HTML publication booklet correctly', () async {
      final outputPath = '${tempDir.path}/booklet.html';
      const options = BookletExportOptions(
        format: BookletFormat.html,
        includeWorldOverview: true,
        includeGroups: true,
        includeTimeline: true,
        includeCharacters: true,
        includeRadarStats: true,
        includeGalleries: true,
        includeRelations: true,
      );

      await service.exportBooklet(
        worldId: 1,
        outputPath: outputPath,
        options: options,
      );

      final file = File(outputPath);
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      // Verify Title & Cover
      expect(content, contains('卡美洛帝国'));
      expect(content, contains('ORIGINAL CHARACTER ARCHIVE'));

      // Verify Chapters
      expect(content, contains('第一章 · 世界纲要'));
      expect(content, contains('第二章 · 势力与组织'));
      expect(content, contains('圆桌骑士团'));
      expect(content, contains('第三章 · 纪元编年史'));
      expect(content, contains('拔出石中剑'));

      // Verify Character Profiles & Wiki Link Parsing
      expect(content, contains('亚瑟'));
      expect(content, contains('<span class="wiki-link">[[兰斯洛特]]</span>'));

      // Verify SVG Radar Chart
      expect(content, contains('<svg class="radar-svg"'));
      expect(content, contains('力量'));
      expect(content, contains('敏捷'));
      expect(content, contains('统帅'));

      // Verify Print media CSS
      expect(content, contains('@media print'));
      expect(content, contains('page-break-after: always;'));
    });

    test('should export Markdown documentation tree in ZIP correctly', () async {
      final outputPath = '${tempDir.path}/booklet.zip';
      const options = BookletExportOptions(
        format: BookletFormat.markdownZip,
        includeWorldOverview: true,
        includeGroups: true,
        includeTimeline: true,
        includeCharacters: true,
        includeRadarStats: true,
        includeGalleries: true,
        includeRelations: true,
      );

      await service.exportBooklet(
        worldId: 1,
        outputPath: outputPath,
        options: options,
      );

      final file = File(outputPath);
      expect(file.existsSync(), isTrue);

      final bytes = file.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Verify Zip archive files
      final fileNames = archive.files.map((f) => f.name).toList();
      expect(fileNames, contains('index.md'));
      expect(fileNames, contains('00_世界概况.md'));
      expect(fileNames, contains('01_组织势力.md'));
      expect(fileNames, contains('02_编年简史.md'));
      expect(fileNames, contains('03_人物图鉴/亚瑟.md'));
      expect(fileNames, contains('03_人物图鉴/兰斯洛特.md'));
      expect(fileNames, contains('04_关系网络拓扑.md'));

      // Inspect index.md
      final indexFile = archive.findFile('index.md')!;
      final indexContent = utf8.decode(indexFile.content as List<int>);
      expect(indexContent, contains('# 📖 卡美洛帝国 · 设定集'));
      expect(indexContent, contains('[[亚瑟]]'));
      expect(indexContent, contains('[[兰斯洛特]]'));

      // Inspect character markdown file
      final charFile = archive.findFile('03_人物图鉴/亚瑟.md')!;
      final charContent = utf8.decode(charFile.content as List<int>);
      expect(charContent, contains('title: "亚瑟"'));
      expect(charContent, contains('## 📊 能力特质评估'));
      expect(charContent, contains('| 力量 | 90.0 | 100.0 | 90% |'));
      expect(charContent, contains('[[兰斯洛特]]'));
    });
  });
}

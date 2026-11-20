import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../../../data/database/app_database.dart';
import '../../storage/image_storage_service.dart';
import '../booklet_export_service.dart';
import 'booklet_export_helpers.dart';

Future<void> exportMarkdownZipBooklet({
  required World world,
  required List<Character> characters,
  required List<Group> groups,
  required Map<int, List<int>> charGroupMap,
  required Map<int, List<CharacterStat>> statsMap,
  required Map<int, List<CharacterGallery>> galleriesMap,
  required List<TimelineEvent> timelineEvents,
  required List<Relation> relations,
  required BookletExportOptions options,
  required String outputPath,
}) async {
  final archive = Archive();
  final groupMap = {for (final g in groups) g.id: g};
  final charNameMap = {for (final c in characters) c.id: c.name};
  final imageService = ImageStorageService.instance;

  // 1. Export Assets folder into ZIP
  final copiedAvatarMap = <int, String>{}; // charId -> relative path in assets
  for (final c in characters) {
    if (c.avatarPath != null) {
      final file = await imageService.resolveImageFile(c.avatarPath);
      if (file != null && await file.exists()) {
        final fileName = 'avatar_${c.id}${p.extension(file.path)}';
        final bytes = await file.readAsBytes();
        archive.addFile(ArchiveFile('assets/$fileName', bytes.length, bytes));
        copiedAvatarMap[c.id] = fileName;
      }
    }
  }

  final copiedGalleryMap = <int, Map<int, String>>{};
  if (options.includeGalleries) {
    for (final entry in galleriesMap.entries) {
      final cId = entry.key;
      copiedGalleryMap[cId] = {};
      for (final g in entry.value) {
        final file = await imageService.resolveImageFile(g.imagePath);
        if (file != null && await file.exists()) {
          final fileName = 'gallery_${cId}_${g.id}${p.extension(file.path)}';
          final bytes = await file.readAsBytes();
          archive.addFile(ArchiveFile('assets/$fileName', bytes.length, bytes));
          copiedGalleryMap[cId]![g.id] = fileName;
        }
      }
    }
  }

  // 2. index.md / README.md
  final indexSb = StringBuffer();
  indexSb.writeln('# 📖 ${world.name} · 设定集');
  indexSb.writeln();
  indexSb.writeln(
    '> 导出时间：${DateTime.now().toLocal().toString().split('.').first}',
  );
  indexSb.writeln();
  indexSb.writeln('## 📑 设定集目录');
  indexSb.writeln('- [[00_世界概况|00 · 世界概况与核心设定]]');
  indexSb.writeln('- [[01_组织势力|01 · 阵营与派系一览]]');
  indexSb.writeln('- [[02_编年简史|02 · 纪元大事件编年史]]');
  indexSb.writeln('- **03_人物图鉴/** (包含 ${characters.length} 位角色独立档案)');
  for (final c in characters) {
    indexSb.writeln('  - [[${c.name}]]');
  }
  indexSb.writeln('- [[04_关系网络拓扑|04 · 全局人际关系拓扑]]');
  addArchiveString(archive, 'index.md', indexSb.toString());

  // 3. 00_世界概况.md
  if (options.includeWorldOverview) {
    final worldSb = StringBuffer();
    worldSb.writeln('# 00 · 世界概况');
    worldSb.writeln();
    worldSb.writeln('## 世界名称：${world.name}');
    worldSb.writeln();
    worldSb.writeln('### 核心背景');
    worldSb.writeln(world.description ?? '暂无详细世界观介绍。');
    worldSb.writeln();
    worldSb.writeln('### 资产统计');
    worldSb.writeln('- 登记角色：${characters.length} 位');
    worldSb.writeln('- 组织阵营：${groups.length} 个');
    worldSb.writeln('- 纪元大事：${timelineEvents.length} 件');
    addArchiveString(archive, '00_世界概况.md', worldSb.toString());
  }

  // 4. 01_组织势力.md
  if (options.includeGroups && groups.isNotEmpty) {
    final groupsSb = StringBuffer();
    groupsSb.writeln('# 01 · 组织势力与阵营');
    groupsSb.writeln();
    for (final g in groups) {
      final memberNames = characters
          .where((c) => (charGroupMap[c.id] ?? []).contains(g.id))
          .map((c) => '[[${c.name}]]')
          .toList();
      groupsSb.writeln('## 🏛️ ${g.name}');
      groupsSb.writeln();
      groupsSb.writeln(
        '**从属成员：** ${memberNames.isEmpty ? '暂无' : memberNames.join('、')}',
      );
      groupsSb.writeln();
    }
    addArchiveString(archive, '01_组织势力.md', groupsSb.toString());
  }

  // 5. 02_编年简史.md
  if (options.includeTimeline && timelineEvents.isNotEmpty) {
    final timeSb = StringBuffer();
    timeSb.writeln('# 02 · 纪元编年史');
    timeSb.writeln();
    timeSb.writeln('| 纪年 / 时间 | 核心事件 | 重要度 | 类别 | 关联角色 | 详细叙述 |');
    timeSb.writeln('| :--- | :--- | :---: | :---: | :---: | :--- |');
    for (final ev in timelineEvents) {
      final relCharName = ev.characterId != null
          ? '[[${charNameMap[ev.characterId]}]]'
          : '-';
      final stars = '★' * ev.importance;
      timeSb.writeln(
        '| ${ev.year} | **${ev.title}** | $stars | ${ev.category} | $relCharName | ${ev.description.replaceAll('\n', ' ')} |',
      );
    }
    addArchiveString(archive, '02_编年简史.md', timeSb.toString());
  }

  // 6. 03_人物图鉴/<角色名>.md
  if (options.includeCharacters) {
    for (final c in characters) {
      final charSb = StringBuffer();
      final avatarFile = copiedAvatarMap[c.id];
      final charStats = statsMap[c.id] ?? [];
      final charGalleries = galleriesMap[c.id] ?? [];
      final charGroups = (charGroupMap[c.id] ?? [])
          .map((gid) => groupMap[gid]?.name)
          .whereType<String>()
          .toList();
      final charRels = relations
          .where((r) => r.fromCharacterId == c.id || r.toCharacterId == c.id)
          .toList();
      final charTimeline = timelineEvents
          .where((e) => e.characterId == c.id)
          .toList();

      // Frontmatter
      charSb.writeln('---');
      charSb.writeln('title: "${c.name}"');
      charSb.writeln('world: "${world.name}"');
      charSb.writeln('gender: "${c.gender}"');
      charSb.writeln('status: ${c.status}');
      charSb.writeln('is_favorite: ${c.isFavorite}');
      charSb.writeln('groups: [${charGroups.map((g) => '"$g"').join(', ')}]');
      charSb.writeln('---');
      charSb.writeln();

      // Heading & Avatar
      charSb.writeln('# ${c.name}');
      charSb.writeln();
      if (avatarFile != null) {
        charSb.writeln('![${c.name}](../assets/$avatarFile)');
        charSb.writeln();
      }

      charSb.writeln('## 👤 基础资料');
      charSb.writeln('- **性别**：${c.gender.isNotEmpty ? c.gender : "未知"}');
      charSb.writeln(
        '- **所属阵营**：${charGroups.isEmpty ? "无" : charGroups.join('、')}',
      );
      charSb.writeln();

      // Stats
      if (options.includeRadarStats && charStats.isNotEmpty) {
        charSb.writeln('## 📊 能力特质评估');
        charSb.writeln('| 属性维度 | 数值 | 最大值 | 达成率 |');
        charSb.writeln('| :--- | :---: | :---: | :---: |');
        for (final s in charStats) {
          final pct = s.maxValue > 0 ? (s.value / s.maxValue * 100).round() : 0;
          charSb.writeln('| ${s.label} | ${s.value} | ${s.maxValue} | $pct% |');
        }
        charSb.writeln();
      }

      // Description
      charSb.writeln('## 📝 背景小传');
      charSb.writeln(c.description.isEmpty ? '暂无背景小传。' : c.description);
      charSb.writeln();

      // Timeline
      if (charTimeline.isNotEmpty) {
        charSb.writeln('## ⏳ 生平大事件');
        for (final e in charTimeline) {
          charSb.writeln('- **${e.year}** · ${e.title}：${e.description}');
        }
        charSb.writeln();
      }

      // Relations
      if (charRels.isNotEmpty) {
        charSb.writeln('## 🤝 人际网络');
        for (final r in charRels) {
          final otherId = r.fromCharacterId == c.id
              ? r.toCharacterId
              : r.fromCharacterId;
          final otherName = charNameMap[otherId] ?? '未知角色';
          final arrow = r.isBidirectional
              ? '⮀ 互为'
              : (r.fromCharacterId == c.id ? '➔ 对' : '⬅ 来自');
          charSb.writeln(
            '- $arrow [[$otherName]]：**${r.relationType}** ${r.note != null && r.note!.isNotEmpty ? "(${r.note})" : ""}',
          );
        }
        charSb.writeln();
      }

      // Galleries
      if (options.includeGalleries && charGalleries.isNotEmpty) {
        charSb.writeln('## 🎨 差分画廊与立绘');
        for (final g in charGalleries) {
          final gFile = copiedGalleryMap[c.id]?[g.id];
          if (gFile != null) {
            charSb.writeln('![${g.caption}](../assets/$gFile)');
            if (g.caption.isNotEmpty) {
              charSb.writeln('*${g.caption}*');
            }
            charSb.writeln();
          }
        }
      }

      addArchiveString(
        archive,
        '03_人物图鉴/${sanitizeFileName(c.name)}.md',
        charSb.toString(),
      );
    }
  }

  // 7. 04_关系网络拓扑.md
  if (options.includeRelations && relations.isNotEmpty) {
    final relSb = StringBuffer();
    relSb.writeln('# 04 · 全局人际关系拓扑');
    relSb.writeln();
    relSb.writeln('| 角色 A | 连结形态 | 角色 B | 关系类型 | 备注设定 |');
    relSb.writeln('| :--- | :---: | :--- | :---: | :--- |');
    for (final r in relations) {
      final fromName =
          charNameMap[r.fromCharacterId] ?? 'ID:${r.fromCharacterId}';
      final toName = charNameMap[r.toCharacterId] ?? 'ID:${r.toCharacterId}';
      final arrow = r.isBidirectional ? '⮀ 双向' : '➔ 单向';
      relSb.writeln(
        '| [[$fromName]] | $arrow | [[$toName]] | **${r.relationType}** | ${r.note ?? ""} |',
      );
    }
    addArchiveString(archive, '04_关系网络拓扑.md', relSb.toString());
  }

  // 8. Write Zip to outputPath
  final zipEncoder = ZipEncoder();
  final encodedBytes = zipEncoder.encode(archive);
  final file = File(outputPath);
  await file.writeAsBytes(encodedBytes);
}

// ==========================================
// SVG Radar Chart Generator
// ==========================================

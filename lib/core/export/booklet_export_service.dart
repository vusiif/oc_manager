import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../data/database/app_database.dart';
import '../storage/image_storage_service.dart';
import 'models/export_bundle.dart';

/// Options controlling which sections and formats to export
class BookletExportOptions {
  final bool includeWorldOverview;
  final bool includeGroups;
  final bool includeTimeline;
  final bool includeCharacters;
  final bool includeRelations;
  final bool includeGalleries;
  final bool includeRadarStats;
  final Set<int>? selectedCharacterIds;
  final BookletFormat format;

  const BookletExportOptions({
    this.includeWorldOverview = true,
    this.includeGroups = true,
    this.includeTimeline = true,
    this.includeCharacters = true,
    this.includeRelations = true,
    this.includeGalleries = true,
    this.includeRadarStats = true,
    this.selectedCharacterIds,
    this.format = BookletFormat.html,
  });
}

/// Service that compiles world data into standalone publications (HTML / Markdown ZIP)
class BookletExportService {
  final AppDatabase db;

  BookletExportService(this.db);

  /// Compiles and exports the world booklet to [outputPath]
  Future<void> exportBooklet({
    required int worldId,
    required String outputPath,
    required BookletExportOptions options,
  }) async {
    // 1. Load world entity
    final world = await (db.select(db.worlds)..where((t) => t.id.equals(worldId))).getSingleOrNull();
    if (world == null) {
      throw Exception('World not found with ID: $worldId');
    }

    // 2. Load characters
    var charQuery = db.select(db.characters)..where((t) => t.worldId.equals(worldId));
    final allCharacters = await charQuery.get();
    final characters = options.selectedCharacterIds != null
        ? allCharacters.where((c) => options.selectedCharacterIds!.contains(c.id)).toList()
        : allCharacters;
    final characterIds = characters.map((c) => c.id).toSet();

    // 3. Load groups and memberships
    final groups = await (db.select(db.groups)
          ..where((t) => t.worldId.equals(worldId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    final characterGroups = await db.select(db.characterGroups).get();
    final charGroupMap = <int, List<int>>{};
    for (final cg in characterGroups) {
      if (characterIds.contains(cg.characterId)) {
        charGroupMap.putIfAbsent(cg.characterId, () => []).add(cg.groupId);
      }
    }

    // 4. Load stats
    final allStats = await (db.select(db.characterStats)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    final statsMap = <int, List<CharacterStat>>{};
    for (final s in allStats) {
      if (characterIds.contains(s.characterId)) {
        statsMap.putIfAbsent(s.characterId, () => []).add(s);
      }
    }

    // 5. Load galleries
    final allGalleries = await (db.select(db.characterGalleries)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    final galleriesMap = <int, List<CharacterGallery>>{};
    for (final g in allGalleries) {
      if (characterIds.contains(g.characterId)) {
        galleriesMap.putIfAbsent(g.characterId, () => []).add(g);
      }
    }

    // 6. Load timeline events
    final timelineEvents = await (db.select(db.timelineEvents)
          ..where((t) => t.worldId.equals(worldId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();

    // 7. Load relations
    final allRelations = await db.select(db.relations).get();
    final relations = allRelations.where((r) =>
        characterIds.contains(r.fromCharacterId) && characterIds.contains(r.toCharacterId)).toList();

    // 8. Generate output according to chosen format
    if (options.format == BookletFormat.html) {
      await _exportHtmlBooklet(
        world: world,
        characters: characters,
        groups: groups,
        charGroupMap: charGroupMap,
        statsMap: statsMap,
        galleriesMap: galleriesMap,
        timelineEvents: timelineEvents,
        relations: relations,
        options: options,
        outputPath: outputPath,
      );
    } else {
      await _exportMarkdownZipBooklet(
        world: world,
        characters: characters,
        groups: groups,
        charGroupMap: charGroupMap,
        statsMap: statsMap,
        galleriesMap: galleriesMap,
        timelineEvents: timelineEvents,
        relations: relations,
        options: options,
        outputPath: outputPath,
      );
    }
  }

  // ==========================================
  // HTML Publication Generator
  // ==========================================

  Future<void> _exportHtmlBooklet({
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
    final groupMap = {for (final g in groups) g.id: g};
    final charNameMap = {for (final c in characters) c.id: c.name};

    // Pre-load images as Base64 data URLs for zero-dependency standalone HTML
    final imageService = ImageStorageService.instance;
    final avatarBase64Map = <int, String>{};
    for (final c in characters) {
      if (c.avatarPath != null) {
        final file = await imageService.resolveImageFile(c.avatarPath);
        if (file != null && await file.exists()) {
          try {
            final bytes = await file.readAsBytes();
            final ext = p.extension(file.path).toLowerCase().replaceAll('.', '');
            final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
            avatarBase64Map[c.id] = 'data:$mime;base64,${base64Encode(bytes)}';
          } catch (_) {}
        }
      }
    }

    final galleryBase64Map = <int, Map<int, String>>{};
    if (options.includeGalleries) {
      for (final entry in galleriesMap.entries) {
        final cId = entry.key;
        galleryBase64Map[cId] = {};
        for (final g in entry.value) {
          final file = await imageService.resolveImageFile(g.imagePath);
          if (file != null && await file.exists()) {
            try {
              final bytes = await file.readAsBytes();
              final ext = p.extension(file.path).toLowerCase().replaceAll('.', '');
              final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
              galleryBase64Map[cId]![g.id] = 'data:$mime;base64,${base64Encode(bytes)}';
            } catch (_) {}
          }
        }
      }
    }

    final sb = StringBuffer();
    final nowStr = DateTime.now().toLocal().toString().split('.').first;

    sb.writeln('<!DOCTYPE html>');
    sb.writeln('<html lang="zh-CN">');
    sb.writeln('<head>');
    sb.writeln('<meta charset="UTF-8">');
    sb.writeln('<meta name="viewport" content="width=device-width, initial-scale=1.0">');
    sb.writeln('<title>${_escapeHtml(world.name)} - 官方出版级设定集</title>');
    sb.writeln('<style>');
    sb.writeln(_buildBookletCss());
    sb.writeln('</style>');
    sb.writeln('</head>');
    sb.writeln('<body>');

    // 1. Cover Page
    sb.writeln('''
      <section class="page cover-page">
        <div class="cover-border">
          <div class="cover-subtitle">ORIGINAL CHARACTER ARCHIVE & WORLD SETTING</div>
          <h1 class="cover-title">${_escapeHtml(world.name)}</h1>
          <div class="cover-divider">✦</div>
          <div class="cover-edition">典藏设定集 · 完备档案</div>
          <div class="cover-meta">
            <p><strong>收录角色：</strong>${characters.length} 位</p>
            <p><strong>编年事件：</strong>${timelineEvents.length} 条</p>
            <p><strong>生成日期：</strong>$nowStr</p>
          </div>
        </div>
      </section>
    ''');

    // 2. Table of Contents
    sb.writeln('''
      <section class="page toc-page">
        <h2 class="section-heading">全书目录 (Table of Contents)</h2>
        <div class="toc-list">
          <div class="toc-item"><span class="toc-title">01 / 世界纲要 (World Overview)</span><span class="toc-dots"></span><span class="toc-page-num">P. 3</span></div>
          <div class="toc-item"><span class="toc-title">02 / 势力与组织 (Factions & Groups)</span><span class="toc-dots"></span><span class="toc-page-num">P. 4</span></div>
          <div class="toc-item"><span class="toc-title">03 / 纪元编年史 (World Chronicle)</span><span class="toc-dots"></span><span class="toc-page-num">P. 5</span></div>
          <div class="toc-item"><span class="toc-title">04 / 角色档案全录 (Character Compendium)</span><span class="toc-dots"></span><span class="toc-page-num">P. 6+</span></div>
          <div class="toc-item"><span class="toc-title">05 / 人际关系网络 (Relational Network)</span><span class="toc-dots"></span><span class="toc-page-num">附录</span></div>
        </div>
      </section>
    ''');

    // 3. World Overview
    if (options.includeWorldOverview) {
      sb.writeln('''
        <section class="page section-page">
          <h2 class="section-heading">第一章 · 世界纲要</h2>
          <div class="card">
            <h3 class="card-title">${_escapeHtml(world.name)}</h3>
            <div class="prose">${_formatDescription(world.description ?? '暂无详细介绍')}</div>
          </div>
        </section>
      ''');
    }

    // 4. Groups & Factions
    if (options.includeGroups && groups.isNotEmpty) {
      sb.writeln('''
        <section class="page section-page">
          <h2 class="section-heading">第二章 · 势力与组织</h2>
          <div class="groups-grid">
      ''');
      for (final g in groups) {
        final memberNames = characters
            .where((c) => (charGroupMap[c.id] ?? []).contains(g.id))
            .map((c) => _escapeHtml(c.name))
            .toList();
        sb.writeln('''
          <div class="group-card">
            <h3 class="group-title">${_escapeHtml(g.name)}</h3>
            <div class="group-members">
              <strong>从属角色 (${memberNames.length})：</strong>
              ${memberNames.isEmpty ? '<span class="text-muted">暂无</span>' : memberNames.map((n) => '<span class="badge">$n</span>').join(' ')}
            </div>
          </div>
        ''');
      }
      sb.writeln('</div></section>');
    }

    // 5. Timeline Events
    if (options.includeTimeline && timelineEvents.isNotEmpty) {
      sb.writeln('''
        <section class="page section-page">
          <h2 class="section-heading">第三章 · 纪元编年史</h2>
          <div class="timeline-list">
      ''');
      for (final ev in timelineEvents) {
        final relCharName = ev.characterId != null ? charNameMap[ev.characterId] : null;
        final stars = '★' * ev.importance + '☆' * (3 - ev.importance);
        sb.writeln('''
          <div class="timeline-item">
            <div class="timeline-year">${_escapeHtml(ev.year)}</div>
            <div class="timeline-body">
              <div class="timeline-header">
                <span class="timeline-title">${_escapeHtml(ev.title)}</span>
                <span class="timeline-stars">$stars</span>
                <span class="badge">${_escapeHtml(ev.category)}</span>
                ${relCharName != null ? '<span class="badge badge-accent">@${_escapeHtml(relCharName)}</span>' : ''}
              </div>
              <div class="timeline-desc">${_escapeHtml(ev.description)}</div>
            </div>
          </div>
        ''');
      }
      sb.writeln('</div></section>');
    }

    // 6. Character Profiles
    if (options.includeCharacters && characters.isNotEmpty) {
      for (var i = 0; i < characters.length; i++) {
        final c = characters[i];
        final avatarUrl = avatarBase64Map[c.id];
        final charStats = statsMap[c.id] ?? [];
        final charGalleries = galleriesMap[c.id] ?? [];
        final charGroups = (charGroupMap[c.id] ?? [])
            .map((gid) => groupMap[gid]?.name)
            .whereType<String>()
            .toList();

        // Specific character relations
        final charRels = relations.where((r) => r.fromCharacterId == c.id || r.toCharacterId == c.id).toList();

        // Specific character timeline events
        final charTimeline = timelineEvents.where((e) => e.characterId == c.id).toList();

        sb.writeln('''
          <section class="page character-profile-page">
            <div class="character-header">
              <div class="character-avatar-wrap">
                ${avatarUrl != null
                    ? '<img class="character-avatar" src="$avatarUrl" alt="${_escapeHtml(c.name)}"/>'
                    : '<div class="character-avatar-placeholder">${_escapeHtml(c.name.isNotEmpty ? c.name[0] : "?")}</div>'}
              </div>
              <div class="character-summary">
                <h2 class="character-name">${_escapeHtml(c.name)}</h2>
                <div class="character-tags">
                  <span class="badge">${_escapeHtml(c.gender.isNotEmpty ? c.gender : "性别未知")}</span>
                  ${charGroups.map((g) => '<span class="badge badge-accent">${_escapeHtml(g)}</span>').join(' ')}
                  ${c.isFavorite ? '<span class="badge badge-fav">★ 典藏精选</span>' : ''}
                </div>
                <div class="character-brief">${_formatWikiLinks(c.description)}</div>
              </div>
            </div>
        ''');

        // Stats & Radar Chart Row
        if (options.includeRadarStats && charStats.isNotEmpty) {
          final svgChart = _generateRadarSvg(charStats);
          sb.writeln('''
            <div class="character-section">
              <h4 class="sub-heading">能力特质评估 (Attribute Profile)</h4>
              <div class="stats-row">
                <div class="radar-wrap">$svgChart</div>
                <div class="stats-table-wrap">
                  <table class="stats-table">
                    <thead><tr><th>特质维度</th><th>当前数值</th><th>最大基准</th><th>评级</th></tr></thead>
                    <tbody>
          ''');
          for (final s in charStats) {
            final pct = s.maxValue > 0 ? (s.value / s.maxValue * 100).round() : 0;
            sb.writeln('<tr><td>${_escapeHtml(s.label)}</td><td>${s.value.toStringAsFixed(1)}</td><td>${s.maxValue.toStringAsFixed(1)}</td><td><strong>$pct%</strong></td></tr>');
          }
          sb.writeln('</tbody></table></div></div></div>');
        }

        // Timeline of the character
        if (charTimeline.isNotEmpty) {
          sb.writeln('''
            <div class="character-section">
              <h4 class="sub-heading">生平轨迹 (Biographical Milestones)</h4>
              <ul class="simple-timeline">
          ''');
          for (final e in charTimeline) {
            sb.writeln('<li><strong>${_escapeHtml(e.year)}</strong> · ${_escapeHtml(e.title)} <span class="text-muted">(${_escapeHtml(e.description)})</span></li>');
          }
          sb.writeln('</ul></div>');
        }

        // Relations of the character
        if (charRels.isNotEmpty) {
          sb.writeln('''
            <div class="character-section">
              <h4 class="sub-heading">人际纽带 (Relationships)</h4>
              <div class="rel-chips">
          ''');
          for (final r in charRels) {
            final otherId = r.fromCharacterId == c.id ? r.toCharacterId : r.fromCharacterId;
            final otherName = charNameMap[otherId] ?? '未知角色';
            final arrow = r.isBidirectional ? '⮀' : (r.fromCharacterId == c.id ? '➔' : '⬅');
            sb.writeln('<div class="rel-chip"><strong>$otherName</strong> $arrow <span class="rel-badge">${_escapeHtml(r.relationType)}</span> ${r.note != null && r.note!.isNotEmpty ? '<span class="text-muted">(${_escapeHtml(r.note!)})</span>' : ''}</div>');
          }
          sb.writeln('</div></div>');
        }

        // Gallery of the character
        if (options.includeGalleries && charGalleries.isNotEmpty) {
          sb.writeln('''
            <div class="character-section">
              <h4 class="sub-heading">差分立绘与相册 (Visual Gallery)</h4>
              <div class="gallery-grid">
          ''');
          for (final g in charGalleries) {
            final dataUrl = galleryBase64Map[c.id]?[g.id];
            if (dataUrl != null) {
              sb.writeln('''
                <div class="gallery-item">
                  <img src="$dataUrl" alt="${_escapeHtml(g.caption)}"/>
                  ${g.caption.isNotEmpty ? '<div class="gallery-caption">${_escapeHtml(g.caption)}</div>' : ''}
                </div>
              ''');
            }
          }
          sb.writeln('</div></div>');
        }

        sb.writeln('</section>');
      }
    }

    // 7. Relations Overview
    if (options.includeRelations && relations.isNotEmpty) {
      sb.writeln('''
        <section class="page section-page">
          <h2 class="section-heading">附录 · 全局人际关系拓扑</h2>
          <table class="full-table">
            <thead><tr><th>发起方</th><th>方向</th><th>目标方</th><th>关系类型</th><th>备注设定</th></tr></thead>
            <tbody>
      ''');
      for (final r in relations) {
        final fromName = charNameMap[r.fromCharacterId] ?? 'ID:${r.fromCharacterId}';
        final toName = charNameMap[r.toCharacterId] ?? 'ID:${r.toCharacterId}';
        final arrow = r.isBidirectional ? '互为 ⮀' : '单向 ➔';
        sb.writeln('<tr><td><strong>${_escapeHtml(fromName)}</strong></td><td>$arrow</td><td><strong>${_escapeHtml(toName)}</strong></td><td><span class="badge">${_escapeHtml(r.relationType)}</span></td><td>${_escapeHtml(r.note ?? '')}</td></tr>');
      }
      sb.writeln('</tbody></table></section>');
    }

    sb.writeln('</body></html>');

    final file = File(outputPath);
    await file.writeAsString(sb.toString(), encoding: utf8);
  }

  // ==========================================
  // Markdown ZIP Tree Generator
  // ==========================================

  Future<void> _exportMarkdownZipBooklet({
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
    indexSb.writeln('> 导出时间：${DateTime.now().toLocal().toString().split('.').first}');
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
    _addArchiveString(archive, 'index.md', indexSb.toString());

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
      _addArchiveString(archive, '00_世界概况.md', worldSb.toString());
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
        groupsSb.writeln('**从属成员：** ${memberNames.isEmpty ? '暂无' : memberNames.join('、')}');
        groupsSb.writeln();
      }
      _addArchiveString(archive, '01_组织势力.md', groupsSb.toString());
    }

    // 5. 02_编年简史.md
    if (options.includeTimeline && timelineEvents.isNotEmpty) {
      final timeSb = StringBuffer();
      timeSb.writeln('# 02 · 纪元编年史');
      timeSb.writeln();
      timeSb.writeln('| 纪年 / 时间 | 核心事件 | 重要度 | 类别 | 关联角色 | 详细叙述 |');
      timeSb.writeln('| :--- | :--- | :---: | :---: | :---: | :--- |');
      for (final ev in timelineEvents) {
        final relCharName = ev.characterId != null ? '[[${charNameMap[ev.characterId]}]]' : '-';
        final stars = '★' * ev.importance;
        timeSb.writeln('| ${ev.year} | **${ev.title}** | $stars | ${ev.category} | $relCharName | ${ev.description.replaceAll('\n', ' ')} |');
      }
      _addArchiveString(archive, '02_编年简史.md', timeSb.toString());
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
        final charRels = relations.where((r) => r.fromCharacterId == c.id || r.toCharacterId == c.id).toList();
        final charTimeline = timelineEvents.where((e) => e.characterId == c.id).toList();

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
        charSb.writeln('- **所属阵营**：${charGroups.isEmpty ? "无" : charGroups.join('、')}');
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
            final otherId = r.fromCharacterId == c.id ? r.toCharacterId : r.fromCharacterId;
            final otherName = charNameMap[otherId] ?? '未知角色';
            final arrow = r.isBidirectional ? '⮀ 互为' : (r.fromCharacterId == c.id ? '➔ 对' : '⬅ 来自');
            charSb.writeln('- $arrow [[$otherName]]：**${r.relationType}** ${r.note != null && r.note!.isNotEmpty ? "(${r.note})" : ""}');
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

        _addArchiveString(archive, '03_人物图鉴/${_sanitizeFileName(c.name)}.md', charSb.toString());
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
        final fromName = charNameMap[r.fromCharacterId] ?? 'ID:${r.fromCharacterId}';
        final toName = charNameMap[r.toCharacterId] ?? 'ID:${r.toCharacterId}';
        final arrow = r.isBidirectional ? '⮀ 双向' : '➔ 单向';
        relSb.writeln('| [[$fromName]] | $arrow | [[$toName]] | **${r.relationType}** | ${r.note ?? ""} |');
      }
      _addArchiveString(archive, '04_关系网络拓扑.md', relSb.toString());
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

  String _generateRadarSvg(List<CharacterStat> stats) {
    if (stats.length < 3) {
      return '<div class="text-muted">（维度少于 3 项，无法生成雷达图）</div>';
    }

    const double cx = 140.0;
    const double cy = 140.0;
    const double radius = 85.0;
    final int count = stats.length;
    final double angleStep = 2 * math.pi / count;

    final sb = StringBuffer();
    sb.writeln('<svg class="radar-svg" viewBox="0 0 280 280" width="280" height="280" xmlns="http://www.w3.org/2000/svg">');

    // Concentric web lines (4 levels)
    for (int level = 1; level <= 4; level++) {
      final r = radius * (level / 4.0);
      final points = <String>[];
      for (int i = 0; i < count; i++) {
        final angle = -math.pi / 2 + i * angleStep;
        final x = cx + r * math.cos(angle);
        final y = cy + r * math.sin(angle);
        points.add('${x.toStringAsFixed(1)},${y.toStringAsFixed(1)}');
      }
      sb.writeln('<polygon points="${points.join(' ')}" fill="none" stroke="#e2e8f0" stroke-width="1"/>');
    }

    // Axis radiating lines
    for (int i = 0; i < count; i++) {
      final angle = -math.pi / 2 + i * angleStep;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      sb.writeln('<line x1="$cx" y1="$cy" x2="${x.toStringAsFixed(1)}" y2="${y.toStringAsFixed(1)}" stroke="#cbd5e1" stroke-width="1"/>');

      // Labels outside vertices
      final labelR = radius + 22;
      final lx = cx + labelR * math.cos(angle);
      final ly = cy + labelR * math.sin(angle) + 4; // slight vertical centering
      sb.writeln('<text x="${lx.toStringAsFixed(1)}" y="${ly.toStringAsFixed(1)}" font-size="11" font-weight="600" fill="#475569" text-anchor="middle">${_escapeHtml(stats[i].label)}</text>');
    }

    // Data polygon
    final dataPoints = <String>[];
    for (int i = 0; i < count; i++) {
      final s = stats[i];
      final ratio = s.maxValue > 0 ? (s.value / s.maxValue).clamp(0.0, 1.0) : 0.0;
      final r = radius * ratio;
      final angle = -math.pi / 2 + i * angleStep;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      dataPoints.add('${x.toStringAsFixed(1)},${y.toStringAsFixed(1)}');
    }

    sb.writeln('<polygon points="${dataPoints.join(' ')}" fill="rgba(99, 102, 241, 0.3)" stroke="#6366f1" stroke-width="2.5"/>');

    // Data vertex dots
    for (int i = 0; i < count; i++) {
      final s = stats[i];
      final ratio = s.maxValue > 0 ? (s.value / s.maxValue).clamp(0.0, 1.0) : 0.0;
      final r = radius * ratio;
      final angle = -math.pi / 2 + i * angleStep;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      sb.writeln('<circle cx="${x.toStringAsFixed(1)}" cy="${y.toStringAsFixed(1)}" r="4" fill="#6366f1" stroke="#ffffff" stroke-width="1.5"/>');
    }

    sb.writeln('</svg>');
    return sb.toString();
  }

  // ==========================================
  // Helper Utilities
  // ==========================================

  void _addArchiveString(Archive archive, String path, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;');
  }

  String _formatDescription(String raw) {
    return raw.split('\n\n').map((p) => '<p>${_escapeHtml(p).replaceAll('\n', '<br/>')}</p>').join('');
  }

  String _formatWikiLinks(String raw) {
    final regex = RegExp(r'\[\[(.*?)\]\]');
    final paragraphs = raw.split('\n\n').map((p) {
      final escaped = _escapeHtml(p).replaceAll('\n', '<br/>');
      return escaped.replaceAllMapped(regex, (m) {
        final target = m.group(1) ?? '';
        return '<span class="wiki-link">[[$target]]</span>';
      });
    });
    return paragraphs.map((p) => '<p>$p</p>').join('');
  }

  String _buildBookletCss() {
    return '''
      @page {
        size: A4 portrait;
        margin: 18mm 15mm;
      }
      * {
        box-sizing: border-box;
      }
      body {
        margin: 0;
        padding: 0;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "PingFang SC", "Microsoft YaHei", sans-serif;
        color: #1e293b;
        background: #f8fafc;
        line-height: 1.6;
      }
      .page {
        background: #ffffff;
        max-width: 860px;
        margin: 20px auto;
        padding: 48px;
        box-shadow: 0 4px 20px rgba(0,0,0,0.06);
        border-radius: 8px;
        page-break-after: always;
      }
      @media print {
        body {
          background: #ffffff;
        }
        .page {
          margin: 0;
          padding: 0;
          box-shadow: none;
          border-radius: 0;
          max-width: 100%;
        }
      }
      .cover-page {
        display: flex;
        align-items: center;
        justify-content: center;
        min-height: 800px;
        text-align: center;
      }
      .cover-border {
        border: 2px solid #cbd5e1;
        padding: 60px 40px;
        width: 100%;
        border-radius: 6px;
      }
      .cover-subtitle {
        font-size: 13px;
        font-weight: 700;
        letter-spacing: 2px;
        color: #64748b;
        margin-bottom: 24px;
      }
      .cover-title {
        font-size: 44px;
        font-weight: 800;
        color: #0f172a;
        margin: 0 0 16px 0;
      }
      .cover-divider {
        font-size: 20px;
        color: #6366f1;
        margin: 20px 0;
      }
      .cover-edition {
        font-size: 18px;
        font-weight: 500;
        color: #475569;
        margin-bottom: 60px;
      }
      .cover-meta {
        font-size: 14px;
        color: #64748b;
        line-height: 1.8;
      }
      .section-heading {
        font-size: 24px;
        font-weight: 700;
        color: #0f172a;
        border-bottom: 2px solid #e2e8f0;
        padding-bottom: 12px;
        margin-top: 0;
        margin-bottom: 28px;
      }
      .sub-heading {
        font-size: 16px;
        font-weight: 700;
        color: #334155;
        margin: 24px 0 12px 0;
        border-left: 3px solid #6366f1;
        padding-left: 8px;
      }
      .toc-list {
        margin-top: 30px;
      }
      .toc-item {
        display: flex;
        align-items: baseline;
        margin-bottom: 16px;
        font-size: 16px;
      }
      .toc-title {
        font-weight: 600;
        color: #334155;
      }
      .toc-dots {
        flex: 1;
        border-bottom: 1px dotted #cbd5e1;
        margin: 0 12px;
      }
      .toc-page-num {
        font-weight: 700;
        color: #64748b;
      }
      .badge {
        display: inline-block;
        font-size: 12px;
        padding: 2px 8px;
        border-radius: 4px;
        background: #f1f5f9;
        color: #475569;
        font-weight: 500;
      }
      .badge-accent {
        background: #ede9fe;
        color: #6366f1;
      }
      .badge-fav {
        background: #fef3c7;
        color: #b45309;
      }
      .character-header {
        display: flex;
        gap: 24px;
        margin-bottom: 24px;
      }
      .character-avatar-wrap {
        width: 140px;
        height: 140px;
        flex-shrink: 0;
      }
      .character-avatar {
        width: 100%;
        height: 100%;
        object-fit: cover;
        border-radius: 8px;
        border: 1px solid #e2e8f0;
      }
      .character-avatar-placeholder {
        width: 100%;
        height: 100%;
        background: #f1f5f9;
        border-radius: 8px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 48px;
        color: #94a3b8;
        font-weight: bold;
      }
      .character-summary {
        flex: 1;
      }
      .character-name {
        margin: 0 0 8px 0;
        font-size: 26px;
        color: #0f172a;
      }
      .character-tags {
        display: flex;
        gap: 6px;
        margin-bottom: 12px;
        flex-wrap: wrap;
      }
      .character-brief {
        font-size: 14px;
        color: #475569;
        line-height: 1.6;
      }
      .stats-row {
        display: flex;
        align-items: center;
        gap: 24px;
        flex-wrap: wrap;
      }
      .radar-wrap {
        width: 280px;
        height: 280px;
        display: flex;
        align-items: center;
        justify-content: center;
      }
      .stats-table-wrap {
        flex: 1;
        min-width: 220px;
      }
      .stats-table, .full-table {
        width: 100%;
        border-collapse: collapse;
        font-size: 13px;
      }
      .stats-table th, .stats-table td, .full-table th, .full-table td {
        padding: 8px 12px;
        border: 1px solid #e2e8f0;
        text-align: left;
      }
      .stats-table th, .full-table th {
        background: #f8fafc;
        color: #475569;
        font-weight: 600;
      }
      .timeline-item {
        display: flex;
        gap: 20px;
        margin-bottom: 20px;
      }
      .timeline-year {
        width: 90px;
        font-weight: 700;
        color: #6366f1;
        font-size: 15px;
        text-align: right;
      }
      .timeline-body {
        flex: 1;
        border-left: 2px solid #e2e8f0;
        padding-left: 16px;
      }
      .timeline-header {
        display: flex;
        gap: 8px;
        align-items: center;
        margin-bottom: 4px;
      }
      .timeline-title {
        font-weight: 700;
        font-size: 15px;
      }
      .timeline-stars {
        color: #f59e0b;
        font-size: 12px;
      }
      .timeline-desc {
        font-size: 14px;
        color: #475569;
      }
      .simple-timeline {
        padding-left: 20px;
        font-size: 13px;
        color: #334155;
      }
      .rel-chips {
        display: flex;
        flex-wrap: wrap;
        gap: 8px;
      }
      .rel-chip {
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        padding: 6px 12px;
        border-radius: 6px;
        font-size: 13px;
      }
      .rel-badge {
        font-weight: 700;
        color: #6366f1;
      }
      .gallery-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
        gap: 12px;
      }
      .gallery-item img {
        width: 100%;
        height: 140px;
        object-fit: cover;
        border-radius: 6px;
        border: 1px solid #e2e8f0;
      }
      .gallery-caption {
        font-size: 11px;
        color: #64748b;
        text-align: center;
        margin-top: 4px;
      }
      .wiki-link {
        color: #6366f1;
        background: #ede9fe;
        padding: 1px 4px;
        border-radius: 3px;
        font-weight: 600;
      }
      .groups-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
        gap: 16px;
      }
      .group-card {
        border: 1px solid #e2e8f0;
        border-radius: 8px;
        padding: 16px;
        background: #fafafa;
      }
      .group-title {
        margin: 0 0 10px 0;
        font-size: 16px;
        color: #0f172a;
      }
      .text-muted {
        color: #94a3b8;
      }
    ''';
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

import '../../../data/database/app_database.dart';
import '../../storage/image_storage_service.dart';
import '../booklet_export_service.dart';
import 'booklet_css_template.dart';
import 'booklet_export_helpers.dart';
import 'booklet_radar_svg.dart';

Future<void> exportHtmlBooklet({
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
            final ext = p
                .extension(file.path)
                .toLowerCase()
                .replaceAll('.', '');
            final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
            galleryBase64Map[cId]![g.id] =
                'data:$mime;base64,${base64Encode(bytes)}';
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
  sb.writeln(
    '<meta name="viewport" content="width=device-width, initial-scale=1.0">',
  );
  sb.writeln('<title>${escapeHtml(world.name)} - 官方出版级设定集</title>');
  sb.writeln('<style>');
  sb.writeln(buildBookletCss());
  sb.writeln('</style>');
  sb.writeln('</head>');
  sb.writeln('<body>');

  // 1. Cover Page
  sb.writeln('''
      <section class="page cover-page">
        <div class="cover-border">
          <div class="cover-subtitle">ORIGINAL CHARACTER ARCHIVE & WORLD SETTING</div>
          <h1 class="cover-title">${escapeHtml(world.name)}</h1>
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
            <h3 class="card-title">${escapeHtml(world.name)}</h3>
            <div class="prose">${formatDescription(world.description ?? '暂无详细介绍')}</div>
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
          .map((c) => escapeHtml(c.name))
          .toList();
      sb.writeln('''
          <div class="group-card">
            <h3 class="group-title">${escapeHtml(g.name)}</h3>
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
      final relCharName = ev.characterId != null
          ? charNameMap[ev.characterId]
          : null;
      final stars = '★' * ev.importance + '☆' * (3 - ev.importance);
      sb.writeln('''
          <div class="timeline-item">
            <div class="timeline-year">${escapeHtml(ev.year)}</div>
            <div class="timeline-body">
              <div class="timeline-header">
                <span class="timeline-title">${escapeHtml(ev.title)}</span>
                <span class="timeline-stars">$stars</span>
                <span class="badge">${escapeHtml(ev.category)}</span>
                ${relCharName != null ? '<span class="badge badge-accent">@${escapeHtml(relCharName)}</span>' : ''}
              </div>
              <div class="timeline-desc">${escapeHtml(ev.description)}</div>
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
      final charRels = relations
          .where((r) => r.fromCharacterId == c.id || r.toCharacterId == c.id)
          .toList();

      // Specific character timeline events
      final charTimeline = timelineEvents
          .where((e) => e.characterId == c.id)
          .toList();

      sb.writeln('''
          <section class="page character-profile-page">
            <div class="character-header">
              <div class="character-avatar-wrap">
                ${avatarUrl != null ? '<img class="character-avatar" src="$avatarUrl" alt="${escapeHtml(c.name)}"/>' : '<div class="character-avatar-placeholder">${escapeHtml(c.name.isNotEmpty ? c.name[0] : "?")}</div>'}
              </div>
              <div class="character-summary">
                <h2 class="character-name">${escapeHtml(c.name)}</h2>
                <div class="character-tags">
                  <span class="badge">${escapeHtml(c.gender.isNotEmpty ? c.gender : "性别未知")}</span>
                  ${charGroups.map((g) => '<span class="badge badge-accent">${escapeHtml(g)}</span>').join(' ')}
                  ${c.isFavorite ? '<span class="badge badge-fav">★ 典藏精选</span>' : ''}
                </div>
                <div class="character-brief">${formatWikiLinks(c.description)}</div>
              </div>
            </div>
        ''');

      // Stats & Radar Chart Row
      if (options.includeRadarStats && charStats.isNotEmpty) {
        final svgChart = generateRadarSvg(charStats);
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
          sb.writeln(
            '<tr><td>${escapeHtml(s.label)}</td><td>${s.value.toStringAsFixed(1)}</td><td>${s.maxValue.toStringAsFixed(1)}</td><td><strong>$pct%</strong></td></tr>',
          );
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
          sb.writeln(
            '<li><strong>${escapeHtml(e.year)}</strong> · ${escapeHtml(e.title)} <span class="text-muted">(${escapeHtml(e.description)})</span></li>',
          );
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
          final otherId = r.fromCharacterId == c.id
              ? r.toCharacterId
              : r.fromCharacterId;
          final otherName = charNameMap[otherId] ?? '未知角色';
          final arrow = r.isBidirectional
              ? '⮀'
              : (r.fromCharacterId == c.id ? '➔' : '⬅');
          sb.writeln(
            '<div class="rel-chip"><strong>${escapeHtml(otherName)}</strong> $arrow <span class="rel-badge">${escapeHtml(r.relationType)}</span> ${r.note != null && r.note!.isNotEmpty ? '<span class="text-muted">(${escapeHtml(r.note!)})</span>' : ''}</div>',
          );
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
                  <img src="$dataUrl" alt="${escapeHtml(g.caption)}"/>
                  ${g.caption.isNotEmpty ? '<div class="gallery-caption">${escapeHtml(g.caption)}</div>' : ''}
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
      final fromName =
          charNameMap[r.fromCharacterId] ?? 'ID:${r.fromCharacterId}';
      final toName = charNameMap[r.toCharacterId] ?? 'ID:${r.toCharacterId}';
      final arrow = r.isBidirectional ? '互为 ⮀' : '单向 ➔';
      sb.writeln(
        '<tr><td><strong>${escapeHtml(fromName)}</strong></td><td>$arrow</td><td><strong>${escapeHtml(toName)}</strong></td><td><span class="badge">${escapeHtml(r.relationType)}</span></td><td>${escapeHtml(r.note ?? '')}</td></tr>',
      );
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

import 'dart:convert';
import 'dart:io';

import '../../../data/database/app_database.dart';
import '../../../data/database/daos/story_dao.dart';
import 'story_script_export_models.dart';

/// Builder for generating standalone, beautiful, and printable HTML story script books.
class StoryScriptHtmlBuilder {
  const StoryScriptHtmlBuilder._();

  /// Generates the complete HTML string and writes it to [outputPath].
  static Future<void> exportHtml({
    required StoryWork work,
    required List<StoryChapter> chapters,
    required Map<int, List<StorySceneDetail>> chapterScenesMap,
    required List<WorkCastMemberStats> castStats,
    required Map<int, String> characterNameMap,
    required StoryScriptExportOptions options,
    required String outputPath,
  }) async {
    final html = buildHtmlString(
      work: work,
      chapters: chapters,
      chapterScenesMap: chapterScenesMap,
      castStats: castStats,
      characterNameMap: characterNameMap,
      options: options,
    );

    final file = File(outputPath);
    await file.writeAsString(html, encoding: utf8);
  }

  /// Builds the complete HTML string.
  static String buildHtmlString({
    required StoryWork work,
    required List<StoryChapter> chapters,
    required Map<int, List<StorySceneDetail>> chapterScenesMap,
    required List<WorkCastMemberStats> castStats,
    required Map<int, String> characterNameMap,
    required StoryScriptExportOptions options,
  }) {
    final totalWords = chapters.fold<int>(0, (sum, c) => sum + c.wordCount);
    final totalScenes = chapterScenesMap.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );

    final title = _escape(work.title);
    final type = _escape(work.type);
    final status = _escape(work.status);
    final exportDate = DateTime.now().toIso8601String().substring(0, 10);

    final buffer = StringBuffer();
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="zh-CN">');
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="UTF-8">');
    buffer.writeln(
      '  <meta name="viewport" content="width=device-width, initial-scale=1.0">',
    );
    buffer.writeln('  <title>$title · 故事剧本大纲</title>');
    buffer.writeln('  <style>');
    buffer.writeln(_cssTemplate);
    buffer.writeln('  </style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');

    // Container layout
    buffer.writeln('<div class="layout">');

    // Sidebar Navigation
    buffer.writeln('  <nav class="sidebar no-print">');
    buffer.writeln('    <div class="sidebar-header">');
    buffer.writeln('      <h2>$title</h2>');
    buffer.writeln('      <span class="badge">$type</span>');
    buffer.writeln('    </div>');
    buffer.writeln('    <ul class="nav-links">');
    buffer.writeln('      <li><a href="#cover">封面与概述</a></li>');
    if (options.includeSynopsis && work.summary.isNotEmpty) {
      buffer.writeln('      <li><a href="#synopsis">故事梗概</a></li>');
    }
    if (options.includeCastTable && castStats.isNotEmpty) {
      buffer.writeln('      <li><a href="#cast">登场演职表</a></li>');
    }
    buffer.writeln('      <li class="nav-section-title">分卷与章节大纲</li>');
    for (int i = 0; i < chapters.length; i++) {
      final ch = chapters[i];
      final chTitle = _escape(ch.title);
      buffer.writeln(
        '      <li><a href="#chapter-${ch.id}">第 ${i + 1} 章: $chTitle</a></li>',
      );
    }
    buffer.writeln('    </ul>');
    buffer.writeln('  </nav>');

    // Main Content
    buffer.writeln('  <main class="content">');

    // Cover page
    buffer.writeln('    <section id="cover" class="cover-page">');
    buffer.writeln('      <div class="cover-meta">$type · $status</div>');
    buffer.writeln('      <h1 class="cover-title">$title</h1>');
    buffer.writeln('      <div class="cover-stats">');
    buffer.writeln(
      '        <div class="stat-item"><span class="stat-num">${chapters.length}</span><span class="stat-lbl">章节</span></div>',
    );
    buffer.writeln(
      '        <div class="stat-item"><span class="stat-num">$totalScenes</span><span class="stat-lbl">分镜场景</span></div>',
    );
    if (options.includeWordCountStats) {
      buffer.writeln(
        '        <div class="stat-item"><span class="stat-num">$totalWords</span><span class="stat-lbl">总字数</span></div>',
      );
    }
    buffer.writeln('      </div>');
    buffer.writeln(
      '      <div class="cover-footer">由 OC Manager 导出 · $exportDate</div>',
    );
    buffer.writeln('    </section>');

    // Synopsis Section
    if (options.includeSynopsis && work.summary.isNotEmpty) {
      buffer.writeln('    <section id="synopsis" class="page-section">');
      buffer.writeln(
        '      <h2 class="section-title"><span class="icon">📖</span> 故事梗概</h2>',
      );
      buffer.writeln('      <div class="synopsis-box">');
      buffer.writeln('        ${_formatParagraphs(work.summary)}');
      buffer.writeln('      </div>');
      buffer.writeln('    </section>');
    }

    // Cast Table Section
    if (options.includeCastTable && castStats.isNotEmpty) {
      buffer.writeln('    <section id="cast" class="page-section">');
      buffer.writeln(
        '      <h2 class="section-title"><span class="icon">👥</span> 登场演职人员表 (Cast)</h2>',
      );
      buffer.writeln('      <div class="cast-grid">');
      for (final stat in castStats) {
        final c = stat.character;
        final name = _escape(c.name);
        final gender = _escape(c.gender.isNotEmpty ? c.gender : '-');
        final firstApp = stat.firstAppearance != null
            ? '${_escape(stat.firstAppearance!.chapter.title)} · ${_escape(stat.firstAppearance!.scene.title)}'
            : '-';
        buffer.writeln('        <div class="cast-card">');
        buffer.writeln(
          '          <div class="cast-name">$name <span class="cast-role">$gender</span></div>',
        );
        buffer.writeln('          <div class="cast-meta">初次登场：$firstApp</div>');
        buffer.writeln(
          '          <div class="cast-numbers">场景出场: <strong>${stat.sceneCount}</strong> 次 · 视点主导: <strong>${stat.povCount}</strong> 次</div>',
        );
        buffer.writeln('        </div>');
      }
      buffer.writeln('      </div>');
      buffer.writeln('    </section>');
    }

    // Chapters & Scenes Section
    buffer.writeln('    <section id="chapters" class="page-section">');
    String? currentArc;
    for (int i = 0; i < chapters.length; i++) {
      final ch = chapters[i];
      final chTitle = _escape(ch.title);

      if (ch.arcName.isNotEmpty && ch.arcName != currentArc) {
        currentArc = ch.arcName;
        buffer.writeln('      <div class="volume-header">');
        buffer.writeln('        <h3>📁 分卷：${_escape(currentArc)}</h3>');
        buffer.writeln('      </div>');
      }

      buffer.writeln(
        '      <article id="chapter-${ch.id}" class="chapter-card">',
      );
      buffer.writeln('        <header class="chapter-header">');
      buffer.writeln(
        '          <span class="chapter-index">第 ${i + 1} 章</span>',
      );
      buffer.writeln('          <h2 class="chapter-title">$chTitle</h2>');
      if (options.includeWordCountStats) {
        buffer.writeln(
          '          <span class="chapter-words">${ch.status} · ${ch.wordCount} 字</span>',
        );
      }
      buffer.writeln('        </header>');

      if (ch.summary.isNotEmpty) {
        buffer.writeln(
          '        <div class="chapter-summary">本章提要：${_escape(ch.summary)}</div>',
        );
      }

      // Scenes
      final scenes = chapterScenesMap[ch.id] ?? [];
      if (scenes.isNotEmpty) {
        if (options.includeSceneCards) {
          buffer.writeln('        <div class="scene-stream">');
          buffer.writeln(
            '          <h4 class="scene-stream-title">🎬 分镜规划大纲 (${scenes.length} 场景)</h4>',
          );
        }

        for (int sIdx = 0; sIdx < scenes.length; sIdx++) {
          final detail = scenes[sIdx];
          final sc = detail.scene;
          final pov = _escape(detail.povCharacter?.name ?? '上帝视点');
          final loc = _escape(
            detail.location?.name ??
                (sc.locationName.isNotEmpty ? sc.locationName : '未设定地点'),
          );
          final time = _escape(
            sc.timelineTime.isNotEmpty ? sc.timelineTime : '未注明',
          );
          final mood = sc.mood.isNotEmpty ? _escape(sc.mood) : null;
          final castList = detail.characterIds
              .map((id) => _escape(characterNameMap[id] ?? '人物#$id'))
              .toList();

          if (options.includeSceneCards) {
            buffer.writeln('          <div class="scene-item">');
            buffer.writeln('            <div class="scene-top">');
            buffer.writeln(
              '              <span class="scene-tag">场景 ${sIdx + 1}</span>',
            );
            buffer.writeln(
              '              <span class="scene-heading">${_escape(sc.title)}</span>',
            );
            if (mood != null) {
              buffer.writeln(
                '              <span class="mood-pill">$mood</span>',
              );
            }
            buffer.writeln('            </div>');
            buffer.writeln('            <div class="scene-meta-row">');
            buffer.writeln(
              '              <span>👁️ POV: <strong>$pov</strong></span>',
            );
            buffer.writeln(
              '              <span>📍 地点: <strong>$loc</strong></span>',
            );
            buffer.writeln(
              '              <span>⏱️ 时段: <strong>$time</strong></span>',
            );
            buffer.writeln('            </div>');
            if (castList.isNotEmpty) {
              buffer.writeln(
                '            <div class="scene-cast">登场：${castList.join('、')}</div>',
              );
            }
            if (sc.summary.isNotEmpty) {
              buffer.writeln(
                '            <div class="scene-summary">${_escape(sc.summary)}</div>',
              );
            }
            buffer.writeln('          </div>');
          }

          // Scene text content (if chapter content is enabled)
          if (options.includeChapterContent && sc.content.isNotEmpty) {
            buffer.writeln('          <div class="scene-body">');
            buffer.writeln(
              '            <div class="scene-body-label">【场景 ${sIdx + 1} 正文/台词】</div>',
            );
            buffer.writeln('            ${_formatParagraphs(sc.content)}');
            buffer.writeln('          </div>');
          }
        }

        if (options.includeSceneCards) {
          buffer.writeln('        </div>');
        }
      }

      buffer.writeln('      </article>');
    }
    buffer.writeln('    </section>');

    buffer.writeln('  </main>');
    buffer.writeln('</div>');

    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }

  static String _escape(String input) {
    return const HtmlEscape().convert(input);
  }

  static String _formatParagraphs(String raw) {
    final paras = raw.split(RegExp(r'\r?\n+'));
    return paras
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .map((p) => '<p>${_escape(p)}</p>')
        .join('\n');
  }

  static const String _cssTemplate = '''
:root {
  --primary: #4F46E5;
  --primary-light: #EEF2FF;
  --bg: #F8FAFC;
  --surface: #FFFFFF;
  --text: #1E293B;
  --text-muted: #64748B;
  --border: #E2E8F0;
  --font-serif: "Songti SC", "SimSun", "Noto Serif SC", serif;
  --font-sans: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "PingFang SC", "Microsoft YaHei", sans-serif;
}
* { box-sizing: border-box; margin: 0; padding: 0; }
body {
  font-family: var(--font-sans);
  background: var(--bg);
  color: var(--text);
  line-height: 1.7;
}
.layout { display: flex; min-height: 100vh; }
.sidebar {
  width: 280px;
  background: var(--surface);
  border-right: 1px solid var(--border);
  position: sticky;
  top: 0;
  height: 100vh;
  overflow-y: auto;
  padding: 24px 16px;
  flex-shrink: 0;
}
.sidebar-header h2 { font-size: 18px; margin-bottom: 6px; font-weight: 700; }
.badge { display: inline-block; font-size: 11px; padding: 2px 8px; background: var(--primary-light); color: var(--primary); border-radius: 12px; font-weight: 600; }
.nav-links { list-style: none; margin-top: 20px; }
.nav-links li { margin-bottom: 6px; }
.nav-links a { color: var(--text-muted); text-decoration: none; font-size: 13px; display: block; padding: 6px 10px; border-radius: 6px; transition: all 0.2s; }
.nav-links a:hover { background: var(--primary-light); color: var(--primary); }
.nav-section-title { font-size: 11px; font-weight: bold; color: var(--text-muted); margin: 16px 0 6px 10px; text-transform: uppercase; }
.content { flex: 1; max-width: 900px; margin: 0 auto; padding: 48px 32px; }
.cover-page { text-align: center; padding: 60px 0 80px; border-bottom: 2px solid var(--border); margin-bottom: 48px; }
.cover-meta { font-size: 14px; color: var(--primary); font-weight: 600; margin-bottom: 12px; letter-spacing: 2px; }
.cover-title { font-size: 38px; font-family: var(--font-serif); font-weight: bold; margin-bottom: 24px; color: #0F172A; }
.cover-stats { display: flex; justify-content: center; gap: 32px; margin-bottom: 24px; }
.stat-item { display: flex; flex-direction: column; align-items: center; }
.stat-num { font-size: 26px; font-weight: bold; color: var(--primary); }
.stat-lbl { font-size: 12px; color: var(--text-muted); }
.cover-footer { font-size: 12px; color: var(--text-muted); }
.page-section { margin-bottom: 48px; }
.section-title { font-size: 22px; font-weight: 700; margin-bottom: 20px; display: flex; align-items: center; gap: 8px; border-bottom: 2px solid var(--primary-light); padding-bottom: 8px; }
.synopsis-box { background: var(--surface); border: 1px solid var(--border); border-radius: 12px; padding: 24px; font-size: 15px; line-height: 1.8; color: #334155; }
.cast-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 16px; }
.cast-card { background: var(--surface); border: 1px solid var(--border); border-radius: 10px; padding: 14px; box-shadow: 0 1px 3px rgba(0,0,0,0.04); }
.cast-name { font-size: 15px; font-weight: bold; margin-bottom: 4px; display: flex; justify-content: space-between; align-items: center; }
.cast-role { font-size: 11px; padding: 1px 6px; background: #F1F5F9; border-radius: 4px; color: var(--text-muted); font-weight: normal; }
.cast-meta { font-size: 12px; color: var(--text-muted); margin-bottom: 6px; }
.cast-numbers { font-size: 12px; color: #475569; }
.volume-header { background: #E2E8F0; padding: 8px 16px; border-radius: 8px; margin: 32px 0 16px; }
.volume-header h3 { font-size: 16px; color: #1E293B; }
.chapter-card { background: var(--surface); border: 1px solid var(--border); border-radius: 14px; padding: 32px; margin-bottom: 32px; box-shadow: 0 2px 6px rgba(0,0,0,0.03); }
.chapter-header { display: flex; align-items: baseline; gap: 12px; margin-bottom: 12px; border-bottom: 1px solid var(--border); padding-bottom: 12px; }
.chapter-index { font-size: 13px; font-weight: 700; color: var(--primary); }
.chapter-title { font-size: 24px; font-family: var(--font-serif); flex: 1; }
.chapter-words { font-size: 12px; color: var(--text-muted); }
.chapter-summary { font-size: 13px; color: #475569; font-style: italic; margin-bottom: 20px; background: #F8FAFC; padding: 8px 12px; border-left: 3px solid var(--primary); }
.scene-stream { margin: 24px 0; background: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 10px; padding: 16px; }
.scene-stream-title { font-size: 13px; font-weight: 700; color: #475569; margin-bottom: 12px; }
.scene-item { background: var(--surface); border: 1px solid #E2E8F0; border-radius: 8px; padding: 12px 14px; margin-bottom: 10px; }
.scene-top { display: flex; align-items: center; gap: 8px; margin-bottom: 6px; }
.scene-tag { font-size: 10px; font-weight: 700; background: #E0E7FF; color: #4338CA; padding: 2px 6px; border-radius: 4px; }
.scene-heading { font-size: 14px; font-weight: bold; flex: 1; }
.mood-pill { font-size: 10px; background: #FEF3C7; color: #D97706; padding: 2px 8px; border-radius: 10px; font-weight: 600; }
.scene-meta-row { font-size: 12px; color: var(--text-muted); display: flex; gap: 16px; margin-bottom: 6px; flex-wrap: wrap; }
.scene-cast { font-size: 12px; color: #475569; margin-bottom: 4px; }
.scene-summary { font-size: 13px; color: #334155; line-height: 1.6; border-top: 1px dashed #E2E8F0; padding-top: 6px; margin-top: 6px; }
.scene-body { font-family: var(--font-serif); font-size: 15px; line-height: 1.9; color: #1E293B; margin-top: 10px; padding: 12px 16px; background: #FFFFFF; border-radius: 6px; border-left: 3px solid #6366F1; }
.scene-body-label { font-size: 11px; font-family: var(--font-sans); color: var(--primary); font-weight: bold; margin-bottom: 6px; }
.scene-body p { margin-bottom: 12px; text-indent: 2em; }

@media print {
  body { background: white; }
  .no-print { display: none !important; }
  .layout { display: block; }
  .content { max-width: 100%; padding: 0; }
  .chapter-card { border: none; box-shadow: none; padding: 0; page-break-before: always; }
  .cover-page { height: 100vh; display: flex; flex-direction: column; justify-content: center; border: none; }
}
''';
}

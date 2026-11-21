import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/daos/story_dao.dart';
import 'story_script_export_models.dart';

/// Builder for generating Markdown story scripts and ZIP project packages.
class StoryScriptMarkdownBuilder {
  const StoryScriptMarkdownBuilder._();

  /// Builds a single comprehensive Markdown document containing the whole story.
  static String buildSingleMarkdown({
    required StoryWork work,
    required List<StoryChapter> chapters,
    required Map<int, List<StorySceneDetail>> chapterScenesMap,
    required List<WorkCastMemberStats> castStats,
    required Map<int, String> characterNameMap,
    required StoryScriptExportOptions options,
  }) {
    final buffer = StringBuffer();

    // 1. Header & Title
    buffer.writeln('# ${work.title}');
    buffer.writeln();

    // Metadata block
    buffer.writeln('**类型**：${work.type}  ');
    buffer.writeln('**状态**：${work.status}  ');
    if (options.includeWordCountStats) {
      final totalWords = chapters.fold<int>(0, (sum, c) => sum + c.wordCount);
      buffer.writeln('**全书规模**：${chapters.length} 章节 · $totalWords 字  ');
    }
    buffer.writeln(
      '**导出时间**：${DateTime.now().toIso8601String().substring(0, 10)}  ',
    );
    buffer.writeln();

    // 2. Synopsis
    if (options.includeSynopsis && work.summary.isNotEmpty) {
      buffer.writeln('## 📖 故事梗概');
      buffer.writeln();
      buffer.writeln(work.summary);
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
    }

    // 3. Cast Table
    if (options.includeCastTable && castStats.isNotEmpty) {
      buffer.writeln('## 👥 登场演职人员表 (Cast)');
      buffer.writeln();
      buffer.writeln('| 角色姓名 | 性别 | 初次登场 | 场景出场次数 | POV 视点次数 |');
      buffer.writeln('| :--- | :---: | :--- | :---: | :---: |');
      for (final stat in castStats) {
        final c = stat.character;
        final gender = c.gender.isNotEmpty ? c.gender : '-';
        final firstApp = stat.firstAppearance != null
            ? '${stat.firstAppearance!.chapter.title} (场景: ${stat.firstAppearance!.scene.title})'
            : '-';
        buffer.writeln(
          '| **${c.name}** | $gender | $firstApp | ${stat.sceneCount} | ${stat.povCount} |',
        );
      }
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
    }

    // 4. Chapters & Scenes
    buffer.writeln('## 📑 章节与分镜正文');
    buffer.writeln();

    String? currentArc;
    for (int i = 0; i < chapters.length; i++) {
      final ch = chapters[i];

      // Volume / Arc heading if changed
      if (ch.arcName.isNotEmpty && ch.arcName != currentArc) {
        currentArc = ch.arcName;
        buffer.writeln('### 📁 分卷：$currentArc');
        buffer.writeln();
      }

      buffer.writeln('#### 第 ${i + 1} 章：${ch.title}');
      buffer.writeln();

      if (options.includeWordCountStats) {
        buffer.writeln('*状态：${ch.status} · 字数：${ch.wordCount} 字*  ');
      }
      if (ch.summary.isNotEmpty) {
        buffer.writeln('*本章提要：${ch.summary}*  ');
      }
      buffer.writeln();

      // Scene Cards for this chapter
      final scenes = chapterScenesMap[ch.id] ?? [];
      if (scenes.isNotEmpty) {
        if (options.includeSceneCards) {
          buffer.writeln('##### 🎬 分镜规划大纲 (${scenes.length} 场景)');
          buffer.writeln();
        }

        for (int sIdx = 0; sIdx < scenes.length; sIdx++) {
          final detail = scenes[sIdx];
          final sc = detail.scene;
          final povName = detail.povCharacter?.name ?? '上帝视点';
          final locName =
              detail.location?.name ??
              (sc.locationName.isNotEmpty ? sc.locationName : '未设定地点');
          final timeStr = sc.timelineTime.isNotEmpty ? sc.timelineTime : '未注明';
          final castNames = detail.characterIds
              .map((id) => characterNameMap[id] ?? '人物#$id')
              .join('、');

          if (options.includeSceneCards) {
            buffer.writeln('> **场景 ${sIdx + 1}：${sc.title}**  ');
            buffer.writeln(
              '> - 视点 (POV)：$povName | 地点：$locName | 时段：$timeStr  ',
            );
            if (sc.mood.isNotEmpty) {
              buffer.writeln('> - 情感基调：${sc.mood}  ');
            }
            if (castNames.isNotEmpty) {
              buffer.writeln('> - 出场人物：$castNames  ');
            }
            if (sc.summary.isNotEmpty) {
              buffer.writeln('> - 剧情大纲：${sc.summary}  ');
            }
            buffer.writeln();
          }

          // Scene text content (if chapter content is enabled)
          if (options.includeChapterContent && sc.content.isNotEmpty) {
            buffer.writeln('###### 【分镜 ${sIdx + 1} 正文/剧本台词】');
            buffer.writeln();
            buffer.writeln(sc.content);
            buffer.writeln();
          }
        }
      }

      buffer.writeln('---');
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Exports story chapters as a directory structure inside a ZIP file.
  static Future<void> exportMarkdownZip({
    required StoryWork work,
    required List<StoryChapter> chapters,
    required Map<int, List<StorySceneDetail>> chapterScenesMap,
    required List<WorkCastMemberStats> castStats,
    required Map<int, String> characterNameMap,
    required StoryScriptExportOptions options,
    required String outputPath,
  }) async {
    final archive = Archive();
    final sanitizedWorkTitle = _sanitizeFileName(work.title);

    // 1. Overview file: 00_故事梗概与人物表.md
    final overviewBuf = StringBuffer();
    overviewBuf.writeln('# ${work.title} - 故事概述与演职表');
    overviewBuf.writeln();
    overviewBuf.writeln('**类型**：${work.type}  ');
    overviewBuf.writeln('**状态**：${work.status}  ');
    final totalWords = chapters.fold<int>(0, (sum, c) => sum + c.wordCount);
    overviewBuf.writeln('**规模**：${chapters.length} 章节 · $totalWords 字  ');
    overviewBuf.writeln();

    if (work.summary.isNotEmpty) {
      overviewBuf.writeln('## 故事梗概');
      overviewBuf.writeln();
      overviewBuf.writeln(work.summary);
      overviewBuf.writeln();
    }

    if (options.includeCastTable && castStats.isNotEmpty) {
      overviewBuf.writeln('## 登场演职人员表 (Cast)');
      overviewBuf.writeln();
      overviewBuf.writeln('| 角色姓名 | 性别 | 初次登场 | 场景出场次数 | POV 视点次数 |');
      overviewBuf.writeln('| :--- | :---: | :--- | :---: | :---: |');
      for (final stat in castStats) {
        final c = stat.character;
        final gender = c.gender.isNotEmpty ? c.gender : '-';
        final firstApp = stat.firstAppearance != null
            ? '${stat.firstAppearance!.chapter.title} (场景: ${stat.firstAppearance!.scene.title})'
            : '-';
        overviewBuf.writeln(
          '| **${c.name}** | $gender | $firstApp | ${stat.sceneCount} | ${stat.povCount} |',
        );
      }
    }

    final overviewBytes = utf8.encode(overviewBuf.toString());
    archive.addFile(
      ArchiveFile(
        '$sanitizedWorkTitle/00_故事梗概与演职表.md',
        overviewBytes.length,
        overviewBytes,
      ),
    );

    // 2. Chapter files
    for (int i = 0; i < chapters.length; i++) {
      final ch = chapters[i];
      final chNum = (i + 1).toString().padLeft(2, '0');
      final sanitizedChTitle = _sanitizeFileName(ch.title);
      final arcName = ch.arcName.isNotEmpty
          ? _sanitizeFileName(ch.arcName)
          : '正卷';

      final chBuf = StringBuffer();
      chBuf.writeln('# 第 $chNum 章：${ch.title}');
      chBuf.writeln();
      if (options.includeWordCountStats) {
        chBuf.writeln('*状态：${ch.status} · 字数：${ch.wordCount} 字*  ');
      }
      if (ch.summary.isNotEmpty) {
        chBuf.writeln('*剧情摘要：${ch.summary}*  ');
      }
      chBuf.writeln();

      // Scenes
      final scenes = chapterScenesMap[ch.id] ?? [];
      if (scenes.isNotEmpty) {
        if (options.includeSceneCards) {
          chBuf.writeln('## 🎬 分镜规划大纲 (${scenes.length} 场景)');
          chBuf.writeln();
        }

        for (int sIdx = 0; sIdx < scenes.length; sIdx++) {
          final detail = scenes[sIdx];
          final sc = detail.scene;
          final povName = detail.povCharacter?.name ?? '上帝视点';
          final locName =
              detail.location?.name ??
              (sc.locationName.isNotEmpty ? sc.locationName : '未设定地点');
          final timeStr = sc.timelineTime.isNotEmpty ? sc.timelineTime : '未注明';
          final castNames = detail.characterIds
              .map((id) => characterNameMap[id] ?? '人物#$id')
              .join('、');

          if (options.includeSceneCards) {
            chBuf.writeln('> **场景 ${sIdx + 1}：${sc.title}**  ');
            chBuf.writeln(
              '> - 视点 (POV)：$povName | 地点：$locName | 时段：$timeStr  ',
            );
            if (sc.mood.isNotEmpty) {
              chBuf.writeln('> - 情感基调：${sc.mood}  ');
            }
            if (castNames.isNotEmpty) {
              chBuf.writeln('> - 出场人物：$castNames  ');
            }
            if (sc.summary.isNotEmpty) {
              chBuf.writeln('> - 剧情大纲：${sc.summary}  ');
            }
            chBuf.writeln();
          }

          if (options.includeChapterContent && sc.content.isNotEmpty) {
            chBuf.writeln('### 【分镜 ${sIdx + 1} 正文/台词】');
            chBuf.writeln();
            chBuf.writeln(sc.content);
            chBuf.writeln();
          }
        }
      }

      final chBytes = utf8.encode(chBuf.toString());
      final entryPath =
          '$sanitizedWorkTitle/$arcName/${chNum}_$sanitizedChTitle.md';
      archive.addFile(ArchiveFile(entryPath, chBytes.length, chBytes));
    }

    final zipData = ZipEncoder().encode(archive);
    final file = File(outputPath);
    await file.writeAsBytes(zipData);
  }

  static String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  }
}

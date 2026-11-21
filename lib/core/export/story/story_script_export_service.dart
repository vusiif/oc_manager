import 'dart:io';
import 'package:drift/drift.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/daos/story_dao.dart';
import 'story_script_export_models.dart';
import 'story_script_html_builder.dart';
import 'story_script_markdown_builder.dart';

/// Service orchestrating the extraction, compilation, and export of story scripts and scene outlines.
class StoryScriptExportService {
  final AppDatabase db;

  const StoryScriptExportService(this.db);

  /// Compiles story data and exports to [outputPath] according to [options].
  Future<void> exportWorkScript({
    required int workId,
    required StoryScriptExportOptions options,
    required String outputPath,
  }) async {
    // 1. Fetch work
    final work = await db.storyDao.getWorkById(workId);
    if (work == null) {
      throw Exception('StoryWork with ID $workId does not exist.');
    }

    // 2. Fetch all chapters for this work
    final allChapters =
        await (db.select(db.storyChapters)
              ..where((t) => t.workId.equals(workId))
              ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
            .get();

    // Filter by selected chapters if specified
    final chapters = options.selectedChapterIds != null
        ? allChapters
              .where((c) => options.selectedChapterIds!.contains(c.id))
              .toList()
        : allChapters;

    // 3. Fetch scenes for these chapters with details
    final chapterScenesMap = <int, List<StorySceneDetail>>{};
    for (final ch in chapters) {
      final details = await db.storyDao.getSceneDetailsByChapter(ch.id);
      chapterScenesMap[ch.id] = details;
    }

    // 4. Fetch cast stats & character name map
    final castStats = await db.storyDao.getWorkCharacterCastStats(workId);
    final allCharacters = await db.select(db.characters).get();
    final characterNameMap = {for (final c in allCharacters) c.id: c.name};

    // 5. Dispatch to appropriate format builder
    switch (options.format) {
      case StoryScriptExportFormat.html:
        await StoryScriptHtmlBuilder.exportHtml(
          work: work,
          chapters: chapters,
          chapterScenesMap: chapterScenesMap,
          castStats: castStats,
          characterNameMap: characterNameMap,
          options: options,
          outputPath: outputPath,
        );
        break;

      case StoryScriptExportFormat.singleMarkdown:
        final mdString = StoryScriptMarkdownBuilder.buildSingleMarkdown(
          work: work,
          chapters: chapters,
          chapterScenesMap: chapterScenesMap,
          castStats: castStats,
          characterNameMap: characterNameMap,
          options: options,
        );
        final file = File(outputPath);
        await file.writeAsString(mdString);
        break;

      case StoryScriptExportFormat.markdownZip:
        await StoryScriptMarkdownBuilder.exportMarkdownZip(
          work: work,
          chapters: chapters,
          chapterScenesMap: chapterScenesMap,
          castStats: castStats,
          characterNameMap: characterNameMap,
          options: options,
          outputPath: outputPath,
        );
        break;
    }
  }
}

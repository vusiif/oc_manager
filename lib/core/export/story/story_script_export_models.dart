/// Export format options for story scripts and scene outlines.
enum StoryScriptExportFormat {
  /// Standalone interactive and printable HTML document.
  html('高颜值排版手册 (HTML/打印PDF)', '.html'),

  /// Single comprehensive Markdown script document.
  singleMarkdown('单一剧本文档 (Markdown)', '.md'),

  /// ZIP package with chapter-by-chapter Markdown directory structure.
  markdownZip('分章工程包 (Markdown ZIP)', '.zip');

  final String label;
  final String extension;
  const StoryScriptExportFormat(this.label, this.extension);
}

/// Configuration options for exporting story scripts.
class StoryScriptExportOptions {
  final bool includeSynopsis;
  final bool includeCastTable;
  final bool includeSceneCards;
  final bool includeChapterContent;
  final bool includeWordCountStats;
  final Set<int>? selectedChapterIds;
  final StoryScriptExportFormat format;

  const StoryScriptExportOptions({
    this.includeSynopsis = true,
    this.includeCastTable = true,
    this.includeSceneCards = true,
    this.includeChapterContent = true,
    this.includeWordCountStats = true,
    this.selectedChapterIds,
    this.format = StoryScriptExportFormat.html,
  });

  StoryScriptExportOptions copyWith({
    bool? includeSynopsis,
    bool? includeCastTable,
    bool? includeSceneCards,
    bool? includeChapterContent,
    bool? includeWordCountStats,
    Set<int>? selectedChapterIds,
    StoryScriptExportFormat? format,
  }) {
    return StoryScriptExportOptions(
      includeSynopsis: includeSynopsis ?? this.includeSynopsis,
      includeCastTable: includeCastTable ?? this.includeCastTable,
      includeSceneCards: includeSceneCards ?? this.includeSceneCards,
      includeChapterContent:
          includeChapterContent ?? this.includeChapterContent,
      includeWordCountStats:
          includeWordCountStats ?? this.includeWordCountStats,
      selectedChapterIds: selectedChapterIds ?? this.selectedChapterIds,
      format: format ?? this.format,
    );
  }
}

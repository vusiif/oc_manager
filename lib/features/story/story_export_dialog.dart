import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/design_tokens.dart';
import '../../core/export/story/story_script_export_models.dart';
import '../../core/export/story/story_script_export_service.dart';
import '../../data/database/app_database.dart';
import '../../providers/database_provider.dart';
import '../../providers/story_provider.dart';

/// Dialog enabling authors to export their story scripts, scene outlines, and cast tables.
class StoryExportDialog extends ConsumerStatefulWidget {
  final StoryWork work;

  const StoryExportDialog({super.key, required this.work});

  static Future<void> show(BuildContext context, StoryWork work) {
    return showDialog(
      context: context,
      builder: (_) => StoryExportDialog(work: work),
    );
  }

  @override
  ConsumerState<StoryExportDialog> createState() => _StoryExportDialogState();
}

class _StoryExportDialogState extends ConsumerState<StoryExportDialog> {
  StoryScriptExportFormat _format = StoryScriptExportFormat.html;
  bool _includeSynopsis = true;
  bool _includeCastTable = true;
  bool _includeSceneCards = true;
  bool _includeChapterContent = true;
  bool _includeWordCountStats = true;

  Set<int> _selectedChapterIds = {};
  bool _initializedChapters = false;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chaptersAsync = ref.watch(chaptersByWorkProvider(widget.work.id));

    final chapters = chaptersAsync.valueOrNull ?? [];
    if (!_initializedChapters && chapters.isNotEmpty) {
      _selectedChapterIds = chapters.map((c) => c.id).toSet();
      _initializedChapters = true;
    }

    final selectedChapters = chapters
        .where((c) => _selectedChapterIds.contains(c.id))
        .toList();
    final selectedWords = selectedChapters.fold<int>(
      0,
      (sum, c) => sum + c.wordCount,
    );

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.import_contacts_rounded, color: AppColors.brand),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '导出剧本与分镜大纲 · ${widget.work.title}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Format Selection
              const Text(
                '选择导出格式',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              RadioGroup<StoryScriptExportFormat>(
                groupValue: _format,
                onChanged: (val) {
                  if (val != null) setState(() => _format = val);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: StoryScriptExportFormat.values.map((f) {
                    return RadioListTile<StoryScriptExportFormat>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: f,
                      title: Text(
                        f.label,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        _formatDescription(f),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const Divider(height: 24),

              // 2. Content Modules Toggle
              const Text(
                '导出包含内容',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: _includeSynopsis,
                title: const Text(
                  '包含故事梗概与基础属性',
                  style: TextStyle(fontSize: 13),
                ),
                onChanged: (v) => setState(() => _includeSynopsis = v ?? true),
              ),
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: _includeCastTable,
                title: const Text(
                  '包含演职人员登场统计表',
                  style: TextStyle(fontSize: 13),
                ),
                onChanged: (v) => setState(() => _includeCastTable = v ?? true),
              ),
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: _includeSceneCards,
                title: const Text(
                  '包含分镜规划大纲 (POV/地点/时段/基调)',
                  style: TextStyle(fontSize: 13),
                ),
                onChanged: (v) =>
                    setState(() => _includeSceneCards = v ?? true),
              ),
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: _includeChapterContent,
                title: const Text(
                  '包含场景剧情正文与台词',
                  style: TextStyle(fontSize: 13),
                ),
                onChanged: (v) =>
                    setState(() => _includeChapterContent = v ?? true),
              ),
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: _includeWordCountStats,
                title: const Text(
                  '包含章节状态与字数统计',
                  style: TextStyle(fontSize: 13),
                ),
                onChanged: (v) =>
                    setState(() => _includeWordCountStats = v ?? true),
              ),

              const Divider(height: 24),

              // 3. Chapters Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '导出章节范围 (${selectedChapters.length}/${chapters.length} 章 · $selectedWords 字)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (_selectedChapterIds.length == chapters.length) {
                          _selectedChapterIds.clear();
                        } else {
                          _selectedChapterIds = chapters
                              .map((c) => c.id)
                              .toSet();
                        }
                      });
                    },
                    child: Text(
                      _selectedChapterIds.length == chapters.length
                          ? '反选/清空'
                          : '全选',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
                child: chapters.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            '当前作品暂无章节',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: chapters.length,
                        itemBuilder: (ctx, idx) {
                          final ch = chapters[idx];
                          final isSelected = _selectedChapterIds.contains(
                            ch.id,
                          );
                          return CheckboxListTile(
                            dense: true,
                            value: isSelected,
                            title: Text(
                              '第 ${idx + 1} 章: ${ch.title}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            subtitle: Text(
                              '${ch.arcName} · ${ch.wordCount} 字',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _selectedChapterIds.add(ch.id);
                                } else {
                                  _selectedChapterIds.remove(ch.id);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          icon: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.file_download_rounded, size: 18),
          label: Text(_isExporting ? '导出中...' : '开始导出'),
          onPressed: (_isExporting || _selectedChapterIds.isEmpty)
              ? null
              : _handleExport,
        ),
      ],
    );
  }

  Future<void> _handleExport() async {
    final messenger = ScaffoldMessenger.of(context);
    final db = ref.read(databaseProvider);
    final service = StoryScriptExportService(db);

    final defaultFileName = '${widget.work.title}_剧本大纲${_format.extension}';

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: '选择保存位置',
      fileName: defaultFileName,
      type: FileType.custom,
      allowedExtensions: [_format.extension.replaceAll('.', '')],
    );

    if (savePath == null) return;

    var actualPath = savePath;
    if (!actualPath.toLowerCase().endsWith(_format.extension)) {
      actualPath += _format.extension;
    }

    setState(() => _isExporting = true);

    try {
      final options = StoryScriptExportOptions(
        format: _format,
        includeSynopsis: _includeSynopsis,
        includeCastTable: _includeCastTable,
        includeSceneCards: _includeSceneCards,
        includeChapterContent: _includeChapterContent,
        includeWordCountStats: _includeWordCountStats,
        selectedChapterIds: _selectedChapterIds,
      );

      await service.exportWorkScript(
        workId: widget.work.id,
        options: options,
        outputPath: actualPath,
      );

      if (mounted) {
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text('已成功导出【${widget.work.title}】至: $actualPath'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text('导出失败: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  static String _formatDescription(StoryScriptExportFormat f) {
    switch (f) {
      case StoryScriptExportFormat.html:
        return '单文件离线网页，优雅书本排版、响应式目录索引，支持浏览器直接另存为精美 PDF';
      case StoryScriptExportFormat.singleMarkdown:
        return '单一 Markdown 文档，包含完整大纲、演职表、分镜卡片与正文';
      case StoryScriptExportFormat.markdownZip:
        return '标准分卷目录结构 ZIP 压缩包，方便导入 Obsidian、Scrivener 或 Notion 生产力工具';
    }
  }
}

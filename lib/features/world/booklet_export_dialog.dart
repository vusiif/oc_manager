import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/export/booklet_export_service.dart';
import '../../core/export/models/export_bundle.dart';
import '../../data/database/app_database.dart';
import '../../providers/character_provider.dart';
import '../../providers/database_provider.dart';

/// Interactive modal dialog for configuring and generating world booklets
class BookletExportDialog extends ConsumerStatefulWidget {
  final World world;

  const BookletExportDialog({super.key, required this.world});

  static Future<void> show(BuildContext context, World world) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BookletExportDialog(world: world),
    );
  }

  @override
  ConsumerState<BookletExportDialog> createState() => _BookletExportDialogState();
}

class _BookletExportDialogState extends ConsumerState<BookletExportDialog> {
  BookletFormat _format = BookletFormat.html;
  bool _includeWorldOverview = true;
  bool _includeGroups = true;
  bool _includeTimeline = true;
  bool _includeCharacters = true;
  bool _includeRadarStats = true;
  bool _includeGalleries = true;
  bool _includeRelations = true;

  Set<int>? _selectedCharacterIds;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final charactersAsync = ref.watch(charactersByWorldProvider(widget.world.id));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.menu_book,
                      color: Theme.of(context).colorScheme.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '生成世界设定集 (Booklet Export)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '将「${widget.world.name}」一键编译为出版级独立设定集或知识库文档',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Scrollable Options Content
              Expanded(
                child: ListView(
                  children: [
                    // Format Selection
                    const Text(
                      '出版导出格式',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<BookletFormat>(
                      segments: const [
                        ButtonSegment(
                          value: BookletFormat.html,
                          icon: Icon(Icons.html),
                          label: Text('HTML 出版设定集 (打印/PDF 就绪)'),
                        ),
                        ButtonSegment(
                          value: BookletFormat.markdownZip,
                          icon: Icon(Icons.folder_zip),
                          label: Text('Markdown 文档树 (.zip 归档)'),
                        ),
                      ],
                      selected: {_format},
                      onSelectionChanged: _isExporting
                          ? null
                          : (newSet) {
                              setState(() {
                                _format = newSet.first;
                              });
                            },
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _format == BookletFormat.html
                            ? '💡 单文件免安装，浏览器直接打开；内置 A4 打印样式与 SVG 矢量雷达图，随时 Ctrl+P 保存为高清出版级 PDF 设定集。'
                            : '💡 打包为 Obsidian / Notion / Logseq 友好的 Markdown 文档树，保留 YAML Frontmatter、维基双链与本地相对资源图片。',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section Switches
                    const Text(
                      '包含章节模块',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    CheckboxListTile(
                      dense: true,
                      title: const Text('世界序章与核心背景概况'),
                      subtitle: const Text('包含世界命名、核心背景大纲与全局资产总览'),
                      value: _includeWorldOverview,
                      onChanged: _isExporting ? null : (v) => setState(() => _includeWorldOverview = v ?? true),
                    ),
                    CheckboxListTile(
                      dense: true,
                      title: const Text('组织势力与派系一览'),
                      subtitle: const Text('收录世界内的所有阵营名称与从属角色成员'),
                      value: _includeGroups,
                      onChanged: _isExporting ? null : (v) => setState(() => _includeGroups = v ?? true),
                    ),
                    CheckboxListTile(
                      dense: true,
                      title: const Text('纪元编年史与大事件'),
                      subtitle: const Text('按纪年排版的历史大事记、重要度星级与分类'),
                      value: _includeTimeline,
                      onChanged: _isExporting ? null : (v) => setState(() => _includeTimeline = v ?? true),
                    ),
                    CheckboxListTile(
                      dense: true,
                      title: const Text('角色档案全录与背景小传'),
                      subtitle: const Text('包含角色头像、基础资料、背景小传与生平轨迹'),
                      value: _includeCharacters,
                      onChanged: _isExporting
                          ? null
                          : (v) {
                              setState(() {
                                _includeCharacters = v ?? true;
                                if (!_includeCharacters) {
                                  _includeRadarStats = false;
                                  _includeGalleries = false;
                                }
                              });
                            },
                    ),
                    if (_includeCharacters) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 28.0),
                        child: Column(
                          children: [
                            CheckboxListTile(
                              dense: true,
                              title: const Text('六维特质雷达图'),
                              subtitle: const Text('包含纯矢量多边形 SVG 雷达图与数值分级评估表'),
                              value: _includeRadarStats,
                              onChanged: _isExporting ? null : (v) => setState(() => _includeRadarStats = v ?? true),
                            ),
                            CheckboxListTile(
                              dense: true,
                              title: const Text('差分画廊与立绘相册'),
                              subtitle: const Text('打包并内嵌角色的所有差分立绘切片与图片描述'),
                              value: _includeGalleries,
                              onChanged: _isExporting ? null : (v) => setState(() => _includeGalleries = v ?? true),
                            ),
                          ],
                        ),
                      ),
                    ],
                    CheckboxListTile(
                      dense: true,
                      title: const Text('全局人际关系拓扑'),
                      subtitle: const Text('收录所有单向/双向人物关系连结矩阵'),
                      value: _includeRelations,
                      onChanged: _isExporting ? null : (v) => setState(() => _includeRelations = v ?? true),
                    ),
                    const SizedBox(height: 12),

                    // Filter Specific Characters
                    charactersAsync.when(
                      data: (chars) {
                        if (chars.isEmpty) return const SizedBox.shrink();
                        final isAllSelected = _selectedCharacterIds == null || _selectedCharacterIds!.length == chars.length;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '收录角色选择 (${_selectedCharacterIds?.length ?? chars.length}/${chars.length})',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                TextButton(
                                  onPressed: _isExporting
                                      ? null
                                      : () {
                                          setState(() {
                                            if (isAllSelected) {
                                              _selectedCharacterIds = {};
                                            } else {
                                              _selectedCharacterIds = null;
                                            }
                                          });
                                        },
                                  child: Text(isAllSelected ? '全部取消' : '全部勾选'),
                                ),
                              ],
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: chars.map((c) {
                                final isSelected = _selectedCharacterIds == null || _selectedCharacterIds!.contains(c.id);
                                return FilterChip(
                                  label: Text(c.name),
                                  selected: isSelected,
                                  onSelected: _isExporting
                                      ? null
                                      : (selected) {
                                          setState(() {
                                            final current = Set<int>.from(_selectedCharacterIds ?? chars.map((e) => e.id));
                                            if (selected) {
                                              current.add(c.id);
                                            } else {
                                              current.remove(c.id);
                                            }
                                            _selectedCharacterIds = current.length == chars.length ? null : current;
                                          });
                                        },
                                );
                              }).toList(),
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _isExporting ? null : _handleExport,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.download),
                    label: Text(_isExporting ? '编译导出中...' : '开始编译导出'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleExport() async {
    final defaultExt = _format == BookletFormat.html ? 'html' : 'zip';
    final nowStr = DateTime.now().toLocal().toString().split('.').first.replaceAll(':', '-').replaceAll(' ', '_');
    final defaultFileName = '${widget.world.name}_设定集_$nowStr.$defaultExt';

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: '保存设定集',
      fileName: defaultFileName,
      type: FileType.custom,
      allowedExtensions: [defaultExt],
    );

    if (savePath == null) return;

    setState(() => _isExporting = true);

    try {
      final exportService = ref.read(bookletExportServiceProvider);
      final options = BookletExportOptions(
        includeWorldOverview: _includeWorldOverview,
        includeGroups: _includeGroups,
        includeTimeline: _includeTimeline,
        includeCharacters: _includeCharacters,
        includeRadarStats: _includeRadarStats,
        includeGalleries: _includeGalleries,
        includeRelations: _includeRelations,
        selectedCharacterIds: _selectedCharacterIds,
        format: _format,
      );

      await exportService.exportBooklet(
        worldId: widget.world.id,
        outputPath: savePath,
        options: options,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('设定集导出成功！已保存至：$savePath'),
            action: SnackBarAction(
              label: '完成',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败：$e')),
        );
      }
    }
  }
}

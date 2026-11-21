export 'character_poster_card.dart';
import 'character_poster_card.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/storage/image_storage_service.dart';
import '../../data/database/app_database.dart';
import '../../providers/character_provider.dart';
import '../../providers/tag_provider.dart';
import '../../providers/world_provider.dart';

class CharacterPosterDialog extends ConsumerStatefulWidget {
  final Character character;
  final int worldId;

  const CharacterPosterDialog({
    super.key,
    required this.character,
    required this.worldId,
  });

  @override
  ConsumerState<CharacterPosterDialog> createState() =>
      _CharacterPosterDialogState();
}

class _CharacterPosterDialogState extends ConsumerState<CharacterPosterDialog> {
  final GlobalKey _posterKey = GlobalKey();

  PosterThemeType _selectedTheme = PosterThemeType.magazine;
  double _exportScale = 2.0; // 默认 2x 高清
  bool _isExporting = false;

  // 自定义海报配文/名言
  late final TextEditingController _quoteController;

  // 模块显隐开关
  bool _showStats = true;
  bool _showPalette = true;
  bool _showBio = true;
  bool _showTags = true;

  // 用户指定展示的立绘路径（默认主头像）
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    _selectedImagePath = widget.character.avatarPath;
    _quoteController = TextEditingController(
      text: widget.character.description.isNotEmpty
          ? widget.character.description.split('\n').first.trim()
          : '',
    );
  }

  @override
  void dispose() {
    _quoteController.dispose();
    super.dispose();
  }

  Future<void> _exportPoster() async {
    try {
      setState(() => _isExporting = true);
      // 等待离屏与主线程渲染帧稳定
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary =
          _posterKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('未能获取海报渲染对象');
      }

      final image = await boundary.toImage(pixelRatio: _exportScale);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('PNG 编码转换失败');
      }
      final pngBytes = byteData.buffer.asUint8List();

      final defaultFileName = '${widget.character.name}_人设卡.png';
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: '保存人设卡海报',
        fileName: defaultFileName,
        allowedExtensions: ['png'],
        type: FileType.custom,
      );

      if (savePath == null) return;
      var finalPath = savePath;
      if (!finalPath.toLowerCase().endsWith('.png')) {
        finalPath += '.png';
      }

      await File(finalPath).writeAsBytes(pngBytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('人设海报已成功导出至: $finalPath'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导出失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final worldAsync = ref.watch(worldByIdProvider(widget.worldId));
    final statsAsync = ref.watch(characterStatsProvider(widget.character.id));
    final tagsAsync = ref.watch(characterTagsProvider(widget.character.id));
    final galleriesAsync = ref.watch(
      characterGalleriesProvider(widget.character.id),
    );

    final worldName = worldAsync.valueOrNull?.name ?? '未知世界';
    final stats = statsAsync.valueOrNull ?? [];
    final tags = tagsAsync.valueOrNull ?? [];
    final galleries = galleriesAsync.valueOrNull ?? [];

    return Dialog.fullscreen(
      backgroundColor: theme.colorScheme.surface,
      child: Scaffold(
        appBar: AppBar(
          title: Text('人设排版长图海报 - ${widget.character.name}'),
          actions: [
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
                  : const Icon(Icons.download_rounded, size: 18),
              label: Text(_isExporting ? '正在生成…' : '导出 PNG 海报'),
              onPressed: _isExporting ? null : _exportPoster,
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 960;

            final previewWidget = Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                child: RepaintBoundary(
                  key: _posterKey,
                  child: CharacterPosterCard(
                    character: widget.character,
                    worldName: worldName,
                    themeType: _selectedTheme,
                    imagePath: _selectedImagePath,
                    quoteText: _quoteController.text.trim(),
                    stats: stats,
                    tags: tags,
                    showStats: _showStats,
                    showPalette: _showPalette,
                    showBio: _showBio,
                    showTags: _showTags,
                  ),
                ),
              ),
            );

            final controlsWidget = _buildControlsDrawer(theme, galleries);

            if (isWide) {
              return Row(
                children: [
                  // 左侧海报实时渲染预览区
                  Expanded(
                    flex: 6,
                    child: Container(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.35),
                      child: previewWidget,
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  // 右侧参数配置抽屉
                  SizedBox(width: 360, child: controlsWidget),
                ],
              );
            } else {
              return Column(
                children: [
                  Expanded(child: previewWidget),
                  const Divider(height: 1),
                  SizedBox(height: 260, child: controlsWidget),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildControlsDrawer(
    ThemeData theme,
    List<CharacterGallery> galleries,
  ) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 1. 排版风格
        Text(
          '排版视觉风格',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PosterThemeType.values.map((t) {
            final isSelected = _selectedTheme == t;
            return ChoiceChip(
              avatar: Icon(t.icon, size: 16),
              label: Text(t.label),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedTheme = t),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // 2. 选择主推立绘（来自画廊）
        if (galleries.isNotEmpty) ...[
          Text(
            '展示立绘/差分选择',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: galleries.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final g = galleries[i];
                final isSelected = _selectedImagePath == g.imagePath;
                return InkWell(
                  onTap: () => setState(() => _selectedImagePath = g.imagePath),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 60,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FutureBuilder<File?>(
                      future: ImageStorageService.instance.resolveImageFile(
                        g.imagePath,
                      ),
                      builder: (context, snapshot) {
                        final file = snapshot.data;
                        if (file != null && file.existsSync()) {
                          return Image.file(
                            file,
                            fit: BoxFit.cover,
                            cacheWidth: 140,
                            cacheHeight: 180,
                            errorBuilder: (_, _, _) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.broken_image, size: 20),
                            ),
                          );
                        }
                        return Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.image, size: 20),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],

        // 3. 经典名言 / 台词
        Text(
          '角色名言 / 题记',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _quoteController,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: '输入一句话台词或名言（可留空）…',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(12),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),

        // 4. 模块内容开关
        Text(
          '模块显示开关',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('六维属性雷达图', style: TextStyle(fontSize: 13)),
          value: _showStats,
          onChanged: (v) => setState(() => _showStats = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('主色调调色板', style: TextStyle(fontSize: 13)),
          value: _showPalette,
          onChanged: (v) => setState(() => _showPalette = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('详细生平故事', style: TextStyle(fontSize: 13)),
          value: _showBio,
          onChanged: (v) => setState(() => _showBio = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('性格标签', style: TextStyle(fontSize: 13)),
          value: _showTags,
          onChanged: (v) => setState(() => _showTags = v),
        ),
        const SizedBox(height: 20),

        // 5. 导出清晰度倍率
        Text(
          '导出清晰度倍率',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<double>(
          segments: const [
            ButtonSegment(value: 1.0, label: Text('1x 标准')),
            ButtonSegment(value: 2.0, label: Text('2x 高清')),
            ButtonSegment(value: 3.0, label: Text('3x 超清')),
          ],
          selected: {_exportScale},
          onSelectionChanged: (set) {
            setState(() => _exportScale = set.first);
          },
        ),
      ],
    );
  }
}

/// 实际被渲染并导出为 PNG 的海报卡片组件

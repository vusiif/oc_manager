import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/storage/image_storage_service.dart';
import '../../core/util/color_palette_extractor.dart';
import '../../core/design/components/radar_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../data/database/app_database.dart';
import '../../providers/character_provider.dart';
import '../../providers/tag_provider.dart';
import '../../providers/world_provider.dart';

/// 海报排版风格定义
enum PosterThemeType {
  magazine('现代杂志风', Icons.auto_awesome_rounded),
  parchment('古典传奇风', Icons.history_edu_rounded),
  cyber('赛博霓虹风', Icons.memory_rounded),
  dossier('绝密档案风', Icons.folder_special_rounded);

  final String label;
  final IconData icon;
  const PosterThemeType(this.label, this.icon);
}

/// 人设海报生成与导出弹窗
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

      final boundary = _posterKey.currentContext?.findRenderObject()
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
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
    final galleriesAsync =
        ref.watch(characterGalleriesProvider(widget.character.id));

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
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: RepaintBoundary(
                  key: _posterKey,
                  child: _CharacterPosterCard(
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

            final controlsWidget = _buildControlsDrawer(
              theme,
              galleries,
            );

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
                  SizedBox(
                    width: 360,
                    child: controlsWidget,
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  Expanded(child: previewWidget),
                  const Divider(height: 1),
                  SizedBox(
                    height: 260,
                    child: controlsWidget,
                  ),
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
        Text('排版视觉风格',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
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
          Text('展示立绘/差分选择',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
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
                      future: ImageStorageService.instance
                          .resolveImageFile(g.imagePath),
                      builder: (context, snapshot) {
                        final file = snapshot.data;
                        if (file != null && file.existsSync()) {
                          return Image.file(file, fit: BoxFit.cover);
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
        Text('角色名言 / 题记',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
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
        Text('模块显示开关',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
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
        Text('导出清晰度倍率',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
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
class _CharacterPosterCard extends StatelessWidget {
  final Character character;
  final String worldName;
  final PosterThemeType themeType;
  final String? imagePath;
  final String quoteText;
  final List<CharacterStat> stats;
  final List<Tag> tags;
  final bool showStats;
  final bool showPalette;
  final bool showBio;
  final bool showTags;

  const _CharacterPosterCard({
    required this.character,
    required this.worldName,
    required this.themeType,
    this.imagePath,
    required this.quoteText,
    required this.stats,
    required this.tags,
    required this.showStats,
    required this.showPalette,
    required this.showBio,
    required this.showTags,
  });

  @override
  Widget build(BuildContext context) {
    // 根据风格获取颜色与字体调性
    final style = _getThemeStyle(themeType);

    return Container(
      width: 580,
      decoration: BoxDecoration(
        color: style.bgColor,
        gradient: style.bgGradient,
        borderRadius: BorderRadius.circular(style.borderRadius),
        border: Border.all(color: style.borderColor, width: style.borderWidth),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. 顶部 Header 栏
          _buildHeader(style),
          const SizedBox(height: 18),

          // 2. 核心大立绘展示
          _buildHeroPortrait(style),
          const SizedBox(height: 16),

          // 3. 主色调调色板色卡条（若开启）
          if (showPalette && imagePath != null && imagePath!.isNotEmpty) ...[
            _buildPaletteBar(style),
            const SizedBox(height: 16),
          ],

          // 4. 角色姓名、世界观与状态徽章
          _buildNameAndMeta(style),
          const SizedBox(height: 14),

          // 5. 经典名言金句
          if (quoteText.isNotEmpty) ...[
            _buildQuoteBlock(style),
            const SizedBox(height: 16),
          ],

          // 6. 属性与六维雷达图
          if (showStats && stats.isNotEmpty) ...[
            _buildStatsSection(style),
            const SizedBox(height: 16),
          ],

          // 7. 性格标签
          if (showTags && tags.isNotEmpty) ...[
            _buildTagsSection(style),
            const SizedBox(height: 16),
          ],

          // 8. 详细生平小传
          if (showBio && character.description.isNotEmpty) ...[
            _buildBioSection(style),
            const SizedBox(height: 16),
          ],

          // 9. 底部水印与编码
          _buildFooter(style),
        ],
      ),
    );
  }

  Widget _buildHeader(_PosterStyle style) {
    return Row(
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: style.accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border:
                  Border.all(color: style.accentColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              style.headerLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.textStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: style.accentColor,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'WORLD // $worldName',
          style: AppFonts.textStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: style.subtextColor,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroPortrait(_PosterStyle style) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(style.imageRadius),
      child: Container(
        height: 310,
        color: style.cardBgColor,
        child: imagePath != null && imagePath!.isNotEmpty
            ? FutureBuilder<File?>(
                future: ImageStorageService.instance.resolveImageFile(imagePath),
                builder: (context, snapshot) {
                  final file = snapshot.data;
                  if (file != null && file.existsSync()) {
                    return Image.file(
                      file,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    );
                  }
                  return _buildAvatarFallback(style);
                },
              )
            : _buildAvatarFallback(style),
      ),
    );
  }

  Widget _buildAvatarFallback(_PosterStyle style) {
    final initial = character.name.isNotEmpty ? character.name[0] : '?';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 46,
            backgroundColor: style.accentColor.withValues(alpha: 0.2),
            foregroundColor: style.accentColor,
            child: Text(
              initial,
              style: AppFonts.textStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '未设置立绘图片',
            style: TextStyle(color: style.subtextColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPaletteBar(_PosterStyle style) {
    return FutureBuilder<File?>(
      future: ImageStorageService.instance.resolveImageFile(imagePath),
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null || !file.existsSync()) return const SizedBox.shrink();

        return FutureBuilder<List<Color>>(
          future: PaletteExtractor.extractPalette(file, maxColors: 6),
          builder: (context, pSnapshot) {
            final colors = pSnapshot.data ?? [];
            if (colors.isEmpty) return const SizedBox.shrink();

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: style.cardBgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: style.cardBorderColor),
              ),
              child: Row(
                children: [
                  Text(
                    'COLOR PALETTE',
                    style: AppFonts.textStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: style.subtextColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 4,
                      children: colors.map((c) {
                        final hex = PaletteExtractor.toHex(c);
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  width: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hex,
                              style: AppFonts.textStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: style.textColor,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNameAndMeta(_PosterStyle style) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                character.name,
                style: AppFonts.textStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: style.textColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  if (character.gender.isNotEmpty) ...[
                    Text(
                      'GENDER: ${character.gender}',
                      style: AppFonts.textStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: style.subtextColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    character.status == 0 ? 'STATUS: ACTIVE' : 'STATUS: DRAFT',
                    style: AppFonts.textStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: style.accentColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuoteBlock(_PosterStyle style) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: style.accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border(
          left: BorderSide(color: style.accentColor, width: 3.5),
        ),
      ),
      child: Text(
        '“$quoteText”',
        style: AppFonts.textStyle(
          fontSize: 13,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w600,
          color: style.textColor,
          height: 1.45,
        ),
      ),
    );
  }

  Widget _buildStatsSection(_PosterStyle style) {
    final radarItems = [
      for (final s in stats)
        RadarStatItem(
          label: s.label,
          value: s.value,
          maxValue: s.maxValue,
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: style.cardBgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: style.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.radar_rounded, size: 16, color: style.accentColor),
              const SizedBox(width: 6),
              Text(
                'ABILITIES & STATS MATRIX',
                style: AppFonts.textStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: style.accentColor,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 雷达图多边形
              SizedBox(
                width: 220,
                height: 200,
                child: RadarChart(
                  items: radarItems,
                  size: 200,
                  strokeColor: style.accentColor,
                  fillColor: style.accentColor.withValues(alpha: 0.24),
                  gridColor: style.subtextColor.withValues(alpha: 0.2),
                ),
              ),
              const SizedBox(width: 14),
              // 右侧数值网格
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: stats.map((s) {
                    final val = s.value.truncateToDouble() == s.value
                        ? s.value.toInt()
                        : s.value.toStringAsFixed(1);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: style.bgColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: style.cardBorderColor.withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.label,
                            style: AppFonts.textStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: style.textColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$val',
                            style: AppFonts.textStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: style.accentColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(_PosterStyle style) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tags.map((t) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: style.cardBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: style.cardBorderColor),
          ),
          child: Text(
            '# ${t.name}',
            style: AppFonts.textStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: style.textColor,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBioSection(_PosterStyle style) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: style.cardBgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: style.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BIOGRAPHY // 角色背景',
            style: AppFonts.textStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: style.subtextColor,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            character.description,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.textStyle(
              fontSize: 12,
              height: 1.6,
              color: style.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(_PosterStyle style) {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: style.cardBorderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              'OC MANAGER • DOSSIER ARCHIVE',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.textStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: style.subtextColor,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'RECORDED: ${character.createdAt.year}-${character.createdAt.month.toString().padLeft(2, '0')}-${character.createdAt.day.toString().padLeft(2, '0')}',
            style: AppFonts.textStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: style.subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  _PosterStyle _getThemeStyle(PosterThemeType type) {
    switch (type) {
      case PosterThemeType.magazine:
        return const _PosterStyle(
          bgColor: Color(0xFFF8FAFC),
          cardBgColor: Colors.white,
          borderColor: Color(0xFFE2E8F0),
          cardBorderColor: Color(0xFFE2E8F0),
          textColor: Color(0xFF0F172A),
          subtextColor: Color(0xFF64748B),
          accentColor: Color(0xFF6366F1),
          borderRadius: 16.0,
          borderWidth: 1.5,
          imageRadius: 12.0,
          headerLabel: 'MODERN EDITORIAL ARCHIVE',
        );
      case PosterThemeType.parchment:
        return const _PosterStyle(
          bgColor: Color(0xFFF4ECD8),
          bgGradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF9F5EA), Color(0xFFEFE6CF)],
          ),
          cardBgColor: Color(0x70E5D9C3),
          borderColor: Color(0xFF8C6D46),
          cardBorderColor: Color(0xFFBCA685),
          textColor: Color(0xFF2C221E),
          subtextColor: Color(0xFF6B5848),
          accentColor: Color(0xFFB45309),
          borderRadius: 8.0,
          borderWidth: 2.5,
          imageRadius: 6.0,
          headerLabel: '❖ CHRONICLE OF HEROES ❖',
        );
      case PosterThemeType.cyber:
        return const _PosterStyle(
          bgColor: Color(0xFF090D16),
          bgGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF080C14), Color(0xFF0F172A)],
          ),
          cardBgColor: Color(0xFF141C2E),
          borderColor: Color(0xFF00F0FF),
          cardBorderColor: Color(0xFF1E293B),
          textColor: Colors.white,
          subtextColor: Color(0xFF94A3B8),
          accentColor: Color(0xFF00F0FF),
          borderRadius: 4.0,
          borderWidth: 2.0,
          imageRadius: 2.0,
          headerLabel: '[SYSTEM: DECRYPTED SPECIMEN]',
        );
      case PosterThemeType.dossier:
        return const _PosterStyle(
          bgColor: Color(0xFFEAE2D0),
          cardBgColor: Color(0xFFDFD4BE),
          borderColor: Color(0xFF5C5248),
          cardBorderColor: Color(0xFFBFB39C),
          textColor: Color(0xFF1F1D1A),
          subtextColor: Color(0xFF5E564D),
          accentColor: Color(0xFF991B1B),
          borderRadius: 2.0,
          borderWidth: 2.0,
          imageRadius: 2.0,
          headerLabel: '【 TOP SECRET // CLASSIFIED DOSSIER 】',
        );
    }
  }
}

class _PosterStyle {
  final Color bgColor;
  final Gradient? bgGradient;
  final Color cardBgColor;
  final Color borderColor;
  final Color cardBorderColor;
  final Color textColor;
  final Color subtextColor;
  final Color accentColor;
  final double borderRadius;
  final double borderWidth;
  final double imageRadius;
  final String headerLabel;

  const _PosterStyle({
    required this.bgColor,
    this.bgGradient,
    required this.cardBgColor,
    required this.borderColor,
    required this.cardBorderColor,
    required this.textColor,
    required this.subtextColor,
    required this.accentColor,
    required this.borderRadius,
    required this.borderWidth,
    required this.imageRadius,
    required this.headerLabel,
  });
}

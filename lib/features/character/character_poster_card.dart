import 'dart:io';
import 'package:flutter/material.dart';

import '../../core/storage/image_storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/database/app_database.dart';
import 'widgets/poster_palette_bar.dart';
import 'widgets/poster_stats_section.dart';
import 'widgets/poster_theme_style.dart';

export 'widgets/poster_theme_style.dart';

class CharacterPosterCard extends StatelessWidget {
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

  const CharacterPosterCard({
    super.key,
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
    final style = getPosterThemeStyle(themeType);

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
            PosterPaletteBar(imagePath: imagePath, style: style),
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
            PosterStatsSection(stats: stats, style: style),
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

  Widget _buildHeader(PosterStyle style) {
    return Row(
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: style.accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: style.accentColor.withValues(alpha: 0.4),
              ),
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

  Widget _buildHeroPortrait(PosterStyle style) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(style.imageRadius),
      child: Container(
        height: 310,
        color: style.cardBgColor,
        child: imagePath != null && imagePath!.isNotEmpty
            ? FutureBuilder<File?>(
                future: ImageStorageService.instance.resolveImageFile(
                  imagePath,
                ),
                builder: (context, snapshot) {
                  final file = snapshot.data;
                  if (file != null && file.existsSync()) {
                    return Image.file(
                      file,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      cacheWidth: 1024,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildAvatarFallback(style),
                    );
                  }
                  return _buildAvatarFallback(style);
                },
              )
            : _buildAvatarFallback(style),
      ),
    );
  }

  Widget _buildAvatarFallback(PosterStyle style) {
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

  Widget _buildNameAndMeta(PosterStyle style) {
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

  Widget _buildQuoteBlock(PosterStyle style) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: style.accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border(left: BorderSide(color: style.accentColor, width: 3.5)),
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

  Widget _buildTagsSection(PosterStyle style) {
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

  Widget _buildBioSection(PosterStyle style) {
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

  Widget _buildFooter(PosterStyle style) {
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
}

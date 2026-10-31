import 'package:flutter/material.dart';
import '../../data/database/app_database.dart';

/// 维基式人名双向链接解析工具
class WikiLinkParser {
  /// 匹配 [[角色名]] 的正则表达式（排除换行与反括号）
  static final RegExp wikiLinkRegex = RegExp(r'\[\[([^\]\r\n]+)\]\]');

  /// 从一段文本中提取所有被引用的名字（去重并保留出现次序）
  static List<String> extractTargetNames(String text) {
    if (text.isEmpty) return const [];
    final matches = wikiLinkRegex.allMatches(text);
    final names = <String>{};
    for (final m in matches) {
      final name = m.group(1)?.trim();
      if (name != null && name.isNotEmpty) {
        names.add(name);
      }
    }
    return names.toList();
  }

  /// 检查文本是否引用了指定的角色名
  static bool hasReferenceTo(String text, String targetName) {
    if (text.isEmpty || targetName.isEmpty) return false;
    final cleanTarget = targetName.trim().toLowerCase();
    final names = extractTargetNames(text);
    return names.any((n) => n.trim().toLowerCase() == cleanTarget);
  }

  /// 提取包含指定角色名引用的上下文摘要句子（前后截取）
  static List<String> extractContextSnippets(String text, String targetName) {
    if (text.isEmpty || targetName.isEmpty) return const [];
    final cleanTarget = targetName.trim();
    final lines = text.split('\n');
    final snippets = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.contains('[[$cleanTarget]]') || trimmed.contains(cleanTarget)) {
        // 如果该行过长，截取包含关键词的前后 80 个字符
        final idx = trimmed.indexOf(cleanTarget);
        if (trimmed.length > 120 && idx >= 0) {
          final start = (idx - 30).clamp(0, trimmed.length);
          final end = (idx + cleanTarget.length + 50).clamp(0, trimmed.length);
          final sub = trimmed.substring(start, end);
          final prefix = start > 0 ? '…' : '';
          final suffix = end < trimmed.length ? '…' : '';
          snippets.add('$prefix$sub$suffix');
        } else {
          snippets.add(trimmed);
        }
      }
    }

    return snippets;
  }

  /// 将包含 [[角色名]] 的文本解析为可在 RichText 或 Text.rich 中展示的 InlineSpan 列表
  static List<InlineSpan> buildWikiSpans({
    required String text,
    required Map<String, Character> nameToCharacterMap,
    required void Function(Character target) onCharacterTap,
    required BuildContext context,
    TextStyle? defaultStyle,
  }) {
    if (text.isEmpty) return const [];

    final theme = Theme.of(context);
    final baseStyle = defaultStyle ??
        TextStyle(
          fontSize: 14,
          height: 1.6,
          color: theme.colorScheme.onSurface,
        );

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in wikiLinkRegex.allMatches(text)) {
      // 1. 匹配前的纯文本
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }

      // 2. 双向链接 [[角色名]]
      final rawTargetName = match.group(1)?.trim() ?? '';
      final targetChar = nameToCharacterMap[rawTargetName];

      if (targetChar != null) {
        // 匹配到有效角色：高保真胶囊式可点击链接
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => onCharacterTap(targetChar),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.link_rounded,
                        size: 13,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        rawTargetName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        // 未在世界观中匹配到该角色（不存在或拼写错误）：灰底虚线提醒
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Tooltip(
              message: '未在该世界观中找到人物 “$rawTargetName”',
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.help_outline_rounded,
                      size: 12,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      rawTargetName,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: theme.colorScheme.outline,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      lastEnd = match.end;
    }

    // 3. 尾部纯文本
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: baseStyle,
      ));
    }

    return spans;
  }
}

/// 解析纪元年份的标准化结果 (CONSIST-002)
class ParsedYearResult {
  /// 解析出的实际纪元年份整数（公元前为负数）
  final int? year;

  /// 是否属于模糊/不详/神话时代等不可比较的模糊日期
  final bool isAmbiguous;

  /// 是否为公元前/BCE
  final bool isBce;

  /// 原始字符串
  final String raw;

  const ParsedYearResult({
    required this.year,
    required this.isAmbiguous,
    required this.isBce,
    required this.raw,
  });

  /// 是否具有可比较的精确数值
  bool get hasExactYear => year != null && !isAmbiguous;
}

/// 纪元时间解析与模糊判定工具 (CONSIST-002)
class TimelineDateParser {
  const TimelineDateParser._();

  /// 常见的模糊/留白词汇
  static const Set<String> _ambiguousKeywords = {
    '未知',
    '不详',
    '不详年代',
    '很久以前',
    '上古',
    '太古',
    '远古',
    '洪荒',
    '神话',
    '神话时代',
    '传说',
    '起源',
    '旧日',
    '古代',
    '???',
    '??',
    '?',
  };

  /// 解析纪元年份。若数据模糊或无法判定，保证不武断猜测。
  static ParsedYearResult parseYear(String raw) {
    if (raw.trim().isEmpty) {
      return ParsedYearResult(
        year: null,
        isAmbiguous: true,
        isBce: false,
        raw: raw,
      );
    }

    final clean = raw.trim();

    // 1. 检查是否完全匹配或以模糊词为主
    for (final kw in _ambiguousKeywords) {
      if (clean == kw ||
          clean.startsWith('$kw ') ||
          clean.endsWith(' $kw') ||
          clean.contains('($kw)') ||
          clean.contains('（$kw）')) {
        return ParsedYearResult(
          year: null,
          isAmbiguous: true,
          isBce: false,
          raw: raw,
        );
      }
    }

    // 2. 检查是否为公元前 / BCE / 负数
    final lower = clean.toLowerCase();
    final isBce =
        clean.contains('前') ||
        clean.contains('公元前') ||
        lower.contains('bce') ||
        lower.contains('bc') ||
        clean.startsWith('-');

    // 3. 提取数字部分
    // 匹配如 1024, 2024, -500 等
    final digitMatch = RegExp(r'\d+').firstMatch(clean);
    if (digitMatch == null) {
      // 纯汉字且未命中数字，安全标记为模糊，不武断断言
      return ParsedYearResult(
        year: null,
        isAmbiguous: true,
        isBce: isBce,
        raw: raw,
      );
    }

    final intVal = int.tryParse(digitMatch.group(0)!);
    if (intVal == null) {
      return ParsedYearResult(
        year: null,
        isAmbiguous: true,
        isBce: isBce,
        raw: raw,
      );
    }

    final resolvedYear = isBce ? -intVal : intVal;

    return ParsedYearResult(
      year: resolvedYear,
      isAmbiguous: false,
      isBce: isBce,
      raw: raw,
    );
  }
}

import 'dart:math';

/// 差异类型
enum DiffType {
  added, // 新增行（当前有，历史无）
  deleted, // 删除行（历史有，当前无）
  unchanged, // 保持不变
}

/// 单行差异结果
class DiffLine {
  final DiffType type;
  final String text;
  final int? oldLineNumber;
  final int? newLineNumber;

  const DiffLine({
    required this.type,
    required this.text,
    this.oldLineNumber,
    this.newLineNumber,
  });
}

/// 纯 Dart 轻量文本差异对比工具 (HISTORY-002)
class TextDiffUtil {
  /// 对比旧文本与新文本，生成行级差异列表
  static List<DiffLine> computeLineDiff(String oldText, String newText) {
    final oldLines = oldText.isEmpty ? <String>[] : oldText.split('\n');
    final newLines = newText.isEmpty ? <String>[] : newText.split('\n');

    final n = oldLines.length;
    final m = newLines.length;

    // 空文本特殊处理
    if (n == 0 && m == 0) return const [];
    if (n == 0) {
      return List.generate(
        m,
        (i) => DiffLine(
          type: DiffType.added,
          text: newLines[i],
          newLineNumber: i + 1,
        ),
      );
    }
    if (m == 0) {
      return List.generate(
        n,
        (i) => DiffLine(
          type: DiffType.deleted,
          text: oldLines[i],
          oldLineNumber: i + 1,
        ),
      );
    }

    // 动态规划构建 LCS 矩阵
    // 若行数过大（例如 > 800 行），采用快速逐行启发式比对避免 O(N*M) 内存过大
    if (n * m > 400000) {
      return _computeFastDiff(oldLines, newLines);
    }

    final dp = List.generate(n + 1, (_) => List.filled(m + 1, 0));
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < m; j++) {
        if (oldLines[i] == newLines[j]) {
          dp[i + 1][j + 1] = dp[i][j] + 1;
        } else {
          dp[i + 1][j + 1] = max(dp[i + 1][j], dp[i][j + 1]);
        }
      }
    }

    // 回溯路径构建 Diff 序列
    final result = <DiffLine>[];
    int i = n;
    int j = m;

    while (i > 0 || j > 0) {
      if (i > 0 && j > 0 && oldLines[i - 1] == newLines[j - 1]) {
        result.add(
          DiffLine(
            type: DiffType.unchanged,
            text: oldLines[i - 1],
            oldLineNumber: i,
            newLineNumber: j,
          ),
        );
        i--;
        j--;
      } else if (j > 0 && (i == 0 || dp[i][j - 1] >= dp[i - 1][j])) {
        result.add(
          DiffLine(
            type: DiffType.added,
            text: newLines[j - 1],
            newLineNumber: j,
          ),
        );
        j--;
      } else if (i > 0 && (j == 0 || dp[i][j - 1] < dp[i - 1][j])) {
        result.add(
          DiffLine(
            type: DiffType.deleted,
            text: oldLines[i - 1],
            oldLineNumber: i,
          ),
        );
        i--;
      }
    }

    return result.reversed.toList();
  }

  /// 快速启发式比对（应对超大文本）
  static List<DiffLine> _computeFastDiff(
    List<String> oldLines,
    List<String> newLines,
  ) {
    final result = <DiffLine>[];
    final minLen = min(oldLines.length, newLines.length);

    for (int i = 0; i < minLen; i++) {
      if (oldLines[i] == newLines[i]) {
        result.add(
          DiffLine(
            type: DiffType.unchanged,
            text: oldLines[i],
            oldLineNumber: i + 1,
            newLineNumber: i + 1,
          ),
        );
      } else {
        result.add(
          DiffLine(
            type: DiffType.deleted,
            text: oldLines[i],
            oldLineNumber: i + 1,
          ),
        );
        result.add(
          DiffLine(
            type: DiffType.added,
            text: newLines[i],
            newLineNumber: i + 1,
          ),
        );
      }
    }

    if (oldLines.length > minLen) {
      for (int i = minLen; i < oldLines.length; i++) {
        result.add(
          DiffLine(
            type: DiffType.deleted,
            text: oldLines[i],
            oldLineNumber: i + 1,
          ),
        );
      }
    } else if (newLines.length > minLen) {
      for (int i = minLen; i < newLines.length; i++) {
        result.add(
          DiffLine(
            type: DiffType.added,
            text: newLines[i],
            newLineNumber: i + 1,
          ),
        );
      }
    }

    return result;
  }
}

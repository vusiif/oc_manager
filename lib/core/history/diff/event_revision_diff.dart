import '../models/event_snapshot.dart';
import 'character_revision_diff.dart';
import 'text_diff_util.dart';

/// 编年事件全维度差异比对结果 (HISTORY-004)
class EventDiffResult {
  final EventSnapshot baseSnapshot;
  final EventSnapshot currentSnapshot;
  final List<FieldDiffItem> fieldDiffs;
  final List<DiffLine> descriptionLineDiffs;
  final int addedLines;
  final int deletedLines;
  final int charCountDelta;

  const EventDiffResult({
    required this.baseSnapshot,
    required this.currentSnapshot,
    required this.fieldDiffs,
    required this.descriptionLineDiffs,
    required this.addedLines,
    required this.deletedLines,
    required this.charCountDelta,
  });

  bool get hasAnyChanges =>
      hasFieldChanges ||
      addedLines > 0 ||
      deletedLines > 0 ||
      charCountDelta != 0;

  bool get hasFieldChanges => fieldDiffs.any((f) => f.hasChanged);
}

/// 编年事件版本差异比对引擎 (HISTORY-004)
class EventRevisionDiffEngine {
  static EventDiffResult compare({
    required EventSnapshot base,
    required EventSnapshot current,
  }) {
    final diffs = <FieldDiffItem>[];

    void compareField(
      String key,
      String label,
      String? oldVal,
      String? newVal,
    ) {
      final o = (oldVal ?? '').trim();
      final n = (newVal ?? '').trim();
      FieldChangeStatus status = FieldChangeStatus.unchanged;
      if (o.isEmpty && n.isNotEmpty) {
        status = FieldChangeStatus.added;
      } else if (o.isNotEmpty && n.isEmpty) {
        status = FieldChangeStatus.removed;
      } else if (o != n) {
        status = FieldChangeStatus.modified;
      }
      diffs.add(
        FieldDiffItem(
          key: key,
          label: label,
          oldValue: oldVal,
          newValue: newVal,
          status: status,
        ),
      );
    }

    compareField('title', '事件名称', base.title, current.title);
    compareField('year', '纪元年份', base.year, current.year);
    compareField('category', '事件分类', base.category, current.category);
    compareField(
      'importance',
      '重要程度',
      '${base.importance} 星',
      '${current.importance} 星',
    );

    final lineDiffs = TextDiffUtil.computeLineDiff(
      base.description,
      current.description,
    );
    int addedCount = 0;
    int deletedCount = 0;
    for (final line in lineDiffs) {
      if (line.type == DiffType.added) addedCount++;
      if (line.type == DiffType.deleted) deletedCount++;
    }
    final charDelta = current.description.length - base.description.length;

    return EventDiffResult(
      baseSnapshot: base,
      currentSnapshot: current,
      fieldDiffs: diffs,
      descriptionLineDiffs: lineDiffs,
      addedLines: addedCount,
      deletedLines: deletedCount,
      charCountDelta: charDelta,
    );
  }
}

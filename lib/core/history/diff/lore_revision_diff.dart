import '../models/lore_snapshot.dart';
import 'character_revision_diff.dart';
import 'text_diff_util.dart';

/// 百科实体选择性恢复选项 (HISTORY-004)
class LoreSelectiveRestoreOptions {
  final bool restoreBasicInfo; // 名称、分类、封面图、层级归属
  final bool restoreSummary; // 梗概摘要
  final bool restoreContent; // 正文设定
  final bool restoreCustomFields; // 专有自定义属性
  final bool restoreTags; // 标签体系

  const LoreSelectiveRestoreOptions({
    this.restoreBasicInfo = true,
    this.restoreSummary = true,
    this.restoreContent = true,
    this.restoreCustomFields = true,
    this.restoreTags = true,
  });

  bool get hasAnySelected =>
      restoreBasicInfo ||
      restoreSummary ||
      restoreContent ||
      restoreCustomFields ||
      restoreTags;

  LoreSelectiveRestoreOptions copyWith({
    bool? restoreBasicInfo,
    bool? restoreSummary,
    bool? restoreContent,
    bool? restoreCustomFields,
    bool? restoreTags,
  }) {
    return LoreSelectiveRestoreOptions(
      restoreBasicInfo: restoreBasicInfo ?? this.restoreBasicInfo,
      restoreSummary: restoreSummary ?? this.restoreSummary,
      restoreContent: restoreContent ?? this.restoreContent,
      restoreCustomFields: restoreCustomFields ?? this.restoreCustomFields,
      restoreTags: restoreTags ?? this.restoreTags,
    );
  }
}

/// 百科实体全维度差异比对结果 (HISTORY-004)
class LoreDiffResult {
  final LoreSnapshot baseSnapshot; // 快照历史基准
  final LoreSnapshot currentSnapshot; // 当前最新状态

  final List<FieldDiffItem> basicFieldDiffs;
  final FieldDiffItem summaryDiff;
  final List<FieldDiffItem> customFieldDiffs;
  final List<FieldDiffItem> tagDiffs;
  final List<DiffLine> contentLineDiffs;

  final int addedLines;
  final int deletedLines;
  final int charCountDelta;

  const LoreDiffResult({
    required this.baseSnapshot,
    required this.currentSnapshot,
    required this.basicFieldDiffs,
    required this.summaryDiff,
    required this.customFieldDiffs,
    required this.tagDiffs,
    required this.contentLineDiffs,
    required this.addedLines,
    required this.deletedLines,
    required this.charCountDelta,
  });

  /// 是否存在任何维度的变更
  bool get hasAnyChanges =>
      hasBasicInfoChanges ||
      hasSummaryChanges ||
      hasCustomFieldChanges ||
      hasTagChanges ||
      hasContentChanges;

  bool get hasBasicInfoChanges => basicFieldDiffs.any((f) => f.hasChanged);
  bool get hasSummaryChanges => summaryDiff.hasChanged;
  bool get hasCustomFieldChanges => customFieldDiffs.any((f) => f.hasChanged);
  bool get hasTagChanges => tagDiffs.any((f) => f.hasChanged);
  bool get hasContentChanges =>
      addedLines > 0 || deletedLines > 0 || charCountDelta != 0;

  /// 计算受选择性恢复影响的字段数量
  int countAffectedFields(LoreSelectiveRestoreOptions options) {
    int count = 0;
    if (options.restoreBasicInfo) {
      count += basicFieldDiffs.where((f) => f.hasChanged).length;
    }
    if (options.restoreSummary && summaryDiff.hasChanged) {
      count += 1;
    }
    if (options.restoreCustomFields) {
      count += customFieldDiffs.where((f) => f.hasChanged).length;
    }
    if (options.restoreTags) {
      count += tagDiffs.where((f) => f.hasChanged).length;
    }
    if (options.restoreContent && hasContentChanges) {
      count += 1;
    }
    return count;
  }
}

/// 百科实体设定版本差异比对引擎 (HISTORY-004)
class LoreRevisionDiffEngine {
  /// 比对历史基准快照与当前实体设定状态
  static LoreDiffResult compare({
    required LoreSnapshot base,
    required LoreSnapshot current,
  }) {
    // 1. 比对基本信息 (名称、类别、封面图、层级归属)
    final basicDiffs = <FieldDiffItem>[];

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
      basicDiffs.add(
        FieldDiffItem(
          key: key,
          label: label,
          oldValue: oldVal,
          newValue: newVal,
          status: status,
        ),
      );
    }

    compareField('name', '词条名称', base.name, current.name);
    compareField('entityType', '实体分类', base.entityType, current.entityType);
    compareField(
      'coverImagePath',
      '封面图鉴',
      base.coverImagePath,
      current.coverImagePath,
    );
    compareField(
      'parentId',
      '上级节点ID',
      base.parentId?.toString(),
      current.parentId?.toString(),
    );

    // 2. 比对梗概摘要
    FieldChangeStatus summaryStatus = FieldChangeStatus.unchanged;
    final oldSummary = base.summary.trim();
    final newSummary = current.summary.trim();
    if (oldSummary.isEmpty && newSummary.isNotEmpty) {
      summaryStatus = FieldChangeStatus.added;
    } else if (oldSummary.isNotEmpty && newSummary.isEmpty) {
      summaryStatus = FieldChangeStatus.removed;
    } else if (oldSummary != newSummary) {
      summaryStatus = FieldChangeStatus.modified;
    }
    final summaryDiff = FieldDiffItem(
      key: 'summary',
      label: '梗概摘要',
      oldValue: base.summary,
      newValue: current.summary,
      status: summaryStatus,
    );

    // 3. 比对专有扩展属性 (customFields)
    final customDiffs = <FieldDiffItem>[];
    final allKeys = {...base.customFields.keys, ...current.customFields.keys};
    for (final key in allKeys) {
      final oldVal = base.customFields[key];
      final newVal = current.customFields[key];

      FieldChangeStatus status = FieldChangeStatus.unchanged;
      if (oldVal == null && newVal != null) {
        status = FieldChangeStatus.added;
      } else if (oldVal != null && newVal == null) {
        status = FieldChangeStatus.removed;
      } else if (oldVal != newVal) {
        status = FieldChangeStatus.modified;
      }

      customDiffs.add(
        FieldDiffItem(
          key: key,
          label: key,
          oldValue: oldVal,
          newValue: newVal,
          status: status,
        ),
      );
    }

    // 4. 比对标签体系 (tags)
    final tagDiffs = <FieldDiffItem>[];
    final oldTags = base.tags.toSet();
    final newTags = current.tags.toSet();
    final allTags = {...oldTags, ...newTags};

    for (final tag in allTags) {
      FieldChangeStatus status = FieldChangeStatus.unchanged;
      if (!oldTags.contains(tag) && newTags.contains(tag)) {
        status = FieldChangeStatus.added; // 新增标签
      } else if (oldTags.contains(tag) && !newTags.contains(tag)) {
        status = FieldChangeStatus.removed; // 移除标签
      }

      tagDiffs.add(
        FieldDiffItem(
          key: tag,
          label: tag,
          oldValue: oldTags.contains(tag) ? tag : null,
          newValue: newTags.contains(tag) ? tag : null,
          status: status,
        ),
      );
    }

    // 5. 比对正文设定长文本 (逐行 Diff)
    final lineDiffs = TextDiffUtil.computeLineDiff(
      base.content,
      current.content,
    );
    int addedCount = 0;
    int deletedCount = 0;
    for (final line in lineDiffs) {
      if (line.type == DiffType.added) addedCount++;
      if (line.type == DiffType.deleted) deletedCount++;
    }
    final charDelta = current.content.length - base.content.length;

    return LoreDiffResult(
      baseSnapshot: base,
      currentSnapshot: current,
      basicFieldDiffs: basicDiffs,
      summaryDiff: summaryDiff,
      customFieldDiffs: customDiffs,
      tagDiffs: tagDiffs,
      contentLineDiffs: lineDiffs,
      addedLines: addedCount,
      deletedLines: deletedCount,
      charCountDelta: charDelta,
    );
  }
}

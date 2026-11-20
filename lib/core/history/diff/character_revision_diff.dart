import '../models/character_snapshot.dart';
import 'text_diff_util.dart';

/// 属性变更状态
enum FieldChangeStatus { added, removed, modified, unchanged }

/// 单字段比对项
class FieldDiffItem {
  final String key;
  final String? label;
  final String? oldValue;
  final String? newValue;
  final FieldChangeStatus status;

  const FieldDiffItem({
    required this.key,
    this.label,
    this.oldValue,
    this.newValue,
    required this.status,
  });

  bool get hasChanged => status != FieldChangeStatus.unchanged;
}

/// 选择性恢复选项 (HISTORY-003)
class SelectiveRestoreOptions {
  final bool restoreBasicInfo;
  final bool restoreDescription;
  final bool restoreCustomFields;
  final bool restoreTags;

  const SelectiveRestoreOptions({
    this.restoreBasicInfo = true,
    this.restoreDescription = true,
    this.restoreCustomFields = true,
    this.restoreTags = true,
  });

  bool get hasAnySelected =>
      restoreBasicInfo ||
      restoreDescription ||
      restoreCustomFields ||
      restoreTags;

  SelectiveRestoreOptions copyWith({
    bool? restoreBasicInfo,
    bool? restoreDescription,
    bool? restoreCustomFields,
    bool? restoreTags,
  }) {
    return SelectiveRestoreOptions(
      restoreBasicInfo: restoreBasicInfo ?? this.restoreBasicInfo,
      restoreDescription: restoreDescription ?? this.restoreDescription,
      restoreCustomFields: restoreCustomFields ?? this.restoreCustomFields,
      restoreTags: restoreTags ?? this.restoreTags,
    );
  }
}

/// 人设全维度差异比对结果 (HISTORY-002)
class CharacterDiffResult {
  final CharacterSnapshot baseSnapshot; // 快照历史基准
  final CharacterSnapshot currentSnapshot; // 当前最新状态

  final List<FieldDiffItem> basicFieldDiffs;
  final List<FieldDiffItem> customFieldDiffs;
  final List<FieldDiffItem> tagDiffs;
  final List<DiffLine> descriptionLineDiffs;

  final int addedLines;
  final int deletedLines;
  final int charCountDelta;

  const CharacterDiffResult({
    required this.baseSnapshot,
    required this.currentSnapshot,
    required this.basicFieldDiffs,
    required this.customFieldDiffs,
    required this.tagDiffs,
    required this.descriptionLineDiffs,
    required this.addedLines,
    required this.deletedLines,
    required this.charCountDelta,
  });

  /// 是否存在任何维度的变更
  bool get hasAnyChanges =>
      hasBasicInfoChanges ||
      hasCustomFieldChanges ||
      hasTagChanges ||
      hasDescriptionChanges;

  bool get hasBasicInfoChanges => basicFieldDiffs.any((f) => f.hasChanged);
  bool get hasCustomFieldChanges => customFieldDiffs.any((f) => f.hasChanged);
  bool get hasTagChanges => tagDiffs.any((f) => f.hasChanged);
  bool get hasDescriptionChanges =>
      addedLines > 0 || deletedLines > 0 || charCountDelta != 0;

  /// 计算受选择性恢复影响的字段数量
  int countAffectedFields(SelectiveRestoreOptions options) {
    int count = 0;
    if (options.restoreBasicInfo) {
      count += basicFieldDiffs.where((f) => f.hasChanged).length;
    }
    if (options.restoreDescription && hasDescriptionChanges) {
      count += 1;
    }
    if (options.restoreCustomFields) {
      count += customFieldDiffs.where((f) => f.hasChanged).length;
    }
    if (options.restoreTags) {
      count += tagDiffs.where((f) => f.hasChanged).length;
    }
    return count;
  }
}

/// 人设版本比对引擎 (HISTORY-002)
class CharacterRevisionDiffEngine {
  /// 对比历史快照 (base) 与当前状态 (current)
  static CharacterDiffResult compare({
    required CharacterSnapshot base,
    required CharacterSnapshot current,
  }) {
    // 1. 基本字段比对 (姓名、性别、年龄、立绘)
    final basicDiffs = <FieldDiffItem>[
      _compareField(
        key: 'name',
        label: '角色姓名',
        oldVal: base.name,
        newVal: current.name,
      ),
      _compareField(
        key: 'gender',
        label: '生理性别',
        oldVal: base.gender ?? '',
        newVal: current.gender ?? '',
      ),
      _compareField(
        key: 'age',
        label: '角色年龄',
        oldVal: base.age ?? '',
        newVal: current.age ?? '',
      ),
      _compareField(
        key: 'avatarPath',
        label: '立绘头像',
        oldVal: base.avatarPath ?? '',
        newVal: current.avatarPath ?? '',
      ),
    ];

    // 2. 自定义字段比对
    final customDiffs = <FieldDiffItem>[];
    final allCustomKeys = {
      ...base.customFields.keys,
      ...current.customFields.keys,
    };

    for (final key in allCustomKeys) {
      final oldVal = base.customFields[key];
      final newVal = current.customFields[key];

      if (oldVal == null && newVal != null) {
        customDiffs.add(
          FieldDiffItem(
            key: key,
            newValue: newVal,
            status: FieldChangeStatus.added,
          ),
        );
      } else if (oldVal != null && newVal == null) {
        customDiffs.add(
          FieldDiffItem(
            key: key,
            oldValue: oldVal,
            status: FieldChangeStatus.removed,
          ),
        );
      } else if (oldVal != newVal) {
        customDiffs.add(
          FieldDiffItem(
            key: key,
            oldValue: oldVal,
            newValue: newVal,
            status: FieldChangeStatus.modified,
          ),
        );
      }
    }

    // 3. 标签比对
    final tagDiffs = <FieldDiffItem>[];
    final oldTags = base.tags.toSet();
    final newTags = current.tags.toSet();

    for (final tag in newTags.difference(oldTags)) {
      tagDiffs.add(
        FieldDiffItem(key: tag, newValue: tag, status: FieldChangeStatus.added),
      );
    }
    for (final tag in oldTags.difference(newTags)) {
      tagDiffs.add(
        FieldDiffItem(
          key: tag,
          oldValue: tag,
          status: FieldChangeStatus.removed,
        ),
      );
    }

    // 4. 小传长文本行级比对
    final lineDiffs = TextDiffUtil.computeLineDiff(
      base.description,
      current.description,
    );

    int added = 0;
    int deleted = 0;
    for (final line in lineDiffs) {
      if (line.type == DiffType.added) added++;
      if (line.type == DiffType.deleted) deleted++;
    }

    final charDelta = current.description.length - base.description.length;

    return CharacterDiffResult(
      baseSnapshot: base,
      currentSnapshot: current,
      basicFieldDiffs: basicDiffs,
      customFieldDiffs: customDiffs,
      tagDiffs: tagDiffs,
      descriptionLineDiffs: lineDiffs,
      addedLines: added,
      deletedLines: deleted,
      charCountDelta: charDelta,
    );
  }

  static FieldDiffItem _compareField({
    required String key,
    required String label,
    required String oldVal,
    required String newVal,
  }) {
    if (oldVal == newVal) {
      return FieldDiffItem(
        key: key,
        label: label,
        oldValue: oldVal,
        newValue: newVal,
        status: FieldChangeStatus.unchanged,
      );
    }
    return FieldDiffItem(
      key: key,
      label: label,
      oldValue: oldVal,
      newValue: newVal,
      status: FieldChangeStatus.modified,
    );
  }
}

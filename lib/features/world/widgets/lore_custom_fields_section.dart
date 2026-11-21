import 'package:flutter/material.dart';

import '../../../providers/lore_provider.dart';

/// Predefined attribute templates for specialized lore entity categories.
class LoreFieldTemplates {
  static const Map<String, String> faction = {
    '组织类别': '军事军团/法师行会',
    '核心宗旨': '坚守信条，维护秩序与正义',
    '势力现状': '活跃兴盛',
    '组织规模': '跨区域大型组织',
  };

  static const Map<String, String> item = {
    '物品类别': '神兵利刃/防具圣物',
    '品阶稀有度': '传说 (Legendary)',
    '持有状态': '现世活跃',
    '来源出处': '远古巨匠铸造/遗迹出土',
    '特殊效果': '注入元素威能，附带破甲冲击',
    '使用代价': '需契约者灵魂同调',
  };

  static const Map<String, String> race = {
    '种族分类': '类人种族/妖精幻兽/异界生灵',
    '平均寿命': '~350岁 (长生种)',
    '生理特征': '尖耳长眸，敏捷感知出众',
    '生活习性': '聚居于林海圣所，崇尚自然与星辰',
    '社会文化': '长老议会制，通用古精灵语与符文',
    '信仰崇拜': '月神艾露恩 / 自然母神',
  };

  static const Map<String, String> ability = {
    '能力分类': '元素魔法/超能觉醒/秘术法则',
    '威能阶位': '超阶禁咒 (Rank S)',
    '生效方式': '瞬发吟唱/大范围法阵侵蚀',
    '前置条件': '需掌握高阶冰霜与奥术亲和',
    '限制条件': '施法时不可移动，需媒介法杖引导',
    '反噬代价': '过量汲取将灼伤经络神识',
  };
}

/// A section widget for managing key-value custom attributes and category-specific presets.
class LoreCustomFieldsSection extends StatelessWidget {
  final LoreEntityType selectedType;
  final List<MapEntry<TextEditingController, TextEditingController>>
  controllers;
  final VoidCallback onAddField;
  final void Function(int index) onRemoveField;
  final void Function(Map<String, String> template) onApplyTemplate;

  const LoreCustomFieldsSection({
    super.key,
    required this.selectedType,
    required this.controllers,
    required this.onAddField,
    required this.onRemoveField,
    required this.onApplyTemplate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '专有属性 / 结构化设定',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                if (selectedType == LoreEntityType.faction) ...[
                  TextButton.icon(
                    onPressed: () =>
                        onApplyTemplate(LoreFieldTemplates.faction),
                    icon: const Icon(Icons.auto_awesome, size: 15),
                    label: const Text('填入组织预设'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 4),
                ] else if (selectedType == LoreEntityType.item) ...[
                  TextButton.icon(
                    onPressed: () => onApplyTemplate(LoreFieldTemplates.item),
                    icon: const Icon(Icons.auto_awesome, size: 15),
                    label: const Text('填入装备预设'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 4),
                ] else if (selectedType == LoreEntityType.race) ...[
                  TextButton.icon(
                    onPressed: () => onApplyTemplate(LoreFieldTemplates.race),
                    icon: const Icon(Icons.auto_awesome, size: 15),
                    label: const Text('填入种族预设'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 4),
                ] else if (selectedType == LoreEntityType.ability) ...[
                  TextButton.icon(
                    onPressed: () =>
                        onApplyTemplate(LoreFieldTemplates.ability),
                    icon: const Icon(Icons.auto_awesome, size: 15),
                    label: const Text('填入能力预设'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                TextButton.icon(
                  onPressed: onAddField,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('添加属性'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (controllers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '暂无专有属性。可点击上方按钮添加（如：领袖、坐标、危险等级、法力消耗等）。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          )
        else
          ...List.generate(controllers.length, (index) {
            final pair = controllers[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: TextField(
                      controller: pair.key,
                      decoration: InputDecoration(
                        hintText: '属性名 (如坐标)',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: pair.value,
                      decoration: InputDecoration(
                        hintText: '属性值 (如北境深渊)',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.redAccent,
                      size: 18,
                    ),
                    onPressed: () => onRemoveField(index),
                    tooltip: '移除',
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

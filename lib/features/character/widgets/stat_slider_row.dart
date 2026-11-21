import 'package:flutter/material.dart';

import '../../../data/database/app_database.dart';

/// Single interactive slider row for a character stat dimension.
class StatSliderRow extends StatelessWidget {
  final CharacterStat stat;
  final double currentValue;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const StatSliderRow({
    super.key,
    required this.stat,
    required this.currentValue,
    required this.onChanged,
    required this.onChangeEnd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final curVal = currentValue.clamp(0.0, stat.maxValue);
    final formattedVal = curVal.truncateToDouble() == curVal
        ? curVal.toInt().toString()
        : curVal.toStringAsFixed(1);
    final formattedMax = stat.maxValue.toInt().toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          // 标签（点击支持修改维度名称或上限）
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stat.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.edit_outlined,
                    size: 13,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),

          // 拖动滑块
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3.5,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 6.0,
                ),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 14.0,
                ),
              ),
              child: Slider(
                value: curVal,
                min: 0.0,
                max: stat.maxValue,
                onChanged: onChanged,
                onChangeEnd: onChangeEnd,
              ),
            ),
          ),

          // 数值展示
          SizedBox(
            width: 62,
            child: Text(
              '$formattedVal / $formattedMax',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),

          // 删除维度按钮
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16),
            visualDensity: VisualDensity.compact,
            tooltip: '删除此维度',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

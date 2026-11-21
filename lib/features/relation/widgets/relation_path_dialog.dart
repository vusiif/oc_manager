import 'package:flutter/material.dart';

import '../../../data/database/app_database.dart';
import '../relation_advanced_analysis.dart';

/// Dialog allowing creators to pick two characters and analyze their shortest connection.
class RelationPathDialog extends StatefulWidget {
  final List<Character> characters;
  final List<Relation> relations;
  final void Function(ShortestPathResult result)? onHighlightPath;

  const RelationPathDialog({
    super.key,
    required this.characters,
    required this.relations,
    this.onHighlightPath,
  });

  @override
  State<RelationPathDialog> createState() => _RelationPathDialogState();
}

class _RelationPathDialogState extends State<RelationPathDialog> {
  int? _startId;
  int? _targetId;
  ShortestPathResult? _result;

  @override
  void initState() {
    super.initState();
    if (widget.characters.isNotEmpty) {
      _startId = widget.characters.first.id;
      if (widget.characters.length > 1) {
        _targetId = widget.characters[1].id;
      }
    }
  }

  void _calculatePath() {
    if (_startId == null || _targetId == null) return;
    final res = RelationPathFinder.findShortestPath(
      startId: _startId!,
      targetId: _targetId!,
      relations: widget.relations,
    );
    setState(() {
      _result = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final charMap = {for (final c in widget.characters) c.id: c.name};

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.route_rounded, color: Colors.blueAccent),
          SizedBox(width: 8),
          Text('人脉寻径与最短路径分析'),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '利用拓扑图广度搜索算法（BFS），探索任意两名角色之间的黄金纽带与关系穿透链路。',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _startId,
                      decoration: const InputDecoration(
                        labelText: '起点人物',
                        isDense: true,
                      ),
                      items: widget.characters
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(
                                c.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _startId = v;
                          _result = null;
                        });
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.grey,
                    ),
                  ),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _targetId,
                      decoration: const InputDecoration(
                        labelText: '目标人物',
                        isDense: true,
                      ),
                      items: widget.characters
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(
                                c.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _targetId = v;
                          _result = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: FilledButton.icon(
                  onPressed: _startId != null && _targetId != null
                      ? _calculatePath
                      : null,
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('开始智能寻径'),
                ),
              ),
              if (_result != null) ...[
                const Divider(height: 32),
                if (!_result!.found)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '未找到连通链路：【${charMap[_startId] ?? ""}】与【${charMap[_targetId] ?? ""}】在当前关系网中彼此处于隔离状态。',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '发现最短链路（${_result!.hopCount} 步跃迁）',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (widget.onHighlightPath != null)
                        TextButton.icon(
                          onPressed: () {
                            widget.onHighlightPath!(_result!);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: const Text('在画布上高亮'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < _result!.nodePath.length; i++) ...[
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: i == 0
                                    ? Colors.green
                                    : (i == _result!.nodePath.length - 1
                                          ? Colors.blue
                                          : Colors.purple),
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                charMap[_result!.nodePath[i]] ?? '未知角色',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (i == 0)
                                const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: Chip(
                                    label: Text(
                                      '起点',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              if (i == _result!.nodePath.length - 1)
                                const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: Chip(
                                    label: Text(
                                      '终点',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                            ],
                          ),
                          if (i < _result!.edgePath.length) ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 11,
                                top: 2,
                                bottom: 2,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 2,
                                    height: 20,
                                    color: Colors.grey.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 12),
                                  Chip(
                                    label: Text(
                                      _result!.edgePath[i].relationType,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}

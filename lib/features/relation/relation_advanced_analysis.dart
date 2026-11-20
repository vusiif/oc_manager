import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../data/database/app_database.dart';

/// Represents a single hop in a relationship path.
class PathEdge {
  final int fromCharacterId;
  final int toCharacterId;
  final String relationType;
  final bool isBidirectional;
  final String? note;

  const PathEdge({
    required this.fromCharacterId,
    required this.toCharacterId,
    required this.relationType,
    required this.isBidirectional,
    this.note,
  });
}

/// Represents the shortest relationship path between two characters.
class ShortestPathResult {
  final int startCharacterId;
  final int targetCharacterId;
  final List<int> nodePath; // [start, intermediate..., target]
  final List<PathEdge> edgePath;

  const ShortestPathResult({
    required this.startCharacterId,
    required this.targetCharacterId,
    required this.nodePath,
    required this.edgePath,
  });

  bool get found => nodePath.isNotEmpty;
  int get hopCount => edgePath.length;
}

/// BFS Shortest path algorithm on character relationship graphs.
class RelationPathFinder {
  const RelationPathFinder._();

  /// Finds the shortest connection path between [startId] and [targetId].
  /// Treats bidirectional relations as two-way and single-directional relations strictly.
  static ShortestPathResult findShortestPath({
    required int startId,
    required int targetId,
    required List<Relation> relations,
  }) {
    if (startId == targetId) {
      return ShortestPathResult(
        startCharacterId: startId,
        targetCharacterId: targetId,
        nodePath: [startId],
        edgePath: [],
      );
    }

    // Build adjacency list: node -> List of (neighborId, Relation)
    final adj = <int, List<({int neighbor, Relation rel})>>{};
    for (final rel in relations) {
      adj.putIfAbsent(rel.fromCharacterId, () => []).add((
        neighbor: rel.toCharacterId,
        rel: rel,
      ));
      if (rel.isBidirectional) {
        adj.putIfAbsent(rel.toCharacterId, () => []).add((
          neighbor: rel.fromCharacterId,
          rel: rel,
        ));
      }
    }

    // BFS
    final queue = Queue<int>()..add(startId);
    final visited = <int>{startId};
    final parentEdge = <int, ({int parent, Relation rel})>{};

    bool reached = false;
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (current == targetId) {
        reached = true;
        break;
      }

      final neighbors = adj[current] ?? const [];
      for (final n in neighbors) {
        if (!visited.contains(n.neighbor)) {
          visited.add(n.neighbor);
          parentEdge[n.neighbor] = (parent: current, rel: n.rel);
          queue.add(n.neighbor);
        }
      }
    }

    if (!reached) {
      return ShortestPathResult(
        startCharacterId: startId,
        targetCharacterId: targetId,
        nodePath: const [],
        edgePath: const [],
      );
    }

    // Reconstruct path
    final nodePath = <int>[];
    final edgePath = <PathEdge>[];
    int curr = targetId;
    nodePath.add(curr);

    while (curr != startId) {
      final step = parentEdge[curr]!;
      edgePath.insert(
        0,
        PathEdge(
          fromCharacterId: step.parent,
          toCharacterId: curr,
          relationType: step.rel.relationType,
          isBidirectional: step.rel.isBidirectional,
          note: step.rel.note,
        ),
      );
      curr = step.parent;
      nodePath.insert(0, curr);
    }

    return ShortestPathResult(
      startCharacterId: startId,
      targetCharacterId: targetId,
      nodePath: nodePath,
      edgePath: edgePath,
    );
  }
}

/// Layout mode options.
enum AutoLayoutMode {
  circular('环形聚类布局', '以度数最高核心人物为中心，其余角色环形排列'),
  hierarchical('分层层级布局', '自顶向下分层排布，契合亲缘谱系与势力组织'),
  grid('紧凑矩阵网格', '矩阵规整排列，适合高密度整理画幅');

  final String label;
  final String description;
  const AutoLayoutMode(this.label, this.description);
}

/// Automatic graph layout engine generating clean coordinate distributions.
class GraphAutoLayoutEngine {
  const GraphAutoLayoutEngine._();

  /// Computes coordinates according to selected [mode].
  static Map<int, Offset> computeLayout({
    required AutoLayoutMode mode,
    required List<Character> characters,
    required List<Relation> relations,
    Offset center = const Offset(1500, 1200),
  }) {
    if (characters.isEmpty) return const {};
    if (characters.length == 1) {
      return {characters.first.id: center};
    }

    switch (mode) {
      case AutoLayoutMode.circular:
        return _computeCircularLayout(characters, relations, center);
      case AutoLayoutMode.hierarchical:
        return _computeHierarchicalLayout(characters, relations, center);
      case AutoLayoutMode.grid:
        return _computeGridLayout(characters, center);
    }
  }

  static Map<int, Offset> _computeCircularLayout(
    List<Character> characters,
    List<Relation> relations,
    Offset center,
  ) {
    // 1. Calculate degrees to find hub
    final degrees = <int, int>{};
    for (final c in characters) {
      degrees[c.id] = 0;
    }
    for (final r in relations) {
      if (degrees.containsKey(r.fromCharacterId)) {
        degrees[r.fromCharacterId] = degrees[r.fromCharacterId]! + 1;
      }
      if (degrees.containsKey(r.toCharacterId)) {
        degrees[r.toCharacterId] = degrees[r.toCharacterId]! + 1;
      }
    }

    // Sort by degree descending
    final sortedChars = List.of(characters)
      ..sort((a, b) => (degrees[b.id] ?? 0).compareTo(degrees[a.id] ?? 0));

    final result = <int, Offset>{};
    final hub = sortedChars.first;
    result[hub.id] = center;

    final outerChars = sortedChars.sublist(1);
    final count = outerChars.length;
    final radius = max(260.0, count * 36.0);

    for (int i = 0; i < count; i++) {
      final angle = (2 * pi * i) / count - (pi / 2);
      final x = center.dx + cos(angle) * radius;
      final y = center.dy + sin(angle) * radius;
      result[outerChars[i].id] = Offset(x, y);
    }

    return result;
  }

  static Map<int, Offset> _computeHierarchicalLayout(
    List<Character> characters,
    List<Relation> relations,
    Offset center,
  ) {
    // Determine in-degrees
    final inDegree = <int, int>{for (final c in characters) c.id: 0};
    for (final r in relations) {
      if (inDegree.containsKey(r.toCharacterId)) {
        inDegree[r.toCharacterId] = inDegree[r.toCharacterId]! + 1;
      }
    }

    // Layer 0: Root nodes (inDegree == 0) or highest degree if cycle
    final layers = <List<Character>>[];
    final remaining = List.of(characters);

    final roots = remaining.where((c) => (inDegree[c.id] ?? 0) == 0).toList();
    if (roots.isEmpty) {
      roots.add(remaining.first);
    }
    layers.add(roots);
    remaining.removeWhere((c) => roots.contains(c));

    // Subsequent layers by relationship adjacency
    while (remaining.isNotEmpty) {
      final prevLayerIds = layers.last.map((c) => c.id).toSet();
      final nextLayer = <Character>[];

      for (final r in relations) {
        if (prevLayerIds.contains(r.fromCharacterId)) {
          final target = remaining
              .where((c) => c.id == r.toCharacterId)
              .firstOrNull;
          if (target != null && !nextLayer.contains(target)) {
            nextLayer.add(target);
          }
        }
      }

      if (nextLayer.isEmpty) {
        // Disconnected nodes
        nextLayer.addAll(remaining);
      }

      layers.add(nextLayer);
      remaining.removeWhere((c) => nextLayer.contains(c));
    }

    final result = <int, Offset>{};
    const rowHeight = 200.0;
    final totalHeight = (layers.length - 1) * rowHeight;
    final startY = center.dy - totalHeight / 2;

    for (int l = 0; l < layers.length; l++) {
      final layer = layers[l];
      final y = startY + l * rowHeight;
      const colWidth = 180.0;
      final totalWidth = (layer.length - 1) * colWidth;
      final startX = center.dx - totalWidth / 2;

      for (int i = 0; i < layer.length; i++) {
        final x = startX + i * colWidth;
        result[layer[i].id] = Offset(x, y);
      }
    }

    return result;
  }

  static Map<int, Offset> _computeGridLayout(
    List<Character> characters,
    Offset center,
  ) {
    final count = characters.length;
    final cols = sqrt(count).ceil();
    final rows = (count / cols).ceil();

    const cellWidth = 190.0;
    const cellHeight = 180.0;
    final totalWidth = (cols - 1) * cellWidth;
    final totalHeight = (rows - 1) * cellHeight;
    final startX = center.dx - totalWidth / 2;
    final startY = center.dy - totalHeight / 2;

    final result = <int, Offset>{};
    for (int i = 0; i < count; i++) {
      final col = i % cols;
      final row = i ~/ cols;
      final x = startX + col * cellWidth;
      final y = startY + row * cellHeight;
      result[characters[i].id] = Offset(x, y);
    }

    return result;
  }
}

/// Filter criteria for relationship graph rendering.
class RelationFilterState {
  final int? selectedGroupId;
  final String? selectedRelationType;
  final int? selectedStatus;
  final ShortestPathResult? highlightedPath;

  const RelationFilterState({
    this.selectedGroupId,
    this.selectedRelationType,
    this.selectedStatus,
    this.highlightedPath,
  });

  bool get hasActiveFilter =>
      selectedGroupId != null ||
      selectedRelationType != null ||
      selectedStatus != null ||
      highlightedPath != null;

  RelationFilterState copyWith({
    int? Function()? selectedGroupId,
    String? Function()? selectedRelationType,
    int? Function()? selectedStatus,
    ShortestPathResult? Function()? highlightedPath,
  }) {
    return RelationFilterState(
      selectedGroupId: selectedGroupId != null
          ? selectedGroupId()
          : this.selectedGroupId,
      selectedRelationType: selectedRelationType != null
          ? selectedRelationType()
          : this.selectedRelationType,
      selectedStatus: selectedStatus != null
          ? selectedStatus()
          : this.selectedStatus,
      highlightedPath: highlightedPath != null
          ? highlightedPath()
          : this.highlightedPath,
    );
  }

  Map<String, dynamic> toJson() => {
    'selectedGroupId': selectedGroupId,
    'selectedRelationType': selectedRelationType,
    'selectedStatus': selectedStatus,
  };

  static RelationFilterState fromJson(Map<String, dynamic> json) {
    return RelationFilterState(
      selectedGroupId: json['selectedGroupId'] as int?,
      selectedRelationType: json['selectedRelationType'] as String?,
      selectedStatus: json['selectedStatus'] as int?,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  static RelationFilterState fromJsonString(String source) {
    try {
      final decoded = jsonDecode(source) as Map<String, dynamic>;
      return fromJson(decoded);
    } catch (_) {
      return const RelationFilterState();
    }
  }
}

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

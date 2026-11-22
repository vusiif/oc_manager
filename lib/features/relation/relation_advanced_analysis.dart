import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../data/database/app_database.dart';

export 'widgets/relation_path_dialog.dart';

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
    Offset center = const Offset(1000, 800),
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
    // Determine degrees
    final inDegree = <int, int>{for (final c in characters) c.id: 0};
    final totalDegree = <int, int>{for (final c in characters) c.id: 0};
    for (final r in relations) {
      if (inDegree.containsKey(r.toCharacterId)) {
        inDegree[r.toCharacterId] = inDegree[r.toCharacterId]! + 1;
      }
      if (totalDegree.containsKey(r.fromCharacterId)) {
        totalDegree[r.fromCharacterId] = totalDegree[r.fromCharacterId]! + 1;
      }
      if (totalDegree.containsKey(r.toCharacterId)) {
        totalDegree[r.toCharacterId] = totalDegree[r.toCharacterId]! + 1;
      }
    }

    final layers = <List<Character>>[];
    final remaining = List.of(characters);

    // Prefer connected nodes with zero in-degree as root
    var roots = remaining
        .where(
          (c) => (inDegree[c.id] ?? 0) == 0 && (totalDegree[c.id] ?? 0) > 0,
        )
        .toList();
    if (roots.isEmpty) {
      // If cycle or disconnected, pick highest degree node
      remaining.sort(
        (a, b) => (totalDegree[b.id] ?? 0).compareTo(totalDegree[a.id] ?? 0),
      );
      roots = [remaining.first];
    }
    layers.add(roots);
    remaining.removeWhere((c) => roots.contains(c));

    // Subsequent layers by relationship adjacency
    while (remaining.isNotEmpty) {
      final prevLayerIds = layers.last.map((c) => c.id).toSet();
      final nextLayer = <Character>[];

      for (final r in relations) {
        if (prevLayerIds.contains(r.fromCharacterId) ||
            (r.isBidirectional && prevLayerIds.contains(r.toCharacterId))) {
          final targetId = prevLayerIds.contains(r.fromCharacterId)
              ? r.toCharacterId
              : r.fromCharacterId;
          final target = remaining.where((c) => c.id == targetId).firstOrNull;
          if (target != null && !nextLayer.contains(target)) {
            nextLayer.add(target);
          }
        }
      }

      if (nextLayer.isEmpty) {
        // Remaining disconnected nodes
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

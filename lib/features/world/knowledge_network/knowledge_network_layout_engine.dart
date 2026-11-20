import 'dart:math';
import 'package:flutter/material.dart';
import 'knowledge_network_models.dart';

/// 布局模式
enum NetworkLayoutMode {
  galaxy('星系同心', Icons.blur_circular_rounded),
  force('力导向分布', Icons.bubble_chart_rounded),
  radial('环形排布', Icons.pie_chart_outline_rounded);

  final String label;
  final IconData icon;
  const NetworkLayoutMode(this.label, this.icon);
}

/// 知识网络排布算法引擎 (LORE-007)
class KnowledgeNetworkLayoutEngine {
  const KnowledgeNetworkLayoutEngine._();

  static const Offset defaultCenter = Offset(1600, 1200);

  /// 根据指定模式计算全图或子图节点坐标
  static Map<String, Offset> computeLayout({
    required NetworkLayoutMode mode,
    required List<NetworkNode> nodes,
    required List<NetworkEdge> edges,
    Offset center = defaultCenter,
  }) {
    if (nodes.isEmpty) return const {};
    if (nodes.length == 1) {
      return {nodes.first.id: center};
    }

    switch (mode) {
      case NetworkLayoutMode.galaxy:
        return _computeGalaxyLayout(nodes, edges, center);
      case NetworkLayoutMode.force:
        return _computeForceDirectedLayout(nodes, edges, center);
      case NetworkLayoutMode.radial:
        return _computeRadialLayout(nodes, edges, center);
    }
  }

  /// 1. 星系同心圆排布 (Galaxy Layout)
  /// - 核心环 (Inner Orbit): 势力组织 (Faction) 与核心地点 (Location)
  /// - 中间环 (Middle Orbit): 关键人物角色 (Character)
  /// - 外层环 (Outer Orbit): 物品、装备、能力、种族、历史大事件
  static Map<String, Offset> _computeGalaxyLayout(
    List<NetworkNode> nodes,
    List<NetworkEdge> edges,
    Offset center,
  ) {
    final positions = <String, Offset>{};

    final coreNodes = <NetworkNode>[];
    final midNodes = <NetworkNode>[];
    final outerNodes = <NetworkNode>[];

    for (final node in nodes) {
      switch (node.type) {
        case NetworkNodeType.faction:
        case NetworkNodeType.location:
          coreNodes.add(node);
          break;
        case NetworkNodeType.character:
          midNodes.add(node);
          break;
        case NetworkNodeType.item:
        case NetworkNodeType.race:
        case NetworkNodeType.ability:
        case NetworkNodeType.event:
        case NetworkNodeType.other:
          outerNodes.add(node);
          break;
      }
    }

    // 环半径按节点规模自适应调整
    final rCore = max(180.0, coreNodes.length * 45.0);
    final rMid = max(rCore + 220.0, rCore + midNodes.length * 28.0);
    final rOuter = max(rMid + 240.0, rMid + outerNodes.length * 20.0);

    // 排布核心环
    _distributeOnRing(coreNodes, center, rCore, positions, angleOffset: 0);

    // 排布中环 (角色)
    _distributeOnRing(midNodes, center, rMid, positions, angleOffset: pi / 8);

    // 排布外环 (物品/事件/能力等)
    _distributeOnRing(
      outerNodes,
      center,
      rOuter,
      positions,
      angleOffset: pi / 4,
    );

    return positions;
  }

  /// 2. 力导向物理排布 (Force-directed Spring Layout)
  /// 结合库仑斥力 + 弹簧胡克引力 + 中心向心力 + 温度退火
  static Map<String, Offset> _computeForceDirectedLayout(
    List<NetworkNode> nodes,
    List<NetworkEdge> edges,
    Offset center,
  ) {
    // 初始位置以微小随机散开的星系或环状为基底
    final positions = _computeGalaxyLayout(nodes, edges, center);

    const int iterations = 60;
    double temperature = 120.0;
    const double coolingFactor = 0.94;
    const double kRepulsion = 120000.0; // 节点间斥力系数
    const double kSpring = 0.04; // 连线引力系数
    const double idealLength = 220.0; // 期望边长
    const double centerGravity = 0.015; // 向心力系数

    final idList = nodes.map((n) => n.id).toList();
    final n = idList.length;

    // 构建邻接边快速索引
    final edgePairs = <(String, String)>[];
    for (final e in edges) {
      if (positions.containsKey(e.fromId) && positions.containsKey(e.toId)) {
        edgePairs.add((e.fromId, e.toId));
      }
    }

    for (int iter = 0; iter < iterations; iter++) {
      final forces = <String, Offset>{for (final id in idList) id: Offset.zero};

      // A. 节点间库仑斥力 (O(N^2))
      for (int i = 0; i < n; i++) {
        final id1 = idList[i];
        final p1 = positions[id1]!;

        for (int j = i + 1; j < n; j++) {
          final id2 = idList[j];
          final p2 = positions[id2]!;

          var delta = p1 - p2;
          var dist = delta.distance;
          if (dist < 1.0) {
            delta = Offset(1.0 + (i % 3), 1.0 + (j % 3));
            dist = delta.distance;
          }

          // 距离过大时斥力衰减，保护性能
          if (dist > 1800.0) continue;

          final repForceMag = kRepulsion / (dist * dist);
          final norm = delta / dist;
          final fVec = norm * repForceMag;

          forces[id1] = forces[id1]! + fVec;
          forces[id2] = forces[id2]! - fVec;
        }
      }

      // B. 连线胡克引力 (Spring Attraction)
      for (final pair in edgePairs) {
        final p1 = positions[pair.$1]!;
        final p2 = positions[pair.$2]!;

        var delta = p2 - p1;
        var dist = delta.distance;
        if (dist < 1.0) dist = 1.0;

        final springForceMag = kSpring * (dist - idealLength);
        final norm = delta / dist;
        final fVec = norm * springForceMag;

        forces[pair.$1] = forces[pair.$1]! + fVec;
        forces[pair.$2] = forces[pair.$2]! - fVec;
      }

      // C. 向心力 (Gravitation toward Center)
      for (final id in idList) {
        final p = positions[id]!;
        final toCenter = center - p;
        forces[id] = forces[id]! + toCenter * centerGravity;
      }

      // D. 位移应用与温度退火约束
      for (final id in idList) {
        final f = forces[id]!;
        final fMag = f.distance;
        if (fMag > 0.001) {
          final step = min(fMag, temperature);
          final displacement = (f / fMag) * step;
          positions[id] = positions[id]! + displacement;
        }
      }

      temperature *= coolingFactor;
    }

    return positions;
  }

  /// 3. 单同心圆环形排布 (Radial Layout)
  static Map<String, Offset> _computeRadialLayout(
    List<NetworkNode> nodes,
    List<NetworkEdge> edges,
    Offset center,
  ) {
    final positions = <String, Offset>{};
    // 按度数倒序排列
    final sorted = List<NetworkNode>.from(nodes)
      ..sort((a, b) => b.degree.compareTo(a.degree));

    final radius = max(350.0, sorted.length * 32.0);
    _distributeOnRing(sorted, center, radius, positions);
    return positions;
  }

  /// 辅助方法：均匀分布在指定半径的圆环上
  static void _distributeOnRing(
    List<NetworkNode> ringNodes,
    Offset center,
    double radius,
    Map<String, Offset> targetMap, {
    double angleOffset = 0.0,
  }) {
    if (ringNodes.isEmpty) return;
    if (ringNodes.length == 1) {
      targetMap[ringNodes.first.id] = center;
      return;
    }

    final step = (2 * pi) / ringNodes.length;
    for (int i = 0; i < ringNodes.length; i++) {
      final angle = angleOffset + i * step;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      targetMap[ringNodes[i].id] = Offset(x, y);
    }
  }
}

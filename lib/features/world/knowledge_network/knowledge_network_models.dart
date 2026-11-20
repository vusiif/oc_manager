import 'package:flutter/material.dart';

/// 统一知识网络节点类型 (LORE-007)
enum NetworkNodeType {
  character('character', '人物', Icons.person_rounded, Color(0xFF6366F1)),
  location('location', '地点', Icons.location_on_rounded, Color(0xFF10B981)),
  faction('faction', '组织', Icons.shield_rounded, Color(0xFF3B82F6)),
  item('item', '物品', Icons.diamond_rounded, Color(0xFFEC4899)),
  race('race', '种族', Icons.diversity_3_rounded, Color(0xFFF59E0B)),
  ability('ability', '能力', Icons.auto_awesome_rounded, Color(0xFF8B5CF6)),
  event('event', '事件', Icons.event_note_rounded, Color(0xFF14B8A6)),
  other('other', '其他', Icons.menu_book_rounded, Color(0xFF64748B));

  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const NetworkNodeType(this.key, this.label, this.icon, this.color);

  static NetworkNodeType fromKey(String key) {
    return NetworkNodeType.values.firstWhere(
      (e) => e.key == key,
      orElse: () => NetworkNodeType.other,
    );
  }
}

/// 统一知识网络连线类型 (LORE-007)
enum NetworkEdgeType {
  social('social', '人物人际关系', Color(0xFF6366F1)),
  membership('membership', '组织职务与成员', Color(0xFF3B82F6)),
  residence('residence', '地理常驻与出身', Color(0xFF10B981)),
  ownership('ownership', '装备持有与锻造', Color(0xFFEC4899)),
  diplomacy('diplomacy', '势力外交与地缘', Color(0xFFF59E0B)),
  hierarchy('hierarchy', '空间层级与上下属', Color(0xFF8B5CF6)),
  eventTie('event_tie', '历史大事记参与', Color(0xFF14B8A6));

  final String key;
  final String label;
  final Color color;

  const NetworkEdgeType(this.key, this.label, this.color);
}

/// 知识网络统一节点模型
class NetworkNode {
  final String id; // 统一全局 ID: "char_1", "lore_2", "event_3"
  final int rawId;
  final NetworkNodeType type;
  final String label;
  final String subtitle;
  final String? imagePath;
  final dynamic entity; // 原生数据库实体 (Character / LoreEntity / TimelineEvent)

  Offset position;
  int degree; // 度数 (连接边数量)

  NetworkNode({
    required this.id,
    required this.rawId,
    required this.type,
    required this.label,
    this.subtitle = '',
    this.imagePath,
    this.entity,
    Offset? position,
    this.degree = 0,
  }) : position = position ?? Offset.zero;

  NetworkNode copyWith({Offset? position, int? degree}) {
    return NetworkNode(
      id: id,
      rawId: rawId,
      type: type,
      label: label,
      subtitle: subtitle,
      imagePath: imagePath,
      entity: entity,
      position: position ?? this.position,
      degree: degree ?? this.degree,
    );
  }
}

/// 知识网络统一边模型
class NetworkEdge {
  final String id;
  final String fromId;
  final String toId;
  final String label;
  final NetworkEdgeType type;
  final bool isBidirectional;
  final String note;
  final Color? customColor;

  const NetworkEdge({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.label,
    required this.type,
    this.isBidirectional = true,
    this.note = '',
    this.customColor,
  });
}

/// 知识网络过滤与视图状态
class KnowledgeNetworkFilterState {
  final Set<NetworkNodeType> enabledNodeTypes;
  final Set<NetworkEdgeType> enabledEdgeTypes;
  final String searchQuery;
  final String? focusedNodeId; // 当前聚焦的中心节点 (高亮 1 度网络)

  const KnowledgeNetworkFilterState({
    this.enabledNodeTypes = const {
      NetworkNodeType.character,
      NetworkNodeType.location,
      NetworkNodeType.faction,
      NetworkNodeType.item,
      NetworkNodeType.race,
      NetworkNodeType.ability,
      NetworkNodeType.event,
      NetworkNodeType.other,
    },
    this.enabledEdgeTypes = const {
      NetworkEdgeType.social,
      NetworkEdgeType.membership,
      NetworkEdgeType.residence,
      NetworkEdgeType.ownership,
      NetworkEdgeType.diplomacy,
      NetworkEdgeType.hierarchy,
      NetworkEdgeType.eventTie,
    },
    this.searchQuery = '',
    this.focusedNodeId,
  });

  KnowledgeNetworkFilterState copyWith({
    Set<NetworkNodeType>? enabledNodeTypes,
    Set<NetworkEdgeType>? enabledEdgeTypes,
    String? searchQuery,
    String? focusedNodeId,
    bool clearFocusedNode = false,
  }) {
    return KnowledgeNetworkFilterState(
      enabledNodeTypes: enabledNodeTypes ?? this.enabledNodeTypes,
      enabledEdgeTypes: enabledEdgeTypes ?? this.enabledEdgeTypes,
      searchQuery: searchQuery ?? this.searchQuery,
      focusedNodeId: clearFocusedNode
          ? null
          : (focusedNodeId ?? this.focusedNodeId),
    );
  }
}

/// 聚合计算得到的图谱完整数据
class KnowledgeNetworkGraphData {
  final Map<String, NetworkNode> nodes;
  final List<NetworkEdge> edges;

  const KnowledgeNetworkGraphData({required this.nodes, required this.edges});

  /// 过滤后的可见节点与连线
  ({
    Map<String, NetworkNode> visibleNodes,
    List<NetworkEdge> visibleEdges,
    Set<String> neighborNodeIds,
  })
  filter(KnowledgeNetworkFilterState filter) {
    // 1. 类型过滤与搜索过滤
    final candidateNodes = <String, NetworkNode>{};
    for (final entry in nodes.entries) {
      final node = entry.value;
      if (!filter.enabledNodeTypes.contains(node.type)) continue;

      if (filter.searchQuery.isNotEmpty) {
        final q = filter.searchQuery.toLowerCase();
        final matchLabel = node.label.toLowerCase().contains(q);
        final matchSub = node.subtitle.toLowerCase().contains(q);
        if (!matchLabel && !matchSub) continue;
      }
      candidateNodes[node.id] = node;
    }

    // 2. 边过滤 (两端点都在候选节点中，且边类型被启用)
    final candidateEdges = <NetworkEdge>[];
    for (final edge in edges) {
      if (!filter.enabledEdgeTypes.contains(edge.type)) continue;
      if (candidateNodes.containsKey(edge.fromId) &&
          candidateNodes.containsKey(edge.toId)) {
        candidateEdges.add(edge);
      }
    }

    // 3. 若有聚焦节点 (Ego-network Focusing)
    final neighborNodeIds = <String>{};
    if (filter.focusedNodeId != null &&
        candidateNodes.containsKey(filter.focusedNodeId)) {
      neighborNodeIds.add(filter.focusedNodeId!);
      for (final edge in candidateEdges) {
        if (edge.fromId == filter.focusedNodeId) {
          neighborNodeIds.add(edge.toId);
        } else if (edge.toId == filter.focusedNodeId) {
          neighborNodeIds.add(edge.fromId);
        }
      }
    }

    return (
      visibleNodes: candidateNodes,
      visibleEdges: candidateEdges,
      neighborNodeIds: neighborNodeIds,
    );
  }
}

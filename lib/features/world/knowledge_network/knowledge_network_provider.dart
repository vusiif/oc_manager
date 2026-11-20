import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/character_provider.dart';
import '../../../providers/relation_provider.dart';
import '../../../providers/lore_provider.dart';
import '../../../providers/timeline_provider.dart';
import 'knowledge_network_models.dart';

export 'knowledge_network_models.dart';

/// 知识网络聚合提供者 (全域知识图谱数据生成引擎)
final knowledgeNetworkGraphProvider =
    Provider.family<AsyncValue<KnowledgeNetworkGraphData>, int>((ref, worldId) {
      final charsAsync = ref.watch(charactersByWorldProvider(worldId));
      final relsAsync = ref.watch(relationsByWorldProvider(worldId));
      final loresAsync = ref.watch(loreEntitiesByWorldProvider(worldId));
      final loreRelationsAsync = ref.watch(worldLoreRelationsProvider(worldId));
      final loreEntityRelationsAsync = ref.watch(
        worldLoreEntityRelationsProvider(worldId),
      );
      final eventsAsync = ref.watch(worldTimelineEventsProvider(worldId));

      // 只要任意核心数据仍在加载中且无旧数据，保持加载态
      if (charsAsync.isLoading || loresAsync.isLoading) {
        return const AsyncValue.loading();
      }

      // 错误处理
      if (charsAsync.hasError) {
        return AsyncValue.error(charsAsync.error!, charsAsync.stackTrace!);
      }
      if (loresAsync.hasError) {
        return AsyncValue.error(loresAsync.error!, loresAsync.stackTrace!);
      }

      final characters = charsAsync.valueOrNull ?? [];
      final relations = relsAsync.valueOrNull ?? [];
      final loreEntities = loresAsync.valueOrNull ?? [];
      final loreRelations = loreRelationsAsync.valueOrNull ?? [];
      final loreEntityRelations = loreEntityRelationsAsync.valueOrNull ?? [];
      final events = eventsAsync.valueOrNull ?? [];

      final nodes = <String, NetworkNode>{};
      final edges = <NetworkEdge>[];

      // 1. 构建人物节点
      for (final c in characters) {
        final nodeId = 'c_${c.id}';
        nodes[nodeId] = NetworkNode(
          id: nodeId,
          rawId: c.id,
          type: NetworkNodeType.character,
          label: c.name,
          subtitle: c.gender.isNotEmpty ? c.gender : '角色',
          imagePath: c.avatarPath,
          entity: c,
        );
      }

      // 2. 构建百科实体节点 (地点、组织、物品、种族、能力等)
      final loreMap = {for (final l in loreEntities) l.id: l};
      for (final l in loreEntities) {
        final nodeId = 'l_${l.id}';
        nodes[nodeId] = NetworkNode(
          id: nodeId,
          rawId: l.id,
          type: NetworkNodeType.fromKey(l.entityType),
          label: l.name,
          subtitle: l.summary.isNotEmpty ? l.summary : l.tags,
          imagePath: l.coverImagePath,
          entity: l,
        );
      }

      // 3. 构建事件节点
      for (final ev in events) {
        final nodeId = 'e_${ev.id}';
        nodes[nodeId] = NetworkNode(
          id: nodeId,
          rawId: ev.id,
          type: NetworkNodeType.event,
          label: ev.title,
          subtitle: ev.year.isNotEmpty ? ev.year : '历史大事件',
          entity: ev,
        );
      }

      // 4. 构建连线: 人物社交关系
      for (final r in relations) {
        final fromId = 'c_${r.fromCharacterId}';
        final toId = 'c_${r.toCharacterId}';
        if (nodes.containsKey(fromId) && nodes.containsKey(toId)) {
          edges.add(
            NetworkEdge(
              id: 'rel_${r.id}',
              fromId: fromId,
              toId: toId,
              label: r.relationType,
              type: NetworkEdgeType.social,
              isBidirectional: r.isBidirectional,
              note: r.note ?? '',
            ),
          );
        }
      }

      // 5. 构建连线: 人物与百科实体关联 (职务、常驻、持有者)
      for (final lr in loreRelations) {
        final fromId = 'c_${lr.characterId}';
        final toId = 'l_${lr.loreId}';
        if (nodes.containsKey(fromId) && nodes.containsKey(toId)) {
          final targetLore = loreMap[lr.loreId];
          final targetType = targetLore?.entityType ?? 'other';

          NetworkEdgeType edgeType;
          if (targetType == 'faction' || targetType == 'race') {
            edgeType = NetworkEdgeType.membership;
          } else if (targetType == 'location') {
            edgeType = NetworkEdgeType.residence;
          } else if (targetType == 'item' || targetType == 'ability') {
            edgeType = NetworkEdgeType.ownership;
          } else {
            edgeType = NetworkEdgeType.membership;
          }

          edges.add(
            NetworkEdge(
              id: 'lr_${lr.id}',
              fromId: fromId,
              toId: toId,
              label: lr.role,
              type: edgeType,
              isBidirectional: false,
            ),
          );
        }
      }

      // 6. 构建连线: 百科实体间相互关联 (外交同盟、地缘存放、套装羁绊)
      for (final ler in loreEntityRelations) {
        final fromId = 'l_${ler.fromLoreId}';
        final toId = 'l_${ler.toLoreId}';
        if (nodes.containsKey(fromId) && nodes.containsKey(toId)) {
          final fromLore = loreMap[ler.fromLoreId];
          final toLore = loreMap[ler.toLoreId];

          NetworkEdgeType edgeType;
          if (fromLore?.entityType == 'faction' &&
              toLore?.entityType == 'faction') {
            edgeType = NetworkEdgeType.diplomacy;
          } else if (fromLore?.entityType == 'item' ||
              toLore?.entityType == 'item' ||
              fromLore?.entityType == 'ability' ||
              toLore?.entityType == 'ability') {
            edgeType = NetworkEdgeType.ownership;
          } else if (fromLore?.entityType == 'location' ||
              toLore?.entityType == 'location' ||
              fromLore?.entityType == 'race' ||
              toLore?.entityType == 'race') {
            edgeType = NetworkEdgeType.residence;
          } else {
            edgeType = NetworkEdgeType.diplomacy;
          }

          edges.add(
            NetworkEdge(
              id: 'ler_${ler.id}',
              fromId: fromId,
              toId: toId,
              label: ler.relationType,
              type: edgeType,
              isBidirectional: ler.isBidirectional,
              note: ler.note,
            ),
          );
        }
      }

      // 7. 构建连线: 空间/组织层级从属 (Parent-Child)
      for (final l in loreEntities) {
        if (l.parentId != null) {
          final fromId = 'l_${l.parentId}';
          final toId = 'l_${l.id}';
          if (nodes.containsKey(fromId) && nodes.containsKey(toId)) {
            edges.add(
              NetworkEdge(
                id: 'l_parent_${l.id}',
                fromId: fromId,
                toId: toId,
                label: l.entityType == 'faction'
                    ? '下属分部'
                    : l.entityType == 'race'
                    ? '衍生亚种'
                    : l.entityType == 'ability'
                    ? '进阶体系'
                    : '下辖空间',
                type: NetworkEdgeType.hierarchy,
                isBidirectional: false,
              ),
            );
          }
        }
      }

      // 8. 构建连线: 事件与角色参与
      for (final ev in events) {
        if (ev.characterId != null) {
          final fromId = 'c_${ev.characterId}';
          final toId = 'e_${ev.id}';
          if (nodes.containsKey(fromId) && nodes.containsKey(toId)) {
            edges.add(
              NetworkEdge(
                id: 'ev_char_${ev.id}',
                fromId: fromId,
                toId: toId,
                label: '亲历事件',
                type: NetworkEdgeType.eventTie,
                isBidirectional: false,
              ),
            );
          }
        }
      }

      // 9. 统计每个节点的度数 (degree)
      for (final edge in edges) {
        if (nodes.containsKey(edge.fromId)) {
          nodes[edge.fromId]!.degree++;
        }
        if (nodes.containsKey(edge.toId)) {
          nodes[edge.toId]!.degree++;
        }
      }

      return AsyncValue.data(
        KnowledgeNetworkGraphData(nodes: nodes, edges: edges),
      );
    });

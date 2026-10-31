import 'package:flutter/material.dart';
import '../../data/database/app_database.dart';
import '../constants/character_status.dart';

/// 分类数据切片
class CategorySlice {
  final String label;
  final int count;
  final double ratio; // 0.0 ~ 1.0
  final Color color;

  const CategorySlice({
    required this.label,
    required this.count,
    required this.ratio,
    required this.color,
  });
}

/// 角色网络中心性条目
class CharacterCentrality {
  final Character character;
  final int inDegree; // 作为目标（被指向）的关系数
  final int outDegree; // 作为发起者的关系数
  final int totalDegree; // 去重或综合关联度
  final double centralityScore; // 归一化中心度（0.0 ~ 1.0）

  const CharacterCentrality({
    required this.character,
    required this.inDegree,
    required this.outDegree,
    required this.totalDegree,
    required this.centralityScore,
  });
}

/// 世界观全景分析计算结果
class WorldAnalyticsData {
  final int totalCharacters;
  final int totalRelations;
  final double finalizedRate; // 定稿率 0.0 ~ 100.0%
  final double averageRelationsPerCharacter;
  final double networkDensity; // 网络密度 0.0 ~ 1.0 (实际边数 / 最大可能边数)

  final List<CategorySlice> statusStats;
  final List<CategorySlice> genderStats;
  final List<CategorySlice> groupStats;
  final List<CharacterCentrality> centralityRanking;

  const WorldAnalyticsData({
    required this.totalCharacters,
    required this.totalRelations,
    required this.finalizedRate,
    required this.averageRelationsPerCharacter,
    required this.networkDensity,
    required this.statusStats,
    required this.genderStats,
    required this.groupStats,
    required this.centralityRanking,
  });

  bool get isEmpty => totalCharacters == 0;
}

/// 世界观全景分析计算引擎
class WorldAnalyticsEngine {
  /// 执行全景统计与图网络分析
  static WorldAnalyticsData analyze({
    required List<Character> characters,
    required List<Relation> relations,
    required List<Group> groups,
    required Map<int, List<int>> characterGroupMap, // characterId -> groupIds
  }) {
    final totalChars = characters.length;
    final totalRels = relations.length;

    if (totalChars == 0) {
      return const WorldAnalyticsData(
        totalCharacters: 0,
        totalRelations: 0,
        finalizedRate: 0.0,
        averageRelationsPerCharacter: 0.0,
        networkDensity: 0.0,
        statusStats: [],
        genderStats: [],
        groupStats: [],
        centralityRanking: [],
      );
    }

    // 1. 创作状态分布
    final statusCounts = <int, int>{};
    for (final c in characters) {
      statusCounts[c.status] = (statusCounts[c.status] ?? 0) + 1;
    }
    final statusSlices = <CategorySlice>[];
    for (final s in CharacterCreationStatus.all) {
      final cnt = statusCounts[s.code] ?? 0;
      if (cnt > 0) {
        statusSlices.add(CategorySlice(
          label: s.label,
          count: cnt,
          ratio: cnt / totalChars,
          color: s.color,
        ));
      }
    }
    final finalizedCount = statusCounts[2] ?? 0;
    final finalizedRate = (finalizedCount / totalChars) * 100.0;

    // 2. 性别比例分布
    final genderCounts = <String, int>{};
    for (final c in characters) {
      final g = c.gender.trim();
      final key = g.isEmpty ? '未设定' : g;
      genderCounts[key] = (genderCounts[key] ?? 0) + 1;
    }

    const genderColorPalette = [
      Color(0xFF3B82F6), // 男 - 蓝
      Color(0xFFEC4899), // 女 - 粉
      Color(0xFF8B5CF6), // 紫
      Color(0xFF10B981), // 绿
      Color(0xFFF59E0B), // 橙
      Color(0xFF6B7280), // 灰
    ];

    final genderSlices = <CategorySlice>[];
    int colorIdx = 0;
    // 优先排男、女
    final sortedGenderKeys = genderCounts.keys.toList()
      ..sort((a, b) {
        if (a == '男') return -1;
        if (b == '男') return 1;
        if (a == '女') return -1;
        if (b == '女') return 1;
        return genderCounts[b]!.compareTo(genderCounts[a]!);
      });

    for (final k in sortedGenderKeys) {
      final cnt = genderCounts[k]!;
      Color sliceColor;
      if (k == '男') {
        sliceColor = const Color(0xFF3B82F6);
      } else if (k == '女') {
        sliceColor = const Color(0xFFEC4899);
      } else {
        sliceColor = genderColorPalette[colorIdx % genderColorPalette.length];
        colorIdx++;
      }
      genderSlices.add(CategorySlice(
        label: k,
        count: cnt,
        ratio: cnt / totalChars,
        color: sliceColor,
      ));
    }

    // 3. 组织阵营分布
    final groupCounts = <int, int>{};
    int unassignedCount = 0;

    for (final c in characters) {
      final gIds = characterGroupMap[c.id] ?? const [];
      if (gIds.isEmpty) {
        unassignedCount++;
      } else {
        for (final gid in gIds) {
          groupCounts[gid] = (groupCounts[gid] ?? 0) + 1;
        }
      }
    }

    final groupMap = {for (final g in groups) g.id: g};
    final groupSlices = <CategorySlice>[];
    const groupColors = [
      Color(0xFF6366F1), // 靛蓝
      Color(0xFF0EA5E9), // 天蓝
      Color(0xFF14B8A6), // 青碧
      Color(0xFFF97316), // 暖橙
      Color(0xFFEAB308), // 金黄
      Color(0xFFA855F7), // 亮紫
      Color(0xFFEF4444), // 赤红
    ];
    int gColorIdx = 0;

    for (final entry in groupCounts.entries) {
      final group = groupMap[entry.key];
      final label = group?.name ?? '未知组织';
      final cnt = entry.value;
      groupSlices.add(CategorySlice(
        label: label,
        count: cnt,
        ratio: cnt / totalChars,
        color: groupColors[gColorIdx % groupColors.length],
      ));
      gColorIdx++;
    }

    if (unassignedCount > 0) {
      groupSlices.add(CategorySlice(
        label: '未归属阵营',
        count: unassignedCount,
        ratio: unassignedCount / totalChars,
        color: const Color(0xFF9CA3AF),
      ));
    }
    // 按人数由多到少排序
    groupSlices.sort((a, b) => b.count.compareTo(a.count));

    // 4. 网络图中心度分析 (Degree Centrality)
    final inDegreeMap = <int, int>{};
    final outDegreeMap = <int, int>{};
    final neighborsMap = <int, Set<int>>{};

    for (final c in characters) {
      inDegreeMap[c.id] = 0;
      outDegreeMap[c.id] = 0;
      neighborsMap[c.id] = <int>{};
    }

    for (final r in relations) {
      outDegreeMap[r.fromCharacterId] =
          (outDegreeMap[r.fromCharacterId] ?? 0) + 1;
      inDegreeMap[r.toCharacterId] =
          (inDegreeMap[r.toCharacterId] ?? 0) + 1;

      neighborsMap[r.fromCharacterId]?.add(r.toCharacterId);
      if (r.isBidirectional) {
        neighborsMap[r.toCharacterId]?.add(r.fromCharacterId);
        // 双向也计入对等度
        inDegreeMap[r.fromCharacterId] =
            (inDegreeMap[r.fromCharacterId] ?? 0) + 1;
        outDegreeMap[r.toCharacterId] =
            (outDegreeMap[r.toCharacterId] ?? 0) + 1;
      }
    }

    // 寻找最大连接数
    int maxDegree = 1;
    final centralities = <CharacterCentrality>[];

    for (final c in characters) {
      final inD = inDegreeMap[c.id] ?? 0;
      final outD = outDegreeMap[c.id] ?? 0;
      final distinctNeighbors = (neighborsMap[c.id] ?? const {}).length;
      if (distinctNeighbors > maxDegree) {
        maxDegree = distinctNeighbors;
      }
      centralities.add(CharacterCentrality(
        character: c,
        inDegree: inD,
        outDegree: outD,
        totalDegree: distinctNeighbors,
        centralityScore: 0.0, // 稍后归一化
      ));
    }

    // 归一化评分并降序排序
    final normalizedRanking = centralities.map((item) {
      final score = maxDegree > 0 ? (item.totalDegree / maxDegree) : 0.0;
      return CharacterCentrality(
        character: item.character,
        inDegree: item.inDegree,
        outDegree: item.outDegree,
        totalDegree: item.totalDegree,
        centralityScore: score,
      );
    }).toList()
      ..sort((a, b) => b.totalDegree.compareTo(a.totalDegree));

    // 计算网络密度：D = 2E / (N * (N - 1)) （针对 N >= 2 的无向化网络参考值）
    double density = 0.0;
    if (totalChars >= 2) {
      final maxPossibleEdges = totalChars * (totalChars - 1) / 2.0;
      density = (totalRels / maxPossibleEdges).clamp(0.0, 1.0);
    }

    final avgRels = totalChars > 0 ? (totalRels * 2.0 / totalChars) : 0.0;

    return WorldAnalyticsData(
      totalCharacters: totalChars,
      totalRelations: totalRels,
      finalizedRate: finalizedRate,
      averageRelationsPerCharacter: avgRels,
      networkDensity: density,
      statusStats: statusSlices,
      genderStats: genderSlices,
      groupStats: groupSlices,
      centralityRanking: normalizedRanking,
    );
  }
}

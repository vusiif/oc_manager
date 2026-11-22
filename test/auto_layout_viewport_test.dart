import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/features/relation/relation_advanced_analysis.dart';
import 'package:oc_manager/features/relation/relation_viewport_helper.dart';

void main() {
  group('GraphAutoLayoutEngine Tests', () {
    final now = DateTime(2026, 1, 1);
    final characters = List.generate(
      6,
      (i) => Character(
        id: i + 1,
        worldId: 1,
        name: 'Char $i',
        gender: i.isEven ? '男' : '女',
        description: '',
        status: 0,
        isFavorite: false,
        isPinned: false,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final relations = [
      const Relation(
        id: 1,
        fromCharacterId: 1,
        toCharacterId: 2,
        relationType: '朋友',
        isBidirectional: true,
      ),
      const Relation(
        id: 2,
        fromCharacterId: 2,
        toCharacterId: 3,
        relationType: '同事',
        isBidirectional: true,
      ),
      const Relation(
        id: 3,
        fromCharacterId: 3,
        toCharacterId: 4,
        relationType: '盟友',
        isBidirectional: true,
      ),
    ];

    test('hierarchical layout places core nodes near provided center', () {
      const center = Offset(500, 400);
      final layout = GraphAutoLayoutEngine.computeLayout(
        mode: AutoLayoutMode.hierarchical,
        characters: characters.sublist(0, 4),
        relations: relations,
        center: center,
      );

      expect(layout.length, 4);
      // All placed node coordinates should surround the center point
      double sumX = 0, sumY = 0;
      for (final pos in layout.values) {
        sumX += pos.dx;
        sumY += pos.dy;
      }
      final avgCenter = Offset(sumX / 4, sumY / 4);
      expect((avgCenter.dx - center.dx).abs(), lessThan(50.0));
      expect((avgCenter.dy - center.dy).abs(), lessThan(50.0));
    });

    test('circular layout places hub at center and peers symmetrically', () {
      const center = Offset(600, 600);
      final layout = GraphAutoLayoutEngine.computeLayout(
        mode: AutoLayoutMode.circular,
        characters: characters.sublist(0, 4),
        relations: relations,
        center: center,
      );

      expect(layout.length, 4);
      // Hub node (id: 2 or 3 with highest degree) should be at center
      expect(layout.values.any((pos) => pos == center), isTrue);
    });

    test('grid layout arranges nodes compactly around center', () {
      const center = Offset(800, 600);
      final layout = GraphAutoLayoutEngine.computeLayout(
        mode: AutoLayoutMode.grid,
        characters: characters.sublist(0, 4),
        relations: relations,
        center: center,
      );

      expect(layout.length, 4);
      for (final pos in layout.values) {
        expect((pos.dx - center.dx).abs(), lessThan(300.0));
        expect((pos.dy - center.dy).abs(), lessThan(300.0));
      }
    });

    test('computeFitCanvasMatrix contains all nodes within viewport', () {
      const center = Offset(500, 400);
      final layout = GraphAutoLayoutEngine.computeLayout(
        mode: AutoLayoutMode.hierarchical,
        characters: characters.sublist(0, 4),
        relations: relations,
        center: center,
      );

      const viewport = Size(1600, 900);
      final matrix = RelationViewportHelper.computeFitCanvasMatrix(
        viewportSize: viewport,
        positions: layout,
      );

      final inv = Matrix4.inverted(matrix);
      final tlWorld = MatrixUtils.transformPoint(inv, Offset.zero);
      final brWorld = MatrixUtils.transformPoint(
        inv,
        Offset(viewport.width, viewport.height),
      );
      final visibleWorldRect = Rect.fromPoints(tlWorld, brWorld);

      for (final pos in layout.values) {
        expect(
          visibleWorldRect.contains(pos),
          isTrue,
          reason: 'Node at $pos must be inside visible rect $visibleWorldRect',
        );
      }
    });
  });
}

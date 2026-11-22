import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oc_manager/core/design/design_tokens.dart';
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/features/relation/relation_graph_painters.dart';

void main() {
  group('RelationStyleHelper Unit Tests', () {
    test('getRelationColor resolves romantic relations to rose tone', () {
      final lightColor = RelationStyleHelper.getRelationColor(
        '恋人',
        isDark: false,
      );
      final darkColor = RelationStyleHelper.getRelationColor(
        '心上人',
        isDark: true,
      );
      expect(lightColor, const Color(0xFFF43F5E));
      expect(darkColor, const Color(0xFFFB7185));
    });

    test('getRelationColor resolves hostile relations to crimson tone', () {
      final lightColor = RelationStyleHelper.getRelationColor(
        '宿敌',
        isDark: false,
      );
      final darkColor = RelationStyleHelper.getRelationColor(
        '仇敌',
        isDark: true,
      );
      expect(lightColor, const Color(0xFFEF4444));
      expect(darkColor, const Color(0xFFF87171));
    });

    test('getRelationColor resolves friendly relations to emerald tone', () {
      final lightColor = RelationStyleHelper.getRelationColor(
        '朋友',
        isDark: false,
      );
      final darkColor = RelationStyleHelper.getRelationColor(
        '同盟',
        isDark: true,
      );
      expect(lightColor, const Color(0xFF10B981));
      expect(darkColor, const Color(0xFF34D399));
    });

    test('getRelationColor resolves family relations to amber tone', () {
      final lightColor = RelationStyleHelper.getRelationColor(
        '父母',
        isDark: false,
      );
      final darkColor = RelationStyleHelper.getRelationColor(
        '家人',
        isDark: true,
      );
      expect(lightColor, const Color(0xFFF59E0B));
      expect(darkColor, const Color(0xFFFBBF24));
    });

    test('getRelationColor resolves mentor relations to violet tone', () {
      final lightColor = RelationStyleHelper.getRelationColor(
        '师徒',
        isDark: false,
      );
      final darkColor = RelationStyleHelper.getRelationColor(
        '指导',
        isDark: true,
      );
      expect(lightColor, const Color(0xFF8B5CF6));
      expect(darkColor, const Color(0xFFA78BFA));
    });

    test('getRelationColor resolves colleague relations to sky blue tone', () {
      final lightColor = RelationStyleHelper.getRelationColor(
        '同事',
        isDark: false,
      );
      final darkColor = RelationStyleHelper.getRelationColor(
        '搭档',
        isDark: true,
      );
      expect(lightColor, const Color(0xFF0284C7));
      expect(darkColor, const Color(0xFF38BDF8));
    });

    test('getRelationColor handles selection and dimmed states', () {
      final selectedColor = RelationStyleHelper.getRelationColor(
        '朋友',
        isSelected: true,
      );
      expect(selectedColor, AppColors.brand);

      final dimmedColor = RelationStyleHelper.getRelationColor(
        '朋友',
        isDimmed: true,
      );
      expect(dimmedColor.a, closeTo(0.18, 0.05));
    });

    test('isDashedRelation identifies conflict types accurately', () {
      expect(RelationStyleHelper.isDashedRelation('敌人'), isTrue);
      expect(RelationStyleHelper.isDashedRelation('宿敌'), isTrue);
      expect(RelationStyleHelper.isDashedRelation('决裂'), isTrue);
      expect(RelationStyleHelper.isDashedRelation('朋友'), isFalse);
      expect(RelationStyleHelper.isDashedRelation('恋人'), isFalse);
    });

    test(
      'computeCurveOffset computes symmetric and distance-scaled offsets',
      () {
        expect(RelationStyleHelper.computeCurveOffset(0, 1, 300), 0.0);

        // Two relations: offsets should be symmetric
        final offset0 = RelationStyleHelper.computeCurveOffset(0, 2, 300);
        final offset1 = RelationStyleHelper.computeCurveOffset(1, 2, 300);
        expect(offset0, equals(-offset1));
        expect(offset0.abs(), greaterThanOrEqualTo(15.0));

        // Scaling with distance
        final shortDistOffset = RelationStyleHelper.computeCurveOffset(
          0,
          2,
          100,
        );
        final longDistOffset = RelationStyleHelper.computeCurveOffset(
          0,
          2,
          500,
        );
        expect(shortDistOffset.abs(), lessThanOrEqualTo(longDistOffset.abs()));
      },
    );
  });

  group('RelationPainter Visual Edge Rendering Widget Tests', () {
    testWidgets('paints multiple semantic relations without error', (
      tester,
    ) async {
      final now = DateTime(2026, 1, 1);
      final charA = Character(
        id: 1,
        worldId: 1,
        name: '角色A',
        gender: '男',
        description: '',
        status: 0,
        isFavorite: false,
        isPinned: false,
        createdAt: now,
        updatedAt: now,
      );
      final charB = Character(
        id: 2,
        worldId: 1,
        name: '角色B',
        gender: '女',
        description: '',
        status: 0,
        isFavorite: false,
        isPinned: false,
        createdAt: now,
        updatedAt: now,
      );

      final relations = [
        const Relation(
          id: 101,
          fromCharacterId: 1,
          toCharacterId: 2,
          relationType: '宿敌',
          isBidirectional: false,
        ),
        const Relation(
          id: 102,
          fromCharacterId: 2,
          toCharacterId: 1,
          relationType: '恋人',
          isBidirectional: true,
        ),
      ];

      final positions = {1: const Offset(100, 100), 2: const Offset(400, 300)};

      final painter = RelationPainter(
        characters: [charA, charB],
        relations: relations,
        positions: positions,
        revision: 1,
        selectedRelationId: 101,
        isDark: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(size: const Size(600, 600), painter: painter),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.byType(ErrorWidget), findsNothing);

      // Verify label centers match curve offset
      final centers = calculateRelationLabelCenters(
        relations: relations,
        positions: positions,
      );
      expect(centers.containsKey(101), isTrue);
      expect(centers.containsKey(102), isTrue);
      expect(centers[101], isNot(equals(centers[102])));
    });
  });
}

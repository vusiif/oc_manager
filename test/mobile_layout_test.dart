import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oc_manager/data/database/app_database.dart';
import 'package:oc_manager/features/main_shell.dart';
import 'package:oc_manager/providers/world_provider.dart';

void main() {
  final now = DateTime(2026, 1, 1);

  testWidgets(
    'MainShell adapts to 390px mobile width with drawer and zero overflow',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final worlds = [
        World(
          id: 1,
          name: '移动端测试世界观',
          description: '验证窄屏下欢迎 Banner、世界观网格与 Drawer 抽屉交互正常。',
          isLocked: false,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            worldsProvider.overrideWith((ref) => Stream.value(worlds)),
          ],
          child: const MaterialApp(home: MainShell()),
        ),
      );
      await tester.pumpAndSettle();

      // Workspace Hub renders without overflow
      expect(find.text('欢迎回到 OC Manager 2.0'), findsOneWidget);
      expect(find.text('移动端测试世界观'), findsOneWidget);

      // Drawer opens when tapping leading menu button on compact screens
      await tester.tap(find.byTooltip('打开导航侧栏'));
      await tester.pumpAndSettle();
      expect(find.byType(Drawer), findsOneWidget);
    },
  );
}

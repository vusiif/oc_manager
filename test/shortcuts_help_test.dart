import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oc_manager/features/shell/shortcuts_help_dialog.dart';

void main() {
  testWidgets('ShortcutsHelpDialog displays global and graph shortcuts', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showShortcutsHelpDialog(context),
              child: const Text('打开帮助'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开帮助'));
    await tester.pumpAndSettle();

    expect(find.text('键盘快捷键指南'), findsOneWidget);
    expect(find.text('全局导航与创作'), findsOneWidget);
    expect(find.text('关系图谱画布'), findsOneWidget);
    expect(find.text('Ctrl + K'), findsOneWidget);
    expect(find.text('Ctrl + F'), findsOneWidget);
    expect(find.text('F1 / Ctrl + /'), findsOneWidget);
    expect(find.text('Ctrl + A'), findsOneWidget);

    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();
    expect(find.text('键盘快捷键指南'), findsNothing);
  });
}

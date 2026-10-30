import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oc_manager/app.dart';

void main() {
  testWidgets('App should render', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: App(),
      ),
    );

    expect(find.text('OC Manager'), findsOneWidget);
  });

  testWidgets('Sidebar should toggle with animation', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: App(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Verify initial state: AnimatedAlign has widthFactor 1.0
    final animatedAlignFinder = find.byType(AnimatedAlign).first;
    expect(animatedAlignFinder, findsOneWidget);
    AnimatedAlign alignWidget = tester.widget(animatedAlignFinder);
    expect(alignWidget.widthFactor, 1.0);

    // Tap to collapse
    final toggleBtn = find.byTooltip('收起侧栏');
    expect(toggleBtn, findsOneWidget);
    await tester.tap(toggleBtn);
    await tester.pump();

    // Check widthFactor target is now 0.0
    alignWidget = tester.widget(animatedAlignFinder);
    expect(alignWidget.widthFactor, 0.0);

    // Settle 250ms animation
    await tester.pump(const Duration(milliseconds: 300));

    // Check button tooltip changes to '展开侧栏'
    final expandBtn = find.byTooltip('展开侧栏');
    expect(expandBtn, findsOneWidget);

    // Tap to expand again
    await tester.tap(expandBtn);
    await tester.pump();

    alignWidget = tester.widget(animatedAlignFinder);
    expect(alignWidget.widthFactor, 1.0);
    await tester.pump(const Duration(milliseconds: 300));
  });
}


import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('InteractiveViewer with Clip.none renders negative coordinate children properly', (tester) async {
    final controller = TransformationController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClipRect(
            child: SizedBox(
              width: 800,
              height: 600,
              child: InteractiveViewer(
                transformationController: controller,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                clipBehavior: Clip.none,
                minScale: 0.1,
                maxScale: 5.0,
                child: SizedBox(
                  width: 1000,
                  height: 1000,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: -100,
                        top: -50,
                        child: Container(
                          key: const ValueKey('negative_node'),
                          width: 80,
                          height: 80,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Pan to see negative coordinates
    controller.value = Matrix4.identity()..setTranslationRaw(200.0, 150.0, 0.0);
    await tester.pump();

    // Verify negative node is rendered in the tree and hit testable
    expect(find.byKey(const ValueKey('negative_node')), findsOneWidget);
    final renderBox = tester.renderObject(find.byKey(const ValueKey('negative_node'))) as RenderBox;
    expect(renderBox.size, const Size(80, 80));
    final globalPos = renderBox.localToGlobal(Offset.zero);
    // Position on screen: 200 + (-100) = 100, 150 + (-50) = 100
    expect(globalPos.dx, 100.0);
    expect(globalPos.dy, 100.0);
  });
}

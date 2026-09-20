import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssk/features/driver/presentation/widgets/slide_to_action.dart';

void main() {
  testWidgets('SlideToAction renders track, thumb and label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SlideToAction(label: 'Swipe to accept', onCompleted: _noop),
        ),
      ),
    );

    expect(find.text('Swipe to accept'), findsOneWidget);
    expect(find.byType(SlideToAction), findsOneWidget);
  });

  testWidgets('SlideToAction completes on full drag', (tester) async {
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SlideToAction(
            label: 'Swipe to accept',
            onCompleted: () => completed++,
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(SlideToAction)),
    );
    // Drag far right past the 90% threshold.
    await gesture.moveBy(const Offset(1200, 0));
    await gesture.up();
    // Success morph (650ms) + reset, then one frame to rebuild.
    // (pumpAndSettle can't be used: the idle hint animation repeats forever.)
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    expect(completed, 1);
    expect(find.text('Swipe to accept'), findsOneWidget);
  });

  testWidgets('SlideToAction snaps back on short drag', (tester) async {
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SlideToAction(
            label: 'Swipe to accept',
            onCompleted: () => completed++,
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(SlideToAction)),
    );
    await gesture.moveBy(const Offset(30, 0));
    await gesture.up();
    // Snap-back runs 280ms; pump past it, then one frame to rebuild.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(completed, 0);
    expect(find.text('Swipe to accept'), findsOneWidget);
  });
}

void _noop() {}

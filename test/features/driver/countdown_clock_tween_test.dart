import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Regression guard for the driver request card crash:
// `_CountdownClock` used a generic `Tween<Color>`, which lerps via the
// `+`/`-`/`*` operators that `Color` no longer implements. Every rebuild of
// the clock threw "Cannot lerp between ..." and Flutter substituted a
// 100000px RenderErrorBox into the hero Row, causing the ~99780px overflow.
// The fix is `ColorTween`.
void main() {
  test(
    'generic Tween<Color> cannot lerp colors (why ColorTween is required)',
    () {
      expect(
        () => Tween<Color>(
          begin: const Color(0xFF22C55E),
          end: const Color(0xFFDC2626),
        ).transform(0.5),
        throwsFlutterError,
      );
    },
  );

  testWidgets('ColorTween lerps clock zone colors without throwing', (
    tester,
  ) async {
    Color? last;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TweenAnimationBuilder<Color?>(
            tween: ColorTween(
              begin: const Color(0xFF22C55E),
              end: const Color(0xFFDC2626),
            ),
            duration: const Duration(milliseconds: 500),
            builder: (context, color, _) {
              last = color;
              return ColoredBox(color: color ?? Colors.transparent);
            },
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 250));
    expect(last, isNotNull);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gadidost/features/auth/presentation/widgets/otp_code_input.dart';

Widget _host(OtpInputStatus status, {VoidCallback? onDone}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: RepaintBoundary(
        key: const ValueKey('otp'),
        child: OtpCodeInput(
          length: 4,
          status: status,
          autofocus: false,
          onCompleted: (_) {},
          onSuccessAnimationDone: onDone,
        ),
      ),
    ),
  ),
);

Finder _tick() => find.byWidgetPredicate(
  (w) => w is CustomPaint && w.painter.runtimeType.toString() == '_TickPainter',
);

void main() {
  testWidgets('success merges the boxes and draws a tick', (tester) async {
    var done = false;
    await tester.pumpWidget(_host(OtpInputStatus.idle));
    await tester.enterText(find.byType(TextField), '1234');
    await tester.pumpWidget(
      _host(OtpInputStatus.success, onDone: () => done = true),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(_tick(), findsNothing);
    await tester.pump(const Duration(milliseconds: 1100));
    expect(_tick(), findsOneWidget);
    await expectLater(
      find.byKey(const ValueKey('otp')),
      matchesGoldenFile('goldens/otp_success.png'),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(done, isTrue);
  });

  testWidgets('error clears the code after shaking', (tester) async {
    await tester.pumpWidget(_host(OtpInputStatus.idle));
    await tester.enterText(find.byType(TextField), '5678');
    await tester.pumpWidget(_host(OtpInputStatus.error));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
  });
}

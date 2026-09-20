import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssk/features/driver/presentation/widgets/history_segment_bar.dart';

void main() {
  testWidgets('HistorySegmentBar renders labels with counts', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HistorySegmentBar(
            upcomingCount: 3,
            completedCount: 12,
            selectedIndex: 0,
            onChanged: _noop,
          ),
        ),
      ),
    );

    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('HistorySegmentBar notifies on segment tap', (tester) async {
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistorySegmentBar(
            upcomingCount: 3,
            completedCount: 12,
            selectedIndex: selected,
            onChanged: (index) => selected = index,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Completed'));
    await tester.pump();

    expect(selected, 1);
  });

  testWidgets('HistorySegmentHeaderDelegate lays out without sliver errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 400)),
              SliverPersistentHeader(
                pinned: true,
                delegate: HistorySegmentHeaderDelegate(
                  upcomingCount: 3,
                  completedCount: 12,
                  selectedIndex: 0,
                  onChanged: _noop,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 1200)),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);

    // Scroll so the header pins and content slides under it.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pump();
    expect(tester.takeException(), isNull);

    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
  });
}

void _noop(int _) {}

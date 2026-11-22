// Web parity (BookTruck.jsx `minScheduleValue`): Book Later starts 5 minutes
// out so picking "now" can't fail the backend's "must be in the future" check.
import 'package:flutter_test/flutter_test.dart';
import 'package:gadidost/features/client/presentation/widgets/home_schedule_sheet.dart';

void main() {
  test('minimum Book Later lead time matches the web (5 minutes)', () {
    expect(kMinScheduleLead, const Duration(minutes: 5));
  });
}

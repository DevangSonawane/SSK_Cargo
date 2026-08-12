import 'package:flutter_riverpod/flutter_riverpod.dart';

final driverOnlineProvider = StateProvider<bool>((ref) => true);
final driverActiveTripIdProvider = StateProvider<String?>((ref) => null);

final driverTrackingEnabledProvider = Provider<bool>((ref) {
  return ref.watch(driverOnlineProvider) ||
      (ref.watch(driverActiveTripIdProvider) ?? '').trim().isNotEmpty;
});

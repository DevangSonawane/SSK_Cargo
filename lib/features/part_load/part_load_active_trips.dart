// Dual active-trip support — additive helpers + picker widget.
// GET /api/trips/active now returns { trip, trips[] }. Old code reads only
// `trip`; these helpers read `trips[]` when present and fall back to `trip`
// so nothing breaks for single-trip drivers.

import 'package:flutter/material.dart';

/// Extract ALL active trips without breaking old single-trip readers.
List<Map<String, dynamic>> extractAllActiveTrips(
    Map<String, dynamic> response) {
  final data = response['data'];
  Map<String, dynamic> asMap(Object? v) =>
      v is Map ? v.cast<String, dynamic>() : <String, dynamic>{};
  if (data is Map) {
    final m = data.cast<String, dynamic>();
    final trips = m['trips'];
    if (trips is List && trips.isNotEmpty) {
      return trips
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    final trip = m['trip'];
    if (trip is Map) return [trip.cast<String, dynamic>()];
    return [m];
  }
  final trip = response['trip'];
  if (trip is Map) return [trip.cast<String, dynamic>()];
  return [asMap(response)];
}

/// Simple tab picker for drivers with 2 simultaneous trips (v1 cap).
/// The detail view below it stays exactly the same — it just receives
/// whichever trip map is selected.
class PartLoadTripPicker extends StatelessWidget {
  const PartLoadTripPicker({
    super.key,
    required this.trips,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<Map<String, dynamic>> trips;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  String _label(Map<String, dynamic> trip, int index) {
    for (final k in const ['bookingNumber', 'booking_number']) {
      final v = trip[k]?.toString().trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return 'Trip ${index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    if (trips.length < 2) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SegmentedButton<int>(
        segments: [
          for (var i = 0; i < trips.length; i++)
            ButtonSegment(value: i, label: Text(_label(trips[i], i))),
        ],
        selected: {selectedIndex.clamp(0, trips.length - 1)},
        onSelectionChanged: (s) => onSelect(s.first),
      ),
    );
  }
}

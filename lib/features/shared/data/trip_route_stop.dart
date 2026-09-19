class TripRouteStop {
  const TripRouteStop({
    required this.index,
    required this.type,
    required this.location,
    required this.status,
    this.lat,
    this.lng,
  });

  final int index;
  final String type;
  final String location;
  final String status;
  final double? lat;
  final double? lng;

  bool get isLoading => type == 'loading';
  bool get isUnloading => type == 'unloading';
  bool get isPickup => type == 'pickup';
  bool get isDrop => type == 'drop';
  bool get isExtraStop => isLoading || isUnloading;
  bool get isDone => status == 'done' || status == 'completed';
  bool get hasCoordinates => lat != null && lng != null;
  String get label => isLoading ? 'Loading Point' : 'Unloading Point';
  String get actionLabel => isLoading ? 'Mark Loaded' : 'Mark Unloaded';

  TripRouteStop copyWith({
    int? index,
    String? type,
    String? location,
    String? status,
    double? lat,
    double? lng,
  }) {
    return TripRouteStop(
      index: index ?? this.index,
      type: type ?? this.type,
      location: location ?? this.location,
      status: status ?? this.status,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }

  factory TripRouteStop.fromJson({
    required int index,
    required Map<String, dynamic> json,
  }) {
    return TripRouteStop(
      index: index,
      type: _readString(json, const ['type']).toLowerCase(),
      location: _readString(json, const [
        'location',
        'address',
        'name',
        'formattedAddress',
        'formatted_address',
      ]),
      status: _readString(json, const ['status']).toLowerCase(),
      lat: _readDouble(json, const ['lat', 'latitude']),
      lng: _readDouble(json, const ['lng', 'longitude']),
    );
  }

  static List<TripRouteStop> listFromJson(Object? rawStops) {
    if (rawStops is! List) return const [];
    return [
      for (var index = 0; index < rawStops.length; index++)
        if (rawStops[index] is Map)
          TripRouteStop.fromJson(
            index: index,
            json: (rawStops[index] as Map).cast<String, dynamic>(),
          ),
    ];
  }

  static List<TripRouteStop> extraStopsFromJson(Object? rawStops) {
    return listFromJson(
      rawStops,
    ).where((stop) => stop.isExtraStop).toList(growable: false);
  }

  static List<TripRouteStop> fallbackExtraStopsFromLocations(
    Map<String, dynamic> source,
  ) {
    final loading = _listFromAny(
      source['loadingLocations'] ??
          source['loading_locations'] ??
          source['add_loading_location'],
      type: 'loading',
      startIndex: 1,
    );
    final unloading = _listFromAny(
      source['unloadingLocations'] ??
          source['unloading_locations'] ??
          source['add_unloading_location'],
      type: 'unloading',
      startIndex: 1 + loading.length,
    );
    return [...loading, ...unloading];
  }

  static int nextActionableIndex(List<TripRouteStop> stops, String type) {
    for (final stop in stops) {
      if (stop.type == type && !stop.isDone) return stop.index;
    }
    return -1;
  }

  static List<TripRouteStop> _listFromAny(
    Object? raw, {
    required String type,
    required int startIndex,
  }) {
    if (raw is! List) return const [];
    final stops = <TripRouteStop>[];
    for (var index = 0; index < raw.length; index++) {
      final item = raw[index];
      if (item is Map) {
        final json = item.cast<String, dynamic>();
        stops.add(
          TripRouteStop(
            index: startIndex + index,
            type: type,
            location: _readString(json, const [
              'location',
              'address',
              'formattedAddress',
              'formatted_address',
            ]),
            status: _readString(json, const ['status']).toLowerCase(),
            lat: _readDouble(json, const ['lat', 'latitude']),
            lng: _readDouble(json, const ['lng', 'longitude']),
          ),
        );
      }
    }
    return stops;
  }
}

List<TripRouteStop> tripRouteStopsFromSource(Map<String, dynamic> source) {
  for (final raw in [
    source['stops'],
    (source['trip'] is Map) ? (source['trip'] as Map)['stops'] : null,
    (source['booking'] is Map) ? (source['booking'] as Map)['stops'] : null,
  ]) {
    final stops = TripRouteStop.extraStopsFromJson(raw);
    if (stops.isNotEmpty) return stops;
  }
  return TripRouteStop.fallbackExtraStopsFromLocations(source);
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key]?.toString().trim();
    if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
      return value;
    }
  }
  return '';
}

double? _readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return null;
}

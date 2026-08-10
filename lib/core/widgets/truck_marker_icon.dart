import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const String truckMarkerAssetPath = 'assets/truck/truck-marker.png';

Future<BitmapDescriptor>? _cachedTruckMarkerIcon;

Future<BitmapDescriptor> loadTruckMarkerIcon() {
  _cachedTruckMarkerIcon ??= _loadTruckMarkerIcon();
  return _cachedTruckMarkerIcon!;
}

Future<BitmapDescriptor> _loadTruckMarkerIcon() async {
  final data = await rootBundle.load(truckMarkerAssetPath);
  return BitmapDescriptor.bytes(
    data.buffer.asUint8List(),
    width: 40,
    height: 40,
  );
}

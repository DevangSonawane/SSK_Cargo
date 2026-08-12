import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'gps_tracking_models.dart';

final gpsTrackingRepositoryProvider = Provider<GpsTrackingRepository>((ref) {
  return GpsTrackingRepository(ref.read(apiClientProvider));
});

class GpsTrackingRepository {
  GpsTrackingRepository(this._apiClient);

  final SskApiClient _apiClient;

  Future<List<GpsTrackerDevice>> fetchDevices({
    required String accessToken,
  }) async {
    final response = await _apiClient.getTrackingDevices(
      accessToken: accessToken,
    );
    return parseGpsTrackerDevices(response);
  }

  Future<GpsTrackerDevice?> fetchDeviceByImei({
    required String accessToken,
    required String imei,
  }) async {
    final response = await _apiClient.getTrackingDeviceByImei(
      accessToken: accessToken,
      imei: imei,
    );
    return parseGpsTrackerDevice(response);
  }

  Future<GpsTrackerDevice?> fetchDeviceByName({
    required String accessToken,
    required String name,
  }) async {
    final response = await _apiClient.getTrackingDeviceByName(
      accessToken: accessToken,
      name: name,
    );
    return parseGpsTrackerDevice(response);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/google_places_service.dart';

final googlePlacesServiceProvider = Provider<GooglePlacesService>((ref) {
  return GooglePlacesService();
});

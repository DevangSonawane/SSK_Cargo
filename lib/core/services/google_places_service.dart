import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/google_maps_config.dart';

class GooglePlaceSuggestion {
  const GooglePlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
    this.distanceMeters,
  });

  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
  final int? distanceMeters;
}

class GooglePlaceSelection {
  const GooglePlaceSelection({
    required this.placeId,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    this.city = '',
  });

  final String placeId;
  final String formattedAddress;
  final double? latitude;
  final double? longitude;
  final String city;
}

class GooglePlacesService {
  GooglePlacesService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://places.googleapis.com/v1',
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(seconds: 15),
              contentType: Headers.jsonContentType,
            ),
          ),
      _geocodeDio = Dio(
        BaseOptions(
          baseUrl: 'https://maps.googleapis.com/maps/api/geocode',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 15),
        ),
      );

  final Dio _dio;
  final Dio _geocodeDio;
  final Dio _directionsDio = Dio(
    BaseOptions(
      baseUrl: 'https://maps.googleapis.com/maps/api/directions',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 15),
    ),
  );

  Future<List<GooglePlaceSuggestion>> autocomplete({
    required String input,
    required String sessionToken,
  }) async {
    if (googleMapsApiKey.isEmpty || input.trim().isEmpty) {
      return const [];
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '/places:autocomplete',
      data: {
        'input': input.trim(),
        'sessionToken': sessionToken,
        'includeQueryPredictions': false,
      },
      options: Options(
        headers: {
          'X-Goog-Api-Key': googleMapsApiKey,
          'X-Goog-FieldMask':
              'suggestions.placePrediction.placeId,suggestions.placePrediction.text,suggestions.placePrediction.structuredFormat,suggestions.placePrediction.distanceMeters',
        },
      ),
    );

    final suggestions = response.data?['suggestions'];
    if (suggestions is! List) {
      return const [];
    }

    return suggestions
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final prediction = _asMap(item['placePrediction']);
          final text = _asMap(prediction['text']);
          final structured = _asMap(prediction['structuredFormat']);
          final mainText = _readString(_asMap(structured['mainText']), const [
            'text',
          ]);
          final secondaryText = _readString(
            _asMap(structured['secondaryText']),
            const ['text'],
          );
          final description = _readString(text, const ['text']);
          final resolvedDescription = description.isNotEmpty
              ? description
              : [
                  mainText,
                  secondaryText,
                ].where((value) => value.isNotEmpty).join(', ');

          return GooglePlaceSuggestion(
            placeId: _readString(prediction, const ['placeId']).isEmpty
                ? _readString(prediction, const ['place'])
                : _readString(prediction, const ['placeId']),
            description: resolvedDescription,
            mainText: mainText.isNotEmpty ? mainText : resolvedDescription,
            secondaryText: secondaryText,
            distanceMeters: _readInt(prediction, const ['distanceMeters']),
          );
        })
        .where((item) => item.placeId.isNotEmpty && item.description.isNotEmpty)
        .toList(growable: false);
  }

  Future<GooglePlaceSelection> fetchPlaceSelection({
    required String placeId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/places/$placeId',
      options: Options(
        headers: {
          'X-Goog-Api-Key': googleMapsApiKey,
          'X-Goog-FieldMask': 'id,formattedAddress,location,addressComponents',
        },
      ),
    );

    final data = response.data ?? const <String, dynamic>{};
    final location = _asMap(data['location']);
    final city = _extractCityFromAddressComponents(
      _asList(data['addressComponents']),
    );
    return GooglePlaceSelection(
      placeId: _readString(data, const ['id', 'placeId']),
      formattedAddress: _readString(data, const ['formattedAddress']),
      latitude: _readDouble(location, const ['latitude']),
      longitude: _readDouble(location, const ['longitude']),
      city: city,
    );
  }

  Future<GooglePlaceSelection> geocodeAddress({required String address}) async {
    if (googleMapsApiKey.isEmpty || address.trim().isEmpty) {
      return const GooglePlaceSelection(
        placeId: '',
        formattedAddress: '',
        latitude: null,
        longitude: null,
      );
    }

    final response = await _geocodeDio.get<Map<String, dynamic>>(
      '/json',
      queryParameters: {'address': address.trim(), 'key': googleMapsApiKey},
    );

    final data = response.data ?? const <String, dynamic>{};
    final results = data['results'];
    if (results is! List || results.isEmpty) {
      return const GooglePlaceSelection(
        placeId: '',
        formattedAddress: '',
        latitude: null,
        longitude: null,
      );
    }

    final first = results.first;
    if (first is! Map<String, dynamic>) {
      return const GooglePlaceSelection(
        placeId: '',
        formattedAddress: '',
        latitude: null,
        longitude: null,
      );
    }

    final geometry = _asMap(first['geometry']);
    final location = _asMap(geometry['location']);
    final city = _extractCityFromAddressComponents(
      _asList(first['address_components']),
    );
    return GooglePlaceSelection(
      placeId: _readString(first, const ['place_id']),
      formattedAddress: _readString(first, const ['formatted_address']),
      latitude: _readDouble(location, const ['lat']),
      longitude: _readDouble(location, const ['lng']),
      city: city,
    );
  }

  Future<String> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    if (googleMapsApiKey.isEmpty) {
      return '';
    }

    final response = await _geocodeDio.get<Map<String, dynamic>>(
      '/json',
      queryParameters: {
        'latlng': '$latitude,$longitude',
        'key': googleMapsApiKey,
      },
    );

    final data = response.data ?? const <String, dynamic>{};
    final results = data['results'];
    if (results is! List || results.isEmpty) {
      return '';
    }

    final first = results.first;
    if (first is! Map<String, dynamic>) {
      return '';
    }

    return _readString(first, const ['formatted_address']);
  }

  Future<List<LatLng>> fetchDrivingRoute({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    if (googleMapsApiKey.isEmpty) {
      return const [];
    }

    final response = await _directionsDio.get<Map<String, dynamic>>(
      '/json',
      queryParameters: {
        'origin': '$originLatitude,$originLongitude',
        'destination': '$destinationLatitude,$destinationLongitude',
        'mode': 'driving',
        'key': googleMapsApiKey,
      },
    );

    final data = response.data ?? const <String, dynamic>{};
    final routes = data['routes'];
    if (routes is! List || routes.isEmpty) {
      return const [];
    }

    final first = routes.first;
    if (first is! Map<String, dynamic>) {
      return const [];
    }

    final overviewPolyline = _asMap(first['overview_polyline']);
    final encoded = _readString(overviewPolyline, const ['points']);
    if (encoded.isEmpty) {
      return const [];
    }

    return decodePolyline(encoded);
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _asList(Object? value) {
  if (value is List) {
    return value.whereType<Map<String, dynamic>>().toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') {
      return text;
    }
  }
  return '';
}

int? _readInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final parsed = int.tryParse(value.toString());
    if (parsed != null) return parsed;
  }
  return null;
}

double? _readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final parsed = double.tryParse(value.toString());
    if (parsed != null) return parsed;
  }
  return null;
}

String _extractCityFromAddressComponents(
  List<Map<String, dynamic>> components,
) {
  const cityTypes = <String>{
    'locality',
    'postal_town',
    'administrative_area_level_3',
    'administrative_area_level_2',
    'sublocality_level_1',
  };

  for (final component in components) {
    final types = _asListOfString(component['types']);
    if (types.any(cityTypes.contains)) {
      final longText = _readString(component, const ['longText', 'long_name']);
      if (longText.isNotEmpty) {
        return longText;
      }
      final shortText = _readString(component, const [
        'shortText',
        'short_name',
      ]);
      if (shortText.isNotEmpty) {
        return shortText;
      }
    }
  }

  return '';
}

List<String> _asListOfString(Object? value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList(growable: false);
  }
  return const <String>[];
}

List<LatLng> decodePolyline(String encoded) {
  final poly = <LatLng>[];
  var index = 0;
  var lat = 0;
  var lng = 0;

  while (index < encoded.length) {
    var result = 0;
    var shift = 0;
    int b;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lat += dlat;

    result = 0;
    shift = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lng += dlng;

    poly.add(LatLng(lat / 1E5, lng / 1E5));
  }

  return poly;
}

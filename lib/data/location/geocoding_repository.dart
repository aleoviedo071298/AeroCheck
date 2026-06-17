import 'package:http/http.dart' as http;
import 'dart:convert';

import 'flight_location.dart';
import 'geocoding_service.dart';

class GeocodingRepository implements GeocodingService {
  static const _baseUrl = 'https://geocoding-api.open-meteo.com/v1/search';

  @override
  Future<List<FlightLocation>> searchCities(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final response = await http
          .get(
            Uri.parse(_baseUrl).replace(
              queryParameters: {'name': query, 'count': '10', 'language': 'es'},
            ),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final results = json['results'] as List<dynamic>?;

        if (results == null || results.isEmpty) {
          return [];
        }

        return results
            .cast<Map<String, dynamic>>()
            .map((r) => _parseGeocodingResult(r))
            .toList();
      }
    } catch (e) {
      // Network error, return empty list
      return [];
    }

    return [];
  }

  FlightLocation _parseGeocodingResult(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    final admin1 = json['admin1'] as String?;
    final country = json['country'] as String? ?? '';
    final latitude = (json['latitude'] as num?)?.toDouble() ?? 0;
    final longitude = (json['longitude'] as num?)?.toDouble() ?? 0;

    // Create a unique ID from coordinates
    final id =
        'geo_${latitude.toStringAsFixed(4)}_${longitude.toStringAsFixed(4)}'
            .replaceAll('.', '_')
            .replaceAll('-', 'm');

    return FlightLocation(
      id: id,
      name: name,
      region: admin1 ?? country,
      country: country,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

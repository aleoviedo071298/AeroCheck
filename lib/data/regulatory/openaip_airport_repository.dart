import 'dart:convert';
import 'package:http/http.dart' as http;
import 'airport.dart';
import 'airport_repository.dart';
import 'openaip_config.dart';
import 'regulatory_repository_exception.dart';

class OpenAipAirportRepository implements AirportRepository {
  OpenAipAirportRepository({
    String apiKey = OpenAipConfig.apiKey,
    http.Client? client,
    Uri? endpoint,
  }) : _apiKey = apiKey,
       _client = client ?? http.Client(),
       _endpoint =
           endpoint ?? Uri.parse('https://api.core.openaip.net/api/airports');

  final String _apiKey;
  final http.Client _client;
  final Uri _endpoint;

  @override
  Future<List<Airport>> fetchNearbyAirports({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    if (_apiKey.trim().isEmpty) {
      throw const RegulatoryRepositoryException(
        'OpenAIP API key is not configured.',
      );
    }

    final uri = _endpoint.replace(
      queryParameters: {
        'pos': '$latitude,$longitude',
        'dist': (radiusKm * 1000).round().toString(),
        'limit': '50',
        'fields': '_id,name,icaoCode,type,geometry',
      },
    );

    final response = await _client.get(
      uri,
      headers: {'x-openaip-api-key': _apiKey},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RegulatoryRepositoryException(
        'OpenAIP airports request failed with status ${response.statusCode}.',
      );
    }

    return _decodeAirports(response.body);
  }

  List<Airport> _decodeAirports(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } catch (error) {
      throw RegulatoryRepositoryException(
        'OpenAIP airports response is not valid JSON.',
        cause: error,
      );
    }

    if (decoded is! Map<String, Object?>) {
      throw const RegulatoryRepositoryException(
        'OpenAIP airports response must be an object.',
      );
    }

    final items = decoded['items'];
    if (items is! List) {
      throw const RegulatoryRepositoryException(
        'OpenAIP airports response must include an items list.',
      );
    }

    return items
        .whereType<Map<String, Object?>>()
        .map(_airportFromJson)
        .whereType<Airport>()
        .toList();
  }

  Airport? _airportFromJson(Map<String, Object?> json) {
    final id = json['_id'] as String? ?? '';
    final name = json['name'] as String? ?? 'Airport';
    final icaoCode = json['icaoCode'] as String?;

    // Support parsing 'type' as int or num
    final typeVal = json['type'];
    final typeCode = typeVal is int
        ? typeVal
        : (typeVal is num ? typeVal.toInt() : 0);

    final geometry = json['geometry'] as Map<String, Object?>?;
    if (geometry == null || geometry['type'] != 'Point') {
      return null;
    }

    final coordinates = geometry['coordinates'] as List?;
    if (coordinates == null || coordinates.length < 2) {
      return null;
    }

    final longitude = (coordinates[0] as num).toDouble();
    final latitude = (coordinates[1] as num).toDouble();

    return Airport(
      id: id,
      name: name,
      icaoCode: icaoCode,
      latitude: latitude,
      longitude: longitude,
      typeCode: typeCode,
    );
  }
}

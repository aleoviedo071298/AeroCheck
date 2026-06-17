import 'dart:convert';

import 'package:http/http.dart' as http;

import 'airspace.dart';
import 'airspace_repository.dart';
import 'openaip_config.dart';
import 'regulatory_repository_exception.dart';

class OpenAipAirspaceRepository implements AirspaceRepository {
  OpenAipAirspaceRepository({
    String apiKey = OpenAipConfig.apiKey,
    http.Client? client,
    Uri? endpoint,
  }) : _apiKey = apiKey,
       _client = client ?? http.Client(),
       _endpoint =
           endpoint ?? Uri.parse('https://api.core.openaip.net/api/airspaces');

  static const _fields = [
    '_id',
    'name',
    'type',
    'icaoClass',
    'country',
    'requestCompliance',
    'lowerLimit',
    'upperLimit',
    'geometry',
  ];

  final String _apiKey;
  final http.Client _client;
  final Uri _endpoint;

  @override
  Future<List<Airspace>> fetchNearbyAirspaces({
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
        'fields': _fields.join(','),
      },
    );

    final response = await _client.get(
      uri,
      headers: {'x-openaip-api-key': _apiKey},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RegulatoryRepositoryException(
        'OpenAIP airspaces request failed with status ${response.statusCode}.',
      );
    }

    return _decodeAirspaces(response.body);
  }

  List<Airspace> _decodeAirspaces(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } catch (error) {
      throw RegulatoryRepositoryException(
        'OpenAIP airspaces response is not valid JSON.',
        cause: error,
      );
    }

    if (decoded is! Map<String, Object?>) {
      throw const RegulatoryRepositoryException(
        'OpenAIP airspaces response must be an object.',
      );
    }

    final items = decoded['items'];
    if (items is! List) {
      throw const RegulatoryRepositoryException(
        'OpenAIP airspaces response must include an items list.',
      );
    }

    return items
        .whereType<Map<String, Object?>>()
        .map(_airspaceFromJson)
        .toList();
  }

  Airspace _airspaceFromJson(Map<String, Object?> json) {
    final typeCode = _optionalInt(json['type']);
    final icaoClassCode = _optionalInt(json['icaoClass']);
    return Airspace(
      id: _optionalString(json['_id']) ?? '',
      name: _optionalString(json['name']) ?? 'Airspace',
      typeCode: typeCode,
      typeLabel: _airspaceTypeLabel(typeCode),
      icaoClassCode: icaoClassCode,
      icaoClassLabel: _icaoClassLabel(icaoClassCode),
      country: _optionalString(json['country']) ?? '',
      lowerLimitLabel: _limitLabel(json['lowerLimit']),
      upperLimitLabel: _limitLabel(json['upperLimit']),
      requestCompliance: json['requestCompliance'] == true,
      coordinates: _coordinatesFromGeometry(json['geometry']),
    );
  }

  List<AirspaceCoordinate> _coordinatesFromGeometry(Object? geometry) {
    if (geometry is! Map<String, Object?>) {
      return const [];
    }
    final coordinates = geometry['coordinates'];
    if (coordinates is! List || coordinates.isEmpty) {
      return const [];
    }
    final outerRing = coordinates.first;
    if (outerRing is! List) {
      return const [];
    }

    final parsed = <AirspaceCoordinate>[];
    for (final point in outerRing) {
      if (point is! List || point.length < 2) {
        continue;
      }
      final longitude = _optionalDouble(point[0]);
      final latitude = _optionalDouble(point[1]);
      if (latitude == null || longitude == null) {
        continue;
      }
      parsed.add(AirspaceCoordinate(latitude: latitude, longitude: longitude));
    }
    return List.unmodifiable(parsed);
  }

  String _limitLabel(Object? value) {
    if (value is! Map<String, Object?>) {
      return 'No disp.';
    }
    final limitValue = _optionalInt(value['value']);
    final unit = _limitUnitLabel(_optionalInt(value['unit']));
    final datum = _referenceDatumLabel(_optionalInt(value['referenceDatum']));
    if (limitValue == null) {
      return 'No disp.';
    }
    return '$limitValue $unit $datum';
  }

  String _airspaceTypeLabel(int? value) {
    return switch (value) {
      1 => 'Restricted',
      2 => 'Danger',
      3 => 'Prohibited',
      4 => 'Controlled Tower Region (CTR)',
      5 => 'Transponder Mandatory Zone (TMZ)',
      6 => 'Radio Mandatory Zone (RMZ)',
      7 => 'Terminal Maneuvering Area (TMA)',
      13 => 'Airport Traffic Zone (ATZ)',
      17 => 'Alert Area',
      18 => 'Warning Area',
      19 => 'Protected Area',
      26 => 'Control Area (CTA)',
      29 => 'Low Altitude Overflight Restriction',
      36 => 'Military Controlled Tower Region (MCTR)',
      _ => 'Other',
    };
  }

  String _icaoClassLabel(int? value) {
    return switch (value) {
      0 => 'A',
      1 => 'B',
      2 => 'C',
      3 => 'D',
      4 => 'E',
      5 => 'F',
      6 => 'G',
      8 => 'Unclassified / SUA',
      _ => 'No disp.',
    };
  }

  String _limitUnitLabel(int? value) {
    return switch (value) {
      0 => 'm',
      1 => 'ft',
      6 => 'FL',
      _ => '',
    };
  }

  String _referenceDatumLabel(int? value) {
    return switch (value) {
      0 => 'GND',
      1 => 'MSL',
      2 => 'STD',
      _ => '',
    };
  }

  String? _optionalString(Object? value) {
    if (value is String) {
      return value;
    }
    return null;
  }

  int? _optionalInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  double? _optionalDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }
}

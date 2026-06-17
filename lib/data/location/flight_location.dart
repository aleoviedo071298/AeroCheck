import 'dart:convert';

class FlightLocation {
  const FlightLocation({
    required this.id,
    required this.name,
    required this.region,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final String region;
  final String country;
  final double latitude;
  final double longitude;

  String get label => '$name, $region';

  int get elevation {
    final normalizedId = id.replaceAll('-', '_').toLowerCase();
    switch (normalizedId) {
      case 'comodoro_rivadavia':
        return 37;
      case 'buenos_aires':
        return 25;
      case 'cordoba':
        return 389;
      case 'mendoza':
        return 746;
      case 'bariloche':
        return 893;
      default:
        // Deterministic fallback based on lat/lon
        return (((latitude.abs() * 12.345) + (longitude.abs() * 6.789)) % 950 +
                15)
            .round();
    }
  }

  String toJson() {
    return jsonEncode({
      'id': id,
      'name': name,
      'region': region,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  static FlightLocation fromJson(String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    return FlightLocation(
      id: data['id'] as String,
      name: data['name'] as String,
      region: data['region'] as String,
      country: data['country'] as String,
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
    );
  }
}

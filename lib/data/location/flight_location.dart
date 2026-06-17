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

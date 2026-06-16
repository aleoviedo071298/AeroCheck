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
}

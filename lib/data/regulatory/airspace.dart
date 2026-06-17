class Airspace {
  const Airspace({
    required this.id,
    required this.name,
    required this.typeCode,
    required this.typeLabel,
    required this.icaoClassCode,
    required this.icaoClassLabel,
    required this.country,
    required this.lowerLimitLabel,
    required this.upperLimitLabel,
    required this.requestCompliance,
    required this.coordinates,
  });

  final String id;
  final String name;
  final int? typeCode;
  final String typeLabel;
  final int? icaoClassCode;
  final String icaoClassLabel;
  final String country;
  final String lowerLimitLabel;
  final String upperLimitLabel;
  final bool requestCompliance;
  final List<AirspaceCoordinate> coordinates;
}

class AirspaceCoordinate {
  const AirspaceCoordinate({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

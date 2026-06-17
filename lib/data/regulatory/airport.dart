class Airport {
  const Airport({
    required this.id,
    required this.name,
    this.icaoCode,
    required this.latitude,
    required this.longitude,
    required this.typeCode,
  });

  final String id;
  final String name;
  final String? icaoCode;
  final double latitude;
  final double longitude;
  final int typeCode;
}

class DroneProfile {
  const DroneProfile({
    required this.id,
    required this.name,
    required this.maxWindKmh,
    required this.maxGustKmh,
    required this.preferredAltitudeMeters,
    required this.minVisibilityKm,
  });

  final String id;
  final String name;
  final double maxWindKmh;
  final double maxGustKmh;
  final int preferredAltitudeMeters;
  final double minVisibilityKm;

  static const micro = DroneProfile(
    id: 'micro',
    name: 'Micro',
    maxWindKmh: 20,
    maxGustKmh: 30,
    preferredAltitudeMeters: 120,
    minVisibilityKm: 3,
  );

  static const standard = DroneProfile(
    id: 'standard',
    name: 'Standard',
    maxWindKmh: 28,
    maxGustKmh: 40,
    preferredAltitudeMeters: 120,
    minVisibilityKm: 4,
  );

  static const professional = DroneProfile(
    id: 'professional',
    name: 'Professional',
    maxWindKmh: 35,
    maxGustKmh: 50,
    preferredAltitudeMeters: 150,
    minVisibilityKm: 5,
  );
}

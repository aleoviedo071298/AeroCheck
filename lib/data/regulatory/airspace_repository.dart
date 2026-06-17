import 'airspace.dart';

abstract class AirspaceRepository {
  Future<List<Airspace>> fetchNearbyAirspaces({
    required double latitude,
    required double longitude,
    required double radiusKm,
  });
}

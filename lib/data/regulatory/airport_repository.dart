import 'airport.dart';

abstract class AirportRepository {
  Future<List<Airport>> fetchNearbyAirports({
    required double latitude,
    required double longitude,
    required double radiusKm,
  });
}

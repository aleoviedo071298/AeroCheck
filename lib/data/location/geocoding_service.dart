import 'flight_location.dart';

abstract class GeocodingService {
  Future<List<FlightLocation>> searchCities(String query);
}

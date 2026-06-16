import 'flight_location.dart';

class DefaultFlightLocations {
  static const comodoroRivadavia = FlightLocation(
    id: 'comodoro-rivadavia',
    name: 'Comodoro Rivadavia',
    region: 'Chubut',
    country: 'Argentina',
    latitude: -45.8641,
    longitude: -67.4966,
  );

  static const buenosAires = FlightLocation(
    id: 'buenos-aires',
    name: 'Buenos Aires',
    region: 'CABA',
    country: 'Argentina',
    latitude: -34.6037,
    longitude: -58.3816,
  );

  static const cordoba = FlightLocation(
    id: 'cordoba',
    name: 'Cordoba',
    region: 'Cordoba',
    country: 'Argentina',
    latitude: -31.4201,
    longitude: -64.1888,
  );

  static const mendoza = FlightLocation(
    id: 'mendoza',
    name: 'Mendoza',
    region: 'Mendoza',
    country: 'Argentina',
    latitude: -32.8895,
    longitude: -68.8458,
  );

  static const bariloche = FlightLocation(
    id: 'bariloche',
    name: 'Bariloche',
    region: 'Rio Negro',
    country: 'Argentina',
    latitude: -41.1335,
    longitude: -71.3103,
  );

  static const all = [
    comodoroRivadavia,
    buenosAires,
    cordoba,
    mendoza,
    bariloche,
  ];

  static const seedFavorites = [comodoroRivadavia];

  static FlightLocation? byId(String? id) {
    if (id == null) {
      return null;
    }

    for (final location in all) {
      if (location.id == id) {
        return location;
      }
    }

    return null;
  }
}

import 'dart:math' as math;

import '../location/flight_location.dart';

class MockSensitiveZone {
  const MockSensitiveZone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
}

class MockSensitiveZones {
  static const all = [
    MockSensitiveZone(
      id: 'comodoro-operational-reference',
      name: 'Zona sensible mock Comodoro',
      latitude: -45.8120,
      longitude: -67.4860,
    ),
    MockSensitiveZone(
      id: 'mendoza-operational-reference',
      name: 'Zona sensible mock Mendoza',
      latitude: -32.8630,
      longitude: -68.8250,
    ),
  ];

  static bool hasZoneWithin({
    required FlightLocation location,
    required double radiusKm,
  }) {
    return all.any(
      (zone) =>
          distanceKm(
            fromLatitude: location.latitude,
            fromLongitude: location.longitude,
            toLatitude: zone.latitude,
            toLongitude: zone.longitude,
          ) <=
          radiusKm,
    );
  }

  static double distanceKm({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  }) {
    const earthRadiusKm = 6371.0;
    final deltaLatitude = _radians(toLatitude - fromLatitude);
    final deltaLongitude = _radians(toLongitude - fromLongitude);
    final fromLatitudeRad = _radians(fromLatitude);
    final toLatitudeRad = _radians(toLatitude);

    final a =
        math.sin(deltaLatitude / 2) * math.sin(deltaLatitude / 2) +
        math.cos(fromLatitudeRad) *
            math.cos(toLatitudeRad) *
            math.sin(deltaLongitude / 2) *
            math.sin(deltaLongitude / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _radians(double degrees) {
    return degrees * math.pi / 180;
  }
}

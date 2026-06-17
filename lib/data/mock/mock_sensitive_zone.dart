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

class MockSensitiveZoneDetection {
  const MockSensitiveZoneDetection({
    required this.zone,
    required this.distanceKm,
  });

  final MockSensitiveZone zone;
  final double distanceKm;
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
    return detectionsWithin(location: location, radiusKm: radiusKm).isNotEmpty;
  }

  static List<MockSensitiveZoneDetection> detectionsWithin({
    required FlightLocation location,
    required double radiusKm,
  }) {
    final detections =
        all
            .map(
              (zone) => MockSensitiveZoneDetection(
                zone: zone,
                distanceKm: distanceKm(
                  fromLatitude: location.latitude,
                  fromLongitude: location.longitude,
                  toLatitude: zone.latitude,
                  toLongitude: zone.longitude,
                ),
              ),
            )
            .where((detection) => detection.distanceKm <= radiusKm)
            .toList()
          ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return detections;
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

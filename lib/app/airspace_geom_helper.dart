import 'dart:math';

import '../data/regulatory/airspace.dart';

class AirspaceGeomHelper {
  static const _earthRadiusKm = 6371.0;

  static bool isPointInsideAirspace({
    required double pointLatitude,
    required double pointLongitude,
    required Airspace airspace,
  }) {
    final coords = airspace.coordinates;
    if (coords.length < 3) {
      return false;
    }

    return _raycastPointInPolygon(pointLatitude, pointLongitude, coords);
  }

  static double distanceToAirspaceKm({
    required double pointLatitude,
    required double pointLongitude,
    required Airspace airspace,
  }) {
    // If inside, distance is 0
    if (isPointInsideAirspace(
      pointLatitude: pointLatitude,
      pointLongitude: pointLongitude,
      airspace: airspace,
    )) {
      return 0;
    }

    final coords = airspace.coordinates;
    if (coords.isEmpty) {
      return double.infinity;
    }

    double minDistance = double.infinity;

    // Check distance to each edge
    for (int i = 0; i < coords.length; i++) {
      final coord1 = coords[i];
      final coord2 = coords[(i + 1) % coords.length];

      final distToEdge = _distancePointToLineSegment(
        pointLatitude,
        pointLongitude,
        coord1.latitude,
        coord1.longitude,
        coord2.latitude,
        coord2.longitude,
      );

      minDistance = min(minDistance, distToEdge);
    }

    return minDistance;
  }

  static bool isControlledAirspace({required int? icaoClassCode}) {
    // Classes A, B, C, D are controlled
    // Classes E, F, G are uncontrolled
    return icaoClassCode != null && icaoClassCode >= 0 && icaoClassCode <= 3;
  }

  static bool shouldBlockFlight({
    required int? icaoClassCode,
    required bool isInside,
  }) {
    // Block if inside any controlled airspace (A-D)
    return isInside && isControlledAirspace(icaoClassCode: icaoClassCode);
  }

  static bool shouldWarn({required int? icaoClassCode, required bool isNear}) {
    // Warn if near controlled airspace (A-D)
    return isNear && isControlledAirspace(icaoClassCode: icaoClassCode);
  }

  // Ray casting algorithm for point-in-polygon
  static bool _raycastPointInPolygon(
    double lat,
    double lon,
    List<AirspaceCoordinate> coords,
  ) {
    int intersections = 0;

    for (int i = 0; i < coords.length; i++) {
      final p1 = coords[i];
      final p2 = coords[(i + 1) % coords.length];

      final minLat = min(p1.latitude, p2.latitude);
      final maxLat = max(p1.latitude, p2.latitude);

      // Check if ray from point going east crosses this edge
      // The point's latitude must be within the edge's latitude range
      if (minLat <= lat && lat < maxLat) {
        // Calculate longitude intersection
        final t = (lat - p1.latitude) / (p2.latitude - p1.latitude);
        final lonIntersection =
            p1.longitude + t * (p2.longitude - p1.longitude);

        // Check if intersection is to the east (greater longitude value)
        if (lon < lonIntersection) {
          intersections++;
        }
      }
    }

    return intersections % 2 == 1;
  }

  // Distance from point to line segment using perpendicular distance formula
  static double _distancePointToLineSegment(
    double px,
    double py,
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    final len2 = dx * dx + dy * dy;

    if (len2 == 0) {
      return haversineDistance(px, py, x1, y1);
    }

    // Parameter t represents where the perpendicular meets the line segment
    var t = ((px - x1) * dx + (py - y1) * dy) / len2;
    t = max(0, min(1, t));

    final closestX = x1 + t * dx;
    final closestY = y1 + t * dy;

    return haversineDistance(px, py, closestX, closestY);
  }

  // Haversine formula for distance between two lat/lon points
  static double haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * asin(sqrt(a));

    return _earthRadiusKm * c;
  }

  static double _toRadians(double degrees) {
    return degrees * pi / 180.0;
  }
}

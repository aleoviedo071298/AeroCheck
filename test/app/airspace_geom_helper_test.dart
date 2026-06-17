import 'package:aerocheck/app/airspace_geom_helper.dart';
import 'package:aerocheck/data/regulatory/airspace.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AirspaceGeomHelper', () {
    test('detects point inside polygon (simple rectangle)', () {
      final airspace = Airspace(
        id: 'rect',
        name: 'Rectangle',
        typeCode: 1,
        typeLabel: 'Restricted',
        icaoClassCode: 0,
        icaoClassLabel: 'A',
        country: 'AR',
        lowerLimitLabel: '0 m GND',
        upperLimitLabel: '500 m MSL',
        requestCompliance: false,
        coordinates: const [
          AirspaceCoordinate(latitude: -45.0, longitude: -67.0),
          AirspaceCoordinate(latitude: -45.0, longitude: -67.5),
          AirspaceCoordinate(latitude: -45.5, longitude: -67.5),
          AirspaceCoordinate(latitude: -45.5, longitude: -67.0),
        ],
      );

      expect(
        AirspaceGeomHelper.isPointInsideAirspace(
          pointLatitude: -45.25,
          pointLongitude: -67.25,
          airspace: airspace,
        ),
        isTrue,
      );
    });

    test('detects point outside polygon (simple rectangle)', () {
      final airspace = Airspace(
        id: 'rect',
        name: 'Rectangle',
        typeCode: 1,
        typeLabel: 'Restricted',
        icaoClassCode: 0,
        icaoClassLabel: 'A',
        country: 'AR',
        lowerLimitLabel: '0 m GND',
        upperLimitLabel: '500 m MSL',
        requestCompliance: false,
        coordinates: const [
          AirspaceCoordinate(latitude: -45.0, longitude: -67.0),
          AirspaceCoordinate(latitude: -45.0, longitude: -67.5),
          AirspaceCoordinate(latitude: -45.5, longitude: -67.5),
          AirspaceCoordinate(latitude: -45.5, longitude: -67.0),
        ],
      );

      expect(
        AirspaceGeomHelper.isPointInsideAirspace(
          pointLatitude: -44.0,
          pointLongitude: -66.0,
          airspace: airspace,
        ),
        isFalse,
      );
    });

    test('returns false for airspace with no coordinates', () {
      final airspace = const Airspace(
        id: 'empty',
        name: 'Empty',
        typeCode: 1,
        typeLabel: 'Restricted',
        icaoClassCode: 0,
        icaoClassLabel: 'A',
        country: 'AR',
        lowerLimitLabel: '0 m GND',
        upperLimitLabel: '500 m MSL',
        requestCompliance: false,
        coordinates: [],
      );

      expect(
        AirspaceGeomHelper.isPointInsideAirspace(
          pointLatitude: -45.25,
          pointLongitude: -67.25,
          airspace: airspace,
        ),
        isFalse,
      );
    });

    test('calculates distance to nearest edge (point outside)', () {
      final airspace = Airspace(
        id: 'rect',
        name: 'Rectangle',
        typeCode: 1,
        typeLabel: 'Restricted',
        icaoClassCode: 0,
        icaoClassLabel: 'A',
        country: 'AR',
        lowerLimitLabel: '0 m GND',
        upperLimitLabel: '500 m MSL',
        requestCompliance: false,
        coordinates: const [
          AirspaceCoordinate(latitude: -45.0, longitude: -67.0),
          AirspaceCoordinate(latitude: -45.0, longitude: -67.5),
          AirspaceCoordinate(latitude: -45.5, longitude: -67.5),
          AirspaceCoordinate(latitude: -45.5, longitude: -67.0),
        ],
      );

      final distanceKm = AirspaceGeomHelper.distanceToAirspaceKm(
        pointLatitude: -44.9,
        pointLongitude: -67.25,
        airspace: airspace,
      );

      // Point is slightly north of the polygon, distance should be small (< 20 km)
      expect(distanceKm, greaterThan(0));
      expect(distanceKm, lessThan(20));
    });

    test('returns 0 distance for point inside polygon', () {
      final airspace = Airspace(
        id: 'rect',
        name: 'Rectangle',
        typeCode: 1,
        typeLabel: 'Restricted',
        icaoClassCode: 0,
        icaoClassLabel: 'A',
        country: 'AR',
        lowerLimitLabel: '0 m GND',
        upperLimitLabel: '500 m MSL',
        requestCompliance: false,
        coordinates: const [
          AirspaceCoordinate(latitude: -45.0, longitude: -67.0),
          AirspaceCoordinate(latitude: -45.0, longitude: -67.5),
          AirspaceCoordinate(latitude: -45.5, longitude: -67.5),
          AirspaceCoordinate(latitude: -45.5, longitude: -67.0),
        ],
      );

      final distanceKm = AirspaceGeomHelper.distanceToAirspaceKm(
        pointLatitude: -45.25,
        pointLongitude: -67.25,
        airspace: airspace,
      );

      expect(distanceKm, 0);
    });

    test('returns large distance for point far from polygon', () {
      final airspace = Airspace(
        id: 'rect',
        name: 'Rectangle',
        typeCode: 1,
        typeLabel: 'Restricted',
        icaoClassCode: 0,
        icaoClassLabel: 'A',
        country: 'AR',
        lowerLimitLabel: '0 m GND',
        upperLimitLabel: '500 m MSL',
        requestCompliance: false,
        coordinates: const [
          AirspaceCoordinate(latitude: -45.0, longitude: -67.0),
          AirspaceCoordinate(latitude: -45.0, longitude: -67.5),
          AirspaceCoordinate(latitude: -45.5, longitude: -67.5),
          AirspaceCoordinate(latitude: -45.5, longitude: -67.0),
        ],
      );

      final distanceKm = AirspaceGeomHelper.distanceToAirspaceKm(
        pointLatitude: -40.0,
        pointLongitude: -60.0,
        airspace: airspace,
      );

      // Should be hundreds of km away
      expect(distanceKm, greaterThan(100));
    });

    test('classifies controlled airspace correctly', () {
      expect(
        AirspaceGeomHelper.isControlledAirspace(icaoClassCode: 0),
        isTrue,
      ); // A
      expect(
        AirspaceGeomHelper.isControlledAirspace(icaoClassCode: 1),
        isTrue,
      ); // B
      expect(
        AirspaceGeomHelper.isControlledAirspace(icaoClassCode: 2),
        isTrue,
      ); // C
      expect(
        AirspaceGeomHelper.isControlledAirspace(icaoClassCode: 3),
        isTrue,
      ); // D
      expect(
        AirspaceGeomHelper.isControlledAirspace(icaoClassCode: 4),
        isFalse,
      ); // E
      expect(
        AirspaceGeomHelper.isControlledAirspace(icaoClassCode: 5),
        isFalse,
      ); // F
      expect(
        AirspaceGeomHelper.isControlledAirspace(icaoClassCode: 6),
        isFalse,
      ); // G
    });

    test('detects Comodoro point inside rectangle airspace', () {
      // Comodoro Rivadavia is at approximately -45.8641, -67.4966
      final airspace = Airspace(
        id: 'comodoro-rect',
        name: 'Comodoro Rectangle',
        typeCode: 3,
        typeLabel: 'Prohibited',
        icaoClassCode: 0,
        icaoClassLabel: 'A',
        country: 'AR',
        lowerLimitLabel: '0 m GND',
        upperLimitLabel: '1000 m MSL',
        requestCompliance: false,
        coordinates: const [
          AirspaceCoordinate(latitude: -45.80, longitude: -67.50),
          AirspaceCoordinate(latitude: -45.80, longitude: -67.45),
          AirspaceCoordinate(latitude: -45.90, longitude: -67.45),
          AirspaceCoordinate(latitude: -45.90, longitude: -67.50),
        ],
      );

      final isInside = AirspaceGeomHelper.isPointInsideAirspace(
        pointLatitude: -45.8641,
        pointLongitude: -67.4966,
        airspace: airspace,
      );

      expect(
        isInside,
        isTrue,
        reason:
            'Comodoro (-45.8641, -67.4966) should be inside rectangle bounded by '
            'lat [-45.80, -45.90] and lon [-67.50, -67.45]',
      );
    });
  });
}

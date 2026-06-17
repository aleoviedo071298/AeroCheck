import 'package:aerocheck/data/mock/mock_flight_data.dart';
import 'package:aerocheck/domain/rules/wind_profile_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WindProfileEvaluator', () {
    test('evaluates wind profile rows with risk status', () {
      final rows = MockFlightData.windProfileRows();
      expect(rows, isNotEmpty);

      final evaluator = WindProfileEvaluator(
        droneProfile: MockFlightData.droneProfile,
        missionProfile: MockFlightData.missionProfile,
      );

      final evaluatedRows = evaluator.evaluateProfile(rows);

      expect(evaluatedRows, hasLength(rows.length));
      for (final row in evaluatedRows) {
        expect(row.status, isIn(['ok', 'warning', 'blocked']));
        expect(row.altitude, isNotEmpty);
      }
    });

    test('marks altitude as blocked when wind exceeds limit', () {
      final row = const WindProfileRow(
        altitude: '100 m',
        windKmh: 50, // Very high wind
        gustKmh: 60,
        temperatureC: 20,
      );

      final evaluator = WindProfileEvaluator(
        droneProfile: MockFlightData.droneProfile,
        missionProfile: MockFlightData.missionProfile,
      );

      final evaluated = evaluator.evaluateRow(row);
      expect(evaluated.status, 'blocked');
    });

    test('marks altitude as warning when wind is near limit', () {
      final row = const WindProfileRow(
        altitude: '100 m',
        windKmh: 23, // Near but below limit (23.8 * 0.85 = 23.8 effective)
        gustKmh: 30, // Below limit
        temperatureC: 20,
      );

      final evaluator = WindProfileEvaluator(
        droneProfile: MockFlightData.droneProfile,
        missionProfile: MockFlightData.missionProfile,
      );

      final evaluated = evaluator.evaluateRow(row);
      expect(evaluated.status, 'warning');
    });

    test('marks altitude as ok when wind is below limit', () {
      final row = const WindProfileRow(
        altitude: '100 m',
        windKmh: 10,
        gustKmh: 15,
        temperatureC: 20,
      );

      final evaluator = WindProfileEvaluator(
        droneProfile: MockFlightData.droneProfile,
        missionProfile: MockFlightData.missionProfile,
      );

      final evaluated = evaluator.evaluateRow(row);
      expect(evaluated.status, 'ok');
    });

    test('finds best-wind altitude in profile', () {
      final rows = [
        const WindProfileRow(
          altitude: '10 m',
          windKmh: 15,
          gustKmh: 22,
          temperatureC: 15,
        ),
        const WindProfileRow(
          altitude: '50 m',
          windKmh: 8, // Best wind
          gustKmh: 12,
          temperatureC: 14,
        ),
        const WindProfileRow(
          altitude: '100 m',
          windKmh: 20,
          gustKmh: 28,
          temperatureC: 12,
        ),
      ];

      final evaluator = WindProfileEvaluator(
        droneProfile: MockFlightData.droneProfile,
        missionProfile: MockFlightData.missionProfile,
      );

      final best = evaluator.findBestWindAltitude(rows);
      expect(best.altitude, '50 m');
    });

    test('returns first row as best when all conditions equal', () {
      final rows = [
        const WindProfileRow(
          altitude: '10 m',
          windKmh: 10,
          gustKmh: 15,
          temperatureC: 15,
        ),
        const WindProfileRow(
          altitude: '50 m',
          windKmh: 10,
          gustKmh: 15,
          temperatureC: 15,
        ),
      ];

      final evaluator = WindProfileEvaluator(
        droneProfile: MockFlightData.droneProfile,
        missionProfile: MockFlightData.missionProfile,
      );

      final best = evaluator.findBestWindAltitude(rows);
      expect(best.altitude, '10 m');
    });

    test('applies mission modifiers to wind limits', () {
      // Standard drone: 28 km/h max wind
      // Photo/video mission: 0.85 modifier
      // Expected effective limit: ~23.8 km/h
      final row = const WindProfileRow(
        altitude: '100 m',
        windKmh: 24, // Above effective limit
        gustKmh: 35,
        temperatureC: 20,
      );

      final evaluator = WindProfileEvaluator(
        droneProfile: MockFlightData.droneProfile,
        missionProfile: MockFlightData.missionProfile, // photo/video
      );

      final evaluated = evaluator.evaluateRow(row);
      expect(evaluated.status, 'blocked');
    });
  });
}

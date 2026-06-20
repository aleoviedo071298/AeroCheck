import 'package:aerocheck/data/mock/mock_flight_data.dart';
import 'package:aerocheck/domain/rules/flight_rules_config.dart';
import 'package:aerocheck/domain/rules/wind_profile_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const config = FlightRulesConfig.defaults(); // wind warn 22, block 28

  group('WindProfileEvaluator', () {
    test('marks blocked when wind exceeds the configured block', () {
      final evaluator = WindProfileEvaluator(config: config);
      final evaluated = evaluator.evaluateRow(
        const WindProfileRow(
          altitude: '100 m',
          windKmh: 50,
          gustKmh: 60,
          temperatureC: 20,
        ),
      );
      expect(evaluated.status, 'blocked');
    });

    test('marks warning when wind is in the warning band', () {
      final evaluator = WindProfileEvaluator(config: config);
      final evaluated = evaluator.evaluateRow(
        const WindProfileRow(
          altitude: '100 m',
          windKmh: 24,
          gustKmh: 30,
          temperatureC: 20,
        ),
      );
      expect(evaluated.status, 'warning');
    });

    test('marks ok when wind is below the warning band', () {
      final evaluator = WindProfileEvaluator(config: config);
      final evaluated = evaluator.evaluateRow(
        const WindProfileRow(
          altitude: '100 m',
          windKmh: 10,
          gustKmh: 15,
          temperatureC: 20,
        ),
      );
      expect(evaluated.status, 'ok');
    });

    test('a custom lower block flips a previously-ok row to blocked', () {
      final evaluator = WindProfileEvaluator(
        config: config.copyWith(windWarningKmh: 6, windBlockedKmh: 9),
      );
      final evaluated = evaluator.evaluateRow(
        const WindProfileRow(
          altitude: '100 m',
          windKmh: 10,
          gustKmh: 12,
          temperatureC: 20,
        ),
      );
      expect(evaluated.status, 'blocked');
    });

    test('finds best-wind altitude in profile', () {
      final evaluator = WindProfileEvaluator(config: config);
      final best = evaluator.findBestWindAltitude(const [
        WindProfileRow(
          altitude: '10 m',
          windKmh: 15,
          gustKmh: 22,
          temperatureC: 15,
        ),
        WindProfileRow(
          altitude: '50 m',
          windKmh: 8,
          gustKmh: 12,
          temperatureC: 14,
        ),
        WindProfileRow(
          altitude: '100 m',
          windKmh: 20,
          gustKmh: 28,
          temperatureC: 12,
        ),
      ]);
      expect(best.altitude, '50 m');
    });

    test(
      'best-wind ranks by sustained wind only (gust only exists at 10 m)',
      () {
        // Upper altitudes have no gust data (0). The lowest-wind altitude (10 m)
        // must win even though it carries the only real, high gust.
        final evaluator = WindProfileEvaluator(config: config);
        final best = evaluator.findBestWindAltitude(const [
          WindProfileRow(
            altitude: '10 m',
            windKmh: 40,
            gustKmh: 79,
            temperatureC: 11,
          ),
          WindProfileRow(
            altitude: '80 m',
            windKmh: 56,
            gustKmh: 0,
            temperatureC: 11,
          ),
          WindProfileRow(
            altitude: '120 m',
            windKmh: 59,
            gustKmh: 0,
            temperatureC: 11,
          ),
          WindProfileRow(
            altitude: '180 m',
            windKmh: 65,
            gustKmh: 0,
            temperatureC: 11,
          ),
        ]);
        expect(best.altitude, '10 m');
      },
    );

    test('evaluates a real mock profile without error', () {
      final evaluator = WindProfileEvaluator(config: config);
      final rows = MockFlightData.windProfileRows();
      final evaluated = evaluator.evaluateProfile(rows);
      expect(evaluated, hasLength(rows.length));
    });
  });
}

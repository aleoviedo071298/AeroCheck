import 'package:aerocheck/domain/entities/flight_window_recommendation.dart';
import 'package:aerocheck/domain/entities/weather_snapshot.dart';
import 'package:aerocheck/domain/rules/flight_readiness_evaluator.dart';
import 'package:aerocheck/domain/rules/flight_readiness_status.dart';
import 'package:aerocheck/domain/rules/flight_rules_config.dart';
import 'package:aerocheck/domain/rules/rule_severity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const evaluator = FlightReadinessEvaluator();
  const config = FlightRulesConfig.defaults();
  final bestWindow = FlightWindowRecommendation(
    start: DateTime(2026, 6, 17, 8),
    end: DateTime(2026, 6, 17, 10),
    score: 92,
    status: FlightReadinessStatus.ready,
    summary: 'Mejor ventana por viento bajo y buena visibilidad.',
  );

  WeatherSnapshot baseWeather({
    double? windKmh = 10,
    double? gustKmh = 16,
    double? precipitationProbability = 0,
    double? precipitationMmPerHour = 0,
    double? visibilityKm = 12,
    double? cloudBaseMeters = 400,
    double? temperatureC = 18,
    double? kpIndex = 2,
    bool isDaylight = true,
    bool isInsideRestrictedArea = false,
    bool isNearRestrictedArea = false,
  }) {
    return WeatherSnapshot(
      time: DateTime(2026, 6, 16, 9),
      locationLabel: 'Comodoro Rivadavia, Chubut',
      temperatureC: temperatureC,
      dewPointC: 8,
      windKmh: windKmh,
      gustKmh: gustKmh,
      windDirectionDegrees: 210,
      precipitationProbability: precipitationProbability,
      precipitationMmPerHour: precipitationMmPerHour,
      cloudCoverPercent: 30,
      cloudBaseMeters: cloudBaseMeters,
      visibilityKm: visibilityKm,
      kpIndex: kpIndex,
      isDaylight: isDaylight,
      isInsideRestrictedArea: isInsideRestrictedArea,
      isNearRestrictedArea: isNearRestrictedArea,
    );
  }

  test('returns ready when all rules are ok', () {
    final report = evaluator.evaluate(
      weather: baseWeather(),
      config: config,
      bestWindow: bestWindow,
    );
    expect(report.status, FlightReadinessStatus.ready);
    expect(report.score, 100);
  });

  test('returns caution when wind is in the warning band', () {
    final report = evaluator.evaluate(
      weather: baseWeather(windKmh: 24),
      config: config,
      bestWindow: bestWindow,
    );
    expect(report.status, FlightReadinessStatus.caution);
    expect(
      report.rules.singleWhere((r) => r.code == 'WIND_SPEED').severity,
      RuleSeverity.warning,
    );
  });

  test('a custom lower wind block flips the same weather to notReady', () {
    final report = evaluator.evaluate(
      weather: baseWeather(windKmh: 15),
      config: config.copyWith(windWarningKmh: 8, windBlockedKmh: 12),
      bestWindow: bestWindow,
    );
    expect(report.status, FlightReadinessStatus.notReady);
    expect(
      report.rules.singleWhere((r) => r.code == 'WIND_SPEED').threshold,
      12,
    );
  });

  test('night flight is blocked by default but allowed when enabled', () {
    final blocked = evaluator.evaluate(
      weather: baseWeather(isDaylight: false),
      config: config,
      bestWindow: bestWindow,
    );
    expect(
      blocked.rules.singleWhere((r) => r.code == 'DAYLIGHT').severity,
      RuleSeverity.blocked,
    );

    final allowed = evaluator.evaluate(
      weather: baseWeather(isDaylight: false),
      config: config.copyWith(allowNightFlight: true),
      bestWindow: bestWindow,
    );
    expect(
      allowed.rules.singleWhere((r) => r.code == 'DAYLIGHT').severity,
      RuleSeverity.ok,
    );
  });

  test('does not return ready when critical data is missing', () {
    final report = evaluator.evaluate(
      weather: baseWeather(windKmh: null),
      config: config,
      bestWindow: bestWindow,
    );
    expect(report.status, FlightReadinessStatus.notReady);
    expect(
      report.rules.singleWhere((r) => r.code == 'MISSING_DATA').severity,
      RuleSeverity.blocked,
    );
  });
}

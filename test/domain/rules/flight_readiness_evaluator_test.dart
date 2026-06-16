import 'package:aerocheck/domain/entities/drone_profile.dart';
import 'package:aerocheck/domain/entities/flight_window_recommendation.dart';
import 'package:aerocheck/domain/entities/mission_profile.dart';
import 'package:aerocheck/domain/entities/weather_snapshot.dart';
import 'package:aerocheck/domain/rules/flight_readiness_evaluator.dart';
import 'package:aerocheck/domain/rules/flight_readiness_status.dart';
import 'package:aerocheck/domain/rules/rule_severity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const evaluator = FlightReadinessEvaluator();
  const drone = DroneProfile.standard;
  const mission = MissionProfile.recreational;
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
    String locationLabel = 'Comodoro Rivadavia, Chubut',
  }) {
    return WeatherSnapshot(
      time: DateTime(2026, 6, 16, 9),
      locationLabel: locationLabel,
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
      droneProfile: drone,
      missionProfile: mission,
      bestWindow: bestWindow,
    );

    expect(report.status, FlightReadinessStatus.ready);
    expect(report.score, 100);
    expect(
      report.rules.every((rule) => rule.severity == RuleSeverity.ok),
      isTrue,
    );
  });

  test('returns caution when wind is near the effective limit', () {
    final report = evaluator.evaluate(
      weather: baseWeather(windKmh: 24),
      droneProfile: drone,
      missionProfile: mission,
      bestWindow: bestWindow,
    );

    expect(report.status, FlightReadinessStatus.caution);
    expect(
      report.rules.singleWhere((rule) => rule.code == 'WIND_SPEED').severity,
      RuleSeverity.warning,
    );
  });

  test('returns notReady when gust exceeds the effective limit', () {
    final report = evaluator.evaluate(
      weather: baseWeather(gustKmh: 46),
      droneProfile: drone,
      missionProfile: mission,
      bestWindow: bestWindow,
    );

    expect(report.status, FlightReadinessStatus.notReady);
    expect(
      report.rules.singleWhere((rule) => rule.code == 'WIND_GUST').severity,
      RuleSeverity.blocked,
    );
  });

  test('returns notReady when precipitation intensity blocks flight', () {
    final report = evaluator.evaluate(
      weather: baseWeather(precipitationMmPerHour: 0.8),
      droneProfile: drone,
      missionProfile: mission,
      bestWindow: bestWindow,
    );

    expect(report.status, FlightReadinessStatus.notReady);
    expect(
      report.rules
          .singleWhere((rule) => rule.code == 'PRECIP_INTENSITY')
          .severity,
      RuleSeverity.blocked,
    );
  });

  test('returns notReady when inside a restricted area', () {
    final report = evaluator.evaluate(
      weather: baseWeather(isInsideRestrictedArea: true),
      droneProfile: drone,
      missionProfile: mission,
      bestWindow: bestWindow,
    );

    expect(report.status, FlightReadinessStatus.notReady);
    expect(
      report.rules
          .singleWhere((rule) => rule.code == 'RESTRICTED_AREA')
          .severity,
      RuleSeverity.blocked,
    );
  });

  test('returns caution when near a restricted area', () {
    final report = evaluator.evaluate(
      weather: baseWeather(isNearRestrictedArea: true),
      droneProfile: drone,
      missionProfile: mission,
      bestWindow: bestWindow,
    );

    expect(report.status, FlightReadinessStatus.caution);
    expect(
      report.rules
          .singleWhere((rule) => rule.code == 'RESTRICTED_AREA')
          .severity,
      RuleSeverity.warning,
    );
  });

  test('applies mission modifiers to effective wind and gust thresholds', () {
    final report = evaluator.evaluate(
      weather: baseWeather(windKmh: 24),
      droneProfile: drone,
      missionProfile: MissionProfile.photoVideo,
      bestWindow: bestWindow,
    );

    expect(report.status, FlightReadinessStatus.notReady);
    expect(
      report.rules.singleWhere((rule) => rule.code == 'WIND_SPEED').threshold,
      23.8,
    );
  });

  test('does not return ready when critical data is missing', () {
    final report = evaluator.evaluate(
      weather: baseWeather(windKmh: null),
      droneProfile: drone,
      missionProfile: mission,
      bestWindow: bestWindow,
    );

    expect(report.status, FlightReadinessStatus.notReady);
    expect(
      report.rules.singleWhere((rule) => rule.code == 'MISSING_DATA').severity,
      RuleSeverity.blocked,
    );
  });

  test('produces user-facing rule reasons', () {
    final report = evaluator.evaluate(
      weather: baseWeather(gustKmh: 46),
      droneProfile: drone,
      missionProfile: mission,
      bestWindow: bestWindow,
    );

    final blocked = report.rules.where(
      (rule) => rule.severity == RuleSeverity.blocked,
    );
    expect(blocked, isNotEmpty);
    expect(blocked.first.title, isNotEmpty);
    expect(blocked.first.details, isNotEmpty);
  });
}

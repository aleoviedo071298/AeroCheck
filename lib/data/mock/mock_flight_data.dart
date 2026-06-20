import '../../domain/entities/drone_profile.dart';
import '../../domain/entities/flight_readiness_report.dart';
import '../../domain/entities/flight_window_recommendation.dart';
import '../../domain/entities/mission_profile.dart';
import '../../domain/entities/weather_snapshot.dart';
import '../../domain/rules/flight_readiness_evaluator.dart';
import '../../domain/rules/flight_readiness_status.dart';
import '../../domain/rules/flight_rules_config.dart';
import '../../domain/rules/rule_severity.dart';

enum MockFlightScenario { goodToFly, cautionWind, notReadyRainAndRestriction }

extension MockFlightScenarioLabel on MockFlightScenario {
  String get label => switch (this) {
    MockFlightScenario.goodToFly => 'APTO',
    MockFlightScenario.cautionWind => 'PRECAUCION',
    MockFlightScenario.notReadyRainAndRestriction => 'NO APTO',
  };

  String get description => switch (this) {
    MockFlightScenario.goodToFly => 'Bajo riesgo',
    MockFlightScenario.cautionWind => 'Rafagas y zona cercana',
    MockFlightScenario.notReadyRainAndRestriction => 'Lluvia y restriccion',
  };
}

class MockFlightData {
  static const evaluator = FlightReadinessEvaluator();
  static const droneProfile = DroneProfile.standard;
  static const missionProfile = MissionProfile.photoVideo;
  static const rulesConfig = FlightRulesConfig.defaults();

  static final bestWindow = FlightWindowRecommendation(
    start: DateTime(2026, 6, 17, 8, 20),
    end: DateTime(2026, 6, 17, 10, 10),
    score: 92,
    status: FlightReadinessStatus.ready,
    summary: 'Mejor ventana por viento bajo, buena visibilidad y sin lluvia.',
  );

  static final goodToFly = WeatherSnapshot(
    time: DateTime(2026, 6, 16, 9),
    locationLabel: 'Comodoro Rivadavia, Chubut',
    temperatureC: 16,
    dewPointC: 8,
    windKmh: 12,
    gustKmh: 18,
    windDirectionDegrees: 230,
    precipitationProbability: 0,
    precipitationMmPerHour: 0,
    cloudCoverPercent: 28,
    cloudBaseMeters: 520,
    visibilityKm: 16,
    kpIndex: 1.7,
    isDaylight: true,
    isInsideRestrictedArea: false,
    isNearRestrictedArea: false,
  );

  static final cautionWind = WeatherSnapshot(
    time: DateTime(2026, 6, 16, 13),
    locationLabel: 'Comodoro Rivadavia, Chubut',
    temperatureC: 16,
    dewPointC: 9,
    windKmh: 19,
    gustKmh: 31,
    windDirectionDegrees: 245,
    precipitationProbability: 18,
    precipitationMmPerHour: 0,
    cloudCoverPercent: 54,
    cloudBaseMeters: 410,
    visibilityKm: 14,
    kpIndex: 2.1,
    isDaylight: true,
    isInsideRestrictedArea: false,
    isNearRestrictedArea: true,
  );

  static final notReadyRainAndRestriction = WeatherSnapshot(
    time: DateTime(2026, 6, 16, 17),
    locationLabel: 'Comodoro Rivadavia, Chubut',
    temperatureC: 11,
    dewPointC: 10,
    windKmh: 24,
    gustKmh: 43,
    windDirectionDegrees: 260,
    precipitationProbability: 72,
    precipitationMmPerHour: 1.2,
    cloudCoverPercent: 88,
    cloudBaseMeters: 160,
    visibilityKm: 2.2,
    kpIndex: 4.5,
    isDaylight: true,
    isInsideRestrictedArea: true,
    isNearRestrictedArea: true,
  );

  static WeatherSnapshot snapshotFor(MockFlightScenario scenario) {
    return switch (scenario) {
      MockFlightScenario.goodToFly => goodToFly,
      MockFlightScenario.cautionWind => cautionWind,
      MockFlightScenario.notReadyRainAndRestriction =>
        notReadyRainAndRestriction,
    };
  }

  static FlightReadinessReport reportFor(MockFlightScenario scenario) {
    return evaluator.evaluate(
      weather: snapshotFor(scenario),
      config: rulesConfig,
      bestWindow: bestWindow,
    );
  }

  static FlightReadinessReport currentReport() {
    return reportFor(MockFlightScenario.cautionWind);
  }

  static List<WeatherSnapshot> forecastSnapshots() {
    return [
      goodToFly.copyWith(
        time: DateTime(2026, 6, 16, 8),
        windKmh: 11,
        gustKmh: 17,
        precipitationProbability: 0,
        visibilityKm: 16,
      ),
      goodToFly.copyWith(
        time: DateTime(2026, 6, 16, 9),
        windKmh: 12,
        gustKmh: 18,
        precipitationProbability: 0,
        visibilityKm: 16,
      ),
      goodToFly.copyWith(
        time: DateTime(2026, 6, 16, 10),
        windKmh: 14,
        gustKmh: 20,
        precipitationProbability: 4,
        visibilityKm: 15,
      ),
      cautionWind,
      notReadyRainAndRestriction,
    ];
  }

  static List<WindProfileRow> windProfileRows() {
    return const [
      WindProfileRow(
        altitude: '10 m',
        windKmh: 20.2,
        gustKmh: 42.1,
        temperatureC: 7.7,
        windDirectionDegrees: 112,
      ),
      WindProfileRow(
        altitude: '80 m',
        windKmh: 26.0,
        gustKmh: 0.0,
        temperatureC: 7.7,
        windDirectionDegrees: 100,
      ),
      WindProfileRow(
        altitude: '120 m',
        windKmh: 27.2,
        gustKmh: 0.0,
        temperatureC: 7.7,
        windDirectionDegrees: 101,
      ),
      WindProfileRow(
        altitude: '180 m',
        windKmh: 24.7,
        gustKmh: 0.0,
        temperatureC: 7.7,
        windDirectionDegrees: 104,
      ),
    ];
  }
}

class ForecastRow {
  const ForecastRow({
    required this.hour,
    required this.status,
    required this.primaryReason,
    required this.reasons,
    required this.isBestWindow,
    required this.windKmh,
    required this.gustKmh,
    required this.rainPercent,
    required this.visibilityKm,
    required this.score,
    this.windDirectionDegrees,
    this.time,
    this.temperatureC,
    this.cloudCoverPercent,
    this.precipitationMmPerHour,
    this.dewPointC,
  });

  final String hour;
  final FlightReadinessStatus status;
  final String primaryReason;
  final List<ForecastReason> reasons;
  final bool isBestWindow;
  final double windKmh;
  final double gustKmh;
  final double rainPercent;
  final double visibilityKm;
  final int score;
  final double? windDirectionDegrees;
  final DateTime? time;
  final double? temperatureC;
  final double? cloudCoverPercent;
  final double? precipitationMmPerHour;
  final double? dewPointC;
}

class ForecastReason {
  const ForecastReason({
    required this.title,
    required this.details,
    required this.severity,
    this.code,
    this.measuredValue,
    this.threshold,
  });

  final String title;
  final String details;
  final RuleSeverity severity;
  final String? code;
  final double? measuredValue;
  final double? threshold;
}

class WindProfileRow {
  const WindProfileRow({
    required this.altitude,
    required this.windKmh,
    required this.gustKmh,
    required this.temperatureC,
    this.windDirectionDegrees,
  });

  final String altitude;
  final double windKmh;
  final double gustKmh;
  final double temperatureC;
  final double? windDirectionDegrees;
}

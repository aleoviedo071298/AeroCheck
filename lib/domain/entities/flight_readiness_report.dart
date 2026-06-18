import '../rules/flight_readiness_status.dart';
import '../rules/flight_rules_config.dart';
import 'flight_rule_result.dart';
import 'flight_window_recommendation.dart';
import 'weather_snapshot.dart';

class FlightReadinessReport {
  const FlightReadinessReport({
    required this.status,
    required this.score,
    required this.summary,
    required this.rules,
    required this.weather,
    required this.config,
    required this.bestWindow,
  });

  final FlightReadinessStatus status;
  final int score;
  final String summary;
  final List<FlightRuleResult> rules;
  final WeatherSnapshot weather;
  final FlightRulesConfig config;
  final FlightWindowRecommendation bestWindow;
}

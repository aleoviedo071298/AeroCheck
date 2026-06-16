import '../rules/flight_readiness_status.dart';
import 'drone_profile.dart';
import 'flight_rule_result.dart';
import 'flight_window_recommendation.dart';
import 'mission_profile.dart';
import 'weather_snapshot.dart';

class FlightReadinessReport {
  const FlightReadinessReport({
    required this.status,
    required this.score,
    required this.summary,
    required this.rules,
    required this.weather,
    required this.droneProfile,
    required this.missionProfile,
    required this.bestWindow,
  });

  final FlightReadinessStatus status;
  final int score;
  final String summary;
  final List<FlightRuleResult> rules;
  final WeatherSnapshot weather;
  final DroneProfile droneProfile;
  final MissionProfile missionProfile;
  final FlightWindowRecommendation bestWindow;
}

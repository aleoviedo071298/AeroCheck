import '../rules/flight_readiness_status.dart';

class FlightWindowRecommendation {
  const FlightWindowRecommendation({
    required this.start,
    required this.end,
    required this.score,
    required this.status,
    required this.summary,
  });

  final DateTime start;
  final DateTime end;
  final int score;
  final FlightReadinessStatus status;
  final String summary;
}

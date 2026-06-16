class WeatherSnapshot {
  const WeatherSnapshot({
    required this.time,
    required this.locationLabel,
    this.temperatureC,
    this.dewPointC,
    this.windKmh,
    this.gustKmh,
    this.windDirectionDegrees,
    this.precipitationProbability,
    this.precipitationMmPerHour,
    this.cloudCoverPercent,
    this.cloudBaseMeters,
    this.visibilityKm,
    this.kpIndex,
    required this.isDaylight,
    required this.isInsideRestrictedArea,
    required this.isNearRestrictedArea,
  });

  final DateTime time;
  final String locationLabel;
  final double? temperatureC;
  final double? dewPointC;
  final double? windKmh;
  final double? gustKmh;
  final double? windDirectionDegrees;
  final double? precipitationProbability;
  final double? precipitationMmPerHour;
  final double? cloudCoverPercent;
  final double? cloudBaseMeters;
  final double? visibilityKm;
  final double? kpIndex;
  final bool isDaylight;
  final bool isInsideRestrictedArea;
  final bool isNearRestrictedArea;
}

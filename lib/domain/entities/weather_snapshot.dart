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

  WeatherSnapshot copyWith({
    DateTime? time,
    String? locationLabel,
    double? temperatureC,
    double? dewPointC,
    double? windKmh,
    double? gustKmh,
    double? windDirectionDegrees,
    double? precipitationProbability,
    double? precipitationMmPerHour,
    double? cloudCoverPercent,
    double? cloudBaseMeters,
    double? visibilityKm,
    double? kpIndex,
    bool? isDaylight,
    bool? isInsideRestrictedArea,
    bool? isNearRestrictedArea,
  }) {
    return WeatherSnapshot(
      time: time ?? this.time,
      locationLabel: locationLabel ?? this.locationLabel,
      temperatureC: temperatureC ?? this.temperatureC,
      dewPointC: dewPointC ?? this.dewPointC,
      windKmh: windKmh ?? this.windKmh,
      gustKmh: gustKmh ?? this.gustKmh,
      windDirectionDegrees: windDirectionDegrees ?? this.windDirectionDegrees,
      precipitationProbability:
          precipitationProbability ?? this.precipitationProbability,
      precipitationMmPerHour:
          precipitationMmPerHour ?? this.precipitationMmPerHour,
      cloudCoverPercent: cloudCoverPercent ?? this.cloudCoverPercent,
      cloudBaseMeters: cloudBaseMeters ?? this.cloudBaseMeters,
      visibilityKm: visibilityKm ?? this.visibilityKm,
      kpIndex: kpIndex ?? this.kpIndex,
      isDaylight: isDaylight ?? this.isDaylight,
      isInsideRestrictedArea:
          isInsideRestrictedArea ?? this.isInsideRestrictedArea,
      isNearRestrictedArea: isNearRestrictedArea ?? this.isNearRestrictedArea,
    );
  }
}

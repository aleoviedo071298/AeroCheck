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
    this.relativeHumidityPercent,
    this.apparentTemperatureC,
    this.pressureHpa,
    this.uvIndex,
    this.weatherCode,
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
  final double? relativeHumidityPercent;
  final double? apparentTemperatureC;
  final double? pressureHpa;
  final double? uvIndex;
  final int? weatherCode;
  final bool isDaylight;
  final bool isInsideRestrictedArea;
  final bool isNearRestrictedArea;

  String? get windDirectionCardinal {
    if (windDirectionDegrees == null) return null;
    final normalized = (windDirectionDegrees! % 360 + 360) % 360;
    final index = ((normalized + 11.25) / 22.5).floor() % 16;
    const directions = [
      'N',
      'NNE',
      'NE',
      'ENE',
      'E',
      'ESE',
      'SE',
      'SSE',
      'S',
      'SSO',
      'SO',
      'OSO',
      'O',
      'ONO',
      'NO',
      'NNO',
    ];
    return directions[index];
  }

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
    double? relativeHumidityPercent,
    double? apparentTemperatureC,
    double? pressureHpa,
    double? uvIndex,
    int? weatherCode,
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
      relativeHumidityPercent:
          relativeHumidityPercent ?? this.relativeHumidityPercent,
      apparentTemperatureC: apparentTemperatureC ?? this.apparentTemperatureC,
      pressureHpa: pressureHpa ?? this.pressureHpa,
      uvIndex: uvIndex ?? this.uvIndex,
      weatherCode: weatherCode ?? this.weatherCode,
      isDaylight: isDaylight ?? this.isDaylight,
      isInsideRestrictedArea:
          isInsideRestrictedArea ?? this.isInsideRestrictedArea,
      isNearRestrictedArea: isNearRestrictedArea ?? this.isNearRestrictedArea,
    );
  }
}

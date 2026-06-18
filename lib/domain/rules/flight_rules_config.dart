// lib/domain/rules/flight_rules_config.dart
class FlightRulesConfig {
  const FlightRulesConfig({
    this.windWarningKmh = 22,
    this.windBlockedKmh = 28,
    this.gustWarningKmh = 32,
    this.gustBlockedKmh = 40,
    this.gustSpreadWarningKmh = 10,
    this.gustSpreadBlockedKmh = 18,
    this.precipProbabilityWarningPercent = 25,
    this.precipProbabilityBlockedPercent = 55,
    this.precipIntensityWarningMmPerHour = 0,
    this.precipIntensityBlockedMmPerHour = 0.5,
    this.visibilityWarningKm = 4,
    this.visibilityBlockedKm = 2.8,
    this.targetAltitudeMeters = 120,
    this.cloudBaseWarningMarginMeters = 120,
    this.cloudBaseBlockedMarginMeters = 60,
    this.temperatureMinWarningC = 0,
    this.temperatureMinBlockedC = -5,
    this.temperatureMaxWarningC = 35,
    this.temperatureMaxBlockedC = 40,
    this.kpWarning = 4,
    this.kpBlocked = 6,
    this.allowNightFlight = false,
  });

  const FlightRulesConfig.defaults() : this();

  final double windWarningKmh;
  final double windBlockedKmh;
  final double gustWarningKmh;
  final double gustBlockedKmh;
  final double gustSpreadWarningKmh;
  final double gustSpreadBlockedKmh;
  final double precipProbabilityWarningPercent;
  final double precipProbabilityBlockedPercent;
  final double precipIntensityWarningMmPerHour;
  final double precipIntensityBlockedMmPerHour;
  final double visibilityWarningKm;
  final double visibilityBlockedKm;
  final int targetAltitudeMeters;
  final int cloudBaseWarningMarginMeters;
  final int cloudBaseBlockedMarginMeters;
  final double temperatureMinWarningC;
  final double temperatureMinBlockedC;
  final double temperatureMaxWarningC;
  final double temperatureMaxBlockedC;
  final double kpWarning;
  final double kpBlocked;
  final bool allowNightFlight;

  FlightRulesConfig copyWith({
    double? windWarningKmh,
    double? windBlockedKmh,
    double? gustWarningKmh,
    double? gustBlockedKmh,
    double? gustSpreadWarningKmh,
    double? gustSpreadBlockedKmh,
    double? precipProbabilityWarningPercent,
    double? precipProbabilityBlockedPercent,
    double? precipIntensityWarningMmPerHour,
    double? precipIntensityBlockedMmPerHour,
    double? visibilityWarningKm,
    double? visibilityBlockedKm,
    int? targetAltitudeMeters,
    int? cloudBaseWarningMarginMeters,
    int? cloudBaseBlockedMarginMeters,
    double? temperatureMinWarningC,
    double? temperatureMinBlockedC,
    double? temperatureMaxWarningC,
    double? temperatureMaxBlockedC,
    double? kpWarning,
    double? kpBlocked,
    bool? allowNightFlight,
  }) {
    return FlightRulesConfig(
      windWarningKmh: windWarningKmh ?? this.windWarningKmh,
      windBlockedKmh: windBlockedKmh ?? this.windBlockedKmh,
      gustWarningKmh: gustWarningKmh ?? this.gustWarningKmh,
      gustBlockedKmh: gustBlockedKmh ?? this.gustBlockedKmh,
      gustSpreadWarningKmh: gustSpreadWarningKmh ?? this.gustSpreadWarningKmh,
      gustSpreadBlockedKmh: gustSpreadBlockedKmh ?? this.gustSpreadBlockedKmh,
      precipProbabilityWarningPercent:
          precipProbabilityWarningPercent ?? this.precipProbabilityWarningPercent,
      precipProbabilityBlockedPercent:
          precipProbabilityBlockedPercent ?? this.precipProbabilityBlockedPercent,
      precipIntensityWarningMmPerHour:
          precipIntensityWarningMmPerHour ?? this.precipIntensityWarningMmPerHour,
      precipIntensityBlockedMmPerHour:
          precipIntensityBlockedMmPerHour ?? this.precipIntensityBlockedMmPerHour,
      visibilityWarningKm: visibilityWarningKm ?? this.visibilityWarningKm,
      visibilityBlockedKm: visibilityBlockedKm ?? this.visibilityBlockedKm,
      targetAltitudeMeters: targetAltitudeMeters ?? this.targetAltitudeMeters,
      cloudBaseWarningMarginMeters:
          cloudBaseWarningMarginMeters ?? this.cloudBaseWarningMarginMeters,
      cloudBaseBlockedMarginMeters:
          cloudBaseBlockedMarginMeters ?? this.cloudBaseBlockedMarginMeters,
      temperatureMinWarningC: temperatureMinWarningC ?? this.temperatureMinWarningC,
      temperatureMinBlockedC: temperatureMinBlockedC ?? this.temperatureMinBlockedC,
      temperatureMaxWarningC: temperatureMaxWarningC ?? this.temperatureMaxWarningC,
      temperatureMaxBlockedC: temperatureMaxBlockedC ?? this.temperatureMaxBlockedC,
      kpWarning: kpWarning ?? this.kpWarning,
      kpBlocked: kpBlocked ?? this.kpBlocked,
      allowNightFlight: allowNightFlight ?? this.allowNightFlight,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'windWarningKmh': windWarningKmh,
      'windBlockedKmh': windBlockedKmh,
      'gustWarningKmh': gustWarningKmh,
      'gustBlockedKmh': gustBlockedKmh,
      'gustSpreadWarningKmh': gustSpreadWarningKmh,
      'gustSpreadBlockedKmh': gustSpreadBlockedKmh,
      'precipProbabilityWarningPercent': precipProbabilityWarningPercent,
      'precipProbabilityBlockedPercent': precipProbabilityBlockedPercent,
      'precipIntensityWarningMmPerHour': precipIntensityWarningMmPerHour,
      'precipIntensityBlockedMmPerHour': precipIntensityBlockedMmPerHour,
      'visibilityWarningKm': visibilityWarningKm,
      'visibilityBlockedKm': visibilityBlockedKm,
      'targetAltitudeMeters': targetAltitudeMeters,
      'cloudBaseWarningMarginMeters': cloudBaseWarningMarginMeters,
      'cloudBaseBlockedMarginMeters': cloudBaseBlockedMarginMeters,
      'temperatureMinWarningC': temperatureMinWarningC,
      'temperatureMinBlockedC': temperatureMinBlockedC,
      'temperatureMaxWarningC': temperatureMaxWarningC,
      'temperatureMaxBlockedC': temperatureMaxBlockedC,
      'kpWarning': kpWarning,
      'kpBlocked': kpBlocked,
      'allowNightFlight': allowNightFlight,
    };
  }

  static FlightRulesConfig fromJson(Map<String, dynamic> json) {
    const d = FlightRulesConfig.defaults();
    double dbl(String k, double fallback) =>
        (json[k] as num?)?.toDouble() ?? fallback;
    int integer(String k, int fallback) =>
        (json[k] as num?)?.toInt() ?? fallback;
    return FlightRulesConfig(
      windWarningKmh: dbl('windWarningKmh', d.windWarningKmh),
      windBlockedKmh: dbl('windBlockedKmh', d.windBlockedKmh),
      gustWarningKmh: dbl('gustWarningKmh', d.gustWarningKmh),
      gustBlockedKmh: dbl('gustBlockedKmh', d.gustBlockedKmh),
      gustSpreadWarningKmh: dbl('gustSpreadWarningKmh', d.gustSpreadWarningKmh),
      gustSpreadBlockedKmh: dbl('gustSpreadBlockedKmh', d.gustSpreadBlockedKmh),
      precipProbabilityWarningPercent:
          dbl('precipProbabilityWarningPercent', d.precipProbabilityWarningPercent),
      precipProbabilityBlockedPercent:
          dbl('precipProbabilityBlockedPercent', d.precipProbabilityBlockedPercent),
      precipIntensityWarningMmPerHour:
          dbl('precipIntensityWarningMmPerHour', d.precipIntensityWarningMmPerHour),
      precipIntensityBlockedMmPerHour:
          dbl('precipIntensityBlockedMmPerHour', d.precipIntensityBlockedMmPerHour),
      visibilityWarningKm: dbl('visibilityWarningKm', d.visibilityWarningKm),
      visibilityBlockedKm: dbl('visibilityBlockedKm', d.visibilityBlockedKm),
      targetAltitudeMeters: integer('targetAltitudeMeters', d.targetAltitudeMeters),
      cloudBaseWarningMarginMeters:
          integer('cloudBaseWarningMarginMeters', d.cloudBaseWarningMarginMeters),
      cloudBaseBlockedMarginMeters:
          integer('cloudBaseBlockedMarginMeters', d.cloudBaseBlockedMarginMeters),
      temperatureMinWarningC: dbl('temperatureMinWarningC', d.temperatureMinWarningC),
      temperatureMinBlockedC: dbl('temperatureMinBlockedC', d.temperatureMinBlockedC),
      temperatureMaxWarningC: dbl('temperatureMaxWarningC', d.temperatureMaxWarningC),
      temperatureMaxBlockedC: dbl('temperatureMaxBlockedC', d.temperatureMaxBlockedC),
      kpWarning: dbl('kpWarning', d.kpWarning),
      kpBlocked: dbl('kpBlocked', d.kpBlocked),
      allowNightFlight: (json['allowNightFlight'] as bool?) ?? d.allowNightFlight,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FlightRulesConfig &&
      other.windWarningKmh == windWarningKmh &&
      other.windBlockedKmh == windBlockedKmh &&
      other.gustWarningKmh == gustWarningKmh &&
      other.gustBlockedKmh == gustBlockedKmh &&
      other.gustSpreadWarningKmh == gustSpreadWarningKmh &&
      other.gustSpreadBlockedKmh == gustSpreadBlockedKmh &&
      other.precipProbabilityWarningPercent == precipProbabilityWarningPercent &&
      other.precipProbabilityBlockedPercent == precipProbabilityBlockedPercent &&
      other.precipIntensityWarningMmPerHour == precipIntensityWarningMmPerHour &&
      other.precipIntensityBlockedMmPerHour == precipIntensityBlockedMmPerHour &&
      other.visibilityWarningKm == visibilityWarningKm &&
      other.visibilityBlockedKm == visibilityBlockedKm &&
      other.targetAltitudeMeters == targetAltitudeMeters &&
      other.cloudBaseWarningMarginMeters == cloudBaseWarningMarginMeters &&
      other.cloudBaseBlockedMarginMeters == cloudBaseBlockedMarginMeters &&
      other.temperatureMinWarningC == temperatureMinWarningC &&
      other.temperatureMinBlockedC == temperatureMinBlockedC &&
      other.temperatureMaxWarningC == temperatureMaxWarningC &&
      other.temperatureMaxBlockedC == temperatureMaxBlockedC &&
      other.kpWarning == kpWarning &&
      other.kpBlocked == kpBlocked &&
      other.allowNightFlight == allowNightFlight;

  @override
  int get hashCode => Object.hashAll([
        windWarningKmh, windBlockedKmh, gustWarningKmh, gustBlockedKmh,
        gustSpreadWarningKmh, gustSpreadBlockedKmh,
        precipProbabilityWarningPercent, precipProbabilityBlockedPercent,
        precipIntensityWarningMmPerHour, precipIntensityBlockedMmPerHour,
        visibilityWarningKm, visibilityBlockedKm, targetAltitudeMeters,
        cloudBaseWarningMarginMeters, cloudBaseBlockedMarginMeters,
        temperatureMinWarningC, temperatureMinBlockedC,
        temperatureMaxWarningC, temperatureMaxBlockedC,
        kpWarning, kpBlocked, allowNightFlight,
      ]);
}

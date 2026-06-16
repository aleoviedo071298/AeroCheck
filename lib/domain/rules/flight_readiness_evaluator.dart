import '../entities/drone_profile.dart';
import '../entities/flight_readiness_report.dart';
import '../entities/flight_rule_result.dart';
import '../entities/flight_window_recommendation.dart';
import '../entities/mission_profile.dart';
import '../entities/weather_snapshot.dart';
import 'flight_readiness_status.dart';
import 'rule_severity.dart';

class FlightReadinessEvaluator {
  const FlightReadinessEvaluator();

  FlightReadinessReport evaluate({
    required WeatherSnapshot weather,
    required DroneProfile droneProfile,
    required MissionProfile missionProfile,
    required FlightWindowRecommendation bestWindow,
  }) {
    final rules = <FlightRuleResult>[];
    final effectiveMaxWind =
        droneProfile.maxWindKmh * missionProfile.windModifier;
    final effectiveMaxGust =
        droneProfile.maxGustKmh * missionProfile.gustModifier;

    rules.add(_missingData(weather));

    if (weather.windKmh != null) {
      rules.add(
        _thresholdRule(
          code: 'WIND_SPEED',
          value: weather.windKmh!,
          threshold: effectiveMaxWind,
          okTitle: 'Viento dentro del limite',
          warningTitle: 'Viento cerca del limite',
          blockedTitle: 'Viento sobre el limite',
          unit: 'km/h',
        ),
      );
    }

    if (weather.gustKmh != null) {
      rules.add(
        _thresholdRule(
          code: 'WIND_GUST',
          value: weather.gustKmh!,
          threshold: effectiveMaxGust,
          okTitle: 'Rafagas dentro del limite',
          warningTitle: 'Rafagas cerca del limite',
          blockedTitle: 'Rafagas sobre el limite',
          unit: 'km/h',
        ),
      );
    }

    if (weather.windKmh != null && weather.gustKmh != null) {
      final spread = weather.gustKmh! - weather.windKmh!;
      rules.add(_gustSpread(spread));
    }

    if (weather.precipitationProbability != null) {
      rules.add(_precipitationProbability(weather.precipitationProbability!));
    }

    if (weather.precipitationMmPerHour != null) {
      rules.add(_precipitationIntensity(weather.precipitationMmPerHour!));
    }

    if (weather.visibilityKm != null) {
      rules.add(
        _visibility(weather.visibilityKm!, droneProfile.minVisibilityKm),
      );
    }

    if (weather.cloudBaseMeters != null) {
      rules.add(
        _cloudBase(
          weather.cloudBaseMeters!,
          droneProfile.preferredAltitudeMeters,
        ),
      );
    }

    if (weather.temperatureC != null) {
      rules.add(_temperature(weather.temperatureC!));
    }

    if (weather.kpIndex != null) {
      rules.add(_kpIndex(weather.kpIndex!));
    }

    rules.add(_daylight(weather.isDaylight));
    rules.add(_restrictedArea(weather));

    final status = _statusFor(rules);
    final score = _scoreFor(rules);

    return FlightReadinessReport(
      status: status,
      score: score,
      summary: _summaryFor(status, rules),
      rules: rules,
      weather: weather,
      droneProfile: droneProfile,
      missionProfile: missionProfile,
      bestWindow: bestWindow,
    );
  }

  FlightRuleResult _missingData(WeatherSnapshot weather) {
    final missing = <String>[];
    if (weather.locationLabel.trim().isEmpty) {
      missing.add('ubicacion');
    }
    if (weather.windKmh == null) {
      missing.add('viento');
    }
    if (weather.gustKmh == null) {
      missing.add('rafagas');
    }
    if (weather.precipitationProbability == null) {
      missing.add('probabilidad de lluvia');
    }
    if (weather.precipitationMmPerHour == null) {
      missing.add('intensidad de lluvia');
    }
    if (weather.visibilityKm == null) {
      missing.add('visibilidad');
    }

    if (missing.isEmpty) {
      return const FlightRuleResult(
        code: 'MISSING_DATA',
        severity: RuleSeverity.ok,
        title: 'Datos criticos disponibles',
        details: 'La decision usa viento, rafagas, lluvia y visibilidad.',
      );
    }

    return FlightRuleResult(
      code: 'MISSING_DATA',
      severity: RuleSeverity.blocked,
      title: 'Datos criticos incompletos',
      details: 'Faltan datos de ${missing.join(', ')}.',
    );
  }

  FlightRuleResult _thresholdRule({
    required String code,
    required double value,
    required double threshold,
    required String okTitle,
    required String warningTitle,
    required String blockedTitle,
    required String unit,
  }) {
    final warningThreshold = threshold * 0.8;
    final severity = value > threshold
        ? RuleSeverity.blocked
        : value > warningThreshold
        ? RuleSeverity.warning
        : RuleSeverity.ok;
    final title = switch (severity) {
      RuleSeverity.ok => okTitle,
      RuleSeverity.warning => warningTitle,
      RuleSeverity.blocked => blockedTitle,
    };

    return FlightRuleResult(
      code: code,
      severity: severity,
      title: title,
      details: '${_fmt(value)} $unit sobre limite de ${_fmt(threshold)} $unit.',
      measuredValue: value,
      threshold: threshold,
    );
  }

  FlightRuleResult _gustSpread(double spread) {
    final severity = spread > 18
        ? RuleSeverity.blocked
        : spread > 10
        ? RuleSeverity.warning
        : RuleSeverity.ok;

    return FlightRuleResult(
      code: 'GUST_SPREAD',
      severity: severity,
      title: switch (severity) {
        RuleSeverity.ok => 'Rafagas estables',
        RuleSeverity.warning => 'Variacion de rafagas relevante',
        RuleSeverity.blocked => 'Variacion de rafagas alta',
      },
      details: 'Diferencia entre viento y rafaga: ${_fmt(spread)} km/h.',
      measuredValue: spread,
      threshold: severity == RuleSeverity.blocked ? 18 : 10,
    );
  }

  FlightRuleResult _precipitationProbability(double probability) {
    final severity = probability >= 55
        ? RuleSeverity.blocked
        : probability >= 25
        ? RuleSeverity.warning
        : RuleSeverity.ok;

    return FlightRuleResult(
      code: 'PRECIP_PROBABILITY',
      severity: severity,
      title: switch (severity) {
        RuleSeverity.ok => 'Baja probabilidad de lluvia',
        RuleSeverity.warning => 'Lluvia posible',
        RuleSeverity.blocked => 'Lluvia probable',
      },
      details: 'Probabilidad de lluvia: ${_fmt(probability)}%.',
      measuredValue: probability,
      threshold: severity == RuleSeverity.blocked ? 55 : 25,
    );
  }

  FlightRuleResult _precipitationIntensity(double intensity) {
    final severity = intensity > 0.5
        ? RuleSeverity.blocked
        : intensity > 0
        ? RuleSeverity.warning
        : RuleSeverity.ok;

    return FlightRuleResult(
      code: 'PRECIP_INTENSITY',
      severity: severity,
      title: switch (severity) {
        RuleSeverity.ok => 'Sin lluvia activa',
        RuleSeverity.warning => 'Llovizna o lluvia leve',
        RuleSeverity.blocked => 'Lluvia activa',
      },
      details: 'Intensidad de lluvia: ${_fmt(intensity)} mm/h.',
      measuredValue: intensity,
      threshold: severity == RuleSeverity.blocked ? 0.5 : 0,
    );
  }

  FlightRuleResult _visibility(double visibility, double minimum) {
    final warningThreshold = minimum * 0.7;
    final severity = visibility < warningThreshold
        ? RuleSeverity.blocked
        : visibility < minimum
        ? RuleSeverity.warning
        : RuleSeverity.ok;

    return FlightRuleResult(
      code: 'VISIBILITY',
      severity: severity,
      title: switch (severity) {
        RuleSeverity.ok => 'Buena visibilidad',
        RuleSeverity.warning => 'Visibilidad reducida',
        RuleSeverity.blocked => 'Visibilidad insuficiente',
      },
      details:
          '${_fmt(visibility)} km disponibles; minimo ${_fmt(minimum)} km.',
      measuredValue: visibility,
      threshold: minimum,
    );
  }

  FlightRuleResult _cloudBase(double cloudBase, int targetAltitude) {
    final okThreshold = targetAltitude + 120;
    final blockedThreshold = targetAltitude + 60;
    final severity = cloudBase < blockedThreshold
        ? RuleSeverity.blocked
        : cloudBase < okThreshold
        ? RuleSeverity.warning
        : RuleSeverity.ok;

    return FlightRuleResult(
      code: 'CLOUD_BASE',
      severity: severity,
      title: switch (severity) {
        RuleSeverity.ok => 'Base de nubes suficiente',
        RuleSeverity.warning => 'Base de nubes cercana',
        RuleSeverity.blocked => 'Base de nubes baja',
      },
      details: 'Base ${_fmt(cloudBase)} m; altura objetivo $targetAltitude m.',
      measuredValue: cloudBase,
      threshold: okThreshold.toDouble(),
    );
  }

  FlightRuleResult _temperature(double temperature) {
    final severity = temperature < -5 || temperature > 40
        ? RuleSeverity.blocked
        : temperature < 0 || temperature > 35
        ? RuleSeverity.warning
        : RuleSeverity.ok;

    return FlightRuleResult(
      code: 'TEMPERATURE',
      severity: severity,
      title: switch (severity) {
        RuleSeverity.ok => 'Temperatura operativa',
        RuleSeverity.warning => 'Temperatura exigente',
        RuleSeverity.blocked => 'Temperatura extrema',
      },
      details: 'Temperatura: ${_fmt(temperature)} C.',
      measuredValue: temperature,
    );
  }

  FlightRuleResult _kpIndex(double kp) {
    final severity = kp >= 6
        ? RuleSeverity.blocked
        : kp >= 4
        ? RuleSeverity.warning
        : RuleSeverity.ok;

    return FlightRuleResult(
      code: 'KP_INDEX',
      severity: severity,
      title: switch (severity) {
        RuleSeverity.ok => 'Kp normal',
        RuleSeverity.warning => 'Actividad geomagnetica elevada',
        RuleSeverity.blocked => 'Actividad geomagnetica alta',
      },
      details: 'Indice Kp: ${_fmt(kp)}.',
      measuredValue: kp,
      threshold: severity == RuleSeverity.blocked ? 6 : 4,
    );
  }

  FlightRuleResult _daylight(bool isDaylight) {
    return FlightRuleResult(
      code: 'DAYLIGHT',
      severity: isDaylight ? RuleSeverity.ok : RuleSeverity.blocked,
      title: isDaylight
          ? 'Luz diurna disponible'
          : 'Vuelo nocturno no habilitado',
      details: isDaylight
          ? 'La ventana esta dentro de horario diurno.'
          : 'Activa vuelo nocturno solo si corresponde y tenes permiso.',
    );
  }

  FlightRuleResult _restrictedArea(WeatherSnapshot weather) {
    final severity = weather.isInsideRestrictedArea
        ? RuleSeverity.blocked
        : weather.isNearRestrictedArea
        ? RuleSeverity.warning
        : RuleSeverity.ok;

    return FlightRuleResult(
      code: 'RESTRICTED_AREA',
      severity: severity,
      title: switch (severity) {
        RuleSeverity.ok => 'Sin restriccion cercana conocida',
        RuleSeverity.warning => 'Zona sensible cercana',
        RuleSeverity.blocked => 'Dentro de zona restringida',
      },
      details: switch (severity) {
        RuleSeverity.ok => 'No hay restricciones mock alrededor del punto.',
        RuleSeverity.warning =>
          'Revisa normativa y permisos antes de despegar.',
        RuleSeverity.blocked =>
          'No planifiques vuelo sin autorizacion oficial.',
      },
    );
  }

  FlightReadinessStatus _statusFor(List<FlightRuleResult> rules) {
    if (rules.any((rule) => rule.severity == RuleSeverity.blocked)) {
      return FlightReadinessStatus.notReady;
    }
    if (rules.any((rule) => rule.severity == RuleSeverity.warning)) {
      return FlightReadinessStatus.caution;
    }
    return FlightReadinessStatus.ready;
  }

  int _scoreFor(List<FlightRuleResult> rules) {
    final warningCount = rules
        .where((rule) => rule.severity == RuleSeverity.warning)
        .length;
    final blockedCount = rules
        .where((rule) => rule.severity == RuleSeverity.blocked)
        .length;
    return (100 - (warningCount * 12) - (blockedCount * 35)).clamp(0, 100);
  }

  String _summaryFor(
    FlightReadinessStatus status,
    List<FlightRuleResult> rules,
  ) {
    final activeRules = rules
        .where((rule) => rule.severity != RuleSeverity.ok)
        .toList();
    if (activeRules.isEmpty) {
      return 'Condiciones principales dentro de tus limites.';
    }
    final primary = activeRules.first.title.toLowerCase();
    return switch (status) {
      FlightReadinessStatus.ready =>
        'Condiciones principales dentro de tus limites.',
      FlightReadinessStatus.caution => 'Precaucion por $primary.',
      FlightReadinessStatus.notReady => 'No apto por $primary.',
    };
  }

  String _fmt(num value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}

import '../entities/flight_readiness_report.dart';
import '../entities/flight_rule_result.dart';
import '../entities/flight_window_recommendation.dart';
import '../entities/weather_snapshot.dart';
import 'flight_readiness_status.dart';
import 'flight_rules_config.dart';
import 'rule_severity.dart';

class FlightReadinessEvaluator {
  const FlightReadinessEvaluator();

  FlightReadinessReport evaluate({
    required WeatherSnapshot weather,
    required FlightRulesConfig config,
    required FlightWindowRecommendation bestWindow,
  }) {
    final rules = <FlightRuleResult>[];

    rules.add(_missingData(weather));

    if (weather.windKmh != null) {
      rules.add(_thresholdRule(
        code: 'WIND_SPEED',
        value: weather.windKmh!,
        warning: config.windWarningKmh,
        blocked: config.windBlockedKmh,
        okTitle: 'Viento dentro del limite',
        warningTitle: 'Viento cerca del limite',
        blockedTitle: 'Viento sobre el limite',
        unit: 'km/h',
      ));
    }
    if (weather.gustKmh != null) {
      rules.add(_thresholdRule(
        code: 'WIND_GUST',
        value: weather.gustKmh!,
        warning: config.gustWarningKmh,
        blocked: config.gustBlockedKmh,
        okTitle: 'Rafagas dentro del limite',
        warningTitle: 'Rafagas cerca del limite',
        blockedTitle: 'Rafagas sobre el limite',
        unit: 'km/h',
      ));
    }
    if (weather.windKmh != null && weather.gustKmh != null) {
      rules.add(_gustSpread(weather.gustKmh! - weather.windKmh!, config));
    }
    if (weather.precipitationProbability != null) {
      rules.add(_precipitationProbability(weather.precipitationProbability!, config));
    }
    if (weather.precipitationMmPerHour != null) {
      rules.add(_precipitationIntensity(weather.precipitationMmPerHour!, config));
    }
    if (weather.visibilityKm != null) {
      rules.add(_visibility(weather.visibilityKm!, config));
    }
    if (weather.cloudBaseMeters != null) {
      rules.add(_cloudBase(weather.cloudBaseMeters!, config));
    }
    if (weather.temperatureC != null) {
      rules.add(_temperature(weather.temperatureC!, config));
    }
    if (weather.kpIndex != null) {
      rules.add(_kpIndex(weather.kpIndex!, config));
    }

    rules.add(_daylight(weather.isDaylight, config));
    rules.add(_restrictedArea(weather));

    final status = _statusFor(rules);
    final score = _scoreFor(rules);

    return FlightReadinessReport(
      status: status,
      score: score,
      summary: _summaryFor(status, rules),
      rules: rules,
      weather: weather,
      config: config,
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
    required double warning,
    required double blocked,
    required String okTitle,
    required String warningTitle,
    required String blockedTitle,
    required String unit,
  }) {
    final severity = value > blocked
        ? RuleSeverity.blocked
        : value > warning
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
      details: '${_fmt(value)} $unit sobre limite de ${_fmt(blocked)} $unit.',
      measuredValue: value,
      threshold: blocked,
    );
  }

  FlightRuleResult _gustSpread(double spread, FlightRulesConfig config) {
    final severity = spread > config.gustSpreadBlockedKmh
        ? RuleSeverity.blocked
        : spread > config.gustSpreadWarningKmh
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
      threshold: config.gustSpreadBlockedKmh,
    );
  }

  FlightRuleResult _precipitationProbability(double probability, FlightRulesConfig config) {
    final severity = probability >= config.precipProbabilityBlockedPercent
        ? RuleSeverity.blocked
        : probability >= config.precipProbabilityWarningPercent
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
      threshold: config.precipProbabilityBlockedPercent,
    );
  }

  FlightRuleResult _precipitationIntensity(double intensity, FlightRulesConfig config) {
    final severity = intensity > config.precipIntensityBlockedMmPerHour
        ? RuleSeverity.blocked
        : intensity > config.precipIntensityWarningMmPerHour
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
      threshold: config.precipIntensityBlockedMmPerHour,
    );
  }

  FlightRuleResult _visibility(double visibility, FlightRulesConfig config) {
    final severity = visibility < config.visibilityBlockedKm
        ? RuleSeverity.blocked
        : visibility < config.visibilityWarningKm
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
          '${_fmt(visibility)} km disponibles; minimo ${_fmt(config.visibilityWarningKm)} km.',
      measuredValue: visibility,
      threshold: config.visibilityWarningKm,
    );
  }

  FlightRuleResult _cloudBase(double cloudBase, FlightRulesConfig config) {
    final okThreshold = config.targetAltitudeMeters + config.cloudBaseWarningMarginMeters;
    final blockedThreshold = config.targetAltitudeMeters + config.cloudBaseBlockedMarginMeters;
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
      details:
          'Base ${_fmt(cloudBase)} m; altura objetivo ${config.targetAltitudeMeters} m.',
      measuredValue: cloudBase,
      threshold: okThreshold.toDouble(),
    );
  }

  FlightRuleResult _temperature(double temperature, FlightRulesConfig config) {
    final severity = temperature < config.temperatureMinBlockedC ||
            temperature > config.temperatureMaxBlockedC
        ? RuleSeverity.blocked
        : temperature < config.temperatureMinWarningC ||
                temperature > config.temperatureMaxWarningC
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

  FlightRuleResult _kpIndex(double kp, FlightRulesConfig config) {
    final severity = kp >= config.kpBlocked
        ? RuleSeverity.blocked
        : kp >= config.kpWarning
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
      threshold: config.kpBlocked,
    );
  }

  FlightRuleResult _daylight(bool isDaylight, FlightRulesConfig config) {
    final ok = isDaylight || config.allowNightFlight;
    return FlightRuleResult(
      code: 'DAYLIGHT',
      severity: ok ? RuleSeverity.ok : RuleSeverity.blocked,
      title: isDaylight
          ? 'Luz diurna disponible'
          : ok
              ? 'Vuelo nocturno habilitado'
              : 'Vuelo nocturno no habilitado',
      details: isDaylight
          ? 'La ventana esta dentro de horario diurno.'
          : ok
              ? 'Activaste vuelo nocturno en tus reglas. Verifica permisos.'
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

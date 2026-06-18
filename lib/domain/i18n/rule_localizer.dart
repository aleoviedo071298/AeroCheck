import '../entities/flight_rule_result.dart';
import '../entities/flight_readiness_report.dart';
import '../rules/rule_severity.dart';
import '../rules/flight_readiness_status.dart';
import '../units/unit_preferences.dart';
import '../units/unit_formatters.dart';
import '../../data/mock/mock_flight_data.dart'; // For ForecastReason
import 'app_strings.dart';
import 'language.dart';

class RuleLocalizer {
  static String getLocalizedTitle(
    String code,
    RuleSeverity severity,
    Language lang,
  ) {
    if (lang == Language.es) {
      return switch (code) {
        'MISSING_DATA' =>
          severity == RuleSeverity.ok
              ? 'Datos críticos disponibles'
              : 'Datos críticos incompletos',
        'WIND_SPEED' =>
          severity == RuleSeverity.ok
              ? 'Viento dentro del límite'
              : severity == RuleSeverity.warning
              ? 'Viento cerca del límite'
              : 'Viento sobre el límite',
        'WIND_GUST' =>
          severity == RuleSeverity.ok
              ? 'Ráfagas dentro del límite'
              : severity == RuleSeverity.warning
              ? 'Ráfagas cerca del límite'
              : 'Ráfagas sobre el límite',
        'GUST_SPREAD' =>
          severity == RuleSeverity.ok
              ? 'Ráfagas estables'
              : severity == RuleSeverity.warning
              ? 'Variación de ráfagas relevante'
              : 'Variación de ráfagas alta',
        'PRECIP_PROBABILITY' =>
          severity == RuleSeverity.ok
              ? 'Baja probabilidad de lluvia'
              : severity == RuleSeverity.warning
              ? 'Lluvia posible'
              : 'Lluvia probable',
        'PRECIP_INTENSITY' =>
          severity == RuleSeverity.ok
              ? 'Sin lluvia activa'
              : severity == RuleSeverity.warning
              ? 'Llovizna o lluvia leve'
              : 'Lluvia activa',
        'VISIBILITY' =>
          severity == RuleSeverity.ok
              ? 'Buena visibilidad'
              : severity == RuleSeverity.warning
              ? 'Visibilidad reducida'
              : 'Visibilidad insuficiente',
        'CLOUD_BASE' =>
          severity == RuleSeverity.ok
              ? 'Base de nubes suficiente'
              : severity == RuleSeverity.warning
              ? 'Base de nubes cercana'
              : 'Base de nubes baja',
        'TEMPERATURE' =>
          severity == RuleSeverity.ok
              ? 'Temperatura operativa'
              : severity == RuleSeverity.warning
              ? 'Temperatura exigente'
              : 'Temperatura extrema',
        'KP_INDEX' =>
          severity == RuleSeverity.ok
              ? 'Kp normal'
              : severity == RuleSeverity.warning
              ? 'Actividad geomagnética elevada'
              : 'Actividad geomagnética alta',
        'DAYLIGHT' =>
          severity == RuleSeverity.ok
              ? 'Luz diurna disponible'
              : 'Vuelo nocturno no habilitado',
        'RESTRICTED_AREA' =>
          severity == RuleSeverity.ok
              ? 'Sin restricción cercana conocida'
              : severity == RuleSeverity.warning
              ? 'Zona sensible cercana'
              : 'Dentro de zona restringida',
        _ => code,
      };
    } else {
      // English
      return switch (code) {
        'MISSING_DATA' =>
          severity == RuleSeverity.ok
              ? 'Critical data available'
              : 'Incomplete critical data',
        'WIND_SPEED' =>
          severity == RuleSeverity.ok
              ? 'Wind within limit'
              : severity == RuleSeverity.warning
              ? 'Wind near limit'
              : 'Wind over limit',
        'WIND_GUST' =>
          severity == RuleSeverity.ok
              ? 'Gusts within limit'
              : severity == RuleSeverity.warning
              ? 'Gusts near limit'
              : 'Gusts over limit',
        'GUST_SPREAD' =>
          severity == RuleSeverity.ok
              ? 'Stable gusts'
              : severity == RuleSeverity.warning
              ? 'Relevant gust variation'
              : 'High gust variation',
        'PRECIP_PROBABILITY' =>
          severity == RuleSeverity.ok
              ? 'Low rain probability'
              : severity == RuleSeverity.warning
              ? 'Rain possible'
              : 'Rain likely',
        'PRECIP_INTENSITY' =>
          severity == RuleSeverity.ok
              ? 'No active rain'
              : severity == RuleSeverity.warning
              ? 'Drizzle or light rain'
              : 'Active rain',
        'VISIBILITY' =>
          severity == RuleSeverity.ok
              ? 'Good visibility'
              : severity == RuleSeverity.warning
              ? 'Reduced visibility'
              : 'Insufficient visibility',
        'CLOUD_BASE' =>
          severity == RuleSeverity.ok
              ? 'Sufficient cloud base'
              : severity == RuleSeverity.warning
              ? 'Close cloud base'
              : 'Low cloud base',
        'TEMPERATURE' =>
          severity == RuleSeverity.ok
              ? 'Operating temperature'
              : severity == RuleSeverity.warning
              ? 'Demanding temperature'
              : 'Extreme temperature',
        'KP_INDEX' =>
          severity == RuleSeverity.ok
              ? 'Normal Kp'
              : severity == RuleSeverity.warning
              ? 'Elevated geomagnetic activity'
              : 'High geomagnetic activity',
        'DAYLIGHT' =>
          severity == RuleSeverity.ok
              ? 'Daylight available'
              : 'Night flight not enabled',
        'RESTRICTED_AREA' =>
          severity == RuleSeverity.ok
              ? 'No known nearby restriction'
              : severity == RuleSeverity.warning
              ? 'Sensitive zone nearby'
              : 'Within restricted zone',
        _ => code,
      };
    }
  }

  static String getLocalizedDetails(
    String code,
    RuleSeverity severity,
    double? measuredValue,
    double? threshold,
    Language lang,
    UnitPreferences units, {
    String fallback = '',
  }) {
    if (measuredValue == null && threshold == null) {
      if (lang == Language.es) return fallback;
      return _translateStaticDetails(code, severity, fallback);
    }

    if (lang == Language.es) {
      return switch (code) {
        'MISSING_DATA' =>
          severity == RuleSeverity.ok
              ? 'La decisión usa viento, ráfagas, lluvia y visibilidad.'
              : _translateFields(fallback, lang),
        'WIND_SPEED' || 'WIND_GUST' =>
          '${UnitFormatters.formatSpeed(measuredValue, units)} sobre límite de ${UnitFormatters.formatSpeed(threshold, units)}.',
        'GUST_SPREAD' =>
          'Diferencia entre viento y ráfaga: ${UnitFormatters.formatSpeed(measuredValue, units)}.',
        'PRECIP_PROBABILITY' =>
          'Probabilidad de lluvia: ${UnitFormatters.formatPercentage(measuredValue)}.',
        'PRECIP_INTENSITY' =>
          'Intensidad de lluvia: ${UnitFormatters.formatPrecipitation(measuredValue, units)}.',
        'VISIBILITY' =>
          '${UnitFormatters.formatDistance(measuredValue, units)} disponibles; mínimo ${UnitFormatters.formatDistance(threshold, units)}.',
        'CLOUD_BASE' => _formatCloudBaseDetails(
          measuredValue,
          threshold,
          lang,
          units,
        ),
        'TEMPERATURE' =>
          'Temperatura: ${UnitFormatters.formatTemperature(measuredValue, units)}.',
        'KP_INDEX' => 'Índice Kp: ${measuredValue?.toStringAsFixed(0) ?? "—"}.',
        'DAYLIGHT' =>
          severity == RuleSeverity.ok
              ? 'La ventana está dentro de horario diurno.'
              : 'Activa vuelo nocturno solo si corresponde y tenes permiso.',
        'RESTRICTED_AREA' =>
          severity == RuleSeverity.ok
              ? 'No hay restricciones mock alrededor del punto.'
              : severity == RuleSeverity.warning
              ? 'Revisa normativa y permisos antes de despegar.'
              : 'No planifiques vuelo sin autorización oficial.',
        _ => fallback,
      };
    } else {
      // English
      return switch (code) {
        'MISSING_DATA' =>
          severity == RuleSeverity.ok
              ? 'The decision uses wind, gusts, rain and visibility.'
              : _translateFields(fallback, lang),
        'WIND_SPEED' || 'WIND_GUST' =>
          '${UnitFormatters.formatSpeed(measuredValue, units)} over limit of ${UnitFormatters.formatSpeed(threshold, units)}.',
        'GUST_SPREAD' =>
          'Difference between wind and gust: ${UnitFormatters.formatSpeed(measuredValue, units)}.',
        'PRECIP_PROBABILITY' =>
          'Rain probability: ${UnitFormatters.formatPercentage(measuredValue)}.',
        'PRECIP_INTENSITY' =>
          'Rain intensity: ${UnitFormatters.formatPrecipitation(measuredValue, units)}.',
        'VISIBILITY' =>
          '${UnitFormatters.formatDistance(measuredValue, units)} available; minimum ${UnitFormatters.formatDistance(threshold, units)}.',
        'CLOUD_BASE' => _formatCloudBaseDetails(
          measuredValue,
          threshold,
          lang,
          units,
        ),
        'TEMPERATURE' =>
          'Temperature: ${UnitFormatters.formatTemperature(measuredValue, units)}.',
        'KP_INDEX' => 'Kp index: ${measuredValue?.toStringAsFixed(0) ?? "—"}.',
        'DAYLIGHT' =>
          severity == RuleSeverity.ok
              ? 'The window is within daylight hours.'
              : 'Enable night flight only if applicable and you have permission.',
        'RESTRICTED_AREA' =>
          severity == RuleSeverity.ok
              ? 'No mock restrictions around the point.'
              : severity == RuleSeverity.warning
              ? 'Review regulations and permissions before takeoff.'
              : 'Do not plan flight without official authorization.',
        _ => _translateStaticDetails(code, severity, fallback),
      };
    }
  }

  static String _translateStaticDetails(
    String code,
    RuleSeverity severity,
    String fallback,
  ) {
    return switch (code) {
      'DAYLIGHT' =>
        severity == RuleSeverity.ok
            ? 'The window is within daylight hours.'
            : 'Enable night flight only if applicable and you have permission.',
      'RESTRICTED_AREA' =>
        severity == RuleSeverity.ok
            ? 'No mock restrictions around the point.'
            : severity == RuleSeverity.warning
            ? 'Review regulations and permissions before takeoff.'
            : 'Do not plan flight without official authorization.',
      _ => fallback,
    };
  }

  static String _translateFields(String original, Language lang) {
    if (lang == Language.es) return original;
    return original
        .replaceAll('Faltan datos de', 'Missing data for')
        .replaceAll('ubicacion', 'location')
        .replaceAll('viento', 'wind')
        .replaceAll('rafagas', 'gusts')
        .replaceAll('probabilidad de lluvia', 'rain probability')
        .replaceAll('intensidad de lluvia', 'rain intensity')
        .replaceAll('visibilidad', 'visibility')
        .replaceAll('y', 'and');
  }

  static String _formatCloudBaseDetails(
    double? cloudBaseM,
    double? okThresholdM,
    Language lang,
    UnitPreferences units,
  ) {
    final targetM = okThresholdM != null ? okThresholdM - 120.0 : 120.0;
    final baseStr = UnitFormatters.formatAltitude(cloudBaseM, units);
    final targetStr = UnitFormatters.formatAltitude(targetM, units);

    if (lang == Language.es) {
      return 'Base $baseStr; altura objetivo $targetStr.';
    } else {
      return 'Base $baseStr; target altitude $targetStr.';
    }
  }

  static String getLocalizedSummary(
    FlightReadinessReport report,
    Language lang,
  ) {
    final activeRules = report.rules
        .where((rule) => rule.severity != RuleSeverity.ok)
        .toList();
    if (activeRules.isEmpty) {
      return AppStrings.get('condiciones_dentro_limites', language: lang);
    }

    final primaryRule = activeRules.first;
    final primaryTitle = getLocalizedTitle(
      primaryRule.code,
      primaryRule.severity,
      lang,
    ).toLowerCase();

    return switch (report.status) {
      FlightReadinessStatus.ready => AppStrings.get(
        'condiciones_dentro_limites',
        language: lang,
      ),
      FlightReadinessStatus.caution =>
        lang == Language.es
            ? 'Precaución por $primaryTitle.'
            : 'Caution due to $primaryTitle.',
      FlightReadinessStatus.notReady =>
        lang == Language.es
            ? 'No apto por $primaryTitle.'
            : 'Not suitable due to $primaryTitle.',
    };
  }
}

extension LocalizedRuleResult on FlightRuleResult {
  String localizedTitle(Language language) {
    return RuleLocalizer.getLocalizedTitle(code, severity, language);
  }

  String localizedDetails(Language language, UnitPreferences units) {
    return RuleLocalizer.getLocalizedDetails(
      code,
      severity,
      measuredValue,
      threshold,
      language,
      units,
      fallback: details,
    );
  }
}

extension LocalizedForecastReason on ForecastReason {
  String localizedTitle(Language language) {
    final c = code;
    if (c == null) return title;
    return RuleLocalizer.getLocalizedTitle(c, severity, language);
  }

  String localizedDetails(Language language, UnitPreferences units) {
    final c = code;
    if (c == null) {
      if (title == 'Condiciones principales dentro de tus limites.' ||
          title == 'Condiciones principales dentro de tus límites.') {
        return AppStrings.get('sin_motivos_activos', language: language);
      }
      return details;
    }
    return RuleLocalizer.getLocalizedDetails(
      c,
      severity,
      measuredValue,
      threshold,
      language,
      units,
      fallback: details,
    );
  }
}

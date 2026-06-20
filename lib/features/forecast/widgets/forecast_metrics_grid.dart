import 'package:flutter/material.dart';

import '../../../data/mock/mock_flight_data.dart';
import '../../../domain/i18n/app_strings.dart';
import '../../../domain/i18n/language.dart';
import '../../../domain/units/unit_formatters.dart';
import '../../../domain/units/unit_preferences.dart';
import '../../shared/weather_condition.dart';
import '../../shared/widgets/metric_card.dart';

class ForecastMetricsGrid extends StatelessWidget {
  const ForecastMetricsGrid({
    super.key,
    required this.row,
    required this.units,
    required this.language,
  });

  final ForecastRow row;
  final UnitPreferences units;
  final Language language;

  String _t(String k) => AppStrings.get(k, language: language);
  String _none() => AppStrings.get('sin_dato', language: language);

  String _fmt(num? v) {
    if (v == null) return _none();
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  String _cardinal(double? deg) {
    if (deg == null) return '';
    const dirs = [
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
    final n = (deg % 360 + 360) % 360;
    return dirs[((n + 11.25) / 22.5).floor() % 16];
  }

  @override
  Widget build(BuildContext context) {
    final condition = weatherConditionFor(row.weatherCode);
    final gustDelta = row.gustKmh - row.windKmh;
    final sensation =
        row.apparentTemperatureC ??
        (row.temperatureC == null ? null : row.temperatureC! - 2.0);

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.1,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      children: [
        MetricCard(
          label: _t('viento').toUpperCase(),
          value: UnitFormatters.formatSpeed(row.windKmh, units, decimals: 0),
          subValue:
              '↗ ${_cardinal(row.windDirectionDegrees)} ${_fmt(row.windDirectionDegrees)}°',
          icon: Icons.air_rounded,
          accentColor: const Color(0xFF0EA5E9),
        ),
        MetricCard(
          label: _t('rafagas').toUpperCase(),
          value: UnitFormatters.formatSpeed(row.gustKmh, units, decimals: 0),
          subValue: gustDelta > 0
              ? 'Δ ${UnitFormatters.formatSpeed(gustDelta, units, decimals: 0)}'
              : _t('sin_rafagas'),
          icon: Icons.wind_power_rounded,
          accentColor: const Color(0xFFD97706),
        ),
        MetricCard(
          label: _t('precip').toUpperCase(),
          value: '${_fmt(row.rainPercent)}%',
          subValue: (row.precipitationMmPerHour ?? 0) > 0
              ? '${_fmt(row.precipitationMmPerHour)} mm/h'
              : _t('sin_lluvia'),
          icon: Icons.water_drop_rounded,
          accentColor: const Color(0xFF06B6D4),
        ),
        MetricCard(
          label: _t('visibilidad').toUpperCase(),
          value: UnitFormatters.formatDistance(
            row.visibilityKm,
            units,
            decimals: 0,
          ),
          subValue: '',
          icon: Icons.visibility_rounded,
          accentColor: const Color(0xFF10B981),
        ),
        MetricCard(
          label: _t('nubosidad').toUpperCase(),
          value: row.cloudCoverPercent == null
              ? _none()
              : '${(row.cloudCoverPercent! / 12.5).round()}/8 (${_fmt(row.cloudCoverPercent)}%)',
          subValue: '',
          icon: Icons.cloud_rounded,
          accentColor: const Color(0xFF14B8A6),
        ),
        MetricCard(
          label: _t('condicion').toUpperCase(),
          value: _t(condition.labelKey),
          subValue: '',
          icon: condition.icon,
          accentColor: const Color(0xFFF59E0B),
        ),
        MetricCard(
          label: _t('temp').toUpperCase(),
          value: UnitFormatters.formatTemperature(
            row.temperatureC,
            units,
            decimals: 0,
          ),
          subValue: sensation == null
              ? ''
              : '${_t('sensacion')} ${UnitFormatters.formatTemperature(sensation, units, decimals: 0)}',
          icon: Icons.device_thermostat_rounded,
          accentColor: const Color(0xFF3B82F6),
        ),
        MetricCard(
          label: _t('humedad').toUpperCase(),
          value: row.relativeHumidityPercent == null
              ? _none()
              : UnitFormatters.formatPercentage(row.relativeHumidityPercent),
          subValue: row.dewPointC == null
              ? ''
              : '${_t('punto_rocio')} ${UnitFormatters.formatTemperature(row.dewPointC, units, decimals: 0)}',
          icon: Icons.opacity_rounded,
          accentColor: const Color(0xFF6366F1),
        ),
        MetricCard(
          label: _t('presion').toUpperCase(),
          value: row.pressureHpa == null
              ? _none()
              : UnitFormatters.formatPressure(row.pressureHpa, units),
          subValue: '',
          icon: Icons.speed_rounded,
          accentColor: const Color(0xFF64748B),
        ),
        MetricCard(
          label: _t('indice_uv').toUpperCase(),
          value: _fmt(row.uvIndex),
          subValue: '',
          icon: Icons.wb_sunny_rounded,
          accentColor: const Color(0xFFF97316),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../data/mock/mock_flight_data.dart';
import '../../../domain/i18n/app_strings.dart';
import '../../../domain/i18n/language.dart';
import '../../../domain/units/unit_formatters.dart';
import '../../../domain/units/unit_preferences.dart';
import 'metric_tile.dart';

class ConditionsMetricsCard extends StatelessWidget {
  const ConditionsMetricsCard({
    super.key,
    required this.row,
    required this.units,
    required this.language,
  });

  final ForecastRow row;
  final UnitPreferences units;
  final Language language;

  String _temp(double? c) =>
      c == null ? '—' : UnitFormatters.formatTemperature(c, units, decimals: 0);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cloud = row.cloudCoverPercent;
    final mm = row.precipitationMmPerHour;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                MetricTile(
                  isDark: isDark,
                  label: AppStrings.get(
                    'temperatura',
                    language: language,
                  ).toUpperCase(),
                  value: _temp(row.temperatureC),
                ),
                const SizedBox(width: 10),
                MetricTile(
                  isDark: isDark,
                  label: AppStrings.get(
                    'nubosidad',
                    language: language,
                  ).toUpperCase(),
                  value: cloud == null ? '—' : '${cloud.round()} %',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                MetricTile(
                  isDark: isDark,
                  label: AppStrings.get(
                    'precipitacion',
                    language: language,
                  ).toUpperCase(),
                  value: mm == null
                      ? '—'
                      : '${UnitFormatters.formatPrecipitation(mm, units, decimals: 1)}/h',
                ),
                const SizedBox(width: 10),
                MetricTile(
                  isDark: isDark,
                  label: AppStrings.get(
                    'punto_rocio',
                    language: language,
                  ).toUpperCase(),
                  value: _temp(row.dewPointC),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

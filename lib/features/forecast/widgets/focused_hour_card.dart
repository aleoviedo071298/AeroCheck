// lib/features/forecast/widgets/focused_hour_card.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/mock/mock_flight_data.dart';
import '../../../domain/i18n/app_strings.dart';
import '../../../domain/i18n/language.dart';
import '../../../domain/i18n/rule_localizer.dart';
import '../../../domain/rules/flight_readiness_status.dart';
import '../../../domain/units/unit_formatters.dart';
import '../../../domain/units/unit_preferences.dart';
import 'metric_tile.dart';

Color forecastStatusColor(FlightReadinessStatus status) => switch (status) {
  FlightReadinessStatus.ready => const Color(0xFF16A34A),
  FlightReadinessStatus.caution => const Color(0xFFF59E0B),
  FlightReadinessStatus.notReady => const Color(0xFFDC2626),
};

class FocusedHourCard extends StatelessWidget {
  const FocusedHourCard({
    super.key,
    required this.row,
    required this.units,
    required this.language,
    required this.isBestHour,
    required this.dayLabel,
  });

  final ForecastRow row;
  final UnitPreferences units;
  final Language language;
  final bool isBestHour;
  final String dayLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = forecastStatusColor(row.status);

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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.hour,
                      key: const ValueKey('focused-hour-time'),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dayLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        row.status
                            .getLocalizedLabel(language: language)
                            .toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (isBestHour) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF0F766E,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: Color(0xFF0F766E),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              AppStrings.get('mejor_hora', language: language),
                              style: const TextStyle(
                                color: Color(0xFF0F766E),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              row.reasons.isNotEmpty
                  ? row.reasons.first.localizedTitle(language)
                  : row.primaryReason,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                MetricTile(
                  isDark: isDark,
                  label: AppStrings.get(
                    'viento',
                    language: language,
                  ).toUpperCase(),
                  value: UnitFormatters.formatSpeed(
                    row.windKmh,
                    units,
                    decimals: 0,
                  ),
                  leading: row.windDirectionDegrees == null
                      ? null
                      : Transform.rotate(
                          angle: row.windDirectionDegrees! * math.pi / 180.0,
                          child: const Icon(
                            Icons.navigation_rounded,
                            size: 13,
                            color: Color(0xFF0EA5E9),
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                MetricTile(
                  isDark: isDark,
                  label: AppStrings.get(
                    'rafagas',
                    language: language,
                  ).toUpperCase(),
                  value: UnitFormatters.formatSpeed(
                    row.gustKmh,
                    units,
                    decimals: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                MetricTile(
                  isDark: isDark,
                  label: AppStrings.get(
                    'lluvia',
                    language: language,
                  ).toUpperCase(),
                  value: '${row.rainPercent.round()} %',
                ),
                const SizedBox(width: 10),
                MetricTile(
                  isDark: isDark,
                  label: AppStrings.get(
                    'visibilidad',
                    language: language,
                  ).toUpperCase(),
                  value: UnitFormatters.formatDistance(
                    row.visibilityKm,
                    units,
                    decimals: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

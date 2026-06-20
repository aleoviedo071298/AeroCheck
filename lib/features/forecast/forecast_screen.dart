import 'package:flutter/material.dart';

import '../../app/weather_session.dart';
import '../../domain/i18n/app_strings.dart';
import '../../domain/i18n/language.dart';
import '../../domain/rules/rule_severity.dart';
import '../../domain/units/unit_preferences.dart';
import 'forecast_day_grouping.dart';
import 'widgets/focused_hour_card.dart';
import 'widgets/forecast_metrics_grid.dart';
import 'widgets/hour_scrubber.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key, required this.session});

  final WeatherSession session;

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  DateTime? _selectedDate;
  DateTime? _selectedHour;

  WeatherSession get session => widget.session;

  void _syncSelection(List<ForecastDay> days) {
    if (days.isEmpty) {
      _selectedDate = null;
      _selectedHour = null;
      return;
    }
    final hasDate = days.any((d) => d.date == _selectedDate);
    if (!hasDate) {
      final first = days.first;
      _selectedDate = first.date;
      _selectedHour = first.bestHour?.time ?? first.rows.first.time;
      return;
    }
    final day = days.firstWhere((d) => d.date == _selectedDate);
    final hasHour = day.rows.any((r) => r.time == _selectedHour);
    if (!hasHour) {
      _selectedHour = day.bestHour?.time ?? day.rows.first.time;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentBg = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF1F5F9);

    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        AppStrings.currentLanguage = session.preferences.language;
        final language = session.preferences.language;
        final units = session.preferences.units;
        final report = session.currentReport;
        final rows = session.forecastRows;
        final days = groupForecastByDay(rows);
        _syncSelection(days);

        return Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: contentBg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    children: [
                      if (session.isLoadingReal)
                        const _RealWeatherLoadingCard()
                      else if (session.dataSource == WeatherDataSource.real &&
                          session.realError != null)
                        _RealWeatherErrorCard(onRetry: session.loadRealWeather)
                      else if (report == null || days.isEmpty)
                        const _StaticLoadingCard()
                      else ...[
                        ..._buildFocusedSection(days, units, language),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildFocusedSection(
    List<ForecastDay> days,
    UnitPreferences units,
    Language language,
  ) {
    final today = DateTime.now();
    final activeDay = days.firstWhere(
      (d) => d.date == _selectedDate,
      orElse: () => days.first,
    );
    final selectedRow = activeDay.rows.firstWhere(
      (r) => r.time == _selectedHour,
      orElse: () => activeDay.bestHour ?? activeDay.rows.first,
    );
    final bestTime = activeDay.bestHour?.time;
    final sun = session.realBundle?.sunTimesFor(activeDay.date);

    return [
      FocusedHourCard(
        row: selectedRow,
        units: units,
        language: language,
        isBestHour: selectedRow.time == bestTime,
        dayLabel: forecastDayLabel(activeDay.date, today, language),
      ),
      const SizedBox(height: 14),
      ForecastMetricsGrid(row: selectedRow, units: units, language: language),
      const SizedBox(height: 14),
      HourScrubber(
        days: days,
        selectedDate: activeDay.date,
        selectedHour: selectedRow.time ?? activeDay.rows.first.time!,
        today: today,
        language: language,
        onHourSelected: (t) => setState(() => _selectedHour = t),
        onDaySelected: (date) => setState(() {
          _selectedDate = date;
          final day = days.firstWhere((d) => d.date == date);
          _selectedHour = day.bestHour?.time ?? day.rows.first.time;
        }),
        onGoToBest: () => setState(() {
          _selectedHour = activeDay.bestHour?.time;
        }),
        sunrise: sun?.sunrise,
        sunset: sun?.sunset,
      ),
    ];
  }
}

class _RealWeatherLoadingCard extends StatelessWidget {
  const _RealWeatherLoadingCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: EdgeInsets.zero,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                AppStrings.get('obteniendo_clima'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RealWeatherErrorCard extends StatelessWidget {
  const _RealWeatherErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: EdgeInsets.zero,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  color: _severityColor(RuleSeverity.blocked),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppStrings.get('error_clima'),
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(AppStrings.get('reintentar_mock')),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(AppStrings.get('reintentar')),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaticLoadingCard extends StatelessWidget {
  const _StaticLoadingCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: EdgeInsets.zero,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            AppStrings.get('cargando_datos'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

Color _severityColor(RuleSeverity severity) {
  return switch (severity) {
    RuleSeverity.ok => const Color(0xFF16A34A),
    RuleSeverity.warning => const Color(0xFFF59E0B),
    RuleSeverity.blocked => const Color(0xFFDC2626),
  };
}

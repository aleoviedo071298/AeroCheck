import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/weather_session.dart';
import '../../data/mock/mock_flight_data.dart';
import '../../domain/i18n/app_strings.dart';
import '../../domain/i18n/language.dart';
import '../../domain/i18n/rule_localizer.dart';
import '../../domain/rules/flight_readiness_status.dart';
import '../../domain/rules/rule_severity.dart';
import '../../domain/units/unit_formatters.dart';
import '../../domain/units/unit_preferences.dart';
import 'forecast_day_grouping.dart';
import 'widgets/focused_hour_card.dart';
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
  bool _listExpanded = false;

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
                      _ScreenHeader(
                        title: AppStrings.get('forecast_horario'),
                        session: session,
                      ),
                      const SizedBox(height: 14),
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

    return [
      FocusedHourCard(
        row: selectedRow,
        units: units,
        language: language,
        isBestHour: selectedRow.time == bestTime,
        dayLabel: forecastDayLabel(activeDay.date, today, language),
      ),
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
      ),
      const SizedBox(height: 14),
      _ForecastTableHeader(units: units),
      const SizedBox(height: 4),
      _ListToggle(
        expanded: _listExpanded,
        language: language,
        onTap: () => setState(() => _listExpanded = !_listExpanded),
      ),
      if (_listExpanded)
        Column(
          key: const ValueKey('forecast-list'),
          children: [
            const SizedBox(height: 8),
            for (final row in activeDay.rows)
              _RedesignedForecastRowTile(row: row, units: units),
          ],
        ),
      const SizedBox(height: 16),
      _ForecastTipCard(language: language),
    ];
  }
}

class _ListToggle extends StatelessWidget {
  const _ListToggle({
    required this.expanded,
    required this.language,
    required this.onTap,
  });

  final bool expanded;
  final Language language;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    return Center(
      child: TextButton.icon(
        key: const ValueKey('forecast-list-toggle'),
        onPressed: onTap,
        style: TextButton.styleFrom(foregroundColor: color),
        icon: Icon(
          expanded
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          size: 18,
        ),
        label: Text(
          AppStrings.get(
            expanded ? 'ocultar_lista' : 'ver_lista_completa',
            language: language,
          ),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({required this.title, required this.session});

  final String title;
  final WeatherSession session;

  @override
  Widget build(BuildContext context) {
    final location = session.selectedLocation;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${location.label}\nLat: ${location.latitude.toStringAsFixed(4)} · Lon: ${location.longitude.toStringAsFixed(4)} · Elev. ${UnitFormatters.formatAltitude(location.elevation.toDouble(), session.preferences.units, decimals: 0)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastTableHeader extends StatelessWidget {
  const _ForecastTableHeader({required this.units});

  final UnitPreferences units;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelStyle = TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.5,
      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          // Hora
          SizedBox(
            width: 46,
            child: Text(
              AppStrings.get('hora').toUpperCase(),
              style: labelStyle,
            ),
          ),
          // Estado / Razón Principal
          Expanded(
            child: Row(
              children: [
                Text(AppStrings.get('estado').toUpperCase(), style: labelStyle),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.get('razon_principal').toUpperCase(),
                    style: labelStyle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          // Viento
          SizedBox(
            width: 58,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(AppStrings.get('viento').toUpperCase(), style: labelStyle),
                Text(
                  units.speed.shortName,
                  style: labelStyle.copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          // Ráfagas
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppStrings.get('rafagas').toUpperCase(),
                  style: labelStyle,
                ),
                Text(
                  units.speed.shortName,
                  style: labelStyle.copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          // Lluvia
          SizedBox(
            width: 58,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(AppStrings.get('lluvia').toUpperCase(), style: labelStyle),
                Text(
                  '%',
                  style: labelStyle.copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          // Spacer for expandable chevron
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}

class _RedesignedForecastRowTile extends StatefulWidget {
  const _RedesignedForecastRowTile({required this.row, required this.units});

  final ForecastRow row;
  final UnitPreferences units;

  @override
  State<_RedesignedForecastRowTile> createState() =>
      _RedesignedForecastRowTileState();
}

class _RedesignedForecastRowTileState
    extends State<_RedesignedForecastRowTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderHighlightColor = const Color(
      0xFF22C55E,
    ); // Green highlight border
    final isHighlight = row.isBestWindow;

    return Card(
      key: ValueKey('forecast-row-${row.hour}'),
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: isHighlight
          ? borderHighlightColor.withValues(alpha: 0.05)
          : (isDark ? const Color(0xFF1E293B) : Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isHighlight
              ? borderHighlightColor
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isHighlight ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  // Column 1: HORA
                  SizedBox(
                    width: 46,
                    child: Text(
                      row.hour,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: isHighlight && !isDark
                            ? const Color(0xFF16A34A)
                            : null,
                      ),
                    ),
                  ),

                  // Column 2: ESTADO & RAZÓN PRINCIPAL
                  Expanded(
                    child: Row(
                      children: [
                        _StatusIcon(
                          status: row.status,
                          reasonTitle: row.reasons.first.localizedTitle(
                            AppStrings.currentLanguage,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 2,
                                children: [
                                  Text(
                                    row.status
                                        .getLocalizedLabel(
                                          language: AppStrings.currentLanguage,
                                        )
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: _statusColor(row.status),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (row.isBestWindow) const _BestWindowPill(),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                row.reasons.first.localizedTitle(
                                  AppStrings.currentLanguage,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Column 3: VIENTO
                  SizedBox(
                    width: 58,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (row.windDirectionDegrees != null)
                              Transform.rotate(
                                angle:
                                    (row.windDirectionDegrees! *
                                    math.pi /
                                    180.0),
                                child: const Icon(
                                  Icons.navigation_rounded,
                                  size: 11,
                                  color: Color(0xFF0EA5E9),
                                ),
                              ),
                            const SizedBox(width: 3),
                            Text(
                              UnitFormatters.formatSpeedValue(
                                row.windKmh,
                                widget.units,
                                decimals: 0,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_windDirectionCardinal(row.windDirectionDegrees)} ${row.windDirectionDegrees == null ? "-" : _fmt(row.windDirectionDegrees!)}°',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Column 4: RÁFAGAS
                  SizedBox(
                    width: 52,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          UnitFormatters.formatSpeedValue(
                            row.gustKmh,
                            widget.units,
                            decimals: 0,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (row.gustKmh - row.windKmh > 0)
                          Text(
                            'Δ ${UnitFormatters.formatSpeedValue(row.gustKmh - row.windKmh, widget.units, decimals: 0)}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFFF59E0B),
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          Text(
                            AppStrings.get('sin_rafagas'),
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Column 5: LLUVIA
                  SizedBox(
                    width: 58,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(
                              Icons.opacity_rounded,
                              size: 11,
                              color: Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${_fmt(row.rainPercent)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          row.rainPercent > 0
                              ? AppStrings.get('con_lluvia')
                              : AppStrings.get('sin_lluvia'),
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Chevron indicator on right
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                  ),
                ],
              ),

              // Expandable content
              if (_isExpanded) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                ...row.reasons.map(
                  (reason) =>
                      _ForecastReasonLine(reason: reason, units: widget.units),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(num value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status, required this.reasonTitle});

  final FlightReadinessStatus status;
  final String reasonTitle;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final icon = _iconForReasonTitle(reasonTitle);

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 14),
    );
  }
}

class _BestWindowPill extends StatelessWidget {
  const _BestWindowPill();

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF0F766E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Text(
        AppStrings.get('mejor_hora'),
        style: const TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _ForecastReasonLine extends StatelessWidget {
  const _ForecastReasonLine({required this.reason, required this.units});

  final ForecastReason reason;
  final UnitPreferences units;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(reason.severity);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizedTitle = reason.localizedTitle(AppStrings.currentLanguage);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular colored icon container
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(
              _iconForReasonTitle(localizedTitle),
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),

          // Rule Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizedTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reason.localizedDetails(AppStrings.currentLanguage, units),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastTipCard extends StatelessWidget {
  const _ForecastTipCard({required this.language});

  final Language language;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(
              Icons.task_alt_rounded,
              color: Color(0xFF16A34A),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppStrings.get('ventana_optima_tip'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

Color _statusColor(FlightReadinessStatus status) {
  return switch (status) {
    FlightReadinessStatus.ready => const Color(0xFF16A34A),
    FlightReadinessStatus.caution => const Color(0xFFF59E0B),
    FlightReadinessStatus.notReady => const Color(0xFFDC2626),
  };
}

Color _severityColor(RuleSeverity severity) {
  return switch (severity) {
    RuleSeverity.ok => const Color(0xFF16A34A),
    RuleSeverity.warning => const Color(0xFFF59E0B),
    RuleSeverity.blocked => const Color(0xFFDC2626),
  };
}

String _windDirectionCardinal(double? degrees) {
  if (degrees == null) return '';
  final normalized = (degrees % 360 + 360) % 360;
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

IconData _iconForReasonTitle(String title) {
  final t = title.toUpperCase();
  if (t.contains('VIENTO') ||
      t.contains('RÁFAGAS') ||
      t.contains('WIND') ||
      t.contains('GUST')) {
    return Icons.air_rounded;
  }
  if (t.contains('RESTRIC') ||
      t.contains('ZONA') ||
      t.contains('LIMIT') ||
      t.contains('NO VOLAR')) {
    return Icons.block_rounded;
  }
  if (t.contains('LLUVIA') || t.contains('PRECIP')) {
    return Icons.water_drop_rounded;
  }
  if (t.contains('SOL') ||
      t.contains('DIA') ||
      t.contains('NOCHE') ||
      t.contains('DAYLIGHT')) {
    return Icons.wb_sunny_rounded;
  }
  if (t.contains('VISIBIL')) {
    return Icons.visibility_rounded;
  }
  return Icons.warning_amber_rounded;
}

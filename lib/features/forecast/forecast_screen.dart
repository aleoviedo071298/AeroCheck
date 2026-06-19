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

class ForecastScreen extends StatelessWidget {
  const ForecastScreen({super.key, required this.session});

  final WeatherSession session;

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
        final report = session.currentReport;
        final rows = session.forecastRows;

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
                      // 1. Screen Header
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
                      else if (report == null)
                        const _StaticLoadingCard()
                      else ...[
                        // 2. Selected Window Card
                        _ForecastWindowStatsCard(session: session),
                        const SizedBox(height: 16),

                        // 3. Forecast Table Header
                        _ForecastTableHeader(units: session.preferences.units),
                        const SizedBox(height: 4),

                        // 4. Forecast Rows List
                        ...rows.map(
                          (row) => _RedesignedForecastRowTile(
                            row: row,
                            units: session.preferences.units,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 5. Timeline Index Chart
                        _HourlyScoreTimeline(rows: rows),
                        const SizedBox(height: 16),

                        // 6. Bottom optimal window tip
                        _ForecastTipCard(
                          language: session.preferences.language,
                        ),
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

class _ForecastWindowStatsCard extends StatelessWidget {
  const _ForecastWindowStatsCard({required this.session});

  final WeatherSession session;

  @override
  Widget build(BuildContext context) {
    final report = session.currentReport;
    if (report == null) return const SizedBox.shrink();

    final window = report.bestWindow;
    final start = window.start;
    final end = window.end;

    // Filter forecast rows that fall within the best window
    final windowRows = session.forecastRows.where((row) {
      if (row.time == null) return false;
      return !row.time!.isBefore(start) && row.time!.isBefore(end);
    }).toList();
    double maxRainPercent = 0.0;

    for (final r in windowRows) {
      if (r.rainPercent > maxRainPercent) {
        maxRainPercent = r.rainPercent;
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textStyleValue = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w900,
      height: 1.2,
    );
    final textStyleLabel = TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.5,
      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
    );

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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Row(
          children: [
            // Ventana Seleccionada
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.get('ventana_seleccionada').toUpperCase(),
                    style: textStyleLabel,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_time(start)} - ${_time(end)}',
                    style: textStyleValue.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),

            _vDivider(isDark),

            // Mejor Hora
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.get('mejor_hora').toUpperCase(),
                    style: textStyleLabel,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _time(start),
                    style: textStyleValue.copyWith(
                      color: const Color(0xFF0D9488),
                    ),
                  ),
                ],
              ),
            ),

            _vDivider(isDark),

            // Lluvia en Ventana
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.get('lluvia_en_ventana').toUpperCase(),
                    style: textStyleLabel,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.opacity_rounded,
                        color: Color(0xFF3B82F6),
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Text('${_fmt(maxRainPercent)}%', style: textStyleValue),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vDivider(bool isDark) {
    return Container(
      width: 1,
      height: 32,
      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
    );
  }

  String _time(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  String _fmt(num value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
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

class _HourlyScoreTimeline extends StatelessWidget {
  const _HourlyScoreTimeline({required this.rows});

  final List<ForecastRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.get('indice_por_hora').toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: List.generate(rows.length, (index) {
                final row = rows[index];
                final hourStr = row.hour.split(':').first;
                final scoreColor = _indexColor(row.score);

                return SizedBox(
                  width: 50,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Hour text
                      Text(
                        hourStr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: row.isBestWindow
                              ? FontWeight.w900
                              : FontWeight.w700,
                          color: row.isBestWindow
                              ? const Color(0xFF16A34A)
                              : textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Dot and connecting lines
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Left connecting line
                          if (index > 0)
                            Positioned(
                              left: 0,
                              right: 25,
                              child: Container(
                                height: 2,
                                color: _lineColor(
                                  rows[index - 1].score,
                                  row.score,
                                ),
                              ),
                            ),
                          // Right connecting line
                          if (index < rows.length - 1)
                            Positioned(
                              left: 25,
                              right: 0,
                              child: Container(
                                height: 2,
                                color: _lineColor(
                                  row.score,
                                  rows[index + 1].score,
                                ),
                              ),
                            ),
                          // The Dot
                          Container(
                            width: row.isBestWindow ? 16 : 8,
                            height: row.isBestWindow ? 16 : 8,
                            decoration: BoxDecoration(
                              color: scoreColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF0F172A)
                                    : Colors.white,
                                width: row.isBestWindow ? 3 : 1.5,
                              ),
                              boxShadow: row.isBestWindow
                                  ? [
                                      BoxShadow(
                                        color: scoreColor.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Color _indexColor(int score) {
    if (score >= 80) return const Color(0xFF16A34A);
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFDC2626);
  }

  Color _lineColor(int score1, int score2) {
    final avg = (score1 + score2) / 2.0;
    return _indexColor(avg.round());
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

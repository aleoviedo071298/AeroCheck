import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/weather_session.dart';
import '../../data/mock/mock_flight_data.dart';
import '../../domain/i18n/app_strings.dart';
import '../../domain/i18n/language.dart';
import '../../domain/rules/rule_severity.dart';
import '../../domain/rules/wind_profile_evaluator.dart';
import '../../domain/units/unit_formatters.dart';
import '../../domain/units/unit_preferences.dart';

class WindScreen extends StatelessWidget {
  const WindScreen({super.key, required this.session});

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
        final rows = session.windProfileRows;

        final evaluator = WindProfileEvaluator(
          droneProfile: MockFlightData.droneProfile,
          missionProfile: MockFlightData.missionProfile,
        );

        final evaluatedRows = evaluator.evaluateProfile(rows);
        final bestWindRow = evaluator.findBestWindAltitude(rows);
        final units = session.preferences.units;

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
                        title: AppStrings.get('perfil_vertical'),
                        session: session,
                      ),
                      const SizedBox(height: 14),

                      if (session.isLoadingReal)
                        const _RealWeatherLoadingCard()
                      else if (session.dataSource == WeatherDataSource.real &&
                          session.realError != null)
                        _RealWeatherErrorCard(onRetry: session.loadRealWeather)
                      else if (rows.isEmpty)
                        const _StaticLoadingCard()
                      else ...[
                        // 3. Side-by-side Wind Stats cards
                        Row(
                          children: [
                            Expanded(
                              child: _WindStatsCard(
                                label: AppStrings.get(
                                  'altitud_maxima',
                                ).toUpperCase(),
                                value: UnitFormatters.formatAltitude(
                                  122.0,
                                  units,
                                  decimals: 0,
                                ),
                                subValue: AppStrings.get('categoria_abierta'),
                                icon: Icons.gps_fixed_rounded,
                                iconColor: const Color(0xFF0284C7),
                                iconBg: const Color(0xFFE0F2FE),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _WindStatsCard(
                                label: AppStrings.get(
                                  'mejor_viento',
                                ).toUpperCase(),
                                value: _formatAltitude(
                                  bestWindRow.altitude,
                                  units,
                                ),
                                subValue: AppStrings.get(
                                  'viento_mas_favorable',
                                ),
                                icon: Icons.air_rounded,
                                iconColor: const Color(0xFF16A34A),
                                iconBg: const Color(0xFFDCFCE7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 4. Vertical Profile Table
                        Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                _WindTableHeader(units: units),
                                const SizedBox(height: 4),
                                const Divider(height: 1),
                                const SizedBox(height: 4),
                                ...List.generate(evaluatedRows.length, (index) {
                                  final row = evaluatedRows[index];
                                  return _RedesignedWindRow(
                                    row: row,
                                    index: index,
                                    isTarget:
                                        _altitudeMeters(row.altitude) ==
                                        MockFlightData
                                            .droneProfile
                                            .preferredAltitudeMeters,
                                    isBestWind:
                                        row.altitude == bestWindRow.altitude,
                                    units: units,
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 5. Legend Card
                        _WindLegendCard(language: session.preferences.language),
                        const SizedBox(height: 14),

                        // 6. Bottom optimal window tip card
                        _WindTipCard(language: session.preferences.language),
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

class _WindStatsCard extends StatelessWidget {
  const _WindStatsCard({
    required this.label,
    required this.value,
    required this.subValue,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  final String label;
  final String value;
  final String subValue;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subValue,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _WindTableHeader extends StatelessWidget {
  const _WindTableHeader({required this.units});

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          // Altitud
          SizedBox(
            width: 75,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.get('altitud').toUpperCase(),
                  style: labelStyle,
                ),
                Text(
                  units.altitude.shortName,
                  style: labelStyle.copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          // Viento
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
          // Ráfaga
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.get('rafaga').toUpperCase(), style: labelStyle),
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
          // Temp
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.get('temp').toUpperCase(), style: labelStyle),
                Text(
                  units.temperature.shortName,
                  style: labelStyle.copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          // Estado
          SizedBox(
            width: 100,
            child: Text(
              AppStrings.get('estado').toUpperCase(),
              style: labelStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _RedesignedWindRow extends StatelessWidget {
  const _RedesignedWindRow({
    required this.row,
    required this.index,
    required this.isTarget,
    required this.isBestWind,
    required this.units,
  });

  final EvaluatedWindProfileRow row;
  final int index;
  final bool isTarget;
  final bool isBestWind;
  final UnitPreferences units;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderHighlightColor = const Color(
      0xFF22C55E,
    ).withValues(alpha: isDark ? 0.6 : 0.4); // Green

    final rowBgColor = isBestWind
        ? (isDark
              ? const Color(0xFF22C55E).withValues(alpha: 0.1)
              : const Color(0xFFDCFCE7).withValues(alpha: 0.6))
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: rowBgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isBestWind ? borderHighlightColor : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            // Column 1: ALTITUD
            SizedBox(
              width: 75,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatAltitude(row.altitude, units),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: isBestWind ? const Color(0xFF15803D) : null,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${AppStrings.get('nivel')} ${index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  if (isBestWind) ...[
                    const SizedBox(height: 4),
                    _buildPill(
                      AppStrings.get('mejor').toUpperCase(),
                      const Color(0xFFDCFCE7),
                      const Color(0xFF15803D),
                    ),
                  ],
                ],
              ),
            ),

            // Column 2: VIENTO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (row.windDirectionDegrees != null)
                        Transform.rotate(
                          angle: (row.windDirectionDegrees! * math.pi / 180.0),
                          child: const Icon(
                            Icons.navigation_rounded,
                            size: 11,
                            color: Color(0xFF0EA5E9),
                          ),
                        ),
                      const SizedBox(width: 4),
                      Text(
                        UnitFormatters.formatSpeedValue(
                          row.windKmh,
                          units,
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
                    row.windDirectionDegrees == null
                        ? '-'
                        : '${_windDirectionCardinal(row.windDirectionDegrees)} ${_fmt(row.windDirectionDegrees!)}°',
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

            // Column 3: RÁFAGA
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.air_rounded,
                        size: 11,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        UnitFormatters.formatSpeedValue(
                          row.gustKmh,
                          units,
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
                    units.speed.shortName,
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

            // Column 4: TEMP.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.device_thermostat_rounded,
                        size: 11,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        UnitFormatters.formatTemperatureValue(
                          row.temperatureC,
                          units,
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
                    '${AppStrings.get('sensacion')} ${UnitFormatters.formatTemperature(row.temperatureC - 1.7, units, decimals: 0)}',
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

            // Column 5: ESTADO
            SizedBox(
              width: 100,
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _statusDotColor(row, isTarget, isBestWind),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _statusLabel(row, isTarget, isBestWind),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _statusDotColor(row, isTarget, isBestWind),
                          ),
                        ),
                        Text(
                          _statusSublabel(row, isTarget, isBestWind),
                          style: TextStyle(
                            fontSize: 9,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
    );
  }

  String _statusLabel(
    EvaluatedWindProfileRow row,
    bool isTarget,
    bool isBestWind,
  ) {
    if (isTarget) return AppStrings.get('objetivo');
    if (isBestWind) return AppStrings.get('mejor_viento');
    return switch (row.status) {
      'blocked' => AppStrings.get('desfavorable'),
      'warning' => AppStrings.get('precaucion'),
      _ => AppStrings.get('favorable'),
    };
  }

  String _statusSublabel(
    EvaluatedWindProfileRow row,
    bool isTarget,
    bool isBestWind,
  ) {
    if (isTarget) return AppStrings.get('nivel_seleccionado');
    if (isBestWind) return AppStrings.get('mas_favorable');
    return switch (row.status) {
      'blocked' =>
        row.limitExceededAt == 'wind'
            ? AppStrings.get('viento_alto')
            : AppStrings.get('rafagas_altas'),
      'warning' =>
        row.limitExceededAt == 'wind'
            ? AppStrings.get('viento_elevado')
            : AppStrings.get('rafagas_elevadas'),
      _ => AppStrings.get('viento_estable'),
    };
  }

  Color _statusDotColor(
    EvaluatedWindProfileRow row,
    bool isTarget,
    bool isBestWind,
  ) {
    if (isTarget) return const Color(0xFF0284C7);
    if (isBestWind) return const Color(0xFF16A34A);
    return switch (row.status) {
      'blocked' => const Color(0xFFDC2626),
      'warning' => const Color(0xFFF59E0B),
      _ => const Color(0xFF16A34A),
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

  String _fmt(num value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }
}

class _WindLegendCard extends StatelessWidget {
  const _WindLegendCard({required this.language});

  final Language language;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final legendTitleStyle = const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
    );
    final legendSubstyle = TextStyle(
      fontSize: 9,
      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
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
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Direction Legend
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    Icons.navigation_rounded,
                    color: Color(0xFF0EA5E9),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.get('direccion_viento'),
                          style: legendTitleStyle,
                        ),
                        Text(
                          AppStrings.get('origen_viento'),
                          style: legendSubstyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _vDivider(isDark),
            const SizedBox(width: 8),

            // Gust Legend
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.air_rounded,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.get('rafagas'),
                          style: legendTitleStyle,
                        ),
                        Text(
                          AppStrings.get('picos_instantaneos'),
                          style: legendSubstyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _vDivider(isDark),
            const SizedBox(width: 8),

            // Status Legend
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDC2626),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.get('estado_operativo'),
                          style: legendTitleStyle,
                        ),
                        Text(
                          AppStrings.get('evaluacion_nivel'),
                          style: legendSubstyle,
                        ),
                      ],
                    ),
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
      height: 24,
      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
    );
  }
}

class _WindTipCard extends StatelessWidget {
  const _WindTipCard({required this.language});

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
            const Icon(Icons.air_rounded, color: Color(0xFF0EA5E9), size: 20),
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

String _formatAltitude(String source, UnitPreferences units) {
  final meters = _altitudeMeters(source);
  if (meters == null) {
    return source.toLowerCase() == 'suelo' ? AppStrings.get('suelo') : source;
  }
  return UnitFormatters.formatAltitude(meters, units, decimals: 0);
}

double? _altitudeMeters(String source) {
  final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(source);
  return match == null ? null : double.tryParse(match.group(0)!);
}

Color _severityColor(RuleSeverity severity) {
  return switch (severity) {
    RuleSeverity.ok => const Color(0xFF16A34A),
    RuleSeverity.warning => const Color(0xFFF59E0B),
    RuleSeverity.blocked => const Color(0xFFDC2626),
  };
}

import 'package:flutter/material.dart';

import '../../app/weather_session.dart';
import '../../domain/entities/flight_readiness_report.dart';
import '../../domain/entities/flight_rule_result.dart';
import '../../domain/entities/weather_snapshot.dart';
import '../../domain/i18n/app_strings.dart';
import '../../domain/i18n/rule_localizer.dart';
import '../../domain/rules/flight_readiness_status.dart';
import '../../domain/rules/rule_severity.dart';
import '../../domain/units/unit_formatters.dart';
import '../../domain/units/unit_preferences.dart';
import '../shared/weather_condition.dart';
import '../shared/widgets/metric_card.dart';

class ConditionsScreen extends StatelessWidget {
  const ConditionsScreen({
    super.key,
    required this.session,
    this.onNavigateToForecast,
  });

  final WeatherSession session;
  final VoidCallback? onNavigateToForecast;

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
        final weather = report?.weather;

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
                      // 1. Weather provider row
                      _ProviderRow(session: session, report: report),
                      const SizedBox(height: 12),

                      if (session.isLoadingReal)
                        const _RealWeatherLoadingCard()
                      else if (session.dataSource == WeatherDataSource.real &&
                          session.realError != null)
                        _RealWeatherErrorCard(onRetry: session.loadRealWeather)
                      else if (report == null)
                        const _StaticLoadingCard()
                      else if (weather != null) ...[
                        // 3. Status dial panel
                        _RedesignedStatusPanel(
                          report: report,
                          onNavigateToForecast: onNavigateToForecast,
                        ),
                        const SizedBox(height: 12),

                        // 4. Reasons list
                        _RedesignedReasonList(
                          rules: report.rules,
                          units: session.preferences.units,
                        ),
                        const SizedBox(height: 12),

                        // 5. Reworked metrics grid (2x2 + 1x4 secondary)
                        _ReworkedMetricsGrid(
                          weather: weather,
                          session: session,
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

class _ProviderRow extends StatelessWidget {
  const _ProviderRow({required this.session, this.report});

  final WeatherSession session;
  final FlightReadinessReport? report;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isReal = session.dataSource == WeatherDataSource.real;
    final providerName = session.realBundle?.providerName ?? 'Open-Meteo';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isReal ? const Color(0xFF16A34A) : const Color(0xFFD97706),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isReal
                ? '${AppStrings.get('clima_real')} | $providerName'
                : AppStrings.get('clima_simulado'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'UTC-3',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFFE2E8F0)
                    : const Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'AGL',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFFE2E8F0)
                    : const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RedesignedStatusPanel extends StatelessWidget {
  const _RedesignedStatusPanel({
    required this.report,
    this.onNavigateToForecast,
  });

  final FlightReadinessReport report;
  final VoidCallback? onNavigateToForecast;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(report.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Circular Progress Dial on the left
                _ScoreDialRing(score: report.score, color: statusColor),
                const SizedBox(width: 20),

                // Status Text on the right
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.status
                            .getLocalizedLabel(
                              language: AppStrings.currentLanguage,
                            )
                            .toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        RuleLocalizer.getLocalizedSummary(
                          report,
                          AppStrings.currentLanguage,
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF334155),
                        ),
                      ),
                    ],
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

class _ScoreDialRing extends StatelessWidget {
  const _ScoreDialRing({required this.score, required this.color});

  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 76,
              height: 76,
              child: CircularProgressIndicator(
                value: score / 100.0,
                strokeWidth: 7,
                color: color,
                backgroundColor: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    height: 1.1,
                  ),
                ),
                Text(
                  '/100',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          AppStrings.get('indice_vuelo').toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

class _RedesignedReasonList extends StatelessWidget {
  const _RedesignedReasonList({required this.rules, required this.units});

  final List<FlightRuleResult> rules;
  final UnitPreferences units;

  @override
  Widget build(BuildContext context) {
    final activeRules = rules
        .where((rule) => rule.severity != RuleSeverity.ok)
        .toList();
    if (activeRules.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBlocked = activeRules.any(
      (r) => r.severity == RuleSeverity.blocked,
    );

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (isBlocked
                      ? AppStrings.get('razones_de_rechazo')
                      : AppStrings.get('recomendaciones_vuelo'))
                  .toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: isDark
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 12),
            ...activeRules.map(
              (rule) => _RedesignedReasonTile(rule: rule, units: units),
            ),
          ],
        ),
      ),
    );
  }
}

class _RedesignedReasonTile extends StatefulWidget {
  const _RedesignedReasonTile({required this.rule, required this.units});

  final FlightRuleResult rule;
  final UnitPreferences units;

  @override
  State<_RedesignedReasonTile> createState() => _RedesignedReasonTileState();
}

class _RedesignedReasonTileState extends State<_RedesignedReasonTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final rule = widget.rule;
    final color = _severityColor(rule.severity);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _ruleIcon(rule.code),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.localizedTitle(AppStrings.currentLanguage),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (!_expanded) ...[
                        const SizedBox(height: 2),
                        Text(
                          rule.localizedDetails(
                            AppStrings.currentLanguage,
                            widget.units,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                  size: 22,
                ),
              ],
            ),
            if (_expanded) ...[
              Padding(
                padding: const EdgeInsets.only(left: 48, top: 6),
                child: Text(
                  rule.localizedDetails(
                    AppStrings.currentLanguage,
                    widget.units,
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _ruleIcon(String code) {
    if (code.contains('WIND') || code.contains('GUST')) {
      return Icons.air_rounded;
    }
    if (code.contains('RESTRICTED') || code.contains('ZONE')) {
      return Icons.block_rounded;
    }
    if (code.contains('RAIN') || code.contains('PRECIP')) {
      return Icons.water_drop_rounded;
    }
    if (code.contains('DAYLIGHT')) {
      return Icons.wb_sunny_rounded;
    }
    if (code.contains('VISIBILITY')) {
      return Icons.visibility_rounded;
    }
    return Icons.warning_amber_rounded;
  }
}

class _ReworkedMetricsGrid extends StatelessWidget {
  const _ReworkedMetricsGrid({required this.weather, required this.session});

  final WeatherSnapshot weather;
  final WeatherSession session;

  @override
  Widget build(BuildContext context) {
    final units = session.preferences.units;
    final condition = weatherConditionFor(weather.weatherCode);

    String dewPointStr = AppStrings.get('sin_dato');
    if (weather.dewPointC != null) {
      dewPointStr = UnitFormatters.formatTemperature(weather.dewPointC, units);
    } else if (weather.temperatureC != null &&
        weather.relativeHumidityPercent != null) {
      final dp =
          weather.temperatureC! -
          ((100 - weather.relativeHumidityPercent!) / 5.0);
      dewPointStr = UnitFormatters.formatTemperature(dp, units);
    }

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      children: [
        MetricCard(
          label: AppStrings.get('viento').toUpperCase(),
          value: UnitFormatters.formatSpeed(weather.windKmh, units),
          subValue:
              '↗ ${weather.windDirectionCardinal ?? ""} ${_fmt(weather.windDirectionDegrees)}°',
          icon: Icons.air_rounded,
          accentColor: const Color(0xFF0EA5E9),
        ),
        MetricCard(
          label: AppStrings.get('rafagas').toUpperCase(),
          value: UnitFormatters.formatSpeed(weather.gustKmh, units),
          subValue: _formatGustDelta(weather, session),
          icon: Icons.wind_power_rounded,
          accentColor: const Color(0xFFD97706),
        ),
        MetricCard(
          label: AppStrings.get('precip').toUpperCase(),
          value: weather.precipitationProbability == null
              ? '0%'
              : '${_fmt(weather.precipitationProbability!)}%',
          subValue:
              weather.precipitationMmPerHour != null &&
                  weather.precipitationMmPerHour! > 0
              ? '${_fmt(weather.precipitationMmPerHour!)} mm/h'
              : AppStrings.get('sin_lluvia'),
          icon: Icons.water_drop_rounded,
          accentColor: const Color(0xFF06B6D4),
        ),
        MetricCard(
          label: AppStrings.get('visibilidad').toUpperCase(),
          value: weather.visibilityKm == null
              ? AppStrings.get('sin_dato')
              : UnitFormatters.formatDistance(weather.visibilityKm, units),
          subValue: '',
          icon: Icons.visibility_rounded,
          accentColor: const Color(0xFF10B981),
        ),
        MetricCard(
          label: AppStrings.get('nubosidad').toUpperCase(),
          value: weather.cloudCoverPercent == null
              ? AppStrings.get('sin_dato')
              : '${_cloudCoverFraction(weather.cloudCoverPercent!)} (${_fmt(weather.cloudCoverPercent!)}%)',
          subValue: weather.cloudBaseMeters != null
              ? 'Base: ${UnitFormatters.formatAltitude(weather.cloudBaseMeters, units, decimals: 0)}'
              : '',
          icon: Icons.cloud_rounded,
          accentColor: const Color(0xFF14B8A6),
        ),
        MetricCard(
          label: AppStrings.get('condicion').toUpperCase(),
          value: AppStrings.get(condition.labelKey),
          subValue: '',
          icon: condition.icon,
          accentColor: const Color(0xFFF59E0B),
        ),
        MetricCard(
          label: AppStrings.get('temp').toUpperCase(),
          value: UnitFormatters.formatTemperature(weather.temperatureC, units),
          subValue: _formatSensation(weather, session),
          icon: Icons.device_thermostat_rounded,
          accentColor: const Color(0xFF3B82F6),
        ),
        MetricCard(
          label: AppStrings.get('humedad').toUpperCase(),
          value: weather.relativeHumidityPercent == null
              ? AppStrings.get('sin_dato')
              : UnitFormatters.formatPercentage(
                  weather.relativeHumidityPercent,
                ),
          subValue: '${AppStrings.get('punto_rocio')} $dewPointStr',
          icon: Icons.opacity_rounded,
          accentColor: const Color(0xFF6366F1),
        ),
        MetricCard(
          label: AppStrings.get('presion').toUpperCase(),
          value: weather.pressureHpa == null
              ? AppStrings.get('sin_dato')
              : UnitFormatters.formatPressure(weather.pressureHpa, units),
          subValue: '',
          icon: Icons.speed_rounded,
          accentColor: const Color(0xFF64748B),
        ),
        MetricCard(
          label: AppStrings.get('indice_kp').toUpperCase(),
          value: weather.kpIndex == null
              ? AppStrings.get('sin_dato')
              : _fmt(weather.kpIndex!),
          subValue: '',
          icon: Icons.sensors_rounded,
          accentColor: const Color(0xFF8B5CF6),
        ),
      ],
    );
  }

  String _cloudCoverFraction(double percent) {
    final okta = (percent / 12.5).round();
    return '$okta/8';
  }

  String _formatGustDelta(WeatherSnapshot weather, WeatherSession session) {
    if (weather.gustKmh != null && weather.windKmh != null) {
      final delta = weather.gustKmh! - weather.windKmh!;
      if (delta > 0) {
        return 'Δ ${UnitFormatters.formatSpeed(delta, session.preferences.units)}';
      }
      return AppStrings.get('sin_rafagas');
    }
    return '';
  }

  String _formatSensation(WeatherSnapshot weather, WeatherSession session) {
    final sensation =
        weather.apparentTemperatureC ??
        (weather.temperatureC != null ? weather.temperatureC! - 2.0 : null);
    if (sensation != null) {
      return '${AppStrings.get('sensacion')} ${UnitFormatters.formatTemperature(sensation, session.preferences.units)}';
    }
    return AppStrings.get('sin_dato');
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

String _fmt(num? value) {
  if (value == null) return '-';
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}

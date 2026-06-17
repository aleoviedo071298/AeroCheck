import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/weather_session.dart';
import '../../data/location/flight_location.dart';
import '../../domain/entities/flight_readiness_report.dart';
import '../../domain/entities/flight_rule_result.dart';
import '../../domain/entities/weather_snapshot.dart';
import '../../domain/rules/flight_readiness_status.dart';
import '../../domain/rules/rule_severity.dart';
import '../../data/mock/mock_flight_data.dart';
import '../../domain/units/unit_formatters.dart';
import '../../domain/units/unit_preferences.dart';

class ConditionsScreen extends StatelessWidget {
  const ConditionsScreen({super.key, required this.session});

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
                      // 1. Collapsible Location Card
                      _CollapsibleLocationCard(
                        session: session,
                        report: report,
                      ),
                      const SizedBox(height: 12),

                      // 2. Weather provider row
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
                        _RedesignedStatusPanel(report: report),
                        const SizedBox(height: 12),

                        // 4. Reasons list
                        _RedesignedReasonList(rules: report.rules),
                        const SizedBox(height: 12),

                        // 5. Reworked metrics grid (2x2 + 1x4 secondary)
                        _ReworkedMetricsGrid(
                          weather: weather,
                          session: session,
                        ),
                        const SizedBox(height: 16),

                        // 6. Hourly timeline table
                        _HourlyTimelineWidget(session: session),
                        const SizedBox(height: 12),

                        // 7. Profile strip
                        _ProfileStrip(report: report),
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

class _CollapsibleLocationCard extends StatefulWidget {
  const _CollapsibleLocationCard({required this.session, this.report});

  final WeatherSession session;
  final FlightReadinessReport? report;

  @override
  State<_CollapsibleLocationCard> createState() =>
      _CollapsibleLocationCardState();
}

class _CollapsibleLocationCardState extends State<_CollapsibleLocationCard> {
  bool _isExpanded = false;
  final _searchController = TextEditingController();
  Future<List<FlightLocation>>? _searchFuture;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = widget.session.selectedLocation;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Lat: ${location.latitude.toStringAsFixed(4)} · Lon: ${location.longitude.toStringAsFixed(4)} · Elev. ${location.elevation} m',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ],
              ),
              if (_isExpanded) ...[
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Cambiar Ubicación',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      key: const ValueKey('gps-location-button'),
                      icon: const Icon(Icons.my_location_rounded),
                      iconSize: 20,
                      tooltip: 'Mi ubicación (GPS)',
                      onPressed: () {
                        widget.session.setLocationToCurrentGPS();
                        setState(() {
                          _isExpanded = false;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...widget.session.availableLocations.map((loc) {
                      final isSelected = loc.id == location.id;
                      return ChoiceChip(
                        key: ValueKey('location-chip-${loc.id}'),
                        label: Text(loc.name),
                        selected: isSelected,
                        onSelected: (_) {
                          widget.session.setLocation(loc);
                          setState(() {
                            _isExpanded = false;
                          });
                        },
                      );
                    }),
                    ActionChip(
                      key: const ValueKey('add-location-button'),
                      label: const Text('Buscar'),
                      avatar: const Icon(Icons.search_rounded, size: 16),
                      onPressed: () {
                        _showAddLocationDialog();
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAddLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Buscar ciudad'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Escribe nombre de ciudad...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (val) {
                      _debounceTimer?.cancel();
                      _debounceTimer = Timer(
                        const Duration(milliseconds: 300),
                        () {
                          setDialogState(() {
                            _searchFuture = widget.session.searchCities(val);
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    width: double.maxFinite,
                    child: _searchFuture == null
                        ? const Center(
                            child: Text('Escribe para buscar ciudades'),
                          )
                        : FutureBuilder<List<FlightLocation>>(
                            future: _searchFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text('Error: ${snapshot.error}'),
                                );
                              }
                              final locations = snapshot.data ?? [];
                              if (locations.isEmpty) {
                                return const Center(
                                  child: Text('No se encontraron ciudades'),
                                );
                              }
                              return ListView.builder(
                                itemCount: locations.length,
                                itemBuilder: (context, index) {
                                  final loc = locations[index];
                                  return ListTile(
                                    key: ValueKey('search-location-${loc.id}'),
                                    title: Text(loc.name),
                                    subtitle: Text(
                                      '${loc.region}, ${loc.country}',
                                    ),
                                    trailing: const Icon(
                                      Icons.add_circle_outline_rounded,
                                    ),
                                    onTap: () {
                                      widget.session.addFavoriteLocation(loc);
                                      Navigator.pop(context);
                                      _searchController.clear();
                                      setState(() {
                                        _isExpanded = false;
                                        _searchFuture = null;
                                      });
                                    },
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _searchController.clear();
                  setState(() {
                    _searchFuture = null;
                  });
                },
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      ),
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
    final providerName = isReal
        ? (session.realBundle?.providerName ?? 'Open-Meteo')
        : 'Mock Data';

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
            isReal ? 'Clima real | $providerName' : 'Clima simulado (Mock)',
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
  const _RedesignedStatusPanel({required this.report});

  final FlightReadinessReport report;

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
                        report.status.label,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.summary,
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

            // Best flight window row embedded at the bottom of status panel
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _EmbeddedBestWindowPill(report: report),
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
          'ÍNDICE DE VUELO',
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

class _EmbeddedBestWindowPill extends StatelessWidget {
  const _EmbeddedBestWindowPill({required this.report});

  final FlightReadinessReport report;

  @override
  Widget build(BuildContext context) {
    final window = report.bestWindow;
    final now = DateTime.now();
    final windowPassed = window.end.isBefore(now);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.5)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            color: Color(0xFF0D9488),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  windowPassed
                      ? 'PRÓXIMA VENTANA DISPONIBLE'
                      : 'MEJOR VENTANA DISPONIBLE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_time(window.start)} - ${_time(window.end)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F766E),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
        ],
      ),
    );
  }
}

class _RedesignedReasonList extends StatelessWidget {
  const _RedesignedReasonList({required this.rules});

  final List<FlightRuleResult> rules;

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
              isBlocked ? 'RAZONES DE RECHAZO' : 'RECOMENDACIONES DE VUELO',
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
            ...activeRules.map((rule) => _RedesignedReasonTile(rule: rule)),
          ],
        ),
      ),
    );
  }
}

class _RedesignedReasonTile extends StatelessWidget {
  const _RedesignedReasonTile({required this.rule});

  final FlightRuleResult rule;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(rule.severity);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular colored icon container
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(_ruleIcon(rule.code), color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),

          // Rule Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rule.details,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            size: 22,
          ),
        ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate dew point estimate if temperature and humidity exist
    String dewPointStr = '9°';
    if (weather.temperatureC != null &&
        weather.relativeHumidityPercent != null) {
      final t = weather.temperatureC!;
      final rh = weather.relativeHumidityPercent!;
      final dp = t - ((100 - rh) / 5.0); // Simple dew point approximation
      dewPointStr = '${_fmt(dp)}°';
    }

    return Column(
      children: [
        // 1. Primary Metrics Grid (2x2)
        GridView(
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
            _MetricCard(
              label: 'VIENTO',
              value: UnitFormatters.formatSpeed(
                weather.windKmh,
                session.preferences.units,
              ),
              subValue:
                  '↗ ${weather.windDirectionCardinal ?? ""} ${_fmt(weather.windDirectionDegrees)}°',
              icon: Icons.air_rounded,
              accentColor: const Color(0xFF0EA5E9), // Cyan bottom line
            ),
            _MetricCard(
              label: 'RÁFAGAS',
              value: UnitFormatters.formatSpeed(
                weather.gustKmh,
                session.preferences.units,
              ),
              subValue: _formatGustDelta(weather, session),
              icon: Icons.wind_power_rounded,
              accentColor: const Color(0xFFD97706), // Orange bottom line
            ),
            _MetricCard(
              label: 'TEMP.',
              value: UnitFormatters.formatTemperature(
                weather.temperatureC,
                session.preferences.units,
              ),
              subValue: _formatSensation(weather, session),
              icon: Icons.device_thermostat_rounded,
              accentColor: const Color(0xFF3B82F6), // Blue bottom line
            ),
            _MetricCard(
              label: 'HUMEDAD',
              value: weather.relativeHumidityPercent == null
                  ? 'Sin dato'
                  : '${_fmt(weather.relativeHumidityPercent!)} %',
              subValue: 'Punto rocío $dewPointStr',
              icon: Icons.opacity_rounded,
              accentColor: const Color(0xFF6366F1), // Indigo bottom line
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2. Secondary Metrics Row (1x4)
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: _MiniMetricCol(
                    icon: Icons.cloud_rounded,
                    label: 'NUBOSIDAD',
                    value: _cloudCoverValue(weather),
                  ),
                ),
                _vDivider(isDark),
                Expanded(
                  child: _MiniMetricCol(
                    icon: Icons.visibility_rounded,
                    label: 'VISIBILIDAD',
                    value: weather.visibilityKm == null
                        ? 'Sin dato'
                        : '${_fmt(weather.visibilityKm!)} km',
                  ),
                ),
                _vDivider(isDark),
                Expanded(
                  child: _MiniMetricCol(
                    icon: Icons.sensors_rounded,
                    label: 'ÍNDICE KP',
                    value: weather.kpIndex == null
                        ? 'Sin dato'
                        : _fmt(weather.kpIndex!),
                  ),
                ),
                _vDivider(isDark),
                Expanded(
                  child: _MiniMetricCol(
                    icon: Icons.water_drop_rounded,
                    label: 'PRECIP.',
                    value: weather.precipitationProbability == null
                        ? '0%'
                        : '${_fmt(weather.precipitationProbability!)}%',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _vDivider(bool isDark) {
    return Container(
      width: 1,
      height: 30,
      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
    );
  }

  String _cloudCoverFraction(double percent) {
    final okta = (percent / 12.5).round();
    return '$okta/8';
  }

  String _cloudCoverValue(WeatherSnapshot weather) {
    if (weather.cloudCoverPercent == null) return 'Sin dato';
    final fraction = _cloudCoverFraction(weather.cloudCoverPercent!);
    final pct = '${_fmt(weather.cloudCoverPercent!)}%';
    if (weather.cloudBaseMeters != null) {
      final feet = (weather.cloudBaseMeters! * 3.28084).round();
      return '$fraction ($pct)\n(${_formatThousands(feet)} ft)';
    }
    return '$fraction ($pct)';
  }

  String _formatThousands(int value) {
    final str = value.toString();
    if (str.length <= 3) return str;
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    return buffer.toString().split('').reversed.join('');
  }

  String _formatGustDelta(WeatherSnapshot weather, WeatherSession session) {
    if (weather.gustKmh != null && weather.windKmh != null) {
      final delta = weather.gustKmh! - weather.windKmh!;
      if (delta > 0) {
        final unitName = session.preferences.units.speed.displayName;
        return 'Δ ${_fmt(delta)} $unitName';
      }
      return 'Sin ráfagas';
    }
    return '';
  }

  String _formatSensation(WeatherSnapshot weather, WeatherSession session) {
    final sensation = weather.temperatureC != null
        ? (weather.temperatureC! - 2.0)
        : null;
    if (sensation != null) {
      return 'Sensación ${UnitFormatters.formatTemperature(sensation, session.preferences.units)}';
    }
    return 'Sin dato';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.subValue,
    required this.icon,
    required this.accentColor,
  });

  final String label;
  final String value;
  final String subValue;
  final IconData icon;
  final Color accentColor;

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Accent Color Line at the bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 4,
              child: Container(color: accentColor),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
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
                        const SizedBox(height: 2),
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subValue,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
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
}

class _MiniMetricCol extends StatelessWidget {
  const _MiniMetricCol({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

class _HourlyTimelineWidget extends StatelessWidget {
  const _HourlyTimelineWidget({required this.session});

  final WeatherSession session;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rows = session.forecastRows;
    if (rows.isEmpty) return const SizedBox.shrink();

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
              'PRÓXIMAS HORAS (hora local)',
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

            // Timeline horizontal scroll area
            SizedBox(
              height: 136,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return _TimelineColumn(row: row);
                },
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Bottom tips
            Row(
              children: [
                const Icon(
                  Icons.task_alt_rounded,
                  color: Color(0xFF16A34A),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ventana óptima: menor viento y ráfagas más estables.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF475569),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineColumn extends StatelessWidget {
  const _TimelineColumn({required this.row});

  final ForecastRow row;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Status color
    final scoreColor = _indexColor(row.score);

    // Wind rotation arrow
    final angleRad = row.windDirectionDegrees != null
        ? (row.windDirectionDegrees! * math.pi / 180.0)
        : 0.0;

    final borderHighlightColor = const Color(
      0xFF22C55E,
    ); // Green highlight border

    return Container(
      width: 68,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: row.isBestWindow
            ? borderHighlightColor.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: row.isBestWindow ? borderHighlightColor : Colors.transparent,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Hour
          Text(
            row.hour,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),

          // Flight index score
          Text(
            '${row.score}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: scoreColor,
            ),
          ),

          // Wind Arrow + speed
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.rotate(
                angle: angleRad,
                child: const Icon(
                  Icons.navigation_rounded,
                  size: 13,
                  color: Color(0xFF0EA5E9),
                ),
              ),
              const SizedBox(width: 3),
              Text(
                _fmt(row.windKmh),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          // Gust speed
          Text(
            _fmt(row.gustKmh),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Color _indexColor(int score) {
    if (score >= 80) return const Color(0xFF16A34A);
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFDC2626);
  }
}

class _ProfileStrip extends StatelessWidget {
  const _ProfileStrip({required this.report});

  final FlightReadinessReport report;

  @override
  Widget build(BuildContext context) {
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
              children: [
                const Icon(Icons.flight_takeoff_rounded),
                const SizedBox(width: 12),
                Text(
                  'OPERACIÓN CONFIGURADA',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dron',
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: Colors.grey),
                      ),
                      Text(
                        report.droneProfile.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Misión',
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: Colors.grey),
                      ),
                      Text(
                        report.missionProfile.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Altitud',
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: Colors.grey),
                      ),
                      Text(
                        '${report.droneProfile.preferredAltitudeMeters} m',
                        style: const TextStyle(fontWeight: FontWeight.w800),
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

class _RealWeatherLoadingCard extends StatelessWidget {
  const _RealWeatherLoadingCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: EdgeInsets.zero,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Obteniendo clima real de Open-Meteo...',
                style: TextStyle(fontWeight: FontWeight.w800),
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
                const Expanded(
                  child: Text(
                    'No se pudo obtener clima real.',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Reintentar o volver a datos mock.'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
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
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Cargando datos de vuelo...',
            style: TextStyle(fontWeight: FontWeight.bold),
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

String _time(DateTime value) {
  return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

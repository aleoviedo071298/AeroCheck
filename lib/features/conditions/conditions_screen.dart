import 'package:flutter/material.dart';

import '../../app/weather_session.dart';
import '../../data/location/flight_location.dart';
import '../../data/weather/weather_bundle.dart';
import '../../domain/entities/flight_readiness_report.dart';
import '../../domain/entities/flight_rule_result.dart';
import '../../domain/entities/weather_snapshot.dart';
import '../../domain/rules/flight_readiness_status.dart';
import '../../domain/rules/rule_severity.dart';

class ConditionsScreen extends StatelessWidget {
  const ConditionsScreen({super.key, required this.session});

  final WeatherSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final report = session.currentReport;
        final weather = report?.weather;

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              if (report != null)
                _LocationHeader(
                  report: report,
                  subtitle: _subtitleFor(report.weather),
                )
              else
                const _LoadingHeader(),
              const SizedBox(height: 12),
              _LocationSelector(session: session),
              const SizedBox(height: 12),
              if (session.isLoadingReal)
                const _RealWeatherLoadingCard()
              else if (session.dataSource == WeatherDataSource.real &&
                  session.realError != null)
                _RealWeatherErrorCard(onRetry: session.loadRealWeather)
              else if (report != null && weather != null) ...[
                if (session.dataSource == WeatherDataSource.real) ...[
                  _ProviderCard(bundle: session.realBundle!),
                  const SizedBox(height: 12),
                ],
                _StatusPanel(report: report),
                const SizedBox(height: 12),
                _BestWindowCard(report: report),
                const SizedBox(height: 12),
                _ReasonList(rules: report.rules),
                const SizedBox(height: 12),
                _MetricGrid(metrics: _metricsFor(weather)),
                const SizedBox(height: 12),
                _ProfileStrip(report: report),
              ],
            ],
          ),
        );
      },
    );
  }

  List<_Metric> _metricsFor(WeatherSnapshot weather) {
    return [
      _Metric('Viento', '${_fmt(weather.windKmh)} km/h', Icons.air_rounded),
      _Metric('Rafagas', '${_fmt(weather.gustKmh)} km/h', Icons.speed_rounded),
      _Metric(
        'Variacion',
        '${_fmt((weather.gustKmh ?? 0) - (weather.windKmh ?? 0))} km/h',
        Icons.swap_vert_rounded,
      ),
      _Metric(
        'Temp.',
        '${_fmt(weather.temperatureC)} C',
        Icons.device_thermostat_rounded,
      ),
      _Metric(
        'Lluvia',
        '${_fmt(weather.precipitationProbability)}%',
        Icons.water_drop_rounded,
      ),
      _Metric(
        'Visibilidad',
        '${_fmt(weather.visibilityKm)} km',
        Icons.visibility_rounded,
      ),
      _Metric(
        'Nubes',
        weather.cloudBaseMeters == null
            ? 'No disp.'
            : '${_fmt(weather.cloudBaseMeters)} m',
        Icons.cloud_rounded,
      ),
      _Metric(
        'Kp',
        weather.kpIndex == null ? 'No disp.' : _fmt(weather.kpIndex),
        Icons.sensors_rounded,
      ),
    ];
  }

  String _subtitleFor(WeatherSnapshot weather) {
    final time = _time(weather.time);
    return 'Open-Meteo - $time';
  }
}

class _LocationSelector extends StatefulWidget {
  const _LocationSelector({required this.session});

  final WeatherSession session;

  @override
  State<_LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<_LocationSelector> {
  late TextEditingController _searchController;
  Future<List<FlightLocation>>? _searchFuture;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterLocations(String query) {
    setState(() {
      _searchFuture = widget.session.searchCities(query);
    });
  }

  void _showAddLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                onChanged: _filterLocations,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                width: double.maxFinite,
                child: _searchFuture == null
                    ? const Center(child: Text('Escribe para buscar ciudades'))
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
                              final location = locations[index];
                              return ListTile(
                                key: ValueKey('search-location-${location.id}'),
                                title: Text(location.name),
                                subtitle: Text(
                                  '${location.region}, ${location.country}',
                                ),
                                trailing: const Icon(Icons.add_circle_outline),
                                onTap: () {
                                  widget.session.addFavoriteLocation(location);
                                  Navigator.pop(context);
                                  _searchController.clear();
                                  setState(() {
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ubicación',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      key: const ValueKey('gps-location-button'),
                      icon: const Icon(Icons.my_location_rounded),
                      iconSize: 20,
                      tooltip: 'Mi ubicación (GPS)',
                      onPressed: () => widget.session.setLocationToCurrentGPS(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...widget.session.availableLocations.map((location) {
                      final isSelected =
                          location.id == widget.session.selectedLocation.id;
                      return ChoiceChip(
                        key: ValueKey('location-chip-${location.id}'),
                        label: Text(location.name),
                        selected: isSelected,
                        onSelected: (_) => widget.session.setLocation(location),
                      );
                    }),
                    ActionChip(
                      key: const ValueKey('add-location-button'),
                      label: const Text('Agregar'),
                      avatar: const Icon(Icons.add, size: 18),
                      onPressed: _showAddLocationDialog,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LoadingHeader extends StatelessWidget {
  const _LoadingHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(width: 44, height: 44),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Comodoro Rivadavia, Chubut',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _LocationHeader extends StatelessWidget {
  const _LocationHeader({required this.report, required this.subtitle});

  final FlightReadinessReport report;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.near_me_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report.weather.locationLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(subtitle, style: textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _RealWeatherLoadingCard extends StatelessWidget {
  const _RealWeatherLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
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
    return Card(
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

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.bundle});

  final WeatherBundle bundle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.cloud_sync_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          'Clima real | ${bundle.providerName}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${bundle.locationLabel} | Actualizado ${_time(bundle.current.time)}',
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.report});

  final FlightReadinessReport report;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(report.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.status.label,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        report.summary,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                _ScoreDial(score: report.score, color: color),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: report.score / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreDial extends StatelessWidget {
  const _ScoreDial({required this.score, required this.color});

  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 74,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 6),
      ),
      child: Text(
        '$score',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _BestWindowCard extends StatelessWidget {
  const _BestWindowCard({required this.report});

  final FlightReadinessReport report;

  @override
  Widget build(BuildContext context) {
    final window = report.bestWindow;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.wb_sunny_rounded, color: Color(0xFFF59E0B)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mejor ventana',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${_time(window.start)} - ${_time(window.end)} | ${window.summary}',
                    style: Theme.of(context).textTheme.bodyMedium,
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

class _ReasonList extends StatelessWidget {
  const _ReasonList({required this.rules});

  final List<FlightRuleResult> rules;

  @override
  Widget build(BuildContext context) {
    final activeRules = rules
        .where((rule) => rule.severity != RuleSeverity.ok)
        .toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Motivos',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            if (activeRules.isEmpty)
              const Text('No hay alertas para esta ventana.')
            else
              ...activeRules.map((rule) => _ReasonTile(rule: rule)),
          ],
        ),
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({required this.rule});

  final FlightRuleResult rule;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(rule.severity);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_severityIcon(rule.severity), color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(rule.details),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_Metric> metrics;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.72,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(metric.icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        metric.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        metric.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileStrip extends StatelessWidget {
  const _ProfileStrip({required this.report});

  final FlightReadinessReport report;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.flight_takeoff_rounded),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${report.droneProfile.name} | ${report.missionProfile.name} | ${report.droneProfile.preferredAltitudeMeters} m',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
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

IconData _severityIcon(RuleSeverity severity) {
  return switch (severity) {
    RuleSeverity.ok => Icons.check_circle_rounded,
    RuleSeverity.warning => Icons.warning_rounded,
    RuleSeverity.blocked => Icons.cancel_rounded,
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

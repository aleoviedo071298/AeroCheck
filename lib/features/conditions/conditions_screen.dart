import 'package:flutter/material.dart';

import '../../data/mock/mock_flight_data.dart';
import '../../data/weather/open_meteo_weather_repository.dart';
import '../../data/weather/weather_bundle.dart';
import '../../data/weather/weather_repository.dart';
import '../../domain/entities/flight_readiness_report.dart';
import '../../domain/entities/flight_rule_result.dart';
import '../../domain/entities/flight_window_recommendation.dart';
import '../../domain/entities/weather_snapshot.dart';
import '../../domain/rules/flight_readiness_evaluator.dart';
import '../../domain/rules/flight_readiness_status.dart';
import '../../domain/rules/rule_severity.dart';

enum _ConditionsDataSource { mock, real }

class ConditionsScreen extends StatefulWidget {
  const ConditionsScreen({super.key, WeatherRepository? weatherRepository})
    : _weatherRepository = weatherRepository;

  final WeatherRepository? _weatherRepository;

  @override
  State<ConditionsScreen> createState() => _ConditionsScreenState();
}

class _ConditionsScreenState extends State<ConditionsScreen> {
  static const _realLatitude = -45.8641;
  static const _realLongitude = -67.4966;
  static const _realLocationLabel = 'Comodoro Rivadavia, Chubut';

  WeatherRepository? _weatherRepository;
  final _evaluator = const FlightReadinessEvaluator();

  var _dataSource = _ConditionsDataSource.mock;
  var _scenario = MockFlightScenario.cautionWind;
  WeatherBundle? _realBundle;
  Object? _realError;
  var _isLoadingReal = false;

  @override
  Widget build(BuildContext context) {
    final report = _reportForCurrentSource();
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
          _DataSourceSelector(
            selected: _dataSource,
            onChanged: _onDataSourceChanged,
          ),
          const SizedBox(height: 12),
          if (_dataSource == _ConditionsDataSource.mock) ...[
            _ScenarioSelector(
              selected: _scenario,
              onChanged: (scenario) => setState(() => _scenario = scenario),
            ),
            const SizedBox(height: 12),
          ],
          if (_dataSource == _ConditionsDataSource.real && _isLoadingReal)
            const _RealWeatherLoadingCard()
          else if (_dataSource == _ConditionsDataSource.real &&
              _realError != null)
            _RealWeatherErrorCard(onRetry: _loadRealWeather)
          else if (report != null && weather != null) ...[
            if (_dataSource == _ConditionsDataSource.real) ...[
              _ProviderCard(bundle: _realBundle!),
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
  }

  FlightReadinessReport? _reportForCurrentSource() {
    if (_dataSource == _ConditionsDataSource.mock) {
      return MockFlightData.reportFor(_scenario);
    }

    final bundle = _realBundle;
    if (bundle == null) {
      return null;
    }

    return _evaluator.evaluate(
      weather: bundle.current,
      droneProfile: MockFlightData.droneProfile,
      missionProfile: MockFlightData.missionProfile,
      bestWindow: _bestWindowFor(bundle.hourlySnapshots),
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
    if (_dataSource == _ConditionsDataSource.real) {
      return 'Open-Meteo - $time';
    }
    return 'Mock operativo - $time';
  }

  void _onDataSourceChanged(_ConditionsDataSource source) {
    setState(() => _dataSource = source);
    if (source == _ConditionsDataSource.real &&
        _realBundle == null &&
        !_isLoadingReal) {
      _loadRealWeather();
    }
  }

  Future<void> _loadRealWeather() async {
    setState(() {
      _isLoadingReal = true;
      _realError = null;
    });

    try {
      final repository = _weatherRepository ??=
          widget._weatherRepository ?? OpenMeteoWeatherRepository();
      final bundle = await repository.fetchWeather(
        latitude: _realLatitude,
        longitude: _realLongitude,
        locationLabel: _realLocationLabel,
      );
      if (!mounted) return;
      setState(() {
        _realBundle = bundle;
        _isLoadingReal = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _realError = error;
        _isLoadingReal = false;
      });
    }
  }

  FlightWindowRecommendation _bestWindowFor(List<WeatherSnapshot> hourly) {
    if (hourly.isEmpty) {
      return MockFlightData.bestWindow;
    }

    FlightReadinessReport? bestReport;
    for (final snapshot in hourly.take(24)) {
      final report = _evaluator.evaluate(
        weather: snapshot,
        droneProfile: MockFlightData.droneProfile,
        missionProfile: MockFlightData.missionProfile,
        bestWindow: MockFlightData.bestWindow,
      );
      if (bestReport == null || report.score > bestReport.score) {
        bestReport = report;
      }
    }

    final bestWeather = bestReport?.weather ?? hourly.first;
    return FlightWindowRecommendation(
      start: bestWeather.time,
      end: bestWeather.time.add(const Duration(hours: 1)),
      score: bestReport?.score ?? 0,
      status: bestReport?.status ?? FlightReadinessStatus.caution,
      summary: 'Mejor hora real estimada por clima disponible.',
    );
  }
}

class _DataSourceSelector extends StatelessWidget {
  const _DataSourceSelector({required this.selected, required this.onChanged});

  final _ConditionsDataSource selected;
  final ValueChanged<_ConditionsDataSource> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SegmentedButton<_ConditionsDataSource>(
          showSelectedIcon: false,
          selected: {selected},
          onSelectionChanged: (selection) => onChanged(selection.first),
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            textStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ),
          segments: const [
            ButtonSegment(
              value: _ConditionsDataSource.mock,
              label: Text('Mock'),
            ),
            ButtonSegment(
              value: _ConditionsDataSource.real,
              label: Text('Clima real'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScenarioSelector extends StatelessWidget {
  const _ScenarioSelector({required this.selected, required this.onChanged});

  final MockFlightScenario selected;
  final ValueChanged<MockFlightScenario> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SegmentedButton<MockFlightScenario>(
          showSelectedIcon: false,
          selected: {selected},
          onSelectionChanged: (selection) => onChanged(selection.first),
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            textStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ),
          segments: MockFlightScenario.values
              .map(
                (scenario) =>
                    ButtonSegment(value: scenario, label: Text(scenario.label)),
              )
              .toList(),
        ),
      ),
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              Icons.cloud_sync_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Clima real | ${bundle.providerName} | ${bundle.timezone}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
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

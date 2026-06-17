import 'package:flutter/material.dart';

import '../../app/weather_session.dart';
import '../../data/mock/mock_flight_data.dart';
import '../../domain/rules/rule_severity.dart';

class ForecastScreen extends StatelessWidget {
  const ForecastScreen({super.key, required this.session});

  final WeatherSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final rows = session.forecastRows;
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Forecast horario',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(_descriptionFor(session)),
              const SizedBox(height: 16),
              ...rows.map((row) => _ForecastRowCard(row: row)),
            ],
          ),
        );
      },
    );
  }

  String _descriptionFor(WeatherSession session) {
    if (session.dataSource == WeatherDataSource.real &&
        session.realBundle != null) {
      return '${session.selectedLocation.label} - clima real de Open-Meteo evaluado con AeroCheck.';
    }
    if (session.dataSource == WeatherDataSource.real && session.isLoadingReal) {
      return 'Cargando clima real para el forecast.';
    }
    return '${session.selectedLocation.label} - datos mock para validar la lectura del MVP.';
  }
}

class _ForecastRowCard extends StatelessWidget {
  const _ForecastRowCard({required this.row});

  final ForecastRow row;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        key: ValueKey('forecast-row-${row.hour}'),
        tilePadding: const EdgeInsets.fromLTRB(14, 2, 8, 2),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: _ForecastRowSummary(row: row),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 10),
          ...row.reasons.map((reason) => _ForecastReasonLine(reason: reason)),
        ],
      ),
    );
  }
}

class _ForecastRowSummary extends StatelessWidget {
  const _ForecastRowSummary({required this.row});

  final ForecastRow row;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 54,
          child: Text(
            row.hour,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.status,
                style: TextStyle(
                  color: _statusColor(row.status),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                row.primaryReason,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.72),
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 96,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_fmt(row.windKmh)} / ${_fmt(row.gustKmh)} km/h',
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                '${_fmt(row.rainPercent)}% lluvia',
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ForecastReasonLine extends StatelessWidget {
  const _ForecastReasonLine({required this.reason});

  final ForecastReason reason;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(reason.severity);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reason.title,
                  style: TextStyle(fontWeight: FontWeight.w800, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  reason.details,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.72),
                    height: 1.2,
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

Color _statusColor(String status) {
  if (status == 'APTO') return const Color(0xFF16A34A);
  if (status == 'PRECAUCION') return const Color(0xFFF59E0B);
  return const Color(0xFFDC2626);
}

Color _severityColor(RuleSeverity severity) {
  return switch (severity) {
    RuleSeverity.ok => const Color(0xFF16A34A),
    RuleSeverity.warning => const Color(0xFFF59E0B),
    RuleSeverity.blocked => const Color(0xFFDC2626),
  };
}

String _fmt(num value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}

import 'package:flutter/material.dart';

import '../../app/weather_session.dart';
import '../../data/mock/mock_flight_data.dart';
import '../../domain/rules/wind_profile_evaluator.dart';

class WindScreen extends StatelessWidget {
  const WindScreen({super.key, required this.session});

  final WeatherSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final rows = session.windProfileRows;
        final evaluator = WindProfileEvaluator(
          droneProfile: MockFlightData.droneProfile,
          missionProfile: MockFlightData.missionProfile,
        );

        final evaluatedRows = evaluator.evaluateProfile(rows);
        final bestWindRow = evaluator.findBestWindAltitude(rows);
        final targetAltitude =
            '${MockFlightData.droneProfile.preferredAltitudeMeters} m';

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Perfil vertical',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(_descriptionFor(session)),
              const SizedBox(height: 16),
              _WindStats(
                bestWindAltitude: bestWindRow.altitude,
                targetAltitude: targetAltitude,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      const _WindHeader(),
                      const Divider(),
                      ...evaluatedRows.map(
                        (row) => _WindRow(
                          row: row,
                          isTarget: row.altitude == targetAltitude,
                          isBestWind: row.altitude == bestWindRow.altitude,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _descriptionFor(WeatherSession session) {
    if (session.dataSource == WeatherDataSource.real &&
        session.realBundle != null) {
      return '${session.selectedLocation.label} - perfil real aproximado con niveles 10, 80, 120 y 180 m.';
    }
    if (session.dataSource == WeatherDataSource.real && session.isLoadingReal) {
      return 'Cargando perfil vertical real.';
    }
    return '${session.selectedLocation.label} - viento y rafagas por altura AGL para el perfil seleccionado.';
  }
}

class _WindHeader extends StatelessWidget {
  const _WindHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Text('Altura', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
        Expanded(
          child: Text('Viento', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
        Expanded(
          child: Text('Rafaga', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
        Expanded(
          child: Text('Temp.', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }
}

class _WindRow extends StatelessWidget {
  const _WindRow({
    required this.row,
    this.isTarget = false,
    this.isBestWind = false,
  });

  final EvaluatedWindProfileRow row;
  final bool isTarget;
  final bool isBestWind;

  Color _statusColor(BuildContext context) {
    return switch (row.status) {
      'ok' => Colors.green.shade700,
      'warning' => Colors.orange.shade700,
      'blocked' => Colors.red.shade700,
      _ => Colors.grey.shade700,
    };
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isTarget
        ? Colors.blue.withValues(alpha: 0.1)
        : isBestWind
        ? Colors.green.withValues(alpha: 0.08)
        : null;

    return Container(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.altitude,
                    style: TextStyle(
                      fontWeight: isTarget || isBestWind
                          ? FontWeight.w800
                          : FontWeight.normal,
                    ),
                  ),
                  if (isTarget)
                    const Text(
                      'Objetivo',
                      style: TextStyle(fontSize: 11, color: Colors.blue),
                    )
                  else if (isBestWind)
                    const Text(
                      'Mejor viento',
                      style: TextStyle(fontSize: 11, color: Colors.green),
                    ),
                ],
              ),
            ),
            Expanded(child: Text('${_fmt(row.windKmh)} km/h')),
            Expanded(child: Text('${_fmt(row.gustKmh)} km/h')),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: Text('${_fmt(row.temperatureC)} C')),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _statusColor(context),
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

class _WindStats extends StatelessWidget {
  const _WindStats({
    required this.bestWindAltitude,
    required this.targetAltitude,
  });

  final String bestWindAltitude;
  final String targetAltitude;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Altitud objetivo',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    targetAltitude,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mejor viento',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bestWindAltitude,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _fmt(num value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}

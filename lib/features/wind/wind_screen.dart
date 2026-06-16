import 'package:flutter/material.dart';

import '../../app/weather_session.dart';
import '../../data/mock/mock_flight_data.dart';

class WindScreen extends StatelessWidget {
  const WindScreen({super.key, required this.session});

  final WeatherSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final rows = session.windProfileRows;
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      const _WindHeader(),
                      const Divider(),
                      ...rows.map((row) => _WindRow(row: row)),
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
      return 'Perfil real aproximado con niveles 10, 80, 120 y 180 m de Open-Meteo.';
    }
    if (session.dataSource == WeatherDataSource.real && session.isLoadingReal) {
      return 'Cargando perfil vertical real.';
    }
    return 'Viento y rafagas por altura AGL para el perfil seleccionado.';
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
  const _WindRow({required this.row});

  final WindProfileRow row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(row.altitude)),
          Expanded(child: Text('${_fmt(row.windKmh)} km/h')),
          Expanded(child: Text('${_fmt(row.gustKmh)} km/h')),
          Expanded(child: Text('${_fmt(row.temperatureC)} C')),
        ],
      ),
    );
  }
}

String _fmt(num value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}

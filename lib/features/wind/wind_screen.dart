import 'package:flutter/material.dart';

import '../../data/mock/mock_flight_data.dart';

class WindScreen extends StatelessWidget {
  const WindScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = MockFlightData.windProfileRows();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Perfil vertical',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Viento y rafagas por altura AGL para el perfil seleccionado.',
          ),
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

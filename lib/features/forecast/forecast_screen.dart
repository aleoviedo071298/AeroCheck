import 'package:flutter/material.dart';

import '../../data/mock/mock_flight_data.dart';

class ForecastScreen extends StatelessWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = MockFlightData.forecastRows();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Forecast horario',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Datos mock para validar la lectura del MVP antes de conectar proveedores.',
          ),
          const SizedBox(height: 16),
          ...rows.map((row) => _ForecastRowCard(row: row)),
        ],
      ),
    );
  }
}

class _ForecastRowCard extends StatelessWidget {
  const _ForecastRowCard({required this.row});

  final ForecastRow row;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox(
              width: 54,
              child: Text(
                row.hour,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            Expanded(
              child: Text(
                row.status,
                style: TextStyle(
                  color: _statusColor(row.status),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text('${_fmt(row.windKmh)} / ${_fmt(row.gustKmh)} km/h'),
            const SizedBox(width: 12),
            Text('${_fmt(row.rainPercent)}%'),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(String status) {
  if (status == 'APTO') return const Color(0xFF16A34A);
  if (status == 'PRECAUCION') return const Color(0xFFF59E0B);
  return const Color(0xFFDC2626);
}

String _fmt(num value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}

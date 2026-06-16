import 'package:flutter/material.dart';

import '../../data/mock/mock_flight_data.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final drone = MockFlightData.droneProfile;
    final mission = MockFlightData.missionProfile;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Ajustes MVP',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Configuracion mock para validar umbrales antes de persistencia real.',
          ),
          const SizedBox(height: 16),
          _SettingCard(
            icon: Icons.flight_takeoff_rounded,
            title: 'Perfil de dron',
            value:
                '${drone.name} | viento ${drone.maxWindKmh.toStringAsFixed(0)} km/h | rafagas ${drone.maxGustKmh.toStringAsFixed(0)} km/h',
          ),
          _SettingCard(
            icon: Icons.camera_alt_rounded,
            title: 'Mision',
            value:
                '${mission.name} | modificador viento ${(mission.windModifier * 100).toStringAsFixed(0)}%',
          ),
          const _SettingCard(
            icon: Icons.straighten_rounded,
            title: 'Unidades',
            value: 'Metrico: km/h, m, C',
          ),
          const _SettingCard(
            icon: Icons.notifications_active_rounded,
            title: 'Alertas',
            value: 'Proxima fase: avisos por ventana apta.',
          ),
        ],
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(value),
      ),
    );
  }
}

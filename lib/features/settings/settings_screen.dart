import 'package:flutter/material.dart';

import '../../app/weather_session.dart';
import '../../data/location/flight_location.dart';
import '../../data/mock/mock_flight_data.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.session});

  final WeatherSession session;

  @override
  Widget build(BuildContext context) {
    final drone = MockFlightData.droneProfile;
    final mission = MockFlightData.missionProfile;

    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Ajustes MVP',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Configuracion local para validar la experiencia antes de perfiles editables.',
              ),
              const SizedBox(height: 16),
              _SettingCard(
                icon: Icons.location_on_rounded,
                title: 'Ubicacion',
                value:
                    '${session.selectedLocation.label} | guardada localmente',
              ),
              _FavoriteLocationsCard(session: session),
              _SettingCard(
                icon: Icons.cloud_sync_rounded,
                title: 'Datos',
                value: session.dataSource == WeatherDataSource.real
                    ? 'Clima real | Open-Meteo'
                    : 'Datos mock | ${session.mockScenario.label}',
              ),
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
      },
    );
  }
}

class _FavoriteLocationsCard extends StatelessWidget {
  const _FavoriteLocationsCard({required this.session});

  final WeatherSession session;

  @override
  Widget build(BuildContext context) {
    final addableLocations = session.addableLocations;
    final canRemove = session.availableLocations.length > 1;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.star_rounded, color: colorScheme.primary),
              title: const Text(
                'Favoritos',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text('${session.availableLocations.length} guardadas'),
            ),
            const Divider(height: 1),
            ...session.availableLocations.map(
              (location) => ListTile(
                title: Text(
                  location.label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  location.id == session.selectedLocation.id
                      ? 'Ubicacion activa'
                      : '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                ),
                trailing: IconButton(
                  key: ValueKey('remove-favorite-${location.id}'),
                  tooltip: 'Quitar favorito',
                  onPressed: canRemove
                      ? () => session.removeFavoriteLocation(location)
                      : null,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _AddFavoriteControl(
                addableLocations: addableLocations,
                onAdd: session.addFavoriteLocation,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddFavoriteControl extends StatefulWidget {
  const _AddFavoriteControl({
    required this.addableLocations,
    required this.onAdd,
  });

  final List<FlightLocation> addableLocations;
  final ValueChanged<FlightLocation> onAdd;

  @override
  State<_AddFavoriteControl> createState() => _AddFavoriteControlState();
}

class _AddFavoriteControlState extends State<_AddFavoriteControl> {
  FlightLocation? _selectedLocation;

  @override
  void didUpdateWidget(_AddFavoriteControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedLocation != null &&
        !widget.addableLocations.any(
          (location) => location.id == _selectedLocation!.id,
        )) {
      _selectedLocation = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.addableLocations.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text('Catalogo MVP completo en favoritos.'),
      );
    }

    final selectedLocation = _selectedLocation ?? widget.addableLocations.first;

    return Row(
      children: [
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<FlightLocation>(
              key: const ValueKey('add-favorite-dropdown'),
              value: selectedLocation,
              isExpanded: true,
              items: widget.addableLocations
                  .map(
                    (location) => DropdownMenuItem(
                      value: location,
                      child: Text(location.label),
                    ),
                  )
                  .toList(),
              onChanged: (location) {
                setState(() => _selectedLocation = location);
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          key: const ValueKey('add-favorite-button'),
          onPressed: () {
            widget.onAdd(selectedLocation);
            setState(() => _selectedLocation = null);
          },
          icon: const Icon(Icons.add_location_alt_rounded),
          label: const Text('Agregar'),
        ),
      ],
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

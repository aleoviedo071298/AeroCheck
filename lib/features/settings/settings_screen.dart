import 'package:flutter/material.dart';

import '../../app/weather_session.dart';
import '../../data/location/flight_location.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.session});

  final WeatherSession session;

  @override
  Widget build(BuildContext context) {
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
              const _SettingCard(
                icon: Icons.cloud_sync_rounded,
                title: 'Datos',
                value: 'Clima real | Open-Meteo + OpenMeteo Geocoding',
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
              child: _LocationSearchControl(session: session),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationSearchControl extends StatefulWidget {
  const _LocationSearchControl({required this.session});

  final WeatherSession session;

  @override
  State<_LocationSearchControl> createState() => _LocationSearchControlState();
}

class _LocationSearchControlState extends State<_LocationSearchControl> {
  final _controller = TextEditingController();
  Future<List<FlightLocation>>? _searchFuture;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchFuture = widget.session.searchCities(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const ValueKey('location-search-field'),
          controller: _controller,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpiar búsqueda',
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _searchFuture = null;
                      });
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
            hintText: 'Buscar ciudad mundial',
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: _onSearchChanged,
        ),
        const SizedBox(height: 8),
        if (_searchFuture == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Escribe para buscar ciudades en el mundo'),
          )
        else
          FutureBuilder<List<FlightLocation>>(
            future: _searchFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final locations = snapshot.data ?? [];
              if (locations.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No se encontraron ciudades'),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: locations
                    .take(4)
                    .map(
                      (location) => _SearchResultTile(
                        location: location,
                        onAdd: () {
                          widget.session.addFavoriteLocation(location);
                          _controller.clear();
                          setState(() {
                            _searchFuture = null;
                          });
                        },
                      ),
                    )
                    .toList(),
              );
            },
          ),
      ],
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.location, required this.onAdd});

  final FlightLocation location;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        location.label,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(location.country),
      trailing: IconButton.filledTonal(
        key: ValueKey('add-favorite-${location.id}'),
        tooltip: 'Agregar favorito',
        onPressed: onAdd,
        icon: const Icon(Icons.add_location_alt_rounded),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        leading: Icon(icon, color: colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(value),
      ),
    );
  }
}

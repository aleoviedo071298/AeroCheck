import 'package:flutter/material.dart';

import '../../app/airspace_state.dart';
import '../../app/weather_session.dart';
import 'presentation/widgets/real_map_widget.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key, required this.session});

  final WeatherSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final location = session.selectedLocation;
        final guideRadiusKm = session.guideRadiusKm;
        final airspaceState = session.airspaceState;

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Mapa operativo',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${location.label} | ${_formatCoordinate(location.latitude)}, ${_formatCoordinate(location.longitude)}',
              ),
              const SizedBox(height: 12),
              _FavoriteLocationSelector(session: session),
              const SizedBox(height: 12),
              _GuideRadiusControl(session: session),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 0.82,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: RealMapWidget(
                    location: location,
                    guideRadiusKm: guideRadiusKm,
                    airspaceState: airspaceState,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _AirspaceLayerCard(state: airspaceState),
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'AeroCheck ayuda a planificar. El piloto debe validar normativa, permisos y restricciones oficiales antes de volar. Los espacios aéreos mostrados son informativos.',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GuideRadiusControl extends StatelessWidget {
  const _GuideRadiusControl({required this.session});

  final WeatherSession session;

  @override
  Widget build(BuildContext context) {
    final radius = session.guideRadiusKm;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.radar_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Radio guia',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  _formatRadius(radius),
                  key: const ValueKey('guide-radius-value'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            Slider(
              key: const ValueKey('guide-radius-slider'),
              value: radius,
              min: WeatherSession.minGuideRadiusKm,
              max: WeatherSession.maxGuideRadiusKm,
              divisions: 14,
              label: _formatRadius(radius),
              onChanged: session.setGuideRadiusKm,
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteLocationSelector extends StatelessWidget {
  const _FavoriteLocationSelector({required this.session});

  final WeatherSession session;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: session.availableLocations.map((location) {
        return ChoiceChip(
          key: ValueKey('map-location-${location.id}'),
          label: Text(location.name),
          selected: location.id == session.selectedLocation.id,
          onSelected: (_) => session.setLocation(location),
        );
      }).toList(),
    );
  }
}

String _formatCoordinate(double value) {
  return value.toStringAsFixed(4);
}

String _formatRadius(double value) {
  return '${value.toStringAsFixed(0)} km';
}

String _formatDistance(double value) {
  return '${value.toStringAsFixed(1)} km';
}

class _AirspaceLayerCard extends StatelessWidget {
  const _AirspaceLayerCard({required this.state});

  final AirspaceState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
        child: Column(
          children: [
            ListTile(
              leading: Icon(
                Icons.airplanemode_active_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text(
                'Espacios aéreos OpenAIP',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: const Text('Capa informativa, no oficial.'),
            ),
            if (state is AirspaceLoadingState)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: CircularProgressIndicator.adaptive(),
                ),
              )
            else if (state is AirspaceErrorState)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'No se pudo cargar espacios aéreos. Verifica tu conexión.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              )
            else if (state is AirspaceEmptyState)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'No hay espacios aéreos en el radio configurado.',
                  ),
                ),
              )
            else if (state is AirspaceLoadedState)
              ...(state as AirspaceLoadedState).airspaces.map(
                (airspace) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.cloud_rounded),
                  title: Text(
                    airspace.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${airspace.icaoClassLabel} | ${airspace.typeLabel}',
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Datos cortesía de OpenAIP. Verifica siempre con autoridades oficiales.',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

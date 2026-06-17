import 'package:flutter/material.dart';

import '../../app/airspace_state.dart';
import '../../app/weather_session.dart';
import '../../data/location/flight_location.dart';
import '../../data/mock/mock_sensitive_zone.dart';

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
        final detections = session.detectedMockSensitiveZones;
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        painter: _MapPlaceholderPainter(
                          location: location,
                          guideRadiusKm: guideRadiusKm,
                          detectedZoneCount: detections.length,
                        ),
                      ),
                      Center(
                        child: Container(
                          width: _circleSizeForRadius(guideRadiusKm),
                          height: _circleSizeForRadius(guideRadiusKm),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF22C55E),
                              width: 4,
                            ),
                            color: const Color(
                              0xFF22C55E,
                            ).withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      const Center(
                        child: Icon(
                          Icons.navigation_rounded,
                          size: 42,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: _LayerBadge(count: detections.length),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              '${location.label}\nRadio guia: ${_formatRadius(guideRadiusKm)} | Datos regulatorios no conectados',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _SensitiveZoneLayerCard(detections: detections),
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

class _LayerBadge extends StatelessWidget {
  const _LayerBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFF59E0B)
            : Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          active ? '$count zona mock' : 'Sin zonas mock',
          style: TextStyle(
            color: active ? Colors.black : Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SensitiveZoneLayerCard extends StatelessWidget {
  const _SensitiveZoneLayerCard({required this.detections});

  final List<MockSensitiveZoneDetection> detections;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
        child: Column(
          children: [
            ListTile(
              leading: Icon(
                Icons.warning_amber_rounded,
                color: detections.isEmpty
                    ? Theme.of(context).colorScheme.primary
                    : const Color(0xFFF59E0B),
              ),
              title: const Text(
                'Zonas sensibles mock',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: const Text('Capa local de prueba, no oficial.'),
            ),
            if (detections.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('No hay zonas mock dentro del radio guia.'),
                ),
              )
            else
              ...detections.map(
                (detection) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.place_rounded),
                  title: Text(
                    detection.zone.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    'Distancia aprox.: ${_formatDistance(detection.distanceKm)}',
                  ),
                ),
              ),
          ],
        ),
      ),
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

double _circleSizeForRadius(double radiusKm) {
  return 150 + ((radiusKm - WeatherSession.minGuideRadiusKm) * 8);
}

double _locationOffset(FlightLocation location, double fallback) {
  final normalized = (location.latitude.abs() + location.longitude.abs()) % 1;
  return fallback + (normalized - 0.5) * 0.18;
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

class _MapPlaceholderPainter extends CustomPainter {
  const _MapPlaceholderPainter({
    required this.location,
    required this.guideRadiusKm,
    required this.detectedZoneCount,
  });

  final FlightLocation location;
  final double guideRadiusKm;
  final int detectedZoneCount;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF10241F);
    canvas.drawRect(Offset.zero & size, bg);

    final land = Paint()..color = const Color(0xFF1F3D34);
    final road = Paint()
      ..color = const Color(0xFFCBD5E1).withValues(alpha: 0.35)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final warning = Paint()
      ..color =
          (detectedZoneCount > 0
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF22C55E))
              .withValues(alpha: detectedZoneCount > 0 ? 0.32 : 0.18);
    final water = Paint()
      ..color = const Color(0xFF0F2F3A).withValues(alpha: 0.58);

    final landPath = Path()
      ..moveTo(0, size.height * 0.15)
      ..lineTo(size.width * 0.75, 0)
      ..lineTo(size.width, size.height * 0.26)
      ..lineTo(size.width * 0.82, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(landPath, land);

    final waterPath = Path()
      ..moveTo(size.width * 0.78, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.86, size.height)
      ..lineTo(size.width * 0.94, size.height * 0.34)
      ..close();
    canvas.drawPath(waterPath, water);

    canvas.drawCircle(
      Offset(
        size.width * _locationOffset(location, 0.62),
        size.height * _locationOffset(location, 0.42),
      ),
      _circleSizeForRadius(guideRadiusKm) / 2,
      warning,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.72),
      Offset(size.width, size.height * 0.36),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.18, 0),
      Offset(size.width * 0.72, size.height),
      road,
    );
  }

  @override
  bool shouldRepaint(covariant _MapPlaceholderPainter oldDelegate) {
    return oldDelegate.location.id != location.id ||
        oldDelegate.guideRadiusKm != guideRadiusKm ||
        oldDelegate.detectedZoneCount != detectedZoneCount;
  }
}

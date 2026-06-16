import 'package:flutter/material.dart';

import '../../app/weather_session.dart';
import '../../data/location/flight_location.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key, required this.session});

  final WeatherSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final location = session.selectedLocation;

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
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 0.82,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(painter: _MapPlaceholderPainter(location)),
                      Center(
                        child: Container(
                          width: 210,
                          height: 210,
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
                              '${location.label}\nRadio guia: 5 km | Datos regulatorios no conectados',
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
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'AeroCheck ayuda a planificar. El piloto debe validar normativa, permisos y restricciones oficiales antes de volar.',
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

double _locationOffset(FlightLocation location, double fallback) {
  final normalized = (location.latitude.abs() + location.longitude.abs()) % 1;
  return fallback + (normalized - 0.5) * 0.18;
}

class _MapPlaceholderPainter extends CustomPainter {
  const _MapPlaceholderPainter(this.location);

  final FlightLocation location;

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
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.30);
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
      105,
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
    return oldDelegate.location.id != location.id;
  }
}

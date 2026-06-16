import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Mapa operativo',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Vista placeholder. Las capas oficiales se conectan en una fase posterior.',
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 0.82,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(painter: _MapPlaceholderPainter()),
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
                        color: const Color(0xFF22C55E).withValues(alpha: 0.08),
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
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Radio guia: 5 km | Datos regulatorios no conectados',
                          style: TextStyle(
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
  }
}

class _MapPlaceholderPainter extends CustomPainter {
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

    final landPath = Path()
      ..moveTo(0, size.height * 0.15)
      ..lineTo(size.width * 0.75, 0)
      ..lineTo(size.width, size.height * 0.26)
      ..lineTo(size.width * 0.82, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(landPath, land);

    canvas.drawCircle(
      Offset(size.width * 0.62, size.height * 0.42),
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

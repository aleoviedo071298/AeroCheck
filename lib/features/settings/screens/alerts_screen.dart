import 'package:flutter/material.dart';

import '../../../domain/i18n/app_strings.dart';
import '../../../domain/i18n/language.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key, required this.language});

  final Language language;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Text(
          AppStrings.get('alertas', language: language),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.schedule_rounded,
                        color: Color(0xFFF59E0B),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppStrings.get('proxima_fase', language: language)} ${AppStrings.get('avisos_ventana_apta', language: language)}',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.get(
                              'notificaciones_personalizadas',
                              language: language,
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppStrings.get('opciones_futuras', language: language),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        _AlertOption(
          icon: Icons.wb_sunny_rounded,
          title: AppStrings.get('ventana_apta_detectada', language: language),
          description: AppStrings.get(
            'notificacion_ventana_segura',
            language: language,
          ),
        ),
        const SizedBox(height: 8),
        _AlertOption(
          icon: Icons.wind_power_rounded,
          title: AppStrings.get('viento_fuerte', language: language),
          description: AppStrings.get(
            'alerta_viento_umbral',
            language: language,
          ),
        ),
        const SizedBox(height: 8),
        _AlertOption(
          icon: Icons.speed_rounded,
          title: AppStrings.get('rafagas_altas', language: language),
          description: AppStrings.get(
            'alerta_rafagas_limite',
            language: language,
          ),
        ),
        const SizedBox(height: 8),
        _AlertOption(
          icon: Icons.airplanemode_inactive_rounded,
          title: AppStrings.get('zona_restringida', language: language),
          description: AppStrings.get(
            'notificacion_espacio_controlado',
            language: language,
          ),
        ),
      ],
    );
  }
}

class _AlertOption extends StatelessWidget {
  const _AlertOption({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFF59E0B), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFFCBD5E1),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

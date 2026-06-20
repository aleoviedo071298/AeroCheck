import 'package:flutter/material.dart';

import '../../../app/weather_session.dart';
import '../../../domain/i18n/app_strings.dart';
import '../../../domain/i18n/language.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({
    super.key,
    required this.language,
    required this.session,
  });

  final Language language;
  final WeatherSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final prefs = session.preferences;
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
              child: SwitchListTile(
                title: Text(
                  AppStrings.get(
                    'avisos_ventana_apta_titulo',
                    language: language,
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                value: prefs.alertsEnabled,
                onChanged: (value) async {
                  if (value) {
                    final granted = await session.requestAlertPermission();
                    if (!granted) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppStrings.get(
                                'permiso_notif_denegado',
                                language: language,
                              ),
                            ),
                          ),
                        );
                      }
                      return;
                    }
                  }
                  await session.updateAlertPreferences(enabled: value);
                },
              ),
            ),
            if (prefs.alertsEnabled) ...[
              const SizedBox(height: 16),
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
                      Text(
                        AppStrings.get('anticipacion', language: language),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [15, 30, 60].map((value) {
                          final selected = prefs.alertLeadMinutes == value;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                '$value ${AppStrings.get('minutos_antes', language: language)}',
                              ),
                              selected: selected,
                              onSelected: (_) {
                                session.updateAlertPreferences(
                                  leadMinutes: value,
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              AppStrings.get('opciones_futuras', language: language),
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
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
      },
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

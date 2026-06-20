import 'package:flutter/material.dart';

class WeatherCondition {
  const WeatherCondition({required this.labelKey, required this.icon});

  final String labelKey;
  final IconData icon;
}

WeatherCondition weatherConditionFor(int? code) {
  if (code == null) {
    return const WeatherCondition(
      labelKey: 'sin_dato',
      icon: Icons.help_outline_rounded,
    );
  }
  if (code == 0 || code == 1) {
    return const WeatherCondition(
      labelKey: 'cielo_despejado',
      icon: Icons.wb_sunny_rounded,
    );
  }
  if (code == 2) {
    return const WeatherCondition(
      labelKey: 'cielo_parcial',
      icon: Icons.cloud_queue_rounded,
    );
  }
  if (code == 3) {
    return const WeatherCondition(
      labelKey: 'cielo_nublado',
      icon: Icons.cloud_rounded,
    );
  }
  if (code == 45 || code == 48) {
    return const WeatherCondition(labelKey: 'cielo_niebla', icon: Icons.foggy);
  }
  if (code >= 51 && code <= 57) {
    return const WeatherCondition(
      labelKey: 'cielo_llovizna',
      icon: Icons.grain_rounded,
    );
  }
  if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82)) {
    return const WeatherCondition(
      labelKey: 'cielo_lluvia',
      icon: Icons.water_drop_rounded,
    );
  }
  if ((code >= 71 && code <= 77) || code == 85 || code == 86) {
    return const WeatherCondition(
      labelKey: 'cielo_nieve',
      icon: Icons.ac_unit_rounded,
    );
  }
  if (code >= 95 && code <= 99) {
    return const WeatherCondition(
      labelKey: 'cielo_tormenta',
      icon: Icons.thunderstorm_rounded,
    );
  }
  return const WeatherCondition(
    labelKey: 'sin_dato',
    icon: Icons.help_outline_rounded,
  );
}

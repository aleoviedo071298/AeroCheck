class MissionProfile {
  const MissionProfile({
    required this.id,
    required this.name,
    required this.windModifier,
    required this.gustModifier,
    required this.description,
  });

  final String id;
  final String name;
  final double windModifier;
  final double gustModifier;
  final String description;

  static const recreational = MissionProfile(
    id: 'recreational',
    name: 'Recreativo',
    windModifier: 1,
    gustModifier: 1,
    description: 'Limites base para vuelos generales.',
  );

  static const photoVideo = MissionProfile(
    id: 'photo_video',
    name: 'Foto/video',
    windModifier: 0.85,
    gustModifier: 0.85,
    description: 'Condiciones mas suaves para tomas estables.',
  );

  static const inspection = MissionProfile(
    id: 'inspection',
    name: 'Inspeccion',
    windModifier: 0.90,
    gustModifier: 0.90,
    description: 'Mayor cautela cerca de estructuras.',
  );

  static const mapping = MissionProfile(
    id: 'mapping',
    name: 'Mapeo',
    windModifier: 0.80,
    gustModifier: 0.80,
    description: 'Prioriza viento estable y buena visibilidad.',
  );

  static const training = MissionProfile(
    id: 'training',
    name: 'Entrenamiento',
    windModifier: 0.75,
    gustModifier: 0.75,
    description: 'Limites conservadores para practica.',
  );
}

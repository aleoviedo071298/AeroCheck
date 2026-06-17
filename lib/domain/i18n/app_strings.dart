import 'language.dart';

class AppStrings {
  static const Map<String, Map<String, String>> _translations = {
    'es': {
      // Navigation
      'condiciones': 'Condiciones',
      'forecast': 'Forecast',
      'viento': 'Viento',
      'mapa': 'Mapa',
      'ajustes': 'Ajustes',

      // Settings
      'ajustes_mvp': 'Ajustes MVP',
      'config_local_mvp':
          'Configuración local para validar la experiencia antes de perfiles editables.',
      'ubicacion': 'Ubicación',
      'guardada_localmente': 'Guardada localmente',
      'favoritos': 'Favoritos',
      'guardadas': 'guardadas',
      'datos': 'Datos',
      'unidades': 'Unidades',
      'idioma': 'Idioma',
      'alertas': 'Alertas',

      // Data Sources Screen
      'fuentes_de_datos': 'Fuentes de datos',
      'clima': 'Clima',
      'fuente': 'Fuente:',
      'open_meteo': 'Open-Meteo',
      'uso': 'Uso:',
      'clima_uso':
          'temperatura, viento, ráfagas, humedad, nubosidad, visibilidad, precipitación y forecast horario.',
      'geocoding': 'Geocoding',
      'open_meteo_geocoding': 'Open-Meteo Geocoding',
      'geocoding_uso':
          'búsqueda de ciudades, coordenadas y ubicación seleccionada.',
      'espacios_aereos': 'Espacios aéreos',
      'openaip': 'OpenAIP',
      'espacios_uso':
          'visualización informativa de CTR, TMA, FIR y otras zonas cercanas.',
      'importante': 'Importante',
      'piloto_validar':
          'AeroCheck ayuda a planificar. El piloto siempre debe validar normativa, permisos, NOTAMs y restricciones oficiales antes de volar.',
      'ultima_actualizacion': 'Última actualización',
      'ubicacion_evaluada': 'Ubicación evaluada',
      'coordenadas_actuales': 'Coordenadas actuales',
      'fuente_meteorologica_activa': 'Fuente meteorológica activa',
      'fuente_espacios_activa': 'Fuente de espacios aéreos activa',

      // Units Screen
      'velocidad_viento': 'Velocidad de viento',
      'altura_altitud': 'Altura / altitud',
      'distancia_visibilidad': 'Distancia / visibilidad',
      'temperatura': 'Temperatura',
      'presion': 'Presión',
      'precipitacion': 'Precipitación',

      // Language Screen
      'seleccionar_idioma': 'Seleccionar idioma',

      // Alerts Screen
      'proxima_fase': 'Próxima fase:',
      'avisos_ventana_apta': 'avisos por ventana apta.',

      // Status & Rules
      'no_apto': 'No apto',
      'apto': 'Apto',
      'precaucion': 'Precaución',
      'mejora_ventana_disponible': 'Mejor ventana disponible',
      'proxima_ventana_disponible': 'Próxima ventana disponible',
      'razones_de_rechazo': 'Razones de rechazo',
      'sin_restricciones': 'Sin restricciones detectadas.',

      // Conditions
      'condiciones_actuales': 'Condiciones actuales',
      'operacion_configurada': 'Operación configurada',
      'aptitud': 'Aptitud',

      // Map
      'mapa_operativo': 'Mapa operativo',
      'radio_guia': 'Radio guía',
      'ubicacion_activa': 'Ubicación activa',

      // Forecast
      'forecast_horario': 'Forecast horario',

      // Wind
      'perfil_vertical': 'Perfil vertical',

      // Location Search
      'buscar_ciudad_mundial': 'Buscar ciudad mundial',

      // Common
      'sin_dato': 'Sin dato',
      'cerrar': 'Cerrar',
      'guardar': 'Guardar',
      'cancelar': 'Cancelar',
      'eliminar': 'Eliminar',
      'aceptar': 'Aceptar',
    },
    'en': {
      // Navigation
      'condiciones': 'Conditions',
      'forecast': 'Forecast',
      'viento': 'Wind',
      'mapa': 'Map',
      'ajustes': 'Settings',

      // Settings
      'ajustes_mvp': 'MVP Settings',
      'config_local_mvp':
          'Local configuration to validate the experience before editable profiles.',
      'ubicacion': 'Location',
      'guardada_localmente': 'Saved locally',
      'favoritos': 'Favorites',
      'guardadas': 'saved',
      'datos': 'Data',
      'unidades': 'Units',
      'idioma': 'Language',
      'alertas': 'Alerts',

      // Data Sources Screen
      'fuentes_de_datos': 'Data Sources',
      'clima': 'Weather',
      'fuente': 'Source:',
      'open_meteo': 'Open-Meteo',
      'uso': 'Usage:',
      'clima_uso':
          'temperature, wind, gusts, humidity, cloudiness, visibility, precipitation and hourly forecast.',
      'geocoding': 'Geocoding',
      'open_meteo_geocoding': 'Open-Meteo Geocoding',
      'geocoding_uso': 'city search, coordinates and selected location.',
      'espacios_aereos': 'Airspaces',
      'openaip': 'OpenAIP',
      'espacios_uso':
          'informational display of CTR, TMA, FIR and other nearby zones.',
      'importante': 'Important',
      'piloto_validar':
          'AeroCheck helps you plan. The pilot must always validate regulations, permissions, NOTAMs and official restrictions before flying.',
      'ultima_actualizacion': 'Last update',
      'ubicacion_evaluada': 'Location evaluated',
      'coordenadas_actuales': 'Current coordinates',
      'fuente_meteorologica_activa': 'Active weather source',
      'fuente_espacios_activa': 'Active airspace source',

      // Units Screen
      'velocidad_viento': 'Wind speed',
      'altura_altitud': 'Altitude',
      'distancia_visibilidad': 'Distance / visibility',
      'temperatura': 'Temperature',
      'presion': 'Pressure',
      'precipitacion': 'Precipitation',

      // Language Screen
      'seleccionar_idioma': 'Select language',

      // Alerts Screen
      'proxima_fase': 'Next phase:',
      'avisos_ventana_apta': 'alerts for suitable window.',

      // Status & Rules
      'no_apto': 'Not suitable',
      'apto': 'Suitable',
      'precaucion': 'Caution',
      'mejora_ventana_disponible': 'Best available window',
      'proxima_ventana_disponible': 'Next available window',
      'razones_de_rechazo': 'Rejection reasons',
      'sin_restricciones': 'No restrictions detected.',

      // Conditions
      'condiciones_actuales': 'Current conditions',
      'operacion_configurada': 'Configured operation',
      'aptitud': 'Aptitude',

      // Map
      'mapa_operativo': 'Operational map',
      'radio_guia': 'Guide radius',
      'ubicacion_activa': 'Active location',

      // Forecast
      'forecast_horario': 'Hourly forecast',

      // Wind
      'perfil_vertical': 'Vertical profile',

      // Location Search
      'buscar_ciudad_mundial': 'Search worldwide city',

      // Common
      'sin_dato': 'No data',
      'cerrar': 'Close',
      'guardar': 'Save',
      'cancelar': 'Cancel',
      'eliminar': 'Delete',
      'aceptar': 'Accept',
    },
  };

  static String get(String key, {Language language = Language.es}) {
    final langCode = language.code;
    return _translations[langCode]?[key] ?? _translations['es']?[key] ?? key;
  }
}

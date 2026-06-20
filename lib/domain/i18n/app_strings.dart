import 'language.dart';

class AppStrings {
  static Language currentLanguage = Language.es;

  static const Map<String, Map<String, String>> _translations = {
    'es': {
      // Navigation
      'condiciones': 'Condiciones',
      'forecast': 'Forecast',
      'viento': 'Viento',
      'mapa': 'Mapa',
      'ajustes': 'Ajustes',

      // Settings
      'ajustes_mvp': 'Ajustes',
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
      'notificaciones_personalizadas':
          'Notificaciones personalizadas según tus preferencias.',
      'opciones_futuras': 'Opciones disponibles en futuras versiones:',
      'ventana_apta_detectada': 'Ventana apta detectada',
      'notificacion_ventana_segura':
          'Notificación cuando aparezca una ventana segura',
      'viento_fuerte': 'Viento fuerte',
      'alerta_viento_umbral': 'Alerta cuando el viento supere tu umbral',
      'alerta_rafagas_limite': 'Alerta cuando las ráfagas excedan el límite',
      'zona_restringida': 'Zona restringida',
      'notificacion_espacio_controlado':
          'Notificación si entras en espacio aéreo controlado',
      'alerta_ventana_titulo': 'Ventana apta para volar',
      'avisos_ventana_apta_titulo': 'Avisos de ventana apta',
      'anticipacion': 'Anticipación',
      'minutos_antes': 'min antes',
      'permiso_notif_denegado': 'Permiso de notificaciones denegado',

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
      'radio_guia': 'Radio de vuelo',
      'ubicacion_activa': 'Ubicación activa',

      // Forecast
      'forecast_horario': 'Forecast horario',
      'ir_a_mejor_hora': 'Ir a mejor hora',
      'ver_lista_completa': 'Ver lista completa por hora',
      'ocultar_lista': 'Ocultar lista',

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
      'estado': 'Estado',
      'actualizado': 'Actualizado',
      'refrescar_clima': 'Refrescar clima',
      'compartir': 'Compartir',
      'buscar': 'Buscar',
      'buscar_ciudad': 'Buscar ciudad',
      'escribe_nombre_ciudad': 'Escribe nombre de ciudad...',
      'escribe_buscar_ciudades': 'Escribe para buscar ciudades',
      'sin_resultados_ciudades': 'No se encontraron ciudades',
      'error': 'Error',
      'cambiar_ubicacion': 'Cambiar ubicación',
      'mi_ubicacion_gps': 'Mi ubicación (GPS)',
      'clima_real': 'Clima real',
      'clima_simulado': 'Clima simulado (Mock)',
      'datos_mock': 'datos mock',
      'evaluado_aerocheck': 'evaluado con AeroCheck',
      'ventana_seleccionada': 'Horario óptimo',
      'mejor_hora': 'Mejor hora',
      'horas': 'horas',
      'lluvia_en_ventana': 'Lluvia en ventana',
      'hora': 'Hora',
      'estado_operativo': 'Estado operativo',
      'razon_principal': 'Razón principal',
      'rafagas': 'Ráfagas',
      'lluvia': 'Lluvia',
      'sin_rafagas': 'Sin ráfagas',
      'con_lluvia': 'Con lluvia',
      'sin_lluvia': 'Sin lluvia',
      'altitud_objetivo': 'Altitud objetivo',
      'nivel_seleccionado': 'Nivel seleccionado',
      'mejor_viento': 'Mejor viento',
      'viento_mas_favorable': 'Viento más favorable',
      'altitud': 'Altitud',
      'rafaga': 'Ráfaga',
      'temp': 'Temp.',
      'nivel': 'Nivel',
      'objetivo': 'Objetivo',
      'mejor': 'Mejor',
      'sensacion': 'Sensación',
      'direccion_viento': 'Dirección del viento',
      'origen_viento': 'Origen del viento',
      'picos_instantaneos': 'Picos instantáneos',
      'evaluacion_nivel': 'Evaluación del nivel',
      'perfil_vertical_viento': 'Perfil vertical de viento',
      'reintentar': 'Reintentar',
      'reintentar_mock': 'Reintentar o volver a datos mock.',
      'cargando_datos': 'Cargando datos de vuelo...',
      'suelo': 'Suelo',
      'desfavorable': 'Desfavorable',
      'favorable': 'Favorable',
      'mas_favorable': 'Más favorable',
      'viento_alto': 'Viento alto',
      'viento_elevado': 'Viento elevado',
      'rafagas_altas': 'Ráfagas altas',
      'rafagas_elevadas': 'Ráfagas elevadas',
      'viento_estable': 'Viento estable',
      'ventana_optima_tip':
          'Ventana óptima: menor viento y ráfagas más estables.',
      'perfil_real_descripcion':
          'Perfil real aproximado con niveles 10, 80, 120 y 180 m.',
      'perfil_mock_descripcion':
          'Viento y ráfagas por altura AGL para el perfil seleccionado.',
      'perfil_info':
          'Evalúa la velocidad y ráfagas del viento a diferentes altitudes AGL para determinar la capa más segura de vuelo.',
      'entendido': 'Entendido',
      'una_guardada': '1 guardada',
      'cambios_tiempo_real': 'Los cambios se aplican en tiempo real.',
      'limpiar_busqueda': 'Limpiar búsqueda',
      'usar_gps_actual': 'Usar GPS actual',
      'escribe_buscar_mundo': 'Escribe para buscar ciudades en el mundo',
      'agregar_favorito': 'Agregar favorito',
      'ubicacion_mapa': 'Ubicación',
      'usar_ubicacion_gps': 'Usar ubicación GPS actual',
      'buscar_otra_ciudad': 'Buscar otra ciudad...',
      'radio_vuelo': 'Radio de vuelo',
      'elevacion': 'Elevación',
      'activa': 'Activa',
      'no_activa': 'No activa',
      'espacios_openaip': 'Espacios aéreos OpenAIP',
      'capa_informativa': 'Capa informativa, no oficial.',
      'error_espacios':
          'No se pudo cargar espacios aéreos. Verifica tu conexión.',
      'sin_espacios': 'No hay espacios aéreos en el radio configurado.',
      'atribucion_openaip':
          'Datos cortesía de OpenAIP. Verifica siempre con autoridades oficiales.',
      'radio_explicacion':
          'El radio de vuelo indica distancias desde la ubicación seleccionada. Verifica las condiciones antes de operar.',
      'zonas_ctr': 'Zonas CTR',
      'indice_vuelo': 'Índice de vuelo',
      'indice_por_hora': 'Índice por hora',
      'recomendaciones_vuelo': 'Recomendaciones de vuelo',
      'humedad': 'Humedad',
      'punto_rocio': 'Punto de rocío',
      'nubosidad': 'Nubosidad',
      'visibilidad': 'Visibilidad',
      'indice_kp': 'Índice Kp',
      'precip': 'Precip.',
      'condicion': 'Condición',
      'indice_uv': 'Índice UV',
      'cielo_despejado': 'Despejado',
      'cielo_parcial': 'Parcial',
      'cielo_nublado': 'Nublado',
      'cielo_niebla': 'Niebla',
      'cielo_llovizna': 'Llovizna',
      'cielo_lluvia': 'Lluvia',
      'cielo_nieve': 'Nieve',
      'cielo_tormenta': 'Tormenta',

      'operacion_configurada_mayus': 'Operación configurada',
      'dron': 'Dron',
      'mision': 'Misión',
      'obteniendo_clima': 'Obteniendo clima real de Open-Meteo...',
      'error_clima': 'No se pudo obtener clima real.',
      'altitud_maxima': 'Altitud máxima',
      'categoria_abierta': 'Categoría Abierta',
      'sin_motivos_activos': 'Sin motivos activos para esta hora.',
      'condiciones_dentro_limites':
          'Condiciones principales dentro de tus límites.',
      'viento_bajo_buena_visibilidad':
          'Mejor ventana por viento bajo y buena visibilidad.',
      'mejor_hora_real_estimada':
          'Mejor hora real estimada por clima disponible.',

      // Flight Rules Screen
      'reglas_de_vuelo': 'Reglas de vuelo',
      'reglas_subtitulo':
          'Personalizá los umbrales que deciden APTO, PRECAUCIÓN y NO APTO.',
      'viento_sostenido': 'Viento sostenido',
      'dif_rafaga_viento': 'Diferencia ráfaga-viento',
      'prob_lluvia': 'Probabilidad de lluvia',
      'intensidad_lluvia': 'Intensidad de lluvia',
      'margen_base_nubes': 'Margen base de nubes',
      'temp_minima': 'Temperatura mínima',
      'temp_maxima': 'Temperatura máxima',
      'indice_kp_regla': 'Índice Kp (GPS)',
      'permitir_nocturno': 'Permitir vuelo nocturno',
      'visibilidad_nubes': 'Visibilidad y nubes',
      'ambientales': 'Ambientales',
      'operativas': 'Operativas',
      'bloqueo': 'Bloqueo',
      'restaurar_defaults': 'Restaurar valores por defecto',
      'aviso_no_oficial':
          'AeroCheck ayuda a planificar. No es autorización oficial de vuelo.',
    },
    'en': {
      // Navigation
      'condiciones': 'Conditions',
      'forecast': 'Forecast',
      'viento': 'Wind',
      'mapa': 'Map',
      'ajustes': 'Settings',

      // Settings
      'ajustes_mvp': 'Settings',
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
      'notificaciones_personalizadas':
          'Personalized notifications based on your preferences.',
      'opciones_futuras': 'Options available in future versions:',
      'ventana_apta_detectada': 'Suitable window detected',
      'notificacion_ventana_segura':
          'Notification when a safe window becomes available',
      'viento_fuerte': 'Strong wind',
      'alerta_viento_umbral': 'Alert when wind exceeds your threshold',
      'alerta_rafagas_limite': 'Alert when gusts exceed the limit',
      'zona_restringida': 'Restricted zone',
      'notificacion_espacio_controlado':
          'Notification when entering controlled airspace',
      'alerta_ventana_titulo': 'Suitable flight window',
      'avisos_ventana_apta_titulo': 'Suitable-window alerts',
      'anticipacion': 'Lead time',
      'minutos_antes': 'min before',
      'permiso_notif_denegado': 'Notification permission denied',

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
      'ir_a_mejor_hora': 'Go to best hour',
      'ver_lista_completa': 'See full hourly list',
      'ocultar_lista': 'Hide list',

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
      'estado': 'Status',
      'actualizado': 'Updated',
      'refrescar_clima': 'Refresh weather',
      'compartir': 'Share',
      'buscar': 'Search',
      'buscar_ciudad': 'Search city',
      'escribe_nombre_ciudad': 'Enter city name...',
      'escribe_buscar_ciudades': 'Type to search cities',
      'sin_resultados_ciudades': 'No cities found',
      'error': 'Error',
      'cambiar_ubicacion': 'Change location',
      'mi_ubicacion_gps': 'My location (GPS)',
      'clima_real': 'Real weather',
      'clima_simulado': 'Simulated weather (Mock)',
      'datos_mock': 'mock data',
      'evaluado_aerocheck': 'evaluated with AeroCheck',
      'ventana_seleccionada': 'Optimal schedule',
      'mejor_hora': 'Best hour',
      'horas': 'hours',
      'lluvia_en_ventana': 'Rain in window',
      'hora': 'Hour',
      'estado_operativo': 'Operational status',
      'razon_principal': 'Primary reason',
      'rafagas': 'Gusts',
      'lluvia': 'Rain',
      'sin_rafagas': 'No gusts',
      'con_lluvia': 'Rain expected',
      'sin_lluvia': 'No rain',
      'altitud_objetivo': 'Target altitude',
      'nivel_seleccionado': 'Selected level',
      'mejor_viento': 'Best wind',
      'viento_mas_favorable': 'Most favorable wind',
      'altitud': 'Altitude',
      'rafaga': 'Gust',
      'temp': 'Temp.',
      'nivel': 'Level',
      'objetivo': 'Target',
      'mejor': 'Best',
      'sensacion': 'Feels like',
      'direccion_viento': 'Wind direction',
      'origen_viento': 'Wind origin',
      'picos_instantaneos': 'Instant peaks',
      'evaluacion_nivel': 'Level evaluation',
      'perfil_vertical_viento': 'Vertical wind profile',
      'reintentar': 'Retry',
      'reintentar_mock': 'Retry or return to mock data.',
      'cargando_datos': 'Loading flight data...',
      'suelo': 'Ground',
      'desfavorable': 'Unfavorable',
      'favorable': 'Favorable',
      'mas_favorable': 'Most favorable',
      'viento_alto': 'High wind',
      'viento_elevado': 'Elevated wind',
      'rafagas_altas': 'High gusts',
      'rafagas_elevadas': 'Elevated gusts',
      'viento_estable': 'Stable wind',
      'ventana_optima_tip': 'Optimal window: lower wind and steadier gusts.',
      'perfil_real_descripcion':
          'Approximate real profile at 10, 80, 120 and 180 m levels.',
      'perfil_mock_descripcion':
          'Wind and gusts by AGL altitude for the selected profile.',
      'perfil_info':
          'Evaluates wind speed and gusts at different AGL altitudes to identify the safest flight layer.',
      'entendido': 'Got it',
      'una_guardada': '1 saved',
      'cambios_tiempo_real': 'Changes apply in real time.',
      'limpiar_busqueda': 'Clear search',
      'usar_gps_actual': 'Use current GPS',
      'escribe_buscar_mundo': 'Type to search cities worldwide',
      'agregar_favorito': 'Add favorite',
      'ubicacion_mapa': 'Location',
      'usar_ubicacion_gps': 'Use current GPS location',
      'buscar_otra_ciudad': 'Search another city...',
      'radio_vuelo': 'Flight radius',
      'elevacion': 'Elevation',
      'activa': 'Active',
      'no_activa': 'Inactive',
      'espacios_openaip': 'OpenAIP airspaces',
      'capa_informativa': 'Informational layer, not official.',
      'error_espacios': 'Airspaces could not be loaded. Check your connection.',
      'sin_espacios': 'No airspaces found within the configured radius.',
      'atribucion_openaip':
          'Data courtesy of OpenAIP. Always verify with official authorities.',
      'radio_explicacion':
          'The flight radius shows distances from the selected location. Verify conditions before operating.',
      'zonas_ctr': 'CTR zones',
      'indice_vuelo': 'Flight index',
      'indice_por_hora': 'Hourly index',
      'recomendaciones_vuelo': 'Flight recommendations',
      'humedad': 'Humidity',
      'punto_rocio': 'Dew point',
      'nubosidad': 'Cloud cover',
      'visibilidad': 'Visibility',
      'indice_kp': 'Kp index',
      'precip': 'Precip.',
      'condicion': 'Condition',
      'indice_uv': 'UV index',
      'cielo_despejado': 'Clear',
      'cielo_parcial': 'Partly cloudy',
      'cielo_nublado': 'Cloudy',
      'cielo_niebla': 'Fog',
      'cielo_llovizna': 'Drizzle',
      'cielo_lluvia': 'Rain',
      'cielo_nieve': 'Snow',
      'cielo_tormenta': 'Thunderstorm',

      'operacion_configurada_mayus': 'Configured operation',
      'dron': 'Drone',
      'mision': 'Mission',
      'obteniendo_clima': 'Fetching real weather from Open-Meteo...',
      'error_clima': 'Real weather could not be loaded.',
      'altitud_maxima': 'Maximum altitude',
      'categoria_abierta': 'Open Category',
      'sin_motivos_activos': 'No active reasons for this hour.',
      'condiciones_dentro_limites': 'Main conditions within your limits.',
      'viento_bajo_buena_visibilidad':
          'Best window due to low wind and good visibility.',
      'mejor_hora_real_estimada':
          'Best real hour estimated by available weather.',

      // Flight Rules Screen
      'reglas_de_vuelo': 'Flight rules',
      'reglas_subtitulo':
          'Customize the thresholds that decide SUITABLE, CAUTION and NOT SUITABLE.',
      'viento_sostenido': 'Sustained wind',
      'dif_rafaga_viento': 'Gust-wind spread',
      'prob_lluvia': 'Rain probability',
      'intensidad_lluvia': 'Rain intensity',
      'margen_base_nubes': 'Cloud base margin',
      'temp_minima': 'Minimum temperature',
      'temp_maxima': 'Maximum temperature',
      'indice_kp_regla': 'Kp index (GPS)',
      'permitir_nocturno': 'Allow night flight',
      'visibilidad_nubes': 'Visibility & clouds',
      'ambientales': 'Environmental',
      'operativas': 'Operational',
      'bloqueo': 'Block',
      'restaurar_defaults': 'Restore defaults',
      'aviso_no_oficial':
          'AeroCheck helps you plan. It is not official flight authorization.',
    },
  };

  static String get(String key, {Language? language}) {
    final langCode = (language ?? currentLanguage).code;
    return _translations[langCode]?[key] ?? _translations['es']?[key] ?? key;
  }
}

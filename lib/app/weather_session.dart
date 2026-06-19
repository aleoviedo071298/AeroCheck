import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../data/kp_index/noaa_kp_index_service.dart';
import '../data/location/flight_location.dart';
import '../data/location/geocoding_service.dart';
import '../data/location/geocoding_repository.dart';
import '../data/mock/mock_flight_data.dart';
import '../data/preferences/shared_preferences_user_preferences_store.dart';
import '../data/preferences/user_preferences.dart';
import '../data/preferences/user_preferences_store.dart';
import '../domain/i18n/language.dart';
import '../domain/units/unit_preferences.dart';
import '../data/regulatory/airport.dart';
import '../data/regulatory/airport_repository.dart';
import '../data/regulatory/airspace.dart';
import '../data/regulatory/airspace_repository.dart';
import '../data/regulatory/openaip_airport_repository.dart';
import '../data/regulatory/openaip_airspace_repository.dart';
import '../data/regulatory/openaip_config.dart';
import '../data/weather/open_meteo_weather_repository.dart';
import '../data/weather/weather_bundle.dart';
import '../data/weather/weather_repository.dart';
import '../domain/entities/flight_readiness_report.dart';
import '../domain/entities/flight_window_recommendation.dart';
import '../domain/entities/weather_snapshot.dart';
import '../domain/rules/flight_readiness_evaluator.dart';
import '../domain/rules/flight_readiness_status.dart';
import '../domain/rules/flight_rules_config.dart';
import '../domain/rules/rule_severity.dart';
import 'airspace_geom_helper.dart';
import 'airspace_state.dart';

enum WeatherDataSource { mock, real }

class WeatherSession extends ChangeNotifier {
  static const defaultGuideRadiusKm = 5.0;
  static const minGuideRadiusKm = 1.0;
  static const maxGuideRadiusKm = 15.0;
  static const regulatoryFetchRadiusKm = 30.0;

  // Default initial location: Comodoro Rivadavia, Argentina
  static const _defaultLocation = FlightLocation(
    id: 'comodoro-rivadavia',
    name: 'Comodoro Rivadavia',
    region: 'Chubut',
    country: 'Argentina',
    latitude: -45.8641,
    longitude: -67.4966,
  );

  WeatherSession({
    WeatherRepository? weatherRepository,
    UserPreferencesStore? preferencesStore,
    AirspaceRepository? airspaceRepository,
    AirportRepository? airportRepository,
    GeocodingService? geocodingService,
  }) : _weatherRepository = weatherRepository,
       _preferencesStore =
           preferencesStore ?? SharedPreferencesUserPreferencesStore(),
       _airspaceRepository =
           airspaceRepository ??
           (OpenAipConfig.apiKey.trim().isEmpty
               ? null
               : OpenAipAirspaceRepository()),
       _airportRepository =
           airportRepository ??
           (OpenAipConfig.apiKey.trim().isEmpty
               ? null
               : OpenAipAirportRepository()),
       _geocodingService = geocodingService ?? GeocodingRepository();

  WeatherRepository? _weatherRepository;
  final UserPreferencesStore _preferencesStore;
  final AirspaceRepository? _airspaceRepository;
  final AirportRepository? _airportRepository;
  final GeocodingService _geocodingService;
  final _evaluator = const FlightReadinessEvaluator();

  FlightLocation _selectedLocation = _defaultLocation;
  List<FlightLocation> _favoriteLocations = [_defaultLocation];
  WeatherDataSource _dataSource = WeatherDataSource.real;
  WeatherBundle? _realBundle;
  Object? _realError;
  var _isLoadingReal = false;
  var _guideRadiusKm = defaultGuideRadiusKm;
  AirspaceState _airspaceState = const AirspaceLoadingState();
  List<Airspace> _loadedAirspaces = [];
  List<Airport> _loadedAirports = [];
  UserPreferences _userPreferences = const UserPreferences();
  WeatherBundle? _cachedRowsBundle;
  List<ForecastRow>? _cachedRows;

  FlightLocation get selectedLocation => _selectedLocation;
  List<FlightLocation> get availableLocations => _favoriteLocations;
  WeatherDataSource get dataSource => _dataSource;
  WeatherBundle? get realBundle => _realBundle;
  Object? get realError => _realError;
  bool get isLoadingReal => _isLoadingReal;
  double get guideRadiusKm => _guideRadiusKm;
  AirspaceState get airspaceState => _airspaceState;
  UserPreferences get preferences => _userPreferences;

  FlightReadinessReport? get currentReport {
    final bundle = _realBundle;
    if (bundle == null) {
      return null;
    }

    return _evaluateWeather(
      _withOperationalContext(bundle.current),
      bestWindowFor(bundle.hourlySnapshots, referenceTime: bundle.current.time),
    );
  }

  List<ForecastRow> get forecastRows {
    final bundle = _realBundle;
    if (bundle == null) {
      return const [];
    }
    if (identical(bundle, _cachedRowsBundle) && _cachedRows != null) {
      return _cachedRows!;
    }
    final bestWindow = bestWindowFor(
      bundle.hourlySnapshots,
      referenceTime: bundle.current.time,
    );
    final now = bundle.current.time;
    final currentHour = DateTime(now.year, now.month, now.day, now.hour);
    final rows = bundle.hourlySnapshots
        .where((snapshot) => !snapshot.time.isBefore(currentHour))
        .map((snapshot) => _forecastRowFor(snapshot, bestWindow))
        .toList();
    _cachedRowsBundle = bundle;
    _cachedRows = rows;
    return rows;
  }

  void _invalidateForecastCache() {
    _cachedRowsBundle = null;
    _cachedRows = null;
  }

  List<WindProfileRow> get windProfileRows {
    if (_realBundle != null) {
      return _realBundle!.windProfileRows;
    }
    return [];
  }

  String get sourceLabel {
    if (_realBundle != null) {
      return 'Clima real | ${_realBundle!.providerName}';
    }
    return 'Cargando clima real...';
  }

  Future<List<FlightLocation>> searchCities(String query) async {
    return _geocodingService.searchCities(query);
  }

  Future<void> restorePreferences() async {
    try {
      final preferences = await _preferencesStore.load();
      _userPreferences = preferences;

      // Restore favorite locations from JSON
      final favorites = <FlightLocation>[];
      for (final json in preferences.favoriteLocationsJson) {
        try {
          favorites.add(FlightLocation.fromJson(json));
        } catch (_) {
          // Skip invalid JSON
        }
      }

      // If no favorites, use default
      if (favorites.isEmpty) {
        favorites.add(_defaultLocation);
      }

      // Try to restore selected location by ID
      FlightLocation? selectedLocation;
      if (preferences.selectedLocationId != null) {
        selectedLocation = favorites.firstWhere(
          (loc) => loc.id == preferences.selectedLocationId,
          orElse: () => favorites.first,
        );
      }

      _favoriteLocations = favorites;
      _selectedLocation = selectedLocation ?? favorites.first;

      if (preferences.guideRadiusKm != null) {
        _guideRadiusKm = _clampGuideRadius(preferences.guideRadiusKm!);
      }

      _dataSource = WeatherDataSource.real;

      notifyListeners();
      _loadNearbyAirspaces();

      await loadRealWeather();
    } catch (_) {
      // Preferences should never block the operational screen.
      _userPreferences = const UserPreferences();
      _dataSource = WeatherDataSource.real;
      _loadNearbyAirspaces();
      await loadRealWeather();
    }
  }

  void setGuideRadiusKm(double radiusKm) {
    final nextRadius = _clampGuideRadius(radiusKm);
    if (_guideRadiusKm == nextRadius) {
      return;
    }

    _guideRadiusKm = nextRadius;
    notifyListeners();
    _persistPreferences();
    _loadNearbyAirspaces();
  }

  Future<void> updateLanguage(Language language) async {
    if (_userPreferences.language == language) {
      return;
    }

    _userPreferences = _userPreferences.copyWith(language: language);
    await _preferencesStore.save(_userPreferences);
    notifyListeners();
  }

  Future<void> updateUnits(UnitPreferences units) async {
    if (_userPreferences.units == units) {
      return;
    }

    _userPreferences = _userPreferences.copyWith(units: units);
    await _preferencesStore.save(_userPreferences);
    notifyListeners();
  }

  Future<void> updateRulesConfig(FlightRulesConfig config) async {
    if (_userPreferences.rulesConfig == config) {
      return;
    }
    _userPreferences = _userPreferences.copyWith(rulesConfig: config);
    _invalidateForecastCache();
    await _preferencesStore.save(_userPreferences);
    notifyListeners();
  }

  void addFavoriteLocation(FlightLocation location) {
    if (_isFavoriteLocation(location.id)) {
      return;
    }

    _favoriteLocations = [..._favoriteLocations, location];
    notifyListeners();
    _persistPreferences();
  }

  void removeFavoriteLocation(FlightLocation location) {
    if (_favoriteLocations.length == 1 || !_isFavoriteLocation(location.id)) {
      return;
    }

    _favoriteLocations = _favoriteLocations
        .where((favorite) => favorite.id != location.id)
        .toList();
    final removedSelected = _selectedLocation.id == location.id;
    if (removedSelected) {
      _selectedLocation = _favoriteLocations.first;
      _realBundle = null;
      _realError = null;
    }

    notifyListeners();
    _persistPreferences();

    if (removedSelected && _dataSource == WeatherDataSource.real) {
      loadRealWeather();
    }
  }

  void setLocation(FlightLocation location) {
    if (_selectedLocation.id == location.id ||
        !_isFavoriteLocation(location.id)) {
      return;
    }

    _selectedLocation = location;
    _realBundle = null;
    _realError = null;
    notifyListeners();
    _persistPreferences();

    if (_dataSource == WeatherDataSource.real) {
      loadRealWeather();
    }
    _loadNearbyAirspaces();
  }

  void setDataSource(WeatherDataSource source) {
    if (_dataSource == WeatherDataSource.real) {
      return;
    }

    _dataSource = WeatherDataSource.real;
    notifyListeners();
    _persistPreferences();

    if (_realBundle == null && !_isLoadingReal) {
      loadRealWeather();
    }
  }

  Future<void> loadRealWeather() async {
    _isLoadingReal = true;
    _realError = null;
    notifyListeners();

    try {
      final repository = _weatherRepository ??= OpenMeteoWeatherRepository();
      var bundle = await repository.fetchWeather(
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
        locationLabel: _selectedLocation.label,
      );

      // Fetch current Kp index from NOAA
      final kpService = NoaaKpIndexService();
      final kpIndex = await kpService.fetchCurrentKpIndex();
      if (kpIndex != null) {
        bundle = bundle.copyWithKpIndex(kpIndex);
      }

      _realBundle = bundle;
      _isLoadingReal = false;
      notifyListeners();
    } catch (error) {
      _realError = error;
      _isLoadingReal = false;
      notifyListeners();
    }
  }

  FlightWindowRecommendation bestWindowFor(
    List<WeatherSnapshot> hourly, {
    DateTime? referenceTime,
  }) {
    if (hourly.isEmpty) {
      final now = referenceTime ?? DateTime.now();
      return FlightWindowRecommendation(
        start: now,
        end: now.add(const Duration(hours: 1)),
        score: 0,
        status: FlightReadinessStatus.notReady,
        summary: 'No hay datos de clima disponibles',
      );
    }

    final ref = referenceTime ?? DateTime.now();
    final currentHour = DateTime(ref.year, ref.month, ref.day, ref.hour);
    final futureHourly = hourly
        .where((s) => !s.time.isBefore(currentHour))
        .toList();
    final searchList = futureHourly.isNotEmpty ? futureHourly : hourly;

    final defaultWindow = FlightWindowRecommendation(
      start: searchList.first.time,
      end: searchList.first.time.add(const Duration(hours: 1)),
      score: 0,
      status: FlightReadinessStatus.caution,
      summary: 'Hora por defecto (esperando datos)',
    );

    FlightReadinessReport? bestReport;
    for (final snapshot in searchList.take(24)) {
      final weather = _withOperationalContext(snapshot);
      final report = _evaluator.evaluate(
        weather: weather,
        config: _userPreferences.rulesConfig,
        bestWindow: defaultWindow,
      );
      if (bestReport == null || report.score > bestReport.score) {
        bestReport = report;
      }
    }

    final bestWeather = bestReport?.weather ?? searchList.first;
    return FlightWindowRecommendation(
      start: bestWeather.time,
      end: bestWeather.time.add(const Duration(hours: 1)),
      score: bestReport?.score ?? 0,
      status: bestReport?.status ?? FlightReadinessStatus.caution,
      summary: 'Mejor hora real estimada por clima disponible.',
    );
  }

  FlightReadinessReport _evaluateWeather(
    WeatherSnapshot weather,
    FlightWindowRecommendation bestWindow,
  ) {
    return _evaluator.evaluate(
      weather: weather,
      config: _userPreferences.rulesConfig,
      bestWindow: bestWindow,
    );
  }

  WeatherSnapshot _withOperationalContext(WeatherSnapshot weather) {
    final isInsideOpenAip = _isInsideOpenAipAirspace();
    final isNearOpenAip = _isNearOpenAipAirspace();

    return weather.copyWith(
      locationLabel: _selectedLocation.label,
      isInsideRestrictedArea: weather.isInsideRestrictedArea || isInsideOpenAip,
      isNearRestrictedArea: weather.isNearRestrictedArea || isNearOpenAip,
    );
  }

  ForecastRow _forecastRowFor(
    WeatherSnapshot snapshot,
    FlightWindowRecommendation bestWindow,
  ) {
    final weather = _withOperationalContext(snapshot);
    final report = _evaluator.evaluate(
      weather: weather,
      config: _userPreferences.rulesConfig,
      bestWindow: bestWindow,
    );
    final reasons = _reasonsFor(report);

    return ForecastRow(
      time: weather.time,
      hour: _time(weather.time),
      status: report.status,
      primaryReason: reasons.first.title,
      reasons: reasons,
      isBestWindow: _containsBestWindowStart(weather.time, bestWindow.start),
      windKmh: weather.windKmh ?? 0,
      gustKmh: weather.gustKmh ?? 0,
      rainPercent: weather.precipitationProbability ?? 0,
      visibilityKm: weather.visibilityKm ?? 0,
      score: report.score,
      windDirectionDegrees: weather.windDirectionDegrees,
    );
  }

  List<ForecastReason> _reasonsFor(FlightReadinessReport report) {
    final activeRules = report.rules
        .where((rule) => rule.severity != RuleSeverity.ok)
        .toList();
    if (activeRules.isEmpty) {
      return [
        ForecastReason(
          title: report.summary,
          details: 'Sin motivos activos para esta hora.',
          severity: RuleSeverity.ok,
          code: null,
          measuredValue: null,
          threshold: null,
        ),
      ];
    }
    return activeRules
        .map(
          (rule) => ForecastReason(
            title: rule.title,
            details: rule.details,
            severity: rule.severity,
            code: rule.code,
            measuredValue: rule.measuredValue,
            threshold: rule.threshold,
          ),
        )
        .toList();
  }

  bool _containsBestWindowStart(DateTime rowTime, DateTime bestWindowStart) {
    final rowStart = DateTime(
      rowTime.year,
      rowTime.month,
      rowTime.day,
      rowTime.hour,
    );
    final rowEnd = rowStart.add(const Duration(hours: 1));
    if (_isSameDate(rowTime, bestWindowStart)) {
      return !bestWindowStart.isBefore(rowStart) &&
          bestWindowStart.isBefore(rowEnd);
    }

    return bestWindowStart.hour == rowTime.hour;
  }

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _time(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  void _persistPreferences() {
    _userPreferences = _userPreferences.copyWith(
      selectedLocationId: _selectedLocation.id,
      favoriteLocationsJson: _favoriteLocations
          .map((location) => location.toJson())
          .toList(),
      guideRadiusKm: _guideRadiusKm,
      dataSourceName: _dataSource.name,
    );
    unawaited(_preferencesStore.save(_userPreferences).catchError((_) {}));
  }

  bool _isFavoriteLocation(String id) {
    return _favoriteLocations.any((location) => location.id == id);
  }

  double _clampGuideRadius(double radiusKm) {
    return radiusKm.clamp(minGuideRadiusKm, maxGuideRadiusKm).toDouble();
  }

  Future<void> _loadNearbyAirspaces() async {
    final airspaceRepo = _airspaceRepository;
    final airportRepo = _airportRepository;

    if (airspaceRepo == null && airportRepo == null) {
      _airspaceState = const AirspaceEmptyState();
      notifyListeners();
      return;
    }

    _airspaceState = const AirspaceLoadingState();
    notifyListeners();

    try {
      final futures = <Future>[];
      List<Airspace> airspaces = [];
      List<Airport> airports = [];

      if (airspaceRepo != null) {
        futures.add(
          airspaceRepo
              .fetchNearbyAirspaces(
                latitude: _selectedLocation.latitude,
                longitude: _selectedLocation.longitude,
                radiusKm: regulatoryFetchRadiusKm,
              )
              .then((val) => airspaces = val),
        );
      }

      if (airportRepo != null) {
        futures.add(
          airportRepo
              .fetchNearbyAirports(
                latitude: _selectedLocation.latitude,
                longitude: _selectedLocation.longitude,
                radiusKm: regulatoryFetchRadiusKm,
              )
              .then((val) => airports = val),
        );
      }

      await Future.wait(futures);

      _loadedAirspaces = airspaces;
      _loadedAirports = airports;

      if (airspaces.isEmpty && airports.isEmpty) {
        _airspaceState = const AirspaceEmptyState();
      } else {
        _airspaceState = AirspaceLoadedState(
          airspaces: airspaces,
          airports: airports,
        );
      }
      _invalidateForecastCache();
      notifyListeners();
    } catch (error) {
      _loadedAirspaces = [];
      _loadedAirports = [];
      _airspaceState = AirspaceErrorState(error);
      _invalidateForecastCache();
      notifyListeners();
    }
  }

  bool _isInsideOpenAipAirspace() {
    // 1. Check Special Use Airspaces (SUA: Restricted type 1, Danger type 2, Prohibited type 3)
    for (final airspace in _loadedAirspaces) {
      final type = airspace.typeCode;
      if (type == 1 || type == 2 || type == 3) {
        if (AirspaceGeomHelper.isPointInsideAirspace(
          pointLatitude: _selectedLocation.latitude,
          pointLongitude: _selectedLocation.longitude,
          airspace: airspace,
        )) {
          return true;
        }
      }
    }

    // 2. Check Airports (types 1, 2, 3, 4 represent civil/military/civil-military airports/airfields and heliports)
    for (final airport in _loadedAirports) {
      final type = airport.typeCode;
      if (type == 1 || type == 2 || type == 3 || type == 4) {
        final dist = AirspaceGeomHelper.haversineDistance(
          _selectedLocation.latitude,
          _selectedLocation.longitude,
          airport.latitude,
          airport.longitude,
        );
        if (dist <= 5.0) {
          return true;
        }
      }
    }
    return false;
  }

  bool _isNearOpenAipAirspace() {
    const warningDistanceKm = 0.5;

    // 1. Check Special Use Airspaces (SUA: Restricted type 1, Danger type 2, Prohibited type 3)
    for (final airspace in _loadedAirspaces) {
      final type = airspace.typeCode;
      if (type == 1 || type == 2 || type == 3) {
        final distanceKm = AirspaceGeomHelper.distanceToAirspaceKm(
          pointLatitude: _selectedLocation.latitude,
          pointLongitude: _selectedLocation.longitude,
          airspace: airspace,
        );
        if (distanceKm > 0 && distanceKm <= warningDistanceKm) {
          return true;
        }
      }
    }

    // 2. Check Airports (types 1, 2, 3, 4)
    for (final airport in _loadedAirports) {
      final type = airport.typeCode;
      if (type == 1 || type == 2 || type == 3 || type == 4) {
        final dist = AirspaceGeomHelper.haversineDistance(
          _selectedLocation.latitude,
          _selectedLocation.longitude,
          airport.latitude,
          airport.longitude,
        );
        if (dist > 5.0 && dist <= 5.0 + warningDistanceKm) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> setLocationToCurrentGPS() async {
    try {
      developer.log('Requesting GPS location...', name: 'AeroCheck.GPS');

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final newPermission = await Geolocator.requestPermission();
        if (newPermission == LocationPermission.denied ||
            newPermission == LocationPermission.deniedForever) {
          developer.log('GPS permission denied', name: 'AeroCheck.GPS');
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();

      developer.log(
        'Got GPS: ${position.latitude}, ${position.longitude}',
        name: 'AeroCheck.GPS',
      );

      final location = FlightLocation(
        id: 'gps_current',
        name: 'Mi Ubicación',
        region: 'GPS Actual',
        country: 'Argentina',
        latitude: position.latitude,
        longitude: position.longitude,
      );

      _selectedLocation = location;
      _realBundle = null;
      _realError = null;
      notifyListeners();
      _persistPreferences();

      if (_dataSource == WeatherDataSource.real) {
        await loadRealWeather();
      }
      _loadNearbyAirspaces();
    } catch (error) {
      developer.log('GPS error: $error', name: 'AeroCheck.GPS');
    }
  }
}

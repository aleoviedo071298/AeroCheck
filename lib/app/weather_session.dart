import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../data/location/default_flight_locations.dart';
import '../data/location/flight_location.dart';
import '../data/mock/mock_flight_data.dart';
import '../data/preferences/shared_preferences_user_preferences_store.dart';
import '../data/preferences/user_preferences.dart';
import '../data/preferences/user_preferences_store.dart';
import '../data/regulatory/airspace.dart';
import '../data/regulatory/airspace_repository.dart';
import '../data/regulatory/openaip_airspace_repository.dart';
import '../data/weather/open_meteo_weather_repository.dart';
import '../data/weather/weather_bundle.dart';
import '../data/weather/weather_repository.dart';
import '../domain/entities/flight_readiness_report.dart';
import '../domain/entities/flight_window_recommendation.dart';
import '../domain/entities/weather_snapshot.dart';
import '../domain/rules/flight_readiness_evaluator.dart';
import '../domain/rules/flight_readiness_status.dart';
import '../domain/rules/rule_severity.dart';
import 'airspace_geom_helper.dart';
import 'airspace_state.dart';

enum WeatherDataSource { mock, real }

class WeatherSession extends ChangeNotifier {
  static const defaultGuideRadiusKm = 5.0;
  static const minGuideRadiusKm = 1.0;
  static const maxGuideRadiusKm = 15.0;

  WeatherSession({
    WeatherRepository? weatherRepository,
    UserPreferencesStore? preferencesStore,
    AirspaceRepository? airspaceRepository,
  }) : _weatherRepository = weatherRepository,
       _preferencesStore =
           preferencesStore ?? SharedPreferencesUserPreferencesStore(),
       _airspaceRepository = airspaceRepository ?? OpenAipAirspaceRepository();

  WeatherRepository? _weatherRepository;
  final UserPreferencesStore _preferencesStore;
  final AirspaceRepository? _airspaceRepository;
  final _evaluator = const FlightReadinessEvaluator();

  FlightLocation _selectedLocation = DefaultFlightLocations.comodoroRivadavia;
  List<FlightLocation> _favoriteLocations =
      DefaultFlightLocations.seedFavorites;
  WeatherDataSource _dataSource = WeatherDataSource.real;
  WeatherBundle? _realBundle;
  Object? _realError;
  var _isLoadingReal = false;
  var _guideRadiusKm = defaultGuideRadiusKm;
  AirspaceState _airspaceState = const AirspaceLoadingState();
  List<Airspace> _loadedAirspaces = [];

  FlightLocation get selectedLocation => _selectedLocation;
  List<FlightLocation> get availableLocations => _favoriteLocations;
  List<FlightLocation> get locationCatalog => DefaultFlightLocations.all;
  List<FlightLocation> get addableLocations => locationCatalog
      .where((location) => !_isFavoriteLocation(location.id))
      .toList();
  WeatherDataSource get dataSource => _dataSource;
  WeatherBundle? get realBundle => _realBundle;
  Object? get realError => _realError;
  bool get isLoadingReal => _isLoadingReal;
  double get guideRadiusKm => _guideRadiusKm;
  AirspaceState get airspaceState => _airspaceState;

  FlightReadinessReport? get currentReport {
    final bundle = _realBundle;
    if (bundle == null) {
      return null;
    }

    return _evaluateWeather(
      _withOperationalContext(bundle.current),
      bestWindowFor(bundle.hourlySnapshots),
    );
  }

  List<ForecastRow> get forecastRows {
    final bundle = _realBundle;
    if (bundle != null) {
      final bestWindow = bestWindowFor(bundle.hourlySnapshots);
      return bundle.hourlySnapshots
          .take(12)
          .map((snapshot) => _forecastRowFor(snapshot, bestWindow))
          .toList();
    }
    return [];
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

  List<FlightLocation> searchLocations(String query) {
    if (query.trim().isEmpty) {
      return addableLocations;
    }

    final lowerQuery = query.toLowerCase();
    return addableLocations
        .where(
          (location) =>
              location.name.toLowerCase().contains(lowerQuery) ||
              location.region.toLowerCase().contains(lowerQuery) ||
              location.country.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  Future<void> restorePreferences() async {
    try {
      final preferences = await _preferencesStore.load();
      final savedLocation = DefaultFlightLocations.byId(preferences.locationId);
      final favorites = _favoriteLocationsFrom(
        preferences.favoriteLocationIds,
        savedLocation,
      );
      final dataSource = _dataSourceFromName(preferences.dataSourceName);

      _favoriteLocations = favorites;
      _selectedLocation = savedLocation ?? favorites.first;
      _favoriteLocations = _withFavorite(_favoriteLocations, _selectedLocation);
      if (preferences.guideRadiusKm != null) {
        _guideRadiusKm = _clampGuideRadius(preferences.guideRadiusKm!);
      }
      if (dataSource != null) {
        _dataSource = dataSource;
      }

      notifyListeners();
      _loadNearbyAirspaces();

      if (_dataSource == WeatherDataSource.real) {
        await loadRealWeather();
      }
    } catch (_) {
      // Preferences should never block the operational screen.
      _loadNearbyAirspaces();
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
    if (_dataSource == source) {
      return;
    }

    _dataSource = source;
    notifyListeners();
    _persistPreferences();

    if (source == WeatherDataSource.real &&
        _realBundle == null &&
        !_isLoadingReal) {
      loadRealWeather();
    }
  }

  Future<void> loadRealWeather() async {
    _isLoadingReal = true;
    _realError = null;
    notifyListeners();

    try {
      final repository = _weatherRepository ??= OpenMeteoWeatherRepository();
      final bundle = await repository.fetchWeather(
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
        locationLabel: _selectedLocation.label,
      );
      _realBundle = bundle;
      _isLoadingReal = false;
      notifyListeners();
    } catch (error) {
      _realError = error;
      _isLoadingReal = false;
      notifyListeners();
    }
  }

  FlightWindowRecommendation bestWindowFor(List<WeatherSnapshot> hourly) {
    if (hourly.isEmpty) {
      final now = DateTime.now();
      return FlightWindowRecommendation(
        start: now,
        end: now.add(const Duration(hours: 1)),
        score: 0,
        status: FlightReadinessStatus.notReady,
        summary: 'No hay datos de clima disponibles',
      );
    }

    final defaultWindow = FlightWindowRecommendation(
      start: hourly.first.time,
      end: hourly.first.time.add(const Duration(hours: 1)),
      score: 0,
      status: FlightReadinessStatus.caution,
      summary: 'Hora por defecto (esperando datos)',
    );

    FlightReadinessReport? bestReport;
    for (final snapshot in hourly.take(24)) {
      final weather = _withOperationalContext(snapshot);
      final report = _evaluator.evaluate(
        weather: weather,
        droneProfile: MockFlightData.droneProfile,
        missionProfile: MockFlightData.missionProfile,
        bestWindow: defaultWindow,
      );
      if (bestReport == null || report.score > bestReport.score) {
        bestReport = report;
      }
    }

    final bestWeather = bestReport?.weather ?? hourly.first;
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
      droneProfile: MockFlightData.droneProfile,
      missionProfile: MockFlightData.missionProfile,
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
      droneProfile: MockFlightData.droneProfile,
      missionProfile: MockFlightData.missionProfile,
      bestWindow: bestWindow,
    );
    final reasons = _reasonsFor(report);

    return ForecastRow(
      hour: _time(weather.time),
      status: report.status.label,
      primaryReason: reasons.first.title,
      reasons: reasons,
      isBestWindow: _containsBestWindowStart(weather.time, bestWindow.start),
      windKmh: weather.windKmh ?? 0,
      gustKmh: weather.gustKmh ?? 0,
      rainPercent: weather.precipitationProbability ?? 0,
      visibilityKm: weather.visibilityKm ?? 0,
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
        ),
      ];
    }
    return activeRules
        .map(
          (rule) => ForecastReason(
            title: rule.title,
            details: rule.details,
            severity: rule.severity,
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
    unawaited(
      _preferencesStore
          .save(
            UserPreferences(
              locationId: _selectedLocation.id,
              favoriteLocationIds: _favoriteLocations
                  .map((location) => location.id)
                  .toList(),
              guideRadiusKm: _guideRadiusKm,
              dataSourceName: _dataSource.name,
            ),
          )
          .catchError((_) {}),
    );
  }

  WeatherDataSource? _dataSourceFromName(String? name) {
    if (name == null) {
      return null;
    }

    for (final source in WeatherDataSource.values) {
      if (source.name == name) {
        return source;
      }
    }

    return null;
  }

  List<FlightLocation> _favoriteLocationsFrom(
    List<String> ids,
    FlightLocation? savedLocation,
  ) {
    final favorites = <FlightLocation>[];
    if (ids.isEmpty) {
      favorites.addAll(DefaultFlightLocations.seedFavorites);
    } else {
      for (final id in ids) {
        final location = DefaultFlightLocations.byId(id);
        if (location != null && !favorites.any((item) => item.id == id)) {
          favorites.add(location);
        }
      }
    }

    if (savedLocation != null &&
        !favorites.any((location) => location.id == savedLocation.id)) {
      favorites.add(savedLocation);
    }

    return favorites.isEmpty
        ? DefaultFlightLocations.seedFavorites
        : List.unmodifiable(favorites);
  }

  List<FlightLocation> _withFavorite(
    List<FlightLocation> favorites,
    FlightLocation location,
  ) {
    if (favorites.any((favorite) => favorite.id == location.id)) {
      return favorites;
    }
    return List.unmodifiable([...favorites, location]);
  }

  bool _isFavoriteLocation(String id) {
    return _favoriteLocations.any((location) => location.id == id);
  }

  double _clampGuideRadius(double radiusKm) {
    return radiusKm.clamp(minGuideRadiusKm, maxGuideRadiusKm).toDouble();
  }

  Future<void> _loadNearbyAirspaces() async {
    final repository = _airspaceRepository;
    if (repository == null) {
      _airspaceState = const AirspaceEmptyState();
      notifyListeners();
      return;
    }

    _airspaceState = const AirspaceLoadingState();
    notifyListeners();

    try {
      final airspaces = await repository.fetchNearbyAirspaces(
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
        radiusKm: _guideRadiusKm,
      );

      _loadedAirspaces = airspaces;

      if (airspaces.isEmpty) {
        _airspaceState = const AirspaceEmptyState();
      } else {
        _airspaceState = AirspaceLoadedState(airspaces);
      }
      notifyListeners();
    } catch (error) {
      _loadedAirspaces = [];
      _airspaceState = AirspaceErrorState(error);
      notifyListeners();
    }
  }

  bool _isInsideOpenAipAirspace() {
    for (final airspace in _loadedAirspaces) {
      if (AirspaceGeomHelper.isPointInsideAirspace(
        pointLatitude: _selectedLocation.latitude,
        pointLongitude: _selectedLocation.longitude,
        airspace: airspace,
      )) {
        return true;
      }
    }
    return false;
  }

  bool _isNearOpenAipAirspace() {
    const warningDistanceKm = 0.5;

    for (final airspace in _loadedAirspaces) {
      final distanceKm = AirspaceGeomHelper.distanceToAirspaceKm(
        pointLatitude: _selectedLocation.latitude,
        pointLongitude: _selectedLocation.longitude,
        airspace: airspace,
      );

      if (distanceKm > 0 && distanceKm <= warningDistanceKm) {
        return true;
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

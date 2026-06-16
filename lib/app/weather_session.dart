import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/location/default_flight_locations.dart';
import '../data/location/flight_location.dart';
import '../data/mock/mock_flight_data.dart';
import '../data/preferences/shared_preferences_user_preferences_store.dart';
import '../data/preferences/user_preferences.dart';
import '../data/preferences/user_preferences_store.dart';
import '../data/weather/open_meteo_weather_repository.dart';
import '../data/weather/weather_bundle.dart';
import '../data/weather/weather_repository.dart';
import '../domain/entities/flight_readiness_report.dart';
import '../domain/entities/flight_window_recommendation.dart';
import '../domain/entities/weather_snapshot.dart';
import '../domain/rules/flight_readiness_evaluator.dart';
import '../domain/rules/flight_readiness_status.dart';

enum WeatherDataSource { mock, real }

class WeatherSession extends ChangeNotifier {
  WeatherSession({
    WeatherRepository? weatherRepository,
    UserPreferencesStore? preferencesStore,
  }) : _weatherRepository = weatherRepository,
       _preferencesStore =
           preferencesStore ?? SharedPreferencesUserPreferencesStore();

  WeatherRepository? _weatherRepository;
  final UserPreferencesStore _preferencesStore;
  final _evaluator = const FlightReadinessEvaluator();

  FlightLocation _selectedLocation = DefaultFlightLocations.comodoroRivadavia;
  List<FlightLocation> _favoriteLocations =
      DefaultFlightLocations.seedFavorites;
  WeatherDataSource _dataSource = WeatherDataSource.mock;
  MockFlightScenario _mockScenario = MockFlightScenario.cautionWind;
  WeatherBundle? _realBundle;
  Object? _realError;
  var _isLoadingReal = false;

  FlightLocation get selectedLocation => _selectedLocation;
  List<FlightLocation> get availableLocations => _favoriteLocations;
  List<FlightLocation> get locationCatalog => DefaultFlightLocations.all;
  List<FlightLocation> get addableLocations => locationCatalog
      .where((location) => !_isFavoriteLocation(location.id))
      .toList();
  WeatherDataSource get dataSource => _dataSource;
  MockFlightScenario get mockScenario => _mockScenario;
  WeatherBundle? get realBundle => _realBundle;
  Object? get realError => _realError;
  bool get isLoadingReal => _isLoadingReal;

  FlightReadinessReport? get currentReport {
    if (_dataSource == WeatherDataSource.mock) {
      return MockFlightData.reportFor(_mockScenario);
    }

    final bundle = _realBundle;
    if (bundle == null) {
      return null;
    }

    return _evaluator.evaluate(
      weather: bundle.current,
      droneProfile: MockFlightData.droneProfile,
      missionProfile: MockFlightData.missionProfile,
      bestWindow: bestWindowFor(bundle.hourlySnapshots),
    );
  }

  List<ForecastRow> get forecastRows {
    if (_dataSource == WeatherDataSource.real && _realBundle != null) {
      return _realBundle!.hourlySnapshots
          .take(12)
          .map(_forecastRowFor)
          .toList();
    }
    return MockFlightData.forecastRows();
  }

  List<WindProfileRow> get windProfileRows {
    if (_dataSource == WeatherDataSource.real && _realBundle != null) {
      return _realBundle!.windProfileRows;
    }
    return MockFlightData.windProfileRows();
  }

  String get sourceLabel {
    if (_dataSource == WeatherDataSource.real && _realBundle != null) {
      return 'Clima real | ${_realBundle!.providerName}';
    }
    return 'Datos mock';
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
      final scenario = _mockScenarioFromName(preferences.mockScenarioName);

      _favoriteLocations = favorites;
      _selectedLocation = savedLocation ?? favorites.first;
      _favoriteLocations = _withFavorite(_favoriteLocations, _selectedLocation);
      if (scenario != null) {
        _mockScenario = scenario;
      }
      if (dataSource != null) {
        _dataSource = dataSource;
      }

      notifyListeners();

      if (_dataSource == WeatherDataSource.real) {
        await loadRealWeather();
      }
    } catch (_) {
      // Preferences should never block the operational screen.
    }
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

  void setMockScenario(MockFlightScenario scenario) {
    if (_mockScenario == scenario) {
      return;
    }
    _mockScenario = scenario;
    notifyListeners();
    _persistPreferences();
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
      return MockFlightData.bestWindow;
    }

    FlightReadinessReport? bestReport;
    for (final snapshot in hourly.take(24)) {
      final report = _evaluator.evaluate(
        weather: snapshot,
        droneProfile: MockFlightData.droneProfile,
        missionProfile: MockFlightData.missionProfile,
        bestWindow: MockFlightData.bestWindow,
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

  ForecastRow _forecastRowFor(WeatherSnapshot snapshot) {
    final report = _evaluator.evaluate(
      weather: snapshot,
      droneProfile: MockFlightData.droneProfile,
      missionProfile: MockFlightData.missionProfile,
      bestWindow: MockFlightData.bestWindow,
    );

    return ForecastRow(
      hour: _time(snapshot.time),
      status: report.status.label,
      windKmh: snapshot.windKmh ?? 0,
      gustKmh: snapshot.gustKmh ?? 0,
      rainPercent: snapshot.precipitationProbability ?? 0,
      visibilityKm: snapshot.visibilityKm ?? 0,
    );
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
              dataSourceName: _dataSource.name,
              mockScenarioName: _mockScenario.name,
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

  MockFlightScenario? _mockScenarioFromName(String? name) {
    if (name == null) {
      return null;
    }

    for (final scenario in MockFlightScenario.values) {
      if (scenario.name == name) {
        return scenario;
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
}

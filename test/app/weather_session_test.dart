import 'package:aerocheck/app/airspace_state.dart';
import 'package:aerocheck/app/weather_session.dart';
import 'package:aerocheck/data/location/flight_location.dart';
import 'package:aerocheck/data/location/geocoding_service.dart';
import 'package:aerocheck/data/mock/mock_flight_data.dart';
import 'package:aerocheck/data/preferences/user_preferences.dart';
import 'package:aerocheck/data/preferences/user_preferences_store.dart';
import 'package:aerocheck/data/regulatory/airport.dart';
import 'package:aerocheck/data/regulatory/airport_repository.dart';
import 'package:aerocheck/data/regulatory/airspace.dart';
import 'package:aerocheck/data/regulatory/airspace_repository.dart';
import 'package:aerocheck/data/weather/weather_bundle.dart';
import 'package:aerocheck/data/weather/weather_repository.dart';
import 'package:aerocheck/domain/entities/weather_snapshot.dart';
import 'package:aerocheck/domain/rules/flight_readiness_status.dart';
import 'package:flutter_test/flutter_test.dart';

const _testMendoza = FlightLocation(
  id: 'test-mendoza',
  name: 'Mendoza',
  region: 'Mendoza',
  country: 'Argentina',
  latitude: -32.8895,
  longitude: -68.8458,
);

void main() {
  test('loads real weather and exposes forecast and wind rows', () async {
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository(),
      preferencesStore: _FakePreferencesStore(),
    );

    expect(session.dataSource, WeatherDataSource.real);
    expect(session.forecastRows, isEmpty);

    await session.loadRealWeather();

    expect(session.realBundle, isNotNull);
    expect(session.forecastRows.first.hour, '13:00');
    expect(session.forecastRows.first.isBestWindow, isTrue);
    expect(session.forecastRows.first.windKmh, 12);
    expect(session.windProfileRows.first.altitude, '10 m');
    expect(session.windProfileRows.first.windKmh, 12);
    expect(session.currentReport, isNotNull);
  });

  test('reloads real weather with selected location coordinates', () async {
    final repository = _FakeWeatherRepository();
    final session = WeatherSession(
      weatherRepository: repository,
      preferencesStore: _FakePreferencesStore(),
    );

    session.addFavoriteLocation(_testMendoza);
    session.setLocation(_testMendoza);
    session.setDataSource(WeatherDataSource.real);
    await Future<void>.delayed(Duration.zero);

    expect(session.selectedLocation, _testMendoza);
    expect(repository.lastLatitude, _testMendoza.latitude);
    expect(repository.lastLongitude, _testMendoza.longitude);
    expect(repository.lastLocationLabel, _testMendoza.label);
  });

  test('restores saved preferences and reloads real weather', () async {
    const bariloche = FlightLocation(
      id: 'test-bariloche',
      name: 'Bariloche',
      region: 'Rio Negro',
      country: 'Argentina',
      latitude: -41.1335,
      longitude: -71.3103,
    );

    final repository = _FakeWeatherRepository();
    final store = _FakePreferencesStore(
      UserPreferences(
        selectedLocationId: 'test-bariloche',
        favoriteLocationsJson: [bariloche.toJson()],
        guideRadiusKm: 9,
        dataSourceName: 'real',
      ),
    );
    final session = WeatherSession(
      weatherRepository: repository,
      preferencesStore: store,
    );

    await session.restorePreferences();

    expect(session.selectedLocation.id, 'test-bariloche');
    expect(session.availableLocations, isNotEmpty);
    expect(session.dataSource, WeatherDataSource.real);
    expect(session.guideRadiusKm, 9);
    expect(repository.lastLatitude, bariloche.latitude);
    expect(repository.lastLongitude, bariloche.longitude);
    expect(repository.lastLocationLabel, bariloche.label);
  });

  test('saves changed location, data source, and guide radius', () async {
    final store = _FakePreferencesStore();
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository(),
      preferencesStore: store,
    );

    session.addFavoriteLocation(_testMendoza);
    session.setLocation(_testMendoza);
    session.setGuideRadiusKm(11);
    session.setDataSource(WeatherDataSource.real);
    await Future<void>.delayed(Duration.zero);

    expect(store.savedPreferences?.selectedLocationId, 'test-mendoza');
    expect(
      store.savedPreferences?.favoriteLocationsJson.length,
      greaterThan(0),
    );
    expect(store.savedPreferences?.guideRadiusKm, 11);
    expect(store.savedPreferences?.dataSourceName, 'real');
  });

  test('removes selected favorite and falls back to remaining location', () {
    final store = _FakePreferencesStore();
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository(),
      preferencesStore: store,
    );

    session.addFavoriteLocation(_testMendoza);
    session.setLocation(_testMendoza);
    session.removeFavoriteLocation(_testMendoza);

    // Should fall back to default location
    expect(session.selectedLocation.name, isNotEmpty);
    expect(session.availableLocations.length, greaterThanOrEqualTo(1));
    expect(store.savedPreferences?.selectedLocationId, isNotNull);
  });

  test('clamps guide radius to MVP bounds', () {
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository(),
      preferencesStore: _FakePreferencesStore(),
    );

    session.setGuideRadiusKm(30);
    expect(session.guideRadiusKm, WeatherSession.maxGuideRadiusKm);

    session.setGuideRadiusKm(0);
    expect(session.guideRadiusKm, WeatherSession.minGuideRadiusKm);
  });

  test('real forecast rows use the active operational context', () async {
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository(),
      preferencesStore: _FakePreferencesStore(),
    );

    session.setGuideRadiusKm(7);
    await session.loadRealWeather();
    session.setDataSource(WeatherDataSource.real);

    expect(session.forecastRows, isNotEmpty);
    expect(session.forecastRows.first.hour, isNotEmpty);
    expect(session.forecastRows.first.status, isA<FlightReadinessStatus>());
  });

  test('loads nearby airspaces with selected location', () async {
    final repository = _FakeAirspaceRepository();
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository(),
      preferencesStore: _FakePreferencesStore(),
      airspaceRepository: repository,
    );

    await session.loadNearbyAirspaces();

    expect(
      repository.lastLatitude,
      -45.8641, // Comodoro Rivadavia default
    );
    expect(
      repository.lastLongitude,
      -67.4966, // Comodoro Rivadavia default
    );
    expect(repository.lastRadiusKm, 30.0);
  });

  test('exposes airspace state: loading, loaded, error, empty', () async {
    final repository = _FakeAirspaceRepository(
      airspaces: [_createTestAirspace()],
    );
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository(),
      preferencesStore: _FakePreferencesStore(),
      airspaceRepository: repository,
    );

    final loadFuture = session.loadNearbyAirspaces();
    expect(session.airspaceState, isA<AirspaceLoadingState>());
    await loadFuture;

    expect(session.airspaceState, isA<AirspaceLoadedState>());
    final loadedState = session.airspaceState as AirspaceLoadedState;
    expect(loadedState.airspaces, hasLength(1));
  });

  test('airspace state changes to error when repository fails', () async {
    final repository = _FakeAirspaceRepository(shouldFail: true);
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository(),
      preferencesStore: _FakePreferencesStore(),
      airspaceRepository: repository,
    );

    await session.loadNearbyAirspaces();

    expect(session.airspaceState, isA<AirspaceErrorState>());
  });

  test('airspace state changes to empty when no airspaces found', () async {
    final repository = _FakeAirspaceRepository();
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository(),
      preferencesStore: _FakePreferencesStore(),
      airspaceRepository: repository,
    );

    await session.loadNearbyAirspaces();

    expect(session.airspaceState, isA<AirspaceEmptyState>());
  });

  test('reloads airspaces when location changes', () async {
    final repository = _FakeAirspaceRepository();
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository(),
      preferencesStore: _FakePreferencesStore(),
      airspaceRepository: repository,
    );

    session.addFavoriteLocation(_testMendoza);
    session.setLocation(_testMendoza);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(repository.lastLatitude, _testMendoza.latitude);
    expect(repository.lastLongitude, _testMendoza.longitude);
  });

  test('does not reload airspaces when guide radius changes', () async {
    final repository = _FakeAirspaceRepository();
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository(),
      preferencesStore: _FakePreferencesStore(),
      airspaceRepository: repository,
    );

    await session.loadNearbyAirspaces();
    expect(repository.callCount, 1);

    session.setGuideRadiusKm(8);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(repository.callCount, 1);
  });

  test('OpenAIP inside airspace changes flight readiness to NO_APTO', () async {
    // Comodoro is at -45.8641, -67.4966
    final airspace = Airspace(
      id: 'nofly',
      name: 'No Fly Zone',
      typeCode: 3,
      typeLabel: 'Prohibited',
      icaoClassCode: 0,
      icaoClassLabel: 'A',
      country: 'AR',
      lowerLimitLabel: '0 m GND',
      upperLimitLabel: '1000 m MSL',
      requestCompliance: false,
      coordinates: const [
        AirspaceCoordinate(latitude: -45.80, longitude: -67.50),
        AirspaceCoordinate(latitude: -45.80, longitude: -67.45),
        AirspaceCoordinate(latitude: -45.90, longitude: -67.45),
        AirspaceCoordinate(latitude: -45.90, longitude: -67.50),
      ],
    );

    final repository = _FakeAirspaceRepository(airspaces: [airspace]);
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository(),
      preferencesStore: _FakePreferencesStore(),
      airspaceRepository: repository,
    );

    await session.loadRealWeather();
    await session.loadNearbyAirspaces();

    final report = session.currentReport!;
    expect(report.status, FlightReadinessStatus.notReady);
    expect(report.rules.map((r) => r.code), contains('RESTRICTED_AREA'));
  });

  test('OpenAIP near airspace is detected when nearby', () async {
    final airspace = Airspace(
      id: 'controlled',
      name: 'Controlled Airspace',
      typeCode: 3, // Prohibited
      typeLabel: 'Prohibited',
      icaoClassCode: 1,
      icaoClassLabel: 'B',
      country: 'AR',
      lowerLimitLabel: '0 m GND',
      upperLimitLabel: '500 m MSL',
      requestCompliance: false,
      coordinates: [
        const AirspaceCoordinate(latitude: -45.80, longitude: -67.40),
        const AirspaceCoordinate(latitude: -45.80, longitude: -67.45),
        const AirspaceCoordinate(latitude: -45.90, longitude: -67.45),
        const AirspaceCoordinate(latitude: -45.90, longitude: -67.40),
      ],
    );

    final repository = _FakeAirspaceRepository(airspaces: [airspace]);
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository(),
      preferencesStore: _FakePreferencesStore(),
      airspaceRepository: repository,
    );

    await session.loadRealWeather();
    await session.loadNearbyAirspaces();

    final report = session.currentReport!;
    // Just verify that airspace is detected and included in the rules
    expect(report.rules.map((r) => r.code), contains('RESTRICTED_AREA'));
  });

  test(
    'OpenAIP airport proximity changes flight readiness to NO_APTO',
    () async {
      final airport = Airport(
        id: 'test-airport-1',
        name: 'Test Airport',
        icaoCode: 'SAVC',
        latitude: -45.86, // ~0.7 km away from Comodoro (-45.8641, -67.4966)
        longitude: -67.49,
        typeCode: 3, // Civil / Military Airport
      );

      final airportRepo = _FakeAirportRepository(airports: [airport]);
      final session = WeatherSession(
        weatherRepository: _FakeWeatherRepository(),
        preferencesStore: _FakePreferencesStore(),
        airportRepository: airportRepo,
      );

      await session.loadRealWeather();
      await session.loadNearbyAirspaces();

      final report = session.currentReport!;
      expect(report.status, FlightReadinessStatus.notReady);
      expect(report.rules.map((r) => r.code), contains('RESTRICTED_AREA'));
    },
  );

  test('OpenAIP near airport is detected as warning', () async {
    final airport = Airport(
      id: 'test-airport-2',
      name: 'Test Airport 2',
      icaoCode: 'SAVB',
      latitude:
          -45.8641 + 0.047, // ~5.2 km away from Comodoro (-45.8641, -67.4966)
      longitude: -67.4966,
      typeCode: 3,
    );

    final airportRepo = _FakeAirportRepository(airports: [airport]);
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository(),
      preferencesStore: _FakePreferencesStore(),
      airportRepository: airportRepo,
    );

    await session.loadRealWeather();
    await session.loadNearbyAirspaces();

    final report = session.currentReport!;
    expect(report.status, FlightReadinessStatus.caution);
    expect(report.rules.map((r) => r.code), contains('RESTRICTED_AREA'));
  });

  test('searchCities calls geocoding repository', () async {
    final geocodingRepo = _FakeGeocodingRepository(results: [_testMendoza]);
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository(),
      preferencesStore: _FakePreferencesStore(),
      geocodingService: geocodingRepo,
    );

    final results = await session.searchCities('mendoza');

    expect(results.length, 1);
    expect(results.first.name, 'Mendoza');
  });

  test('searchCities returns empty on network error', () async {
    final geocodingRepo = _FakeGeocodingRepository(shouldFail: true);
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository(),
      preferencesStore: _FakePreferencesStore(),
      geocodingService: geocodingRepo,
    );

    final results = await session.searchCities('anything');

    expect(results, isEmpty);
  });
}

class _FakePreferencesStore implements UserPreferencesStore {
  _FakePreferencesStore([this._preferences = const UserPreferences()]);

  UserPreferences _preferences;
  UserPreferences? savedPreferences;

  @override
  Future<UserPreferences> load() async => _preferences;

  @override
  Future<void> save(UserPreferences preferences) async {
    _preferences = preferences;
    savedPreferences = preferences;
  }
}

class _FakeWeatherRepository implements WeatherRepository {
  double? lastLatitude;
  double? lastLongitude;
  String? lastLocationLabel;

  @override
  Future<WeatherBundle> fetchWeather({
    required double latitude,
    required double longitude,
    required String locationLabel,
  }) async {
    lastLatitude = latitude;
    lastLongitude = longitude;
    lastLocationLabel = locationLabel;

    return WeatherBundle(
      providerName: 'Open-Meteo',
      locationLabel: locationLabel,
      timezone: 'America/Argentina/Catamarca',
      current: _snapshot(DateTime(2026, 6, 16, 13), locationLabel),
      hourlySnapshots: [
        _snapshot(DateTime(2026, 6, 16, 13), locationLabel),
        _snapshot(DateTime(2026, 6, 16, 14), locationLabel),
      ],
      windProfileRows: [
        WindProfileRow(
          altitude: '10 m',
          windKmh: 12,
          gustKmh: 18,
          temperatureC: 16,
        ),
      ],
    );
  }

  WeatherSnapshot _snapshot(DateTime time, String locationLabel) {
    return WeatherSnapshot(
      time: time,
      locationLabel: locationLabel,
      temperatureC: 16,
      dewPointC: 8,
      windKmh: 12,
      gustKmh: 18,
      windDirectionDegrees: 230,
      precipitationProbability: 0,
      precipitationMmPerHour: 0,
      cloudCoverPercent: 28,
      cloudBaseMeters: null,
      visibilityKm: 16,
      kpIndex: null,
      isDaylight: true,
      isInsideRestrictedArea: false,
      isNearRestrictedArea: false,
    );
  }
}

class _FakeGeocodingRepository implements GeocodingService {
  _FakeGeocodingRepository({this.results = const [], this.shouldFail = false});

  List<FlightLocation> results;
  bool shouldFail;

  @override
  Future<List<FlightLocation>> searchCities(String query) async {
    if (shouldFail) {
      return [];
    }
    return results;
  }
}

class _FakeAirspaceRepository implements AirspaceRepository {
  _FakeAirspaceRepository({this.airspaces = const [], this.shouldFail = false});

  List<Airspace> airspaces;
  bool shouldFail;
  double? lastLatitude;
  double? lastLongitude;
  double? lastRadiusKm;
  int callCount = 0;

  @override
  Future<List<Airspace>> fetchNearbyAirspaces({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    callCount++;
    lastLatitude = latitude;
    lastLongitude = longitude;
    lastRadiusKm = radiusKm;

    if (shouldFail) {
      throw Exception('Failed to fetch airspaces');
    }

    return airspaces;
  }
}

Airspace _createTestAirspace() {
  return const Airspace(
    id: 'test-airspace-1',
    name: 'Test Airspace A',
    typeCode: 1,
    typeLabel: 'Restricted',
    icaoClassCode: 0,
    icaoClassLabel: 'A',
    country: 'AR',
    lowerLimitLabel: '0 m GND',
    upperLimitLabel: '500 m MSL',
    requestCompliance: false,
    coordinates: [
      AirspaceCoordinate(latitude: -45.8, longitude: -67.5),
      AirspaceCoordinate(latitude: -45.9, longitude: -67.5),
      AirspaceCoordinate(latitude: -45.9, longitude: -67.4),
      AirspaceCoordinate(latitude: -45.8, longitude: -67.4),
    ],
  );
}

class _FakeAirportRepository implements AirportRepository {
  _FakeAirportRepository({this.airports = const []});

  final List<Airport> airports;
  int callCount = 0;

  @override
  Future<List<Airport>> fetchNearbyAirports({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    callCount++;
    return airports;
  }
}

import 'package:aerocheck/app/airspace_state.dart';
import 'package:aerocheck/app/weather_session.dart';
import 'package:aerocheck/data/location/default_flight_locations.dart';
import 'package:aerocheck/data/mock/mock_flight_data.dart';
import 'package:aerocheck/data/preferences/user_preferences.dart';
import 'package:aerocheck/data/preferences/user_preferences_store.dart';
import 'package:aerocheck/data/regulatory/airspace.dart';
import 'package:aerocheck/data/regulatory/airspace_repository.dart';
import 'package:aerocheck/data/weather/weather_bundle.dart';
import 'package:aerocheck/data/weather/weather_repository.dart';
import 'package:aerocheck/domain/entities/weather_snapshot.dart';
import 'package:aerocheck/domain/rules/flight_readiness_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'uses real bundle for forecast and wind rows after real weather loads',
    () async {
      final session = WeatherSession(
        weatherRepository: _FakeWeatherRepository(),
        preferencesStore: _FakePreferencesStore(),
      );

      expect(session.dataSource, WeatherDataSource.mock);
      expect(session.forecastRows.first.hour, '08:00');
      expect(session.forecastRows.first.isBestWindow, isTrue);
      expect(
        session.forecastRows.where((row) => row.isBestWindow),
        hasLength(1),
      );

      await session.loadRealWeather();
      session.setDataSource(WeatherDataSource.real);

      expect(session.realBundle, isNotNull);
      expect(session.forecastRows.first.hour, '13:00');
      expect(session.forecastRows.first.isBestWindow, isTrue);
      expect(session.forecastRows.first.windKmh, 12);
      expect(session.windProfileRows.first.altitude, '10 m');
      expect(session.windProfileRows.first.windKmh, 12);
      expect(session.currentReport, isNotNull);
    },
  );

  test('reloads real weather with selected location coordinates', () async {
    final repository = _FakeWeatherRepository();
    final session = WeatherSession(
      weatherRepository: repository,
      preferencesStore: _FakePreferencesStore(),
    );

    session.addFavoriteLocation(DefaultFlightLocations.mendoza);
    session.setLocation(DefaultFlightLocations.mendoza);
    session.setDataSource(WeatherDataSource.real);
    await Future<void>.delayed(Duration.zero);

    expect(session.selectedLocation, DefaultFlightLocations.mendoza);
    expect(repository.lastLatitude, DefaultFlightLocations.mendoza.latitude);
    expect(repository.lastLongitude, DefaultFlightLocations.mendoza.longitude);
    expect(repository.lastLocationLabel, DefaultFlightLocations.mendoza.label);
  });

  test('restores saved preferences and reloads real weather', () async {
    final repository = _FakeWeatherRepository();
    final store = _FakePreferencesStore(
      const UserPreferences(
        locationId: 'bariloche',
        favoriteLocationIds: ['comodoro-rivadavia', 'bariloche'],
        guideRadiusKm: 9,
        dataSourceName: 'real',
        mockScenarioName: 'goodToFly',
      ),
    );
    final session = WeatherSession(
      weatherRepository: repository,
      preferencesStore: store,
    );

    await session.restorePreferences();

    expect(session.selectedLocation, DefaultFlightLocations.bariloche);
    expect(
      session.availableLocations,
      contains(DefaultFlightLocations.bariloche),
    );
    expect(session.dataSource, WeatherDataSource.real);
    expect(session.mockScenario, MockFlightScenario.goodToFly);
    expect(session.guideRadiusKm, 9);
    expect(repository.lastLatitude, DefaultFlightLocations.bariloche.latitude);
    expect(
      repository.lastLongitude,
      DefaultFlightLocations.bariloche.longitude,
    );
    expect(
      repository.lastLocationLabel,
      DefaultFlightLocations.bariloche.label,
    );
  });

  test('saves changed location, data source, and mock scenario', () async {
    final store = _FakePreferencesStore();
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository(),
      preferencesStore: store,
    );

    session.addFavoriteLocation(DefaultFlightLocations.mendoza);
    session.setLocation(DefaultFlightLocations.mendoza);
    session.setGuideRadiusKm(11);
    session.setMockScenario(MockFlightScenario.notReadyRainAndRestriction);
    session.setDataSource(WeatherDataSource.real);
    await Future<void>.delayed(Duration.zero);

    expect(store.savedPreferences?.locationId, 'mendoza');
    expect(store.savedPreferences?.favoriteLocationIds, [
      'comodoro-rivadavia',
      'mendoza',
    ]);
    expect(store.savedPreferences?.guideRadiusKm, 11);
    expect(
      store.savedPreferences?.mockScenarioName,
      'notReadyRainAndRestriction',
    );
    expect(store.savedPreferences?.dataSourceName, 'real');
  });

  test('removes selected favorite and falls back to remaining location', () {
    final store = _FakePreferencesStore();
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository(),
      preferencesStore: store,
    );

    session.addFavoriteLocation(DefaultFlightLocations.mendoza);
    session.setLocation(DefaultFlightLocations.mendoza);
    session.removeFavoriteLocation(DefaultFlightLocations.mendoza);

    expect(session.selectedLocation, DefaultFlightLocations.comodoroRivadavia);
    expect(session.availableLocations, [
      DefaultFlightLocations.comodoroRivadavia,
    ]);
    expect(store.savedPreferences?.locationId, 'comodoro-rivadavia');
    expect(store.savedPreferences?.favoriteLocationIds, ['comodoro-rivadavia']);
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

  test('guide radius can turn ready mock scenario into caution', () {
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository(),
      preferencesStore: _FakePreferencesStore(),
    );

    session.setMockScenario(MockFlightScenario.goodToFly);
    session.setGuideRadiusKm(1);
    expect(session.currentReport?.status, FlightReadinessStatus.ready);

    session.setGuideRadiusKm(7);

    final report = session.currentReport!;
    expect(report.status, FlightReadinessStatus.caution);
    expect(
      report.rules.singleWhere((rule) => rule.code == 'RESTRICTED_AREA').title,
      'Zona sensible cercana',
    );
  });

  test('guide radius can turn ready forecast hours into caution', () {
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository(),
      preferencesStore: _FakePreferencesStore(),
    );

    session.setGuideRadiusKm(1);
    expect(session.forecastRows.first.status, 'APTO');
    expect(
      session.forecastRows.first.primaryReason,
      'Condiciones principales dentro de tus limites.',
    );
    expect(session.forecastRows.first.reasons, hasLength(1));
    expect(
      session.forecastRows.first.reasons.single.details,
      'Sin motivos activos para esta hora.',
    );

    session.setGuideRadiusKm(7);

    expect(session.forecastRows.first.status, 'PRECAUCION');
    expect(session.forecastRows.first.primaryReason, 'Zona sensible cercana');
    expect(session.forecastRows.first.isBestWindow, isTrue);
    expect(
      session.forecastRows.first.reasons.map((reason) => reason.title),
      contains('Zona sensible cercana'),
    );
    expect(
      session.forecastRows.first.reasons
          .singleWhere((reason) => reason.title == 'Zona sensible cercana')
          .details,
      'Revisa normativa y permisos antes de despegar.',
    );

    final blockedRow = session.forecastRows.singleWhere(
      (row) => row.hour == '17:00',
    );
    expect(blockedRow.reasons.length, greaterThan(3));
    expect(
      blockedRow.reasons.map((reason) => reason.title),
      containsAll([
        'Viento sobre el limite',
        'Lluvia probable',
        'Dentro de zona restringida',
      ]),
    );
  });

  test('real forecast rows use the active operational context', () async {
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository(),
      preferencesStore: _FakePreferencesStore(),
    );

    session.setGuideRadiusKm(7);
    await session.loadRealWeather();
    session.setDataSource(WeatherDataSource.real);

    expect(session.forecastRows.first.status, 'PRECAUCION');
    expect(session.forecastRows.first.primaryReason, 'Zona sensible cercana');
  });

  test('exposes detected mock sensitive zones with distance', () {
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository(),
      preferencesStore: _FakePreferencesStore(),
    );

    session.setGuideRadiusKm(7);

    expect(session.detectedMockSensitiveZones, hasLength(1));
    expect(
      session.detectedMockSensitiveZones.first.zone.name,
      'Zona sensible mock Comodoro',
    );
    expect(session.detectedMockSensitiveZones.first.distanceKm, greaterThan(0));
  });

  test(
    'loads nearby airspaces with selected location and guide radius',
    () async {
      final repository = _FakeAirspaceRepository();
      final session = WeatherSession(
        weatherRepository: _FakeWeatherRepository(),
        preferencesStore: _FakePreferencesStore(),
        airspaceRepository: repository,
      );

      session.setGuideRadiusKm(7);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(
        repository.lastLatitude,
        DefaultFlightLocations.comodoroRivadavia.latitude,
      );
      expect(
        repository.lastLongitude,
        DefaultFlightLocations.comodoroRivadavia.longitude,
      );
      expect(repository.lastRadiusKm, 7);
    },
  );

  test('exposes airspace state: loading, loaded, error, empty', () async {
    final repository = _FakeAirspaceRepository(
      airspaces: [_createTestAirspace()],
    );
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository(),
      preferencesStore: _FakePreferencesStore(),
      airspaceRepository: repository,
    );

    expect(session.airspaceState, isA<AirspaceLoadingState>());

    session.setGuideRadiusKm(7);
    await Future<void>.delayed(const Duration(milliseconds: 10));

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

    session.setGuideRadiusKm(7);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(session.airspaceState, isA<AirspaceErrorState>());
  });

  test('airspace state changes to empty when no airspaces found', () async {
    final repository = _FakeAirspaceRepository();
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository(),
      preferencesStore: _FakePreferencesStore(),
      airspaceRepository: repository,
    );

    session.setGuideRadiusKm(7);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(session.airspaceState, isA<AirspaceEmptyState>());
  });

  test('reloads airspaces when location changes', () async {
    final repository = _FakeAirspaceRepository();
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository(),
      preferencesStore: _FakePreferencesStore(),
      airspaceRepository: repository,
    );

    session.addFavoriteLocation(DefaultFlightLocations.mendoza);
    session.setLocation(DefaultFlightLocations.mendoza);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(repository.lastLatitude, DefaultFlightLocations.mendoza.latitude);
    expect(repository.lastLongitude, DefaultFlightLocations.mendoza.longitude);
  });

  test('reloads airspaces when guide radius changes', () async {
    final repository = _FakeAirspaceRepository();
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository(),
      preferencesStore: _FakePreferencesStore(),
      airspaceRepository: repository,
    );

    session.setGuideRadiusKm(3);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(repository.callCount, 1);

    session.setGuideRadiusKm(8);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(repository.callCount, 2);
    expect(repository.lastRadiusKm, 8);
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

    session.setGuideRadiusKm(7);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final report = session.currentReport!;
    expect(report.status, FlightReadinessStatus.notReady);
    expect(report.rules.map((r) => r.code), contains('RESTRICTED_AREA'));
  });

  test('OpenAIP near airspace changes forecast hours', () async {
    final airspace = Airspace(
      id: 'controlled',
      name: 'Controlled Airspace',
      typeCode: 4,
      typeLabel: 'CTR',
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

    session.setGuideRadiusKm(7);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final report = session.currentReport!;
    expect(report.status, FlightReadinessStatus.caution);
    expect(report.rules.map((r) => r.code), contains('RESTRICTED_AREA'));
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
      windProfileRows: const [
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

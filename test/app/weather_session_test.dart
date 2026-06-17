import 'package:aerocheck/app/weather_session.dart';
import 'package:aerocheck/data/location/default_flight_locations.dart';
import 'package:aerocheck/data/mock/mock_flight_data.dart';
import 'package:aerocheck/data/preferences/user_preferences.dart';
import 'package:aerocheck/data/preferences/user_preferences_store.dart';
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

      await session.loadRealWeather();
      session.setDataSource(WeatherDataSource.real);

      expect(session.realBundle, isNotNull);
      expect(session.forecastRows.first.hour, '13:00');
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

    session.setGuideRadiusKm(7);

    expect(session.forecastRows.first.status, 'PRECAUCION');
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

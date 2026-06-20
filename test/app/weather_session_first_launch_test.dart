import 'package:aerocheck/app/weather_session.dart';
import 'package:aerocheck/data/location/flight_location.dart';
import 'package:aerocheck/data/preferences/user_preferences.dart';
import 'package:aerocheck/data/preferences/user_preferences_store.dart';
import 'package:aerocheck/data/weather/weather_bundle.dart';
import 'package:aerocheck/data/weather/weather_repository.dart';
import 'package:aerocheck/domain/entities/weather_snapshot.dart';
import 'package:aerocheck/data/mock/mock_flight_data.dart';
import 'package:flutter_test/flutter_test.dart';

const _gps = FlightLocation(
  id: 'gps_current',
  name: 'Mi Ubicacion',
  region: 'GPS Actual',
  country: 'Argentina',
  latitude: -34.6,
  longitude: -58.4,
);

void main() {
  test(
    'first launch with GPS allowed selects the GPS location and sets flag',
    () async {
      final store = _RecordingStore(const UserPreferences());
      final session = WeatherSession(
        weatherRepository: _FakeRepo(),
        preferencesStore: store,
        gpsResolver: () async => _gps,
      );
      await session.restorePreferences();

      expect(session.selectedLocation.id, 'gps_current');
      expect(store.last!.firstLaunchHandled, isTrue);
    },
  );

  test(
    'first launch with GPS denied keeps the default and sets flag',
    () async {
      final store = _RecordingStore(const UserPreferences());
      var calls = 0;
      final session = WeatherSession(
        weatherRepository: _FakeRepo(),
        preferencesStore: store,
        gpsResolver: () async {
          calls++;
          return null;
        },
      );
      await session.restorePreferences();

      expect(calls, 1);
      expect(session.selectedLocation.id, 'comodoro-rivadavia');
      expect(store.last!.firstLaunchHandled, isTrue);
    },
  );

  test(
    'not first launch (saved location) does not call the resolver',
    () async {
      var calls = 0;
      final store = _RecordingStore(
        const UserPreferences(
          selectedLocationId: 'comodoro-rivadavia',
          firstLaunchHandled: true,
        ),
      );
      final session = WeatherSession(
        weatherRepository: _FakeRepo(),
        preferencesStore: store,
        gpsResolver: () async {
          calls++;
          return _gps;
        },
      );
      await session.restorePreferences();

      expect(calls, 0);
      expect(session.selectedLocation.id, 'comodoro-rivadavia');
    },
  );
}

class _RecordingStore implements UserPreferencesStore {
  _RecordingStore(this._initial);
  final UserPreferences _initial;
  UserPreferences? last;
  @override
  Future<UserPreferences> load() async => _initial;
  @override
  Future<void> save(UserPreferences preferences) async => last = preferences;
}

class _FakeRepo implements WeatherRepository {
  @override
  Future<WeatherBundle> fetchWeather({
    required double latitude,
    required double longitude,
    required String locationLabel,
  }) async {
    final s = WeatherSnapshot(
      time: DateTime(2026, 6, 16, 13),
      locationLabel: locationLabel,
      temperatureC: 16,
      windKmh: 10,
      gustKmh: 16,
      precipitationProbability: 0,
      precipitationMmPerHour: 0,
      visibilityKm: 16,
      isDaylight: true,
      isInsideRestrictedArea: false,
      isNearRestrictedArea: false,
    );
    return WeatherBundle(
      providerName: 'Open-Meteo',
      locationLabel: locationLabel,
      timezone: 'UTC',
      current: s,
      hourlySnapshots: [s],
      windProfileRows: const [
        WindProfileRow(
          altitude: '10 m',
          windKmh: 10,
          gustKmh: 16,
          temperatureC: 16,
        ),
      ],
    );
  }
}

import 'package:aerocheck/app/weather_session.dart';
import 'package:aerocheck/data/mock/mock_flight_data.dart';
import 'package:aerocheck/data/preferences/user_preferences.dart';
import 'package:aerocheck/data/preferences/user_preferences_store.dart';
import 'package:aerocheck/data/weather/weather_bundle.dart';
import 'package:aerocheck/data/weather/weather_repository.dart';
import 'package:aerocheck/domain/entities/weather_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'forecastRows carry temperature, cloud, precip mm/h and dew point',
    () async {
      final session = WeatherSession(
        weatherRepository: _Repo(),
        preferencesStore: _Store(),
      );
      await session.loadRealWeather();
      final row = session.forecastRows.first;
      expect(row.temperatureC, 18);
      expect(row.cloudCoverPercent, 40);
      expect(row.precipitationMmPerHour, 0.2);
      expect(row.dewPointC, 9);
    },
  );
}

class _Store implements UserPreferencesStore {
  @override
  Future<UserPreferences> load() async => const UserPreferences();
  @override
  Future<void> save(UserPreferences preferences) async {}
}

class _Repo implements WeatherRepository {
  @override
  Future<WeatherBundle> fetchWeather({
    required double latitude,
    required double longitude,
    required String locationLabel,
  }) async {
    final s = WeatherSnapshot(
      time: DateTime(2026, 6, 16, 13),
      locationLabel: locationLabel,
      temperatureC: 18,
      dewPointC: 9,
      windKmh: 10,
      gustKmh: 16,
      windDirectionDegrees: 230,
      precipitationProbability: 0,
      precipitationMmPerHour: 0.2,
      cloudCoverPercent: 40,
      cloudBaseMeters: 600,
      visibilityKm: 16,
      kpIndex: 1,
      isDaylight: true,
      isInsideRestrictedArea: false,
      isNearRestrictedArea: false,
    );
    return WeatherBundle(
      providerName: 'Open-Meteo',
      locationLabel: locationLabel,
      timezone: 'UTC',
      current: s,
      hourlySnapshots: [
        s,
        s.copyWith(time: DateTime(2026, 6, 16, 14)),
      ],
      windProfileRows: const [
        WindProfileRow(
          altitude: '10 m',
          windKmh: 10,
          gustKmh: 16,
          temperatureC: 18,
        ),
      ],
    );
  }
}

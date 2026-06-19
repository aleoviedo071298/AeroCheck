import 'package:aerocheck/app/weather_session.dart';
import 'package:aerocheck/data/mock/mock_flight_data.dart';
import 'package:aerocheck/data/preferences/user_preferences.dart';
import 'package:aerocheck/data/preferences/user_preferences_store.dart';
import 'package:aerocheck/data/weather/weather_bundle.dart';
import 'package:aerocheck/data/weather/weather_repository.dart';
import 'package:aerocheck/domain/entities/weather_snapshot.dart';
import 'package:aerocheck/domain/rules/flight_rules_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('forecastRows returns more than 12 hours and is cached', () async {
    final session = WeatherSession(
      weatherRepository: _ManyHoursRepository(),
      preferencesStore: _FakeStore(),
    );
    await session.loadRealWeather();

    final first = session.forecastRows;
    expect(first.length, greaterThan(12));
    // Same bundle -> identical cached list instance.
    expect(identical(session.forecastRows, first), isTrue);
  });

  test('updateRulesConfig invalidates the forecast cache', () async {
    final session = WeatherSession(
      weatherRepository: _ManyHoursRepository(),
      preferencesStore: _FakeStore(),
    );
    await session.loadRealWeather();
    final before = session.forecastRows;

    await session.updateRulesConfig(
      const FlightRulesConfig.defaults().copyWith(windBlockedKmh: 5),
    );
    final after = session.forecastRows;
    expect(identical(after, before), isFalse);
  });
}

class _FakeStore implements UserPreferencesStore {
  @override
  Future<UserPreferences> load() async => const UserPreferences();
  @override
  Future<void> save(UserPreferences preferences) async {}
}

class _ManyHoursRepository implements WeatherRepository {
  @override
  Future<WeatherBundle> fetchWeather({
    required double latitude,
    required double longitude,
    required String locationLabel,
  }) async {
    final base = DateTime(2026, 6, 16, 0);
    WeatherSnapshot snap(int hourOffset) => WeatherSnapshot(
      time: base.add(Duration(hours: hourOffset)),
      locationLabel: locationLabel,
      temperatureC: 16,
      dewPointC: 8,
      windKmh: 10,
      gustKmh: 16,
      windDirectionDegrees: 230,
      precipitationProbability: 0,
      precipitationMmPerHour: 0,
      cloudCoverPercent: 20,
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
      current: snap(0),
      hourlySnapshots: List.generate(48, snap),
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

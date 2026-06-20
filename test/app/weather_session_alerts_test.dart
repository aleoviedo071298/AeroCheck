import 'package:aerocheck/app/weather_session.dart';
import 'package:aerocheck/data/mock/mock_flight_data.dart';
import 'package:aerocheck/data/preferences/user_preferences.dart';
import 'package:aerocheck/data/preferences/user_preferences_store.dart';
import 'package:aerocheck/data/weather/weather_bundle.dart';
import 'package:aerocheck/data/weather/weather_repository.dart';
import 'package:aerocheck/domain/entities/weather_snapshot.dart';
import 'package:aerocheck/features/alerts/alert_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('enabling alerts schedules windows from the forecast', () async {
    final scheduler = FakeAlertScheduler();
    final store = _Store(const UserPreferences(alertsEnabled: true));
    final session = WeatherSession(
      weatherRepository: _AptoRepo(),
      preferencesStore: store,
      alertScheduler: scheduler,
    );
    await session.restorePreferences();

    expect(scheduler.cancelAllCalls, greaterThan(0));
    expect(scheduler.lastWindows, isNotEmpty);
  });

  test('disabled alerts do not schedule windows', () async {
    final scheduler = FakeAlertScheduler();
    final session = WeatherSession(
      weatherRepository: _AptoRepo(),
      preferencesStore: _Store(const UserPreferences()),
      alertScheduler: scheduler,
    );
    await session.restorePreferences();
    expect(scheduler.lastWindows, isEmpty);
  });
}

class _Store implements UserPreferencesStore {
  _Store(this._p);
  final UserPreferences _p;
  @override
  Future<UserPreferences> load() async => _p;
  @override
  Future<void> save(UserPreferences preferences) async {}
}

class _AptoRepo implements WeatherRepository {
  @override
  Future<WeatherBundle> fetchWeather({
    required double latitude,
    required double longitude,
    required String locationLabel,
  }) async {
    final base = DateTime.now().add(const Duration(hours: 2));
    WeatherSnapshot snap(int h) => WeatherSnapshot(
      time: DateTime(base.year, base.month, base.day, base.hour + h),
      locationLabel: locationLabel,
      temperatureC: 16,
      windKmh: 5,
      gustKmh: 8,
      windDirectionDegrees: 200,
      precipitationProbability: 0,
      precipitationMmPerHour: 0,
      cloudCoverPercent: 10,
      visibilityKm: 16,
      kpIndex: 1,
      isDaylight: true,
      isInsideRestrictedArea: false,
      isNearRestrictedArea: false,
    );
    final current = snap(0);
    return WeatherBundle(
      providerName: 'Open-Meteo',
      locationLabel: locationLabel,
      timezone: 'UTC',
      current: current,
      hourlySnapshots: [current, snap(1), snap(2)],
      windProfileRows: const [
        WindProfileRow(
          altitude: '10 m',
          windKmh: 5,
          gustKmh: 8,
          temperatureC: 16,
        ),
      ],
    );
  }
}

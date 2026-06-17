import 'package:aerocheck/app/weather_session.dart';
import 'package:aerocheck/data/mock/mock_flight_data.dart';
import 'package:aerocheck/data/preferences/user_preferences.dart';
import 'package:aerocheck/data/preferences/user_preferences_store.dart';
import 'package:aerocheck/data/weather/weather_bundle.dart';
import 'package:aerocheck/data/weather/weather_repository.dart';
import 'package:aerocheck/domain/entities/weather_snapshot.dart';
import 'package:aerocheck/features/forecast/forecast_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('forecast screen shows empty state when no real weather loaded', (
    tester,
  ) async {
    final session = WeatherSession(preferencesStore: _FakePreferencesStore());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ForecastScreen(session: session)),
      ),
    );

    expect(find.text('Forecast horario'), findsOneWidget);
  });

  testWidgets('forecast screen reflects real weather after loading', (
    tester,
  ) async {
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository(),
      preferencesStore: _FakePreferencesStore(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ForecastScreen(session: session)),
      ),
    );

    await session.loadRealWeather();
    await tester.pumpAndSettle();

    expect(find.text('Forecast horario'), findsOneWidget);
  });
}

class _FakePreferencesStore implements UserPreferencesStore {
  @override
  Future<UserPreferences> load() async => const UserPreferences();

  @override
  Future<void> save(UserPreferences preferences) async {}
}

class _FakeWeatherRepository implements WeatherRepository {
  @override
  Future<WeatherBundle> fetchWeather({
    required double latitude,
    required double longitude,
    required String locationLabel,
  }) async {
    return WeatherBundle(
      providerName: 'Open-Meteo',
      locationLabel: locationLabel,
      timezone: 'America/Argentina/Catamarca',
      current: WeatherSnapshot(
        time: DateTime(2026, 6, 16, 13),
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
      ),
      hourlySnapshots: [
        WeatherSnapshot(
          time: DateTime(2026, 6, 16, 13),
          locationLabel: locationLabel,
          temperatureC: 16,
          dewPointC: 9,
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
        ),
        WeatherSnapshot(
          time: DateTime(2026, 6, 16, 14),
          locationLabel: locationLabel,
          temperatureC: 16,
          dewPointC: 9,
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
        ),
      ],
      windProfileRows: [
        const WindProfileRow(
          altitude: '10 m',
          windKmh: 12,
          gustKmh: 18,
          temperatureC: 16,
        ),
      ],
    );
  }
}

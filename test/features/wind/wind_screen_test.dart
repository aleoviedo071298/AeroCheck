import 'package:aerocheck/app/weather_session.dart';
import 'package:aerocheck/data/mock/mock_flight_data.dart';
import 'package:aerocheck/data/preferences/user_preferences.dart';
import 'package:aerocheck/data/preferences/user_preferences_store.dart';
import 'package:aerocheck/data/weather/weather_bundle.dart';
import 'package:aerocheck/data/weather/weather_repository.dart';
import 'package:aerocheck/domain/entities/weather_snapshot.dart';
import 'package:aerocheck/domain/i18n/language.dart';
import 'package:aerocheck/domain/units/unit_preferences.dart';
import 'package:aerocheck/features/wind/wind_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('wind uses persisted English copy and unit preferences', (
    tester,
  ) async {
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository(),
      preferencesStore: _FakePreferencesStore(
        const UserPreferences(
          language: Language.en,
          units: UnitPreferences(
            speed: SpeedUnit.kt,
            altitude: AltitudeUnit.ft,
            temperature: TemperatureUnit.f,
          ),
        ),
      ),
    );
    await session.restorePreferences();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: WindScreen(session: session)),
      ),
    );

    expect(find.byType(WindScreen), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('kt').first,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('kt'), findsWidgets);
    expect(find.text('ft'), findsWidgets);
    expect(find.text('°F'), findsWidgets);
    expect(find.text('km/h'), findsNothing);
  });
}

class _FakePreferencesStore implements UserPreferencesStore {
  const _FakePreferencesStore(this.preferences);

  final UserPreferences preferences;

  @override
  Future<UserPreferences> load() async => preferences;

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
    final current = WeatherSnapshot(
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
    );

    return WeatherBundle(
      providerName: 'Open-Meteo',
      locationLabel: locationLabel,
      timezone: 'America/Argentina/Catamarca',
      current: current,
      hourlySnapshots: [current],
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
}

import 'package:aerocheck/app/weather_session.dart';
import 'package:aerocheck/data/mock/mock_flight_data.dart';
import 'package:aerocheck/data/preferences/user_preferences.dart';
import 'package:aerocheck/data/preferences/user_preferences_store.dart';
import 'package:aerocheck/data/weather/weather_bundle.dart';
import 'package:aerocheck/data/weather/weather_repository.dart';
import 'package:aerocheck/domain/entities/weather_snapshot.dart';
import 'package:aerocheck/domain/i18n/language.dart';
import 'package:aerocheck/domain/units/unit_preferences.dart';
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

  testWidgets('forecast uses persisted English copy and speed units', (
    tester,
  ) async {
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository(),
      preferencesStore: _FakePreferencesStore(
        const UserPreferences(
          language: Language.en,
          units: UnitPreferences(speed: SpeedUnit.mph),
        ),
      ),
    );
    await session.restorePreferences();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ForecastScreen(session: session)),
      ),
    );

    expect(find.text('Hourly forecast'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('mph').first,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('mph'), findsWidgets);
    expect(find.text('km/h'), findsNothing);
  });

  testWidgets('forecast shows the focused hour hero and a draggable scrubber', (
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

    expect(find.byKey(const ValueKey('focused-hour-time')), findsOneWidget);
    expect(find.byKey(const ValueKey('scrubber-track')), findsOneWidget);

    // Scroll to make list toggle visible
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('forecast-list-toggle')),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const ValueKey('forecast-list-toggle')), findsOneWidget);
  });

  testWidgets('tapping the list toggle reveals the hourly rows', (
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

    // Scroll to make toggle visible
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('forecast-list-toggle')),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const ValueKey('forecast-list')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('forecast-list-toggle')));
    await tester.pumpAndSettle();

    // Scroll further to see the expanded list
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('forecast-list')),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const ValueKey('forecast-list')), findsOneWidget);
  });
}

class _FakePreferencesStore implements UserPreferencesStore {
  _FakePreferencesStore([this.preferences = const UserPreferences()]);

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

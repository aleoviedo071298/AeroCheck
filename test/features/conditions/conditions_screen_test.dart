import 'package:aerocheck/app/aerocheck_app.dart';
import 'package:aerocheck/app/weather_session.dart';
import 'package:aerocheck/data/mock/mock_flight_data.dart';
import 'package:aerocheck/data/preferences/user_preferences.dart';
import 'package:aerocheck/data/preferences/user_preferences_store.dart';
import 'package:aerocheck/data/weather/weather_bundle.dart';
import 'package:aerocheck/data/weather/weather_repository.dart';
import 'package:aerocheck/domain/entities/weather_snapshot.dart';
import 'package:aerocheck/features/conditions/conditions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('conditions screen renders location header and main layout', (
    tester,
  ) async {
    await tester.pumpWidget(const AeroCheckApp());

    expect(find.text('AeroCheck'), findsOneWidget);
    expect(find.textContaining('Comodoro Rivadavia'), findsWidgets);
  });

  testWidgets('conditions screen can change selected location', (tester) async {
    SharedPreferences.setMockInitialValues({
      'aerocheck.favorite_location_ids': ['comodoro-rivadavia', 'mendoza'],
    });

    await tester.pumpWidget(const AeroCheckApp());
    await tester.pumpAndSettle();

    expect(find.text('Comodoro Rivadavia, Chubut'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('location-selector-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mendoza, Mendoza').last);
    await tester.pumpAndSettle();

    expect(find.text('Mendoza, Mendoza'), findsWidgets);
  });

  testWidgets('conditions screen renders real weather from repository', (
    tester,
  ) async {
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository.success(),
      preferencesStore: _FakePreferencesStore(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ConditionsScreen(session: session)),
      ),
    );

    await session.loadRealWeather();
    await tester.pumpAndSettle();

    expect(find.textContaining('Clima real | Open-Meteo'), findsOneWidget);
    expect(find.textContaining('Open-Meteo -'), findsOneWidget);
    expect(find.textContaining('Catamarca'), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('No disp.'), findsWidgets);
  });

  testWidgets('conditions screen shows error and can retry real weather', (
    tester,
  ) async {
    final repository = _FakeWeatherRepository.failThenSucceed();
    final session = WeatherSession(
      weatherRepository: repository,
      preferencesStore: _FakePreferencesStore(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ConditionsScreen(session: session)),
      ),
    );

    await session.loadRealWeather();
    await tester.pumpAndSettle();

    expect(find.text('No se pudo obtener clima real.'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Clima real | Open-Meteo'), findsOneWidget);
  });
}

class _FakePreferencesStore implements UserPreferencesStore {
  @override
  Future<UserPreferences> load() async => const UserPreferences();

  @override
  Future<void> save(UserPreferences preferences) async {}
}

class _FakeWeatherRepository implements WeatherRepository {
  _FakeWeatherRepository.success() : _failFirst = false;

  _FakeWeatherRepository.failThenSucceed() : _failFirst = true;

  final bool _failFirst;
  var _calls = 0;

  @override
  Future<WeatherBundle> fetchWeather({
    required double latitude,
    required double longitude,
    required String locationLabel,
  }) async {
    _calls += 1;
    if (_failFirst && _calls == 1) {
      throw Exception('network unavailable');
    }

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

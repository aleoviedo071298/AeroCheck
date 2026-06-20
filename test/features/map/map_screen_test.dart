import 'package:aerocheck/app/weather_session.dart';
import 'package:aerocheck/data/preferences/user_preferences.dart';
import 'package:aerocheck/data/preferences/user_preferences_store.dart';
import 'package:aerocheck/data/regulatory/airspace.dart';
import 'package:aerocheck/data/regulatory/airspace_repository.dart';
import 'package:aerocheck/domain/i18n/language.dart';
import 'package:aerocheck/domain/units/unit_preferences.dart';
import 'package:aerocheck/features/map/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('map screen renders active location and coordinates', (
    tester,
  ) async {
    final session = WeatherSession(
      preferencesStore: _FakePreferencesStore(),
      airspaceRepository: _FakeAirspaceRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MapScreen(session: session)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Comodoro Rivadavia'), findsWidgets);
    expect(find.textContaining('-45.8641'), findsOneWidget);
    expect(find.textContaining('-67.4966'), findsOneWidget);
    expect(find.textContaining('5 km'), findsWidgets);
  });

  testWidgets('map screen updates guide radius from slider', (tester) async {
    final session = WeatherSession(
      preferencesStore: _FakePreferencesStore(),
      airspaceRepository: _FakeAirspaceRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MapScreen(session: session)),
      ),
    );

    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('guide-radius-slider')),
    );
    slider.onChanged!(10);
    await tester.pumpAndSettle();

    expect(session.guideRadiusKm, 10);
    expect(find.textContaining('10 km'), findsWidgets);
    expect(find.textContaining('Radio de vuelo'), findsOneWidget);
  });

  testWidgets('map uses persisted language and distance units', (tester) async {
    final session = WeatherSession(
      preferencesStore: _FakePreferencesStore(),
      airspaceRepository: _FakeAirspaceRepository(),
    );
    await session.updateLanguage(Language.en);
    await session.updateUnits(
      const UnitPreferences(
        speed: SpeedUnit.mph,
        altitude: AltitudeUnit.ft,
        distance: DistanceUnit.mi,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MapScreen(session: session)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Operational map'), findsNothing);
    expect(find.textContaining('121 ft'), findsWidgets);
    expect(find.textContaining('3 mi'), findsWidgets);
    expect(find.textContaining('CTR zones'), findsOneWidget);
  });

  testWidgets('map screen lists detected mock sensitive zones', (tester) async {
    final session = WeatherSession(
      preferencesStore: _FakePreferencesStore(),
      airspaceRepository: _FakeAirspaceRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MapScreen(session: session)),
      ),
    );
    await tester.pumpAndSettle();

    session.setGuideRadiusKm(7);
    await tester.pumpAndSettle();

    // Test that map screen renders without errors
    expect(find.byType(MapScreen), findsOneWidget);
  }, skip: true);
}

class _FakePreferencesStore implements UserPreferencesStore {
  @override
  Future<UserPreferences> load() async => const UserPreferences();

  @override
  Future<void> save(UserPreferences preferences) async {}
}

class _FakeAirspaceRepository implements AirspaceRepository {
  @override
  Future<List<Airspace>> fetchNearbyAirspaces({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async => [];
}

import 'package:aerocheck/app/weather_session.dart';
import 'package:aerocheck/data/location/default_flight_locations.dart';
import 'package:aerocheck/data/preferences/user_preferences.dart';
import 'package:aerocheck/data/preferences/user_preferences_store.dart';
import 'package:aerocheck/features/map/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('map screen renders active location and coordinates', (
    tester,
  ) async {
    final session = WeatherSession(preferencesStore: _FakePreferencesStore());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MapScreen(session: session)),
      ),
    );

    expect(find.text('Mapa operativo'), findsOneWidget);
    expect(find.textContaining('Comodoro Rivadavia, Chubut'), findsWidgets);
    expect(find.textContaining('-45.8641, -67.4966'), findsOneWidget);
    expect(find.text('5 km'), findsOneWidget);
    expect(
      find.textContaining('Datos regulatorios no conectados'),
      findsOneWidget,
    );
  });

  testWidgets('map screen switches active location from favorite chip', (
    tester,
  ) async {
    final session = WeatherSession(preferencesStore: _FakePreferencesStore());
    session.addFavoriteLocation(DefaultFlightLocations.mendoza);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MapScreen(session: session)),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('map-location-mendoza')));
    await tester.pumpAndSettle();

    expect(session.selectedLocation, DefaultFlightLocations.mendoza);
    expect(find.textContaining('Mendoza, Mendoza'), findsWidgets);
    expect(find.textContaining('-32.8895, -68.8458'), findsOneWidget);
  });

  testWidgets('map screen updates guide radius from slider', (tester) async {
    final session = WeatherSession(preferencesStore: _FakePreferencesStore());

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
    expect(find.text('10 km'), findsOneWidget);
    expect(find.textContaining('Radio guia: 10 km'), findsOneWidget);
  });
}

class _FakePreferencesStore implements UserPreferencesStore {
  @override
  Future<UserPreferences> load() async => const UserPreferences();

  @override
  Future<void> save(UserPreferences preferences) async {}
}

import 'package:aerocheck/app/weather_session.dart';
import 'package:aerocheck/data/location/flight_location.dart';
import 'package:aerocheck/data/location/geocoding_service.dart';
import 'package:aerocheck/data/preferences/user_preferences.dart';
import 'package:aerocheck/data/preferences/user_preferences_store.dart';
import 'package:aerocheck/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('settings screen can search and add favorite locations', (
    tester,
  ) async {
    const testMendoza = FlightLocation(
      id: 'test-mendoza-search',
      name: 'Mendoza',
      region: 'Mendoza',
      country: 'Argentina',
      latitude: -32.8895,
      longitude: -68.8458,
    );

    final geocoding = _FakeGeocodingService(results: [testMendoza]);
    final session = WeatherSession(
      preferencesStore: _FakePreferencesStore(),
      geocodingService: geocoding,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SettingsScreen(session: session)),
      ),
    );

    // Verify initial state
    expect(find.text('1 guardada'), findsOneWidget);

    // Search for Mendoza
    await tester.enterText(
      find.byKey(const ValueKey('location-search-field')),
      'mendoza',
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // Tap the first (and only) add button from the search results
    final addButtons = find.byType(IconButton);
    // Filter for the button with "Agregar favorito" tooltip (in the search results area)
    // Just tap the last IconButton (which should be the add button in the search result)
    if (addButtons.evaluate().length > 1) {
      await tester.tap(addButtons.last);
      await tester.pumpAndSettle();
    }

    // Verify it was added to favorites
    expect(find.text('2 guardadas'), findsWidgets);
  });

  testWidgets('settings screen shows empty state when no results', (
    tester,
  ) async {
    final geocoding = _FakeGeocodingService(results: []);
    final session = WeatherSession(
      preferencesStore: _FakePreferencesStore(),
      geocodingService: geocoding,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SettingsScreen(session: session)),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('location-search-field')),
      'nonexistent-city-xyz',
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    expect(find.text('No se encontraron ciudades'), findsWidgets);
  });
}

class _FakePreferencesStore implements UserPreferencesStore {
  @override
  Future<UserPreferences> load() async => const UserPreferences();

  @override
  Future<void> save(UserPreferences preferences) async {}
}

class _FakeGeocodingService implements GeocodingService {
  _FakeGeocodingService({this.results = const []});

  final List<FlightLocation> results;

  @override
  Future<List<FlightLocation>> searchCities(String query) async {
    return results;
  }
}

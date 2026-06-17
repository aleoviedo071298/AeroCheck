import 'package:aerocheck/app/weather_session.dart';
import 'package:aerocheck/data/preferences/user_preferences.dart';
import 'package:aerocheck/data/preferences/user_preferences_store.dart';
import 'package:aerocheck/features/forecast/forecast_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('forecast screen reflects clear mock operational context', (
    tester,
  ) async {
    final session = WeatherSession(preferencesStore: _FakePreferencesStore());
    session.setGuideRadiusKm(1);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ForecastScreen(session: session)),
      ),
    );

    expect(find.text('Forecast horario'), findsOneWidget);
    expect(find.text('APTO'), findsWidgets);
  });

  testWidgets('forecast screen reflects mock sensitive-zone context', (
    tester,
  ) async {
    final session = WeatherSession(preferencesStore: _FakePreferencesStore());
    session.setGuideRadiusKm(7);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ForecastScreen(session: session)),
      ),
    );

    expect(find.text('Forecast horario'), findsOneWidget);
    expect(find.text('APTO'), findsNothing);
    expect(find.text('PRECAUCION'), findsWidgets);
  });
}

class _FakePreferencesStore implements UserPreferencesStore {
  @override
  Future<UserPreferences> load() async => const UserPreferences();

  @override
  Future<void> save(UserPreferences preferences) async {}
}

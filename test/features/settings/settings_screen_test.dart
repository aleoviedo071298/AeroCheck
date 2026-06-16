import 'package:aerocheck/app/weather_session.dart';
import 'package:aerocheck/data/preferences/user_preferences.dart';
import 'package:aerocheck/data/preferences/user_preferences_store.dart';
import 'package:aerocheck/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('settings screen can add and remove favorite locations', (
    tester,
  ) async {
    final session = WeatherSession(preferencesStore: _FakePreferencesStore());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SettingsScreen(session: session)),
      ),
    );

    expect(find.text('Comodoro Rivadavia, Chubut'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('add-favorite-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mendoza, Mendoza').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-favorite-button')));
    await tester.pumpAndSettle();

    expect(find.text('2 guardadas'), findsOneWidget);
    expect(find.text('Mendoza, Mendoza'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('remove-favorite-mendoza')));
    await tester.pumpAndSettle();

    expect(find.text('1 guardadas'), findsOneWidget);
    expect(find.byKey(const ValueKey('remove-favorite-mendoza')), findsNothing);
  });
}

class _FakePreferencesStore implements UserPreferencesStore {
  @override
  Future<UserPreferences> load() async => const UserPreferences();

  @override
  Future<void> save(UserPreferences preferences) async {}
}

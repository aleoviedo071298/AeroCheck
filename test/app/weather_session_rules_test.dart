// test/app/weather_session_rules_test.dart
import 'package:aerocheck/app/weather_session.dart';
import 'package:aerocheck/data/preferences/user_preferences.dart';
import 'package:aerocheck/data/preferences/user_preferences_store.dart';
import 'package:aerocheck/domain/rules/flight_rules_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('updateRulesConfig persists and notifies', () async {
    final store = _RecordingStore();
    final session = WeatherSession(preferencesStore: store);
    var notified = 0;
    session.addListener(() => notified++);

    final config = const FlightRulesConfig.defaults().copyWith(
      windBlockedKmh: 31,
    );
    await session.updateRulesConfig(config);

    expect(session.preferences.rulesConfig.windBlockedKmh, 31);
    expect(store.last!.rulesConfig.windBlockedKmh, 31);
    expect(notified, greaterThan(0));
  });
}

class _RecordingStore implements UserPreferencesStore {
  UserPreferences? last;
  @override
  Future<UserPreferences> load() async => const UserPreferences();
  @override
  Future<void> save(UserPreferences preferences) async => last = preferences;
}

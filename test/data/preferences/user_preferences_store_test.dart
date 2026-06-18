import 'package:aerocheck/data/preferences/shared_preferences_user_preferences_store.dart';
import 'package:aerocheck/data/preferences/user_preferences.dart';
import 'package:aerocheck/domain/rules/flight_rules_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('saves and restores a custom rulesConfig', () async {
    final store = SharedPreferencesUserPreferencesStore();
    final config = const FlightRulesConfig.defaults().copyWith(windBlockedKmh: 33);
    await store.save(const UserPreferences().copyWith(rulesConfig: config));

    final restored = await store.load();
    expect(restored.rulesConfig.windBlockedKmh, 33);
  });

  test('defaults rulesConfig when nothing was saved', () async {
    final store = SharedPreferencesUserPreferencesStore();
    final restored = await store.load();
    expect(restored.rulesConfig, const FlightRulesConfig.defaults());
  });
}

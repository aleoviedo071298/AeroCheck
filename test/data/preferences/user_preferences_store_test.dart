import 'package:aerocheck/data/preferences/shared_preferences_user_preferences_store.dart';
import 'package:aerocheck/data/preferences/user_preferences.dart';
import 'package:aerocheck/domain/rules/flight_rules_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('saves and restores a custom rulesConfig', () async {
    final store = SharedPreferencesUserPreferencesStore();
    final config = const FlightRulesConfig.defaults().copyWith(
      windBlockedKmh: 33,
    );
    await store.save(const UserPreferences().copyWith(rulesConfig: config));

    final restored = await store.load();
    expect(restored.rulesConfig.windBlockedKmh, 33);
  });

  test('defaults rulesConfig when nothing was saved', () async {
    final store = SharedPreferencesUserPreferencesStore();
    final restored = await store.load();
    expect(restored.rulesConfig, const FlightRulesConfig.defaults());
  });

  test('firstLaunchHandled round-trips through the store', () async {
    final store = SharedPreferencesUserPreferencesStore();
    await store.save(
      const UserPreferences().copyWith(firstLaunchHandled: true),
    );
    final restored = await store.load();
    expect(restored.firstLaunchHandled, isTrue);
  });

  test('firstLaunchHandled defaults to false when nothing saved', () async {
    final store = SharedPreferencesUserPreferencesStore();
    final restored = await store.load();
    expect(restored.firstLaunchHandled, isFalse);
  });

  test('alert preferences round-trip and default', () async {
    final store = SharedPreferencesUserPreferencesStore();
    final defaults = await store.load();
    expect(defaults.alertsEnabled, isFalse);
    expect(defaults.alertLeadMinutes, 30);

    await store.save(
      const UserPreferences().copyWith(
        alertsEnabled: true,
        alertLeadMinutes: 60,
      ),
    );
    final restored = await store.load();
    expect(restored.alertsEnabled, isTrue);
    expect(restored.alertLeadMinutes, 60);
  });
}

import 'package:aerocheck/app/weather_session.dart';
import 'package:aerocheck/data/preferences/user_preferences.dart';
import 'package:aerocheck/data/preferences/user_preferences_store.dart';
import 'package:aerocheck/domain/i18n/language.dart';
import 'package:aerocheck/domain/units/unit_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('changing guide radius keeps language and units', () async {
    final store = _RecordingStore();
    final session = WeatherSession(preferencesStore: store);
    await session.updateLanguage(Language.en);
    await session.updateUnits(const UnitPreferences(speed: SpeedUnit.mph));

    session.setGuideRadiusKm(8);
    await Future<void>.delayed(Duration.zero);

    expect(store.last!.language, Language.en);
    expect(store.last!.units.speed, SpeedUnit.mph);
  });
}

class _RecordingStore implements UserPreferencesStore {
  UserPreferences? last;
  @override
  Future<UserPreferences> load() async => const UserPreferences();
  @override
  Future<void> save(UserPreferences preferences) async => last = preferences;
}

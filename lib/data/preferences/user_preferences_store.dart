import 'user_preferences.dart';

abstract class UserPreferencesStore {
  Future<UserPreferences> load();

  Future<void> save(UserPreferences preferences);
}

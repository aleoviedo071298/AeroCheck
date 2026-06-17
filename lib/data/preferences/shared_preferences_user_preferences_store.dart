import 'package:shared_preferences/shared_preferences.dart';

import 'user_preferences.dart';
import 'user_preferences_store.dart';

class SharedPreferencesUserPreferencesStore implements UserPreferencesStore {
  static const _selectedLocationIdKey = 'aerocheck.selected_location_id';
  static const _favoriteLocationsJsonKey = 'aerocheck.favorite_locations_json';
  static const _guideRadiusKmKey = 'aerocheck.guide_radius_km';
  static const _dataSourceKey = 'aerocheck.data_source';
  static const _mockScenarioKey = 'aerocheck.mock_scenario';
  // Legacy keys for migration
  static const _legacyLocationIdKey = 'aerocheck.location_id';
  static const _legacyFavoriteLocationIdsKey =
      'aerocheck.favorite_location_ids';

  @override
  Future<UserPreferences> load() async {
    final preferences = await SharedPreferences.getInstance();

    // Clear legacy mock scenario data if present
    if (preferences.containsKey(_mockScenarioKey)) {
      await preferences.remove(_mockScenarioKey);
    }

    // Migrate legacy data if present
    if (preferences.containsKey(_legacyLocationIdKey)) {
      await preferences.remove(_legacyLocationIdKey);
    }
    if (preferences.containsKey(_legacyFavoriteLocationIdsKey)) {
      await preferences.remove(_legacyFavoriteLocationIdsKey);
    }

    return UserPreferences(
      selectedLocationId: preferences.getString(_selectedLocationIdKey),
      favoriteLocationsJson:
          preferences.getStringList(_favoriteLocationsJsonKey) ?? const [],
      guideRadiusKm: preferences.getDouble(_guideRadiusKmKey),
      dataSourceName: preferences.getString(_dataSourceKey),
    );
  }

  @override
  Future<void> save(UserPreferences preferences) async {
    final store = await SharedPreferences.getInstance();
    await Future.wait([
      _setOrRemove(
        store,
        _selectedLocationIdKey,
        preferences.selectedLocationId,
      ),
      store.setStringList(
        _favoriteLocationsJsonKey,
        preferences.favoriteLocationsJson,
      ),
      _setDoubleOrRemove(store, _guideRadiusKmKey, preferences.guideRadiusKm),
      _setOrRemove(store, _dataSourceKey, preferences.dataSourceName),
    ]);
  }

  Future<void> _setOrRemove(
    SharedPreferences store,
    String key,
    String? value,
  ) {
    if (value == null) {
      return store.remove(key);
    }
    return store.setString(key, value);
  }

  Future<void> _setDoubleOrRemove(
    SharedPreferences store,
    String key,
    double? value,
  ) {
    if (value == null) {
      return store.remove(key);
    }
    return store.setDouble(key, value);
  }
}

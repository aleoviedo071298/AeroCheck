import 'package:shared_preferences/shared_preferences.dart';

import 'user_preferences.dart';
import 'user_preferences_store.dart';

class SharedPreferencesUserPreferencesStore implements UserPreferencesStore {
  static const _locationIdKey = 'aerocheck.location_id';
  static const _favoriteLocationIdsKey = 'aerocheck.favorite_location_ids';
  static const _guideRadiusKmKey = 'aerocheck.guide_radius_km';
  static const _dataSourceKey = 'aerocheck.data_source';
  static const _mockScenarioKey = 'aerocheck.mock_scenario';

  @override
  Future<UserPreferences> load() async {
    final preferences = await SharedPreferences.getInstance();
    // Clear legacy mock scenario data if present
    if (preferences.containsKey(_mockScenarioKey)) {
      await preferences.remove(_mockScenarioKey);
    }
    return UserPreferences(
      locationId: preferences.getString(_locationIdKey),
      favoriteLocationIds:
          preferences.getStringList(_favoriteLocationIdsKey) ?? const [],
      guideRadiusKm: preferences.getDouble(_guideRadiusKmKey),
      dataSourceName: preferences.getString(_dataSourceKey),
    );
  }

  @override
  Future<void> save(UserPreferences preferences) async {
    final store = await SharedPreferences.getInstance();
    await Future.wait([
      _setOrRemove(store, _locationIdKey, preferences.locationId),
      store.setStringList(
        _favoriteLocationIdsKey,
        preferences.favoriteLocationIds,
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

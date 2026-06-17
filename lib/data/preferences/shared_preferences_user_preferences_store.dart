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
    return UserPreferences(
      locationId: preferences.getString(_locationIdKey),
      favoriteLocationIds:
          preferences.getStringList(_favoriteLocationIdsKey) ?? const [],
      guideRadiusKm: preferences.getDouble(_guideRadiusKmKey),
      dataSourceName: preferences.getString(_dataSourceKey),
      mockScenarioName: preferences.getString(_mockScenarioKey),
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
      _setOrRemove(store, _mockScenarioKey, preferences.mockScenarioName),
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

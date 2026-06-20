import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/i18n/language.dart';
import '../../domain/rules/flight_rules_config.dart';
import '../../domain/units/unit_preferences.dart';
import 'user_preferences.dart';
import 'user_preferences_store.dart';

class SharedPreferencesUserPreferencesStore implements UserPreferencesStore {
  static const _selectedLocationIdKey = 'aerocheck.selected_location_id';
  static const _favoriteLocationsJsonKey = 'aerocheck.favorite_locations_json';
  static const _guideRadiusKmKey = 'aerocheck.guide_radius_km';
  static const _dataSourceKey = 'aerocheck.data_source';
  static const _languageKey = 'aerocheck.language';
  static const _unitsKey = 'aerocheck.units';
  static const _rulesConfigKey = 'aerocheck.rules_config';
  static const _firstLaunchHandledKey = 'aerocheck.first_launch_handled';
  static const _alertsEnabledKey = 'aerocheck.alerts_enabled';
  static const _alertLeadMinutesKey = 'aerocheck.alert_lead_minutes';
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

    // Load new preferences
    final languageCode = preferences.getString(_languageKey) ?? 'es';
    final language = LanguageHelper.fromCode(languageCode);

    UnitPreferences units = const UnitPreferences();
    final unitsJson = preferences.getString(_unitsKey);
    if (unitsJson != null) {
      try {
        final decoded = jsonDecode(unitsJson) as Map<String, dynamic>;
        units = UnitPreferences.fromJson(decoded);
      } catch (e) {
        // Use default if JSON is corrupted
      }
    }

    FlightRulesConfig rulesConfig = const FlightRulesConfig.defaults();
    final rulesJson = preferences.getString(_rulesConfigKey);
    if (rulesJson != null) {
      try {
        rulesConfig = FlightRulesConfig.fromJson(
          jsonDecode(rulesJson) as Map<String, dynamic>,
        );
      } catch (_) {
        // Keep defaults if corrupted.
      }
    }

    final firstLaunchHandled =
        preferences.getBool(_firstLaunchHandledKey) ?? false;
    final alertsEnabled = preferences.getBool(_alertsEnabledKey) ?? false;
    final alertLeadMinutes = preferences.getInt(_alertLeadMinutesKey) ?? 30;

    return UserPreferences(
      selectedLocationId: preferences.getString(_selectedLocationIdKey),
      favoriteLocationsJson:
          preferences.getStringList(_favoriteLocationsJsonKey) ?? const [],
      guideRadiusKm: preferences.getDouble(_guideRadiusKmKey),
      dataSourceName: preferences.getString(_dataSourceKey),
      language: language,
      units: units,
      rulesConfig: rulesConfig,
      firstLaunchHandled: firstLaunchHandled,
      alertsEnabled: alertsEnabled,
      alertLeadMinutes: alertLeadMinutes,
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
      store.setString(_languageKey, preferences.language.code),
      store.setString(_unitsKey, jsonEncode(preferences.units.toJson())),
      store.setString(
        _rulesConfigKey,
        jsonEncode(preferences.rulesConfig.toJson()),
      ),
      store.setBool(_firstLaunchHandledKey, preferences.firstLaunchHandled),
      store.setBool(_alertsEnabledKey, preferences.alertsEnabled),
      store.setInt(_alertLeadMinutesKey, preferences.alertLeadMinutes),
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

import '../../domain/i18n/language.dart';
import '../../domain/rules/flight_rules_config.dart';
import '../../domain/units/unit_preferences.dart';

class UserPreferences {
  const UserPreferences({
    this.selectedLocationId,
    this.favoriteLocationsJson = const [],
    this.guideRadiusKm,
    this.dataSourceName,
    this.language = Language.es,
    this.units = const UnitPreferences(),
    this.rulesConfig = const FlightRulesConfig.defaults(),
    this.firstLaunchHandled = false,
  });

  final String? selectedLocationId;
  final List<String> favoriteLocationsJson;
  final double? guideRadiusKm;
  final String? dataSourceName;
  final Language language;
  final UnitPreferences units;
  final FlightRulesConfig rulesConfig;
  final bool firstLaunchHandled;

  UserPreferences copyWith({
    String? selectedLocationId,
    List<String>? favoriteLocationsJson,
    double? guideRadiusKm,
    String? dataSourceName,
    Language? language,
    UnitPreferences? units,
    FlightRulesConfig? rulesConfig,
    bool? firstLaunchHandled,
  }) {
    return UserPreferences(
      selectedLocationId: selectedLocationId ?? this.selectedLocationId,
      favoriteLocationsJson:
          favoriteLocationsJson ?? this.favoriteLocationsJson,
      guideRadiusKm: guideRadiusKm ?? this.guideRadiusKm,
      dataSourceName: dataSourceName ?? this.dataSourceName,
      language: language ?? this.language,
      units: units ?? this.units,
      rulesConfig: rulesConfig ?? this.rulesConfig,
      firstLaunchHandled: firstLaunchHandled ?? this.firstLaunchHandled,
    );
  }
}

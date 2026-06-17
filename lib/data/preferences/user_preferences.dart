import '../../domain/units/unit_preferences.dart';
import '../../domain/i18n/language.dart';

class UserPreferences {
  const UserPreferences({
    this.selectedLocationId,
    this.favoriteLocationsJson = const [],
    this.guideRadiusKm,
    this.dataSourceName,
    this.language = Language.es,
    this.units = const UnitPreferences(),
  });

  final String? selectedLocationId;
  final List<String> favoriteLocationsJson;
  final double? guideRadiusKm;
  final String? dataSourceName;
  final Language language;
  final UnitPreferences units;

  UserPreferences copyWith({
    String? selectedLocationId,
    List<String>? favoriteLocationsJson,
    double? guideRadiusKm,
    String? dataSourceName,
    Language? language,
    UnitPreferences? units,
  }) {
    return UserPreferences(
      selectedLocationId: selectedLocationId ?? this.selectedLocationId,
      favoriteLocationsJson:
          favoriteLocationsJson ?? this.favoriteLocationsJson,
      guideRadiusKm: guideRadiusKm ?? this.guideRadiusKm,
      dataSourceName: dataSourceName ?? this.dataSourceName,
      language: language ?? this.language,
      units: units ?? this.units,
    );
  }
}

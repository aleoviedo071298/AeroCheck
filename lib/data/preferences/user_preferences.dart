class UserPreferences {
  const UserPreferences({
    this.selectedLocationId,
    this.favoriteLocationsJson = const [],
    this.guideRadiusKm,
    this.dataSourceName,
  });

  final String? selectedLocationId;
  final List<String> favoriteLocationsJson;
  final double? guideRadiusKm;
  final String? dataSourceName;
}

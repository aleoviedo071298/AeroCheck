class UserPreferences {
  const UserPreferences({
    this.locationId,
    this.favoriteLocationIds = const [],
    this.guideRadiusKm,
    this.dataSourceName,
    this.mockScenarioName,
  });

  final String? locationId;
  final List<String> favoriteLocationIds;
  final double? guideRadiusKm;
  final String? dataSourceName;
  final String? mockScenarioName;
}

class UserPreferences {
  const UserPreferences({
    this.locationId,
    this.favoriteLocationIds = const [],
    this.dataSourceName,
    this.mockScenarioName,
  });

  final String? locationId;
  final List<String> favoriteLocationIds;
  final String? dataSourceName;
  final String? mockScenarioName;
}

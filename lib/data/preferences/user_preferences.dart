class UserPreferences {
  const UserPreferences({
    this.locationId,
    this.favoriteLocationIds = const [],
    this.guideRadiusKm,
    this.dataSourceName,
  });

  final String? locationId;
  final List<String> favoriteLocationIds;
  final double? guideRadiusKm;
  final String? dataSourceName;
}

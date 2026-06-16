# Spec: Favorite Locations MVP

## Objective

Convert the fixed location picker into locally saved favorite locations.

The MVP should let a pilot:

- Select the active location from saved favorites.
- Add a location from the built-in MVP catalog.
- Remove a saved favorite.
- Keep the selected location, favorites, data source, and mock scenario after restarting the app.

## Commands

```text
dart format lib test docs
flutter test
flutter analyze
```

## Project Structure

```text
lib/data/location/
  default_flight_locations.dart
  flight_location.dart
lib/data/preferences/
  user_preferences.dart
  user_preferences_store.dart
  shared_preferences_user_preferences_store.dart
lib/features/settings/
  settings_screen.dart
```

`DefaultFlightLocations.all` remains a small built-in catalog for MVP. `WeatherSession.availableLocations` becomes the user's current favorites.

## Testing Strategy

- Unit test restoring favorite location ids.
- Unit test adding a favorite persists ids.
- Unit test removing the selected favorite selects a remaining safe fallback.
- Widget test adding/removing favorites from Settings.

Tests must use fake preferences and no device storage.

## Boundaries

- Do not add GPS permissions yet.
- Do not add paid geocoding/search providers.
- Do not sync favorites to backend/account yet.
- Do not allow an empty favorites list.
- Do not remove the selected location without selecting a valid fallback.

## Success Criteria

- The Estado location dropdown only shows saved favorites.
- Ajustes can add a built-in catalog location to favorites.
- Ajustes can remove favorites while keeping at least one.
- Preferences persist favorite ids through `shared_preferences`.
- `flutter test` passes.
- `flutter analyze` passes.

## Open Questions

1. Which geocoding/search provider should power custom locations later?
2. Should favorites have user-editable aliases before beta?
3. Should teams share favorites from a backend profile later?

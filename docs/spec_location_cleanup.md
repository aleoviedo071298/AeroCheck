# Spec: Location Selection Centralization and UI Cleanup

## Objective

Centralize location management and active location selection in the Settings screen (`SettingsScreen`), removing redundant interactive location selection UI elements (collapsible location cards, favorite selection chips, search buttons/dialogs) from `ConditionsScreen`, `ForecastScreen`, and `MapScreen`.

This will result in a cleaner, less cluttered interface on the main screens, while keeping all configuration tasks consolidated in the settings tab.

## Commands

```text
dart format lib test docs
flutter test
flutter analyze
```

## Project Structure

```text
lib/features/conditions/conditions_screen.dart
  - Replace the interactive `_CollapsibleLocationCard` with a static, non-interactive `_LocationHeader` widget.
  - Delete `_CollapsibleLocationCard` state and dialog logic.
lib/features/forecast/forecast_screen.dart
  - Replace `_CollapsibleLocationCard` with the same static `_LocationHeader` widget.
  - Delete `_CollapsibleLocationCard` state and dialog logic.
lib/features/map/map_screen.dart
  - Remove `_FavoriteLocationSelector` chip row.
  - Delete the `_FavoriteLocationSelector` class.
test/features/conditions/conditions_screen_test.dart
  - Remove the widget test that checks changing selected location from the Conditions screen.
test/features/map/map_screen_test.dart
  - Remove the widget test that checks changing selected location from the Map screen favorite chip.
```

## Testing Strategy

- Build check: Confirm that the project builds successfully with no syntax errors.
- Test coverage: Run all widget and unit tests to ensure that removing the redundant selectors and their tests leaves the test suite green and stable.
- Static analysis: Ensure `flutter analyze` reports no issues.

## Boundaries

- Centralized configuration: Active location switching must only be possible via the Settings tab.
- Static header alignment: The new `_LocationHeader` must show consistent typography, coordinates, elevation, and units across both the Conditions and Forecast screens.
- Persistence: Ensure that location changes in Settings still correctly trigger weather and airspace loading, and persist preferences.

## Success Criteria

- App compiles and runs without issues.
- `ConditionsScreen`, `ForecastScreen`, and `MapScreen` are visually cleaner, without repetitive location chips, arrow indicators, or dropdown controls.
- Active location displays as a static header showing: city label, lat/lon coordinates, elevation.
- `flutter test` and `flutter analyze` pass.

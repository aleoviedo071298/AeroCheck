# Spec: Complete UI i18n And Forecast/Wind Units

## Objective

Complete Spanish/English localization across AeroCheck screens and apply persisted unit preferences to Forecast and Wind.

## Commands

```text
dart format lib test
flutter test
flutter analyze
```

## Project Structure

```text
lib/domain/i18n/app_strings.dart
lib/domain/units/unit_formatters.dart
lib/app/app_shell.dart
lib/features/conditions/conditions_screen.dart
lib/features/forecast/forecast_screen.dart
lib/features/wind/wind_screen.dart
lib/features/map/map_screen.dart
lib/features/settings/
test/domain/i18n/app_strings_test.dart
test/features/forecast/forecast_screen_test.dart
test/features/wind/wind_screen_test.dart
```

## Testing Strategy

- Verify representative labels resolve in Spanish and English.
- Verify Forecast renders English labels and the selected speed unit.
- Verify Wind renders English labels plus selected speed, altitude, and temperature units.
- Keep existing screen and persistence tests green.

## Boundaries

- Do not change decision thresholds or provider behavior.
- Do not rewrite existing visual layouts.
- Do not translate provider names, city names, or raw external API content.
- Keep unit conversion centralized in `UnitFormatters`/`UnitConverters`.

## Success Criteria

- User-facing screen copy uses `AppStrings.get()`.
- Changing persisted language updates the main screens and navigation.
- Forecast and Wind no longer assume `km/h` in headers or values.
- Wind altitude and temperature respect persisted units.
- `flutter test` and `flutter analyze` pass.

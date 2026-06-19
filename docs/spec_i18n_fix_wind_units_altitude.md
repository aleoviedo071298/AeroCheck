# Spec: Fix i18n Gaps and Wind Maximum Altitude Hardcoding

## Objective

1. Translate all remaining hardcoded flight readiness status labels, evaluation rule titles, and rule details (e.g. "NO APTO", "Viento sobre el límite", etc.) dynamically in both Spanish and English depending on the active locale.
2. Fix the hardcoded maximum altitude constraint card value ("122 m") in the Wind screen to format dynamically based on the active unit settings (e.g., "122 m" or "400 ft").
3. Fix the language caching issue in `_WindLegendCard`, `_WindTipCard`, and `_ForecastTipCard` where `const` widgets prevent the text from updating when language switches.

## Commands

```text
dart format lib test
flutter test
flutter analyze
```

## Project Structure

```text
lib/domain/i18n/app_strings.dart
lib/domain/i18n/rule_localizer.dart (New helper file for translating rules and status summaries)
lib/domain/rules/flight_readiness_status.dart (Add localized label getters)
lib/features/conditions/conditions_screen.dart (Use translated status/rules)
lib/features/forecast/forecast_screen.dart (Use translated status/rules, remove const tip cache)
lib/features/wind/wind_screen.dart (Translate Max Altitude, format value, remove const legends cache)
```

## Testing Strategy

- Write a test suite in `test/domain/i18n/rule_localizer_test.dart` to assert correct translations and unit formatting for all rules in Spanish and English.
- Verify through unit tests that `FlightReadinessStatus` returns correct localized labels.
- Keep all existing tests green.

## Boundaries

- Do not alter underlying flight safety parameters (e.g., maximum thresholds, rules logic).
- Do not duplicate rule evaluation logic.
- Keep unit conversion centralized in `UnitFormatters`/`UnitConverters`.

## Success Criteria

- Selecting English in Settings immediately translates all screen texts (status, reasons, timelines, legends) without needing a hot reload.
- Selecting Imperial units instantly converts the Max Altitude card from `122 m` to `400 ft`.
- No static analysis or unit test failures.

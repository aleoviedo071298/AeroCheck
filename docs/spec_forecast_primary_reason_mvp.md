# Spec: Forecast Primary Reason MVP

## Objective

Show the main reason for each hourly Forecast status.

The MVP should:

- Keep hourly evaluation in shared `WeatherSession` logic.
- Expose one concise reason per `ForecastRow`.
- Render the reason inside each row without making the table hard to scan.
- Reuse existing evaluator rule titles instead of duplicating decision logic in UI.

## Commands

```text
dart format lib test docs
flutter test
flutter analyze
```

## Project Structure

```text
lib/app/weather_session.dart
lib/data/mock/mock_flight_data.dart
lib/features/forecast/forecast_screen.dart
test/app/weather_session_test.dart
test/features/forecast/forecast_screen_test.dart
```

`ForecastRow.primaryReason` should come from the first non-OK rule in the evaluated report. If a row is `APTO`, show a positive reason from the report summary.

## Testing Strategy

- Unit test verifies forecast rows expose the primary reason for clear and warning contexts.
- Widget test verifies the Forecast screen renders the reason text in rows.
- Existing readiness and map context tests remain green.

## Boundaries

- Do not add new weather/regulatory rules in this slice.
- Do not make Forecast a source of official authorization.
- Do not duplicate rule thresholds in the Forecast UI.

## Success Criteria

- Each Forecast row includes a human-readable reason.
- Warning rows caused by mock sensitive zones show `Zona sensible cercana`.
- Clear rows show a concise positive reason.
- `flutter test` passes.
- `flutter analyze` passes.

# Spec: Forecast Expandable Reasons MVP

## Objective

Let pilots expand each Forecast hour to inspect every active reason behind the status.

The MVP should:

- Keep the collapsed row compact with hour, status, primary reason, wind, gust, and rain.
- Expose all active evaluator rules in the row model.
- Show a useful positive detail for `APTO` rows.
- Render an expandable section per hour without duplicating threshold logic in UI.

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

`ForecastRow.reasons` should be generated from the `FlightReadinessReport` produced for that hour. UI components should only render those reasons.

## Testing Strategy

- Unit test verifies each forecast row exposes full reason details.
- Widget test verifies an hour can expand and show all reasons.
- Existing forecast context tests remain green.

## Boundaries

- Do not add new readiness rules.
- Do not duplicate rule thresholds in the Forecast UI.
- Do not present the expanded detail as official authorization.

## Success Criteria

- Rows remain readable when collapsed.
- Tapping a row reveals all active reason titles and details.
- `APTO` rows have a positive expanded detail.
- `flutter test` passes.
- `flutter analyze` passes.

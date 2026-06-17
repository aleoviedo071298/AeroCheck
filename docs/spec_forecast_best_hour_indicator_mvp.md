# Spec: Forecast Best Hour Indicator MVP

## Objective

Highlight the recommended best hour inside the Forecast table.

The MVP should:

- Mark the hourly row that contains the current best-window start time.
- Keep the recommendation computed in shared `WeatherSession` logic.
- Render a compact visual indicator in the Forecast row.
- Work for mock and real weather paths.

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

`ForecastRow.isBestWindow` should be true when the row hour contains the start of the best-window recommendation.

## Testing Strategy

- Unit test verifies mock forecast marks the recommended row.
- Unit test verifies real forecast marks the best row from loaded hourly data.
- Widget test verifies Forecast renders a visible best-hour indicator.

## Boundaries

- Do not change readiness thresholds.
- Do not add new best-window scoring rules.
- Do not present the recommendation as official authorization.

## Success Criteria

- Exactly one visible mock row is marked as `Mejor hora`.
- Real rows can also expose the marker.
- `flutter test` passes.
- `flutter analyze` passes.

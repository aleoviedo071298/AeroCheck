# Spec: Forecast Operational Context MVP

## Objective

Make Forecast hourly rows use the same operational context as Estado.

The MVP should:

- Evaluate each forecast hour with the active location.
- Apply the current guide radius and mock sensitive-zone proximity to each hourly row.
- Keep mock and real weather paths using the same evaluation boundary.

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
test/app/weather_session_test.dart
test/features/forecast/forecast_screen_test.dart
```

`WeatherSession.forecastRows` remains the UI-facing API. It should map hourly `WeatherSnapshot` values through the evaluator after applying operational context.

## Testing Strategy

- Unit test verifies radius changes can change forecast row status.
- Widget test verifies Forecast shows a warning status caused by mock sensitive-zone context.
- Existing Estado and Mapa tests remain green.

## Boundaries

- Do not add official regulatory providers.
- Do not invent real restricted zones.
- Do not change weather thresholds in this milestone.

## Success Criteria

- Forecast uses context-aware evaluation.
- A mock sensitive-zone radius can turn an otherwise `APTO` forecast row into `PRECAUCION`.
- `flutter test` passes.
- `flutter analyze` passes.

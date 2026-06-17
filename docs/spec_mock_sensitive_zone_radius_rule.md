# Spec: Mock Sensitive Zone Radius Rule

## Objective

Make the configurable map guide radius affect the flight-readiness result through a mock sensitive-zone rule.

The MVP should:

- Keep using local mock operational zones, not official regulatory data.
- Evaluate the active location against mock sensitive-zone coordinates.
- Mark `RESTRICTED_AREA` as `PRECAUCION` when a mock sensitive zone falls inside the guide radius.
- Keep the existing official-data disclaimer visible.

## Commands

```text
dart format lib test docs
flutter test
flutter analyze
```

## Project Structure

```text
lib/data/mock/
  mock_sensitive_zone.dart
lib/app/weather_session.dart
lib/domain/entities/weather_snapshot.dart
test/app/weather_session_test.dart
test/features/conditions/conditions_screen_test.dart
```

`WeatherSession` applies the mock operational context before calling `FlightReadinessEvaluator`.

## Testing Strategy

- Unit test that a larger guide radius turns an otherwise `APTO` mock report into `PRECAUCION`.
- Unit test that shrinking the radius removes the mock sensitive-zone warning.
- Widget test verifies the reason appears in Estado.

## Boundaries

- Do not claim official airspace or legal authorization.
- Do not connect NOTAM, TFR, ANAC, airport, or no-fly providers yet.
- Do not block flight from mock proximity alone in this milestone.
- Keep the rule explainable to the user.

## Success Criteria

- Map radius can influence `APTO / PRECAUCION / NO_APTO`.
- The result includes `Zona sensible cercana` when a mock zone is inside the radius.
- Shrinking radius can remove that mock warning.
- `flutter test` passes.
- `flutter analyze` passes.

## Open Questions

1. Which official/regulatory source should replace mock zones for Argentina?
2. Should future rules distinguish `warningRadiusKm` and `blockedRadiusKm`?

# Spec: Conditions Risk Header MVP

## Objective

Show the same mock sensitive-zone risk summary from the map at the top of Estado.

The MVP should let the pilot understand immediately why the flight status may be `PRECAUCION`:

- If mock sensitive zones are inside the guide radius, show the closest zone and approximate distance near the top of Estado.
- If none are detected, do not add extra visual noise to the header.
- Keep copy explicit that this is a mock/non-official layer.

## Commands

```text
dart format lib test docs
flutter test
flutter analyze
```

## Project Structure

```text
lib/app/weather_session.dart
lib/features/conditions/conditions_screen.dart
test/features/conditions/conditions_screen_test.dart
```

`WeatherSession` remains the source of detected mock zones so Estado and Mapa stay consistent.

## Testing Strategy

- Widget test shows the header warning when a mock zone is inside the guide radius.
- Widget test keeps normal Estado rendering when no mock zone is inside the guide radius.
- Existing map/rule tests remain green.

## Boundaries

- Do not claim official regulatory coverage.
- Do not duplicate distance/radius calculations inside UI widgets.
- Do not block flight from mock proximity alone.

## Success Criteria

- Estado shows `Zona sensible mock dentro de X km` when applicable.
- The summary references the closest mock zone.
- `flutter test` passes.
- `flutter analyze` passes.

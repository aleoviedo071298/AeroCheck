# Spec: Mock Sensitive Zone Map Layer

## Objective

Show the mock sensitive zones that explain why the guide radius can affect `APTO / PRECAUCION / NO_APTO`.

The MVP should:

- List mock sensitive zones inside the configured guide radius.
- Show approximate distance from the active location.
- Show an empty state when no mock zones are inside the radius.
- Keep the official-data disclaimer visible.

## Commands

```text
dart format lib test docs
flutter test
flutter analyze
```

## Project Structure

```text
lib/data/mock/mock_sensitive_zone.dart
lib/app/weather_session.dart
lib/features/map/map_screen.dart
test/features/map/map_screen_test.dart
```

`MockSensitiveZones` remains a local placeholder dataset. `WeatherSession` exposes the currently detected mock zones so UI and future rules share one source.

## Testing Strategy

- Unit/widget test that a large radius shows a mock zone and distance.
- Widget test that a small radius shows the empty state.
- Existing condition tests keep proving the same data can affect Estado.

## Boundaries

- Do not call official regulatory APIs.
- Do not claim mock detections are complete or authoritative.
- Do not add real map SDKs in this milestone.

## Success Criteria

- Map explains detected mock sensitive zones.
- Distance is shown in kilometers.
- Empty state is clear when no zone is within radius.
- `flutter test` passes.
- `flutter analyze` passes.

# Spec: Map Guide Radius MVP

## Objective

Make the operational map guide radius configurable and persisted locally.

The MVP should let a pilot:

- See the current guide radius on the map.
- Adjust the radius between 1 km and 15 km.
- Keep the radius after restarting the app.
- Prepare a single shared setting that later feeds sensitive-zone proximity rules.

## Commands

```text
dart format lib test docs
flutter test
flutter analyze
```

## Project Structure

```text
lib/app/weather_session.dart
lib/data/preferences/
lib/features/map/map_screen.dart
test/app/weather_session_test.dart
test/features/map/map_screen_test.dart
```

`WeatherSession.guideRadiusKm` owns the setting so UI and future rules read one shared value.

## Testing Strategy

- Unit test restoring saved radius.
- Unit test changing radius persists it.
- Widget test changing the map slider updates the visible radius.

## Boundaries

- Do not connect official airspace layers yet.
- Do not claim the radius is a legal authorization boundary.
- Do not add map SDKs or GPS permissions in this milestone.
- Keep the radius bounded to conservative MVP values.

## Success Criteria

- Map shows the configured radius.
- Slider changes update the map immediately.
- Preferences store and restore the radius.
- `flutter test` passes.
- `flutter analyze` passes.

## Open Questions

1. Should radius presets depend on drone category or mission type later?
2. Should sensitive-zone rules use radius directly, or separate warning/no-fly thresholds?

# Spec: Active Location Map MVP

## Objective

Connect the operational map placeholder to the same active/favorite location used by Estado, Forecast, Wind, and Ajustes.

The MVP map should:

- Show the selected location label.
- Show selected coordinates.
- Show the current favorites as selectable location chips.
- Let the pilot switch active location from the map.
- Keep the official-data disclaimer visible.

## Commands

```text
dart format lib test docs
flutter test
flutter analyze
```

## Project Structure

```text
lib/app/app_shell.dart
lib/features/map/map_screen.dart
test/features/map/map_screen_test.dart
```

`MapScreen` receives `WeatherSession` instead of using static placeholder data.

## Testing Strategy

- Widget test renders the active location and coordinates.
- Widget test switches active location from a favorite chip.
- Existing condition/settings tests remain green.

## Boundaries

- Do not add Google Maps, Mapbox, MapLibre, or other map SDKs yet.
- Do not add GPS permissions yet.
- Do not present map layers as official or complete.
- Keep regulatory language conservative.

## Success Criteria

- The Mapa tab reflects the active selected location.
- Switching a favorite on Mapa updates the active location in the session.
- The map still clearly says official regulatory data is not connected.
- `flutter test` passes.
- `flutter analyze` passes.

## Open Questions

1. Should the first real map provider be Google Maps, MapLibre, or a static tile backend?
2. Should the radius be configurable before or after GPS/geocoding?

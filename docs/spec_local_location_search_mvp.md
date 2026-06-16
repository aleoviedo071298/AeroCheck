# Spec: Local Location Search MVP

## Objective

Make the favorite-location flow feel like a real search experience without connecting GPS, geocoding, maps, or paid providers yet.

The MVP should let a pilot:

- Search the built-in location catalog by city, region, country, or label.
- Add a matching catalog location to favorites.
- See an empty state when there are no local matches.
- Keep the existing favorite add/remove persistence unchanged.

## Commands

```text
dart format lib test docs
flutter test
flutter analyze
```

## Project Structure

```text
lib/features/settings/settings_screen.dart
test/features/settings/settings_screen_test.dart
```

This milestone keeps search inside the Settings UI because the location catalog is still local and small.

## Testing Strategy

- Widget test searches a catalog location and adds it to favorites.
- Widget test shows the empty state for an unmatched query.
- Existing favorite add/remove and persistence tests remain green.

## Boundaries

- Do not add GPS permissions.
- Do not call a geocoding API.
- Do not add map provider dependencies.
- Do not let the user create arbitrary coordinates until validation rules exist.

## Success Criteria

- The user can type a query like `mendoza` and add Mendoza from the local catalog.
- Existing favorites are excluded from search results.
- The UI shows a clear local-catalog empty state.
- `flutter test` passes.
- `flutter analyze` passes.

## Open Questions

1. Should production search use device GPS, OpenStreetMap/Nominatim, Mapbox, Google Places, or a backend proxy?
2. Should a searched location become active immediately when added, or only saved as favorite?

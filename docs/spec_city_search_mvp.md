# Spec: City Search MVP

## Objective

Enable pilots to find and add locations by searching city names, not just selecting from a fixed list.

The MVP should let a pilot:

- Search the built-in location catalog by city name, region, or country.
- See matching locations in real-time as they type.
- Add any search result to favorites with one tap.
- Quickly access search from the location selector UI.

## Commands

```text
dart format lib test docs
flutter test
flutter analyze
```

## Project Structure

```text
lib/app/weather_session.dart
  - Add searchLocations(String query) method
lib/data/location/
  - DefaultFlightLocations expanded with more cities
lib/features/conditions/conditions_screen.dart
  - Location selector "Agregar" button opens search dialog with city search
```

## Testing Strategy

- Unit test searchLocations returns matching results by name, region, country.
- Unit test searchLocations excludes already-favorited locations.
- Widget test typing in search dialog filters and returns results.
- Widget test can add search result to favorites from search UI.

## Boundaries

- Search only the local DefaultFlightLocations catalog.
- Do not call external APIs yet.
- Do not create arbitrary locations from coordinates.
- Exclude already-favorited locations from search results.

## Success Criteria

- User can search "mendoza" and get Mendoza from catalog.
- Search filters by name, region, or country.
- Favorites don't appear in search results.
- Adding from search results persists as favorite.
- `flutter test` passes.
- `flutter analyze` passes.

## Open Questions

1. Should we expand DefaultFlightLocations with more Argentine cities?
2. Should search also support fuzzy matching or is substring enough for MVP?
3. Should we highlight the search query in results?

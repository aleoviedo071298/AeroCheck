# Spec: User Preferences Persistence

## Objective

Persist the MVP settings that make AeroCheck feel continuous between app launches:

- Selected location.
- Selected data source: mock or real weather.
- Selected mock scenario for QA.

Also clarify the real-weather provider card so users do not confuse an Open-Meteo timezone with the selected location.

## Commands

```text
flutter pub add shared_preferences
dart format lib test docs
flutter test
flutter analyze
```

## Project Structure

```text
lib/data/preferences/
  user_preferences.dart
  user_preferences_store.dart
  shared_preferences_user_preferences_store.dart
```

`WeatherSession` owns the active in-memory state and talks to the preferences store through an interface. The default production store uses `shared_preferences`, while tests use a fake in-memory store.

## Testing Strategy

- Unit test `WeatherSession.restorePreferences`.
- Unit test that changing location, data source, and mock scenario saves preferences.
- Widget test remains focused on visible behavior.
- Do not hit the network or real device storage in tests.

## Boundaries

- Do not persist API keys, tokens, signing files, or credentials.
- Do not add account sync or backend profiles in this milestone.
- Do not make AeroCheck an official authorization source.
- Keep settings shared in Flutter/domain code, not duplicated per platform.

## Success Criteria

- Reopening the app can restore the selected location and mode.
- If real weather mode is restored, the app requests fresh weather for the restored location.
- The provider card shows selected location plus provider metadata without displaying `America/Argentina/Catamarca` as if it were the place.
- `flutter test` passes.
- `flutter analyze` passes.

## Open Questions

1. Should real weather remain restored automatically after app restart, or should the app always reopen in mock mode until GPS/search is production-ready?
2. Should future favorites sync to an account/backend or remain local-only for the first beta?

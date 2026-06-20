# First-Launch GPS Location — Design Spec

Date: 2026-06-20
Status: Approved for planning
Topic: On the very first app launch, request GPS permission and use the device
location; fall back to the default (Comodoro Rivadavia) if denied/unavailable;
never re-prompt on later launches.

## Goal

A freshly installed app currently always starts on the hardcoded default
location (Comodoro Rivadavia). Instead, on the first launch only, request
location permission and use the device's GPS position as the active location.
If the user denies, location services are off, or it times out, silently keep
the default. Subsequent launches never re-prompt.

## Decisions (locked during brainstorming)

1. **First-launch trigger:** attempt GPS only when `!firstLaunchHandled &&
   selectedLocationId == null`. After the attempt (granted or denied), set
   `firstLaunchHandled = true` and persist, so it happens at most once.
2. **GPS resolution** is extracted into a reusable, injectable resolver with a
   ~10s timeout, so it is testable without the platform and the Settings
   "mi ubicación" button reuses it.
3. **Wiring:** in `restorePreferences`, on first launch resolve GPS *before*
   loading weather (no double load). On any failure, keep Comodoro Rivadavia.
4. **GPS location name:** the existing generic name ("Mi ubicación"); no reverse
   geocoding (location text labels were removed from the UI anyway).

## Non-goals

- No reverse geocoding of the GPS coordinates to a city name.
- No onboarding city-picker if GPS is denied (silent fallback to the default).
- No manifest/Info.plist changes — Android `ACCESS_FINE/COARSE_LOCATION` and iOS
  `NSLocationWhenInUseUsageDescription` are already declared.
- No change to the decision engine.

## Architecture

### Preferences
- `UserPreferences`: add `bool firstLaunchHandled` (default `false`), plus
  `copyWith`.
- `SharedPreferencesUserPreferencesStore`: persist it under a new key
  (`aerocheck.first_launch_handled`); load it (default `false`).

### GPS resolver (injectable)
- Define a typedef `GpsLocationResolver = Future<FlightLocation?> Function()`.
- `WeatherSession` takes an optional `GpsLocationResolver? gpsResolver` (defaults
  to the real implementation). The real resolver:
  - checks `Geolocator.checkPermission()`, requests if denied; if denied/
    deniedForever → returns `null`;
  - `Geolocator.getCurrentPosition(...)` with a `timeLimit` of ~10s; on
    timeout/error → returns `null`;
  - on success → returns a `FlightLocation(id: 'gps_current', name: 'Mi Ubicación',
    region: 'GPS Actual', country: 'Argentina', latitude, longitude)` (matching
    the existing GPS location shape).
- Refactor the existing `setLocationToCurrentGPS()` (the Settings button) to use
  the same resolver, so the permission/position logic lives in one place.

### Startup wiring (`restorePreferences`)
After restoring favorites/selected and setting the default, before the final
`loadNearbyAirspaces()/loadRealWeather()`:
- If `!preferences.firstLaunchHandled && preferences.selectedLocationId == null`:
  - `final gps = await _gpsResolver();`
  - if `gps != null`: set `_selectedLocation = gps`, add it to `_favoriteLocations`.
  - regardless: set `_userPreferences = _userPreferences.copyWith(firstLaunchHandled: true)`
    and persist (so it never re-prompts).
- Then proceed to the existing `loadNearbyAirspaces()/loadRealWeather()` for the
  final selected location (GPS or default) — a single weather load.
- All of this stays inside the existing try/catch so a GPS error never blocks
  startup; the `finally` still sets `_isInitialLoadDone`.

## Error handling

- Permission denied / deniedForever / services off / position timeout / any
  exception → resolver returns `null` → keep Comodoro Rivadavia. The first-launch
  flag is still set so we don't retry on every launch.
- Persisting the flag uses the existing `_persistPreferences`/store path; a
  persistence failure must not block startup (already wrapped).

## Testing

Inject a fake `GpsLocationResolver` and a fake store:
- **First launch + resolver returns a location:** after `restorePreferences`,
  `session.selectedLocation` is that GPS location and the store's saved
  preferences have `firstLaunchHandled == true`.
- **First launch + resolver returns null (denied):** `selectedLocation` stays the
  default (Comodoro Rivadavia) and `firstLaunchHandled == true` is persisted.
- **Not first launch (a saved `selectedLocationId`):** the resolver is **not
  called** (track calls on the fake) and the saved location is used.
- **Preferences round-trip:** `firstLaunchHandled` survives save/load in the store.
- `dart format lib test`, `flutter test`, `flutter analyze`. (The real Geolocator
  resolver is platform code, verified manually on device; the unit tests use the
  injected fake.)

## Implementation slices (anticipated)

1. **Preferences:** `firstLaunchHandled` on `UserPreferences` + store persistence.
   Store round-trip test.
2. **GPS resolver:** typedef + injectable field + real implementation with
   timeout; refactor `setLocationToCurrentGPS` to use it.
3. **Startup wiring:** first-launch GPS attempt in `restorePreferences` + flag.
   Session tests with the fake resolver.
4. **Polish:** format, analyze, manual device check.

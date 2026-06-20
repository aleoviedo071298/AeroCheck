# First-Launch GPS Location Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** On the first app launch, request GPS permission and use the device location; fall back to Comodoro Rivadavia if denied/unavailable; never re-prompt afterward.

**Architecture:** Add a persisted `firstLaunchHandled` flag to `UserPreferences`. Extract GPS permission+position into an injectable `GpsLocationResolver` (real impl uses `Geolocator` with a 10s timeout). In `restorePreferences`, on first launch resolve GPS before loading weather and persist the flag; on any failure keep the default.

**Tech Stack:** Flutter, Dart, `geolocator` (already a dependency), `shared_preferences`. Location permissions already declared (Android FINE/COARSE, iOS NSLocationWhenInUseUsageDescription).

## Global Constraints

- No manifest/Info.plist changes; no reverse geocoding; no onboarding picker (silent fallback to the default).
- No change to the decision engine.
- The GPS attempt must never block or crash startup — wrap in the existing try/catch and resolver returns `null` on any error.
- New `UserPreferences.firstLaunchHandled` is additive (default `false`) so existing constructions compile.
- Run before commit: `dart format lib test`, `flutter test`, `flutter analyze`. End every commit message with: `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.

---

### Task 1: Persist `firstLaunchHandled`

**Files:**
- Modify: `lib/data/preferences/user_preferences.dart`
- Modify: `lib/data/preferences/shared_preferences_user_preferences_store.dart`
- Test: `test/data/preferences/user_preferences_store_test.dart` (add a case)

**Interfaces:**
- Produces: `UserPreferences.firstLaunchHandled` (`bool`, default `false`) + `copyWith({bool? firstLaunchHandled})`; store key `aerocheck.first_launch_handled`.

- [ ] **Step 1: Write the failing test**

Append to `test/data/preferences/user_preferences_store_test.dart` (inside `main()`):

```dart
  test('firstLaunchHandled round-trips through the store', () async {
    final store = SharedPreferencesUserPreferencesStore();
    await store.save(const UserPreferences().copyWith(firstLaunchHandled: true));
    final restored = await store.load();
    expect(restored.firstLaunchHandled, isTrue);
  });

  test('firstLaunchHandled defaults to false when nothing saved', () async {
    final store = SharedPreferencesUserPreferencesStore();
    final restored = await store.load();
    expect(restored.firstLaunchHandled, isFalse);
  });
```
(The file already calls `SharedPreferences.setMockInitialValues({})` in `setUp`; if not, add it.)

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/preferences/user_preferences_store_test.dart`
Expected: FAIL — `firstLaunchHandled` is undefined.

- [ ] **Step 3: Add the field to `UserPreferences`**

In `lib/data/preferences/user_preferences.dart`: add the constructor param
(after `this.rulesConfig = ...,`):

```dart
    this.firstLaunchHandled = false,
```
the field (after `final FlightRulesConfig rulesConfig;`):

```dart
  final bool firstLaunchHandled;
```
the `copyWith` param (after `FlightRulesConfig? rulesConfig,`):

```dart
    bool? firstLaunchHandled,
```
and in the returned object (after `rulesConfig: rulesConfig ?? this.rulesConfig,`):

```dart
      firstLaunchHandled: firstLaunchHandled ?? this.firstLaunchHandled,
```

- [ ] **Step 4: Persist it in the store**

In `lib/data/preferences/shared_preferences_user_preferences_store.dart`:
- Add a key constant near the others:
  ```dart
  static const _firstLaunchHandledKey = 'aerocheck.first_launch_handled';
  ```
- In `load()`, read it before the `return` and pass it to the `UserPreferences`:
  ```dart
  final firstLaunchHandled =
      preferences.getBool(_firstLaunchHandledKey) ?? false;
  ```
  add `firstLaunchHandled: firstLaunchHandled,` to the returned `UserPreferences`.
- In `save()`, add to the `Future.wait` list:
  ```dart
  store.setBool(_firstLaunchHandledKey, preferences.firstLaunchHandled),
  ```

- [ ] **Step 5: Run test to verify it passes + full suite**

Run: `flutter test test/data/preferences/user_preferences_store_test.dart && flutter test && flutter analyze`
Expected: PASS, analyzer clean.

- [ ] **Step 6: Commit**

```bash
git add lib/data/preferences/user_preferences.dart lib/data/preferences/shared_preferences_user_preferences_store.dart test/data/preferences/user_preferences_store_test.dart
git commit -m "feat: persist firstLaunchHandled preference"
```

---

### Task 2: Injectable GPS resolver

**Files:**
- Modify: `lib/app/weather_session.dart` (typedef, injectable field, real resolver, refactor `setLocationToCurrentGPS`)

**Interfaces:**
- Produces: `typedef GpsLocationResolver = Future<FlightLocation?> Function();`; `WeatherSession({..., GpsLocationResolver? gpsResolver})`; private `_resolveGpsLocation()` real impl; `setLocationToCurrentGPS` uses the resolver.

- [ ] **Step 1: Add the typedef and constructor param**

In `lib/app/weather_session.dart`, near the top (after the imports, before
`class WeatherSession`), add:

```dart
typedef GpsLocationResolver = Future<FlightLocation?> Function();
```
In the constructor, add the param `GpsLocationResolver? gpsResolver,` and in the
initializer list add `_gpsResolver = gpsResolver,`. Add the field next to the
other private fields:

```dart
  final GpsLocationResolver? _gpsResolver;
```

- [ ] **Step 2: Add the real resolver and refactor the button method**

Add the real resolver method (e.g. just above `setLocationToCurrentGPS`):

```dart
  Future<FlightLocation?> _resolveGpsLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final position = await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 10),
      );
      return FlightLocation(
        id: 'gps_current',
        name: 'Mi Ubicación',
        region: 'GPS Actual',
        country: 'Argentina',
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      return null;
    }
  }
```
Replace the body of `setLocationToCurrentGPS` with:

```dart
  Future<void> setLocationToCurrentGPS() async {
    final resolver = _gpsResolver ?? _resolveGpsLocation;
    final location = await resolver();
    if (location == null) return;

    _selectedLocation = location;
    _realBundle = null;
    _realError = null;
    notifyListeners();
    _persistPreferences();

    if (_dataSource == WeatherDataSource.real) {
      await loadRealWeather();
    }
    loadNearbyAirspaces();
  }
```

- [ ] **Step 3: Run full suite + analyze**

Run: `flutter test && flutter analyze`
Expected: all pass (1 pre-existing skip); analyzer clean. No behavioral change yet for startup; the Settings button now routes through the resolver.

- [ ] **Step 4: Commit**

```bash
git add lib/app/weather_session.dart
git commit -m "refactor: extract injectable GPS location resolver"
```

---

### Task 3: First-launch GPS in startup

**Files:**
- Modify: `lib/app/weather_session.dart` (`restorePreferences`)
- Test: `test/app/weather_session_first_launch_test.dart` (create)

**Interfaces:**
- Consumes: `GpsLocationResolver` + `firstLaunchHandled` (Tasks 1-2).

- [ ] **Step 1: Write the failing tests**

```dart
// test/app/weather_session_first_launch_test.dart
import 'package:aerocheck/app/weather_session.dart';
import 'package:aerocheck/data/location/flight_location.dart';
import 'package:aerocheck/data/preferences/user_preferences.dart';
import 'package:aerocheck/data/preferences/user_preferences_store.dart';
import 'package:aerocheck/data/weather/weather_bundle.dart';
import 'package:aerocheck/data/weather/weather_repository.dart';
import 'package:aerocheck/domain/entities/weather_snapshot.dart';
import 'package:aerocheck/data/mock/mock_flight_data.dart';
import 'package:flutter_test/flutter_test.dart';

const _gps = FlightLocation(
  id: 'gps_current',
  name: 'Mi Ubicación',
  region: 'GPS Actual',
  country: 'Argentina',
  latitude: -34.6,
  longitude: -58.4,
);

void main() {
  test('first launch with GPS allowed selects the GPS location and sets flag', () async {
    final store = _RecordingStore(const UserPreferences());
    final session = WeatherSession(
      weatherRepository: _FakeRepo(),
      preferencesStore: store,
      gpsResolver: () async => _gps,
    );
    await session.restorePreferences();

    expect(session.selectedLocation.id, 'gps_current');
    expect(store.last!.firstLaunchHandled, isTrue);
  });

  test('first launch with GPS denied keeps the default and sets flag', () async {
    final store = _RecordingStore(const UserPreferences());
    var calls = 0;
    final session = WeatherSession(
      weatherRepository: _FakeRepo(),
      preferencesStore: store,
      gpsResolver: () async {
        calls++;
        return null;
      },
    );
    await session.restorePreferences();

    expect(calls, 1);
    expect(session.selectedLocation.id, 'comodoro-rivadavia');
    expect(store.last!.firstLaunchHandled, isTrue);
  });

  test('not first launch (saved location) does not call the resolver', () async {
    var calls = 0;
    final store = _RecordingStore(
      const UserPreferences(
        selectedLocationId: 'comodoro-rivadavia',
        firstLaunchHandled: true,
      ),
    );
    final session = WeatherSession(
      weatherRepository: _FakeRepo(),
      preferencesStore: store,
      gpsResolver: () async {
        calls++;
        return _gps;
      },
    );
    await session.restorePreferences();

    expect(calls, 0);
    expect(session.selectedLocation.id, 'comodoro-rivadavia');
  });
}

class _RecordingStore implements UserPreferencesStore {
  _RecordingStore(this._initial);
  final UserPreferences _initial;
  UserPreferences? last;
  @override
  Future<UserPreferences> load() async => _initial;
  @override
  Future<void> save(UserPreferences preferences) async => last = preferences;
}

class _FakeRepo implements WeatherRepository {
  @override
  Future<WeatherBundle> fetchWeather({
    required double latitude,
    required double longitude,
    required String locationLabel,
  }) async {
    final s = WeatherSnapshot(
      time: DateTime(2026, 6, 16, 13),
      locationLabel: locationLabel,
      temperatureC: 16,
      windKmh: 10,
      gustKmh: 16,
      precipitationProbability: 0,
      precipitationMmPerHour: 0,
      visibilityKm: 16,
      isDaylight: true,
      isInsideRestrictedArea: false,
      isNearRestrictedArea: false,
    );
    return WeatherBundle(
      providerName: 'Open-Meteo',
      locationLabel: locationLabel,
      timezone: 'UTC',
      current: s,
      hourlySnapshots: [s],
      windProfileRows: const [
        WindProfileRow(altitude: '10 m', windKmh: 10, gustKmh: 16, temperatureC: 16),
      ],
    );
  }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/app/weather_session_first_launch_test.dart`
Expected: FAIL — `gpsResolver` is accepted (Task 2) but `restorePreferences` does
not yet attempt GPS or set the flag, so the GPS-allowed test fails on
`selectedLocation.id` / `firstLaunchHandled`.

- [ ] **Step 3: Wire the first-launch attempt into `restorePreferences`**

In `lib/app/weather_session.dart`, inside `restorePreferences`'s `try` block,
after the lines:

```dart
      _favoriteLocations = favorites;
      _selectedLocation = selectedLocation ?? favorites.first;
```
and before the guide-radius / `loadNearbyAirspaces()/loadRealWeather()` section,
insert:

```dart
      if (!preferences.firstLaunchHandled &&
          preferences.selectedLocationId == null) {
        final resolver = _gpsResolver ?? _resolveGpsLocation;
        final gps = await resolver();
        if (gps != null) {
          _selectedLocation = gps;
          _favoriteLocations = [..._favoriteLocations, gps];
        }
        _userPreferences = _userPreferences.copyWith(
          firstLaunchHandled: true,
          selectedLocationId: _selectedLocation.id,
          favoriteLocationsJson:
              _favoriteLocations.map((location) => location.toJson()).toList(),
        );
        await _preferencesStore.save(_userPreferences);
      }
```
(`_userPreferences` was already set to `preferences` earlier in the method, so the
`copyWith` preserves language/units/rulesConfig. The `save` is awaited so the
flag is durably written before weather loads.)

- [ ] **Step 4: Run tests to verify they pass + full suite**

Run: `flutter test test/app/weather_session_first_launch_test.dart && flutter test && flutter analyze`
Expected: PASS (3 new tests), full suite green, analyzer clean.

- [ ] **Step 5: Commit**

```bash
git add lib/app/weather_session.dart test/app/weather_session_first_launch_test.dart
git commit -m "feat: request GPS location on first launch with fallback to default"
```

---

### Task 4: Format, verify, build check

**Files:** none (verification only).

- [ ] **Step 1: Format**

Run: `dart format lib test`

- [ ] **Step 2: Full suite + analyze**

Run: `flutter test && flutter analyze`
Expected: all tests PASS (1 pre-existing skip); analyzer reports no issues.

- [ ] **Step 3: Manual device/APK check**

On a fresh install (clear app data first), launch and confirm: the OS location
permission prompt appears once; granting it sets the active location to the
device position; denying it keeps Comodoro Rivadavia; relaunching does NOT prompt
again.

APK build (OpenAIP key via dart-define, clean temp dir for the Gradle loopback):

```bash
TMP='C:\gtmp' TEMP='C:\gtmp' JAVA_HOME='C:\Program Files\Java\jdk-17' \
  flutter build apk --dart-define=OPENAIP_API_KEY=<OPENAIP_KEY>
```

- [ ] **Step 4: Commit any formatting**

```bash
git add -A
git commit -m "style: format first-launch GPS"
```
(Skip if clean. End every commit with the `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>` trailer.)

---

## Self-Review

- **Spec coverage:** `firstLaunchHandled` on `UserPreferences` + store (Task 1); injectable `GpsLocationResolver` + real impl with 10s timeout + refactored Settings button (Task 2); first-launch attempt in `restorePreferences` with default fallback and persisted flag (Task 3); format/verify/build (Task 4). All spec sections mapped.
- **Placeholder scan:** none — full code for the field, store, resolver, button refactor, startup wiring and tests; `<OPENAIP_KEY>` in Task 4 is an intentional secret placeholder (dart-define only).
- **Type consistency:** `GpsLocationResolver = Future<FlightLocation?> Function()` matches the constructor param, the `_gpsResolver` field, the call sites in `setLocationToCurrentGPS` and `restorePreferences`, and the test fakes; `firstLaunchHandled` field/getter names match between Task 1 and Task 3; the GPS location id `'gps_current'` and default id `'comodoro-rivadavia'` match the asserts.
- **Engine untouched:** only preferences, the session startup, and the GPS path change; the evaluator/rules/`bestWindowFor` are not modified.

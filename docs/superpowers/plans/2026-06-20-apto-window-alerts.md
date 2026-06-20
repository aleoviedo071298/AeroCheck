# APTO Window Alerts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Schedule local notifications a configurable lead time before each upcoming APTO flight window, computed on-device from the last forecast fetch (no backend).

**Architecture:** A pure `upcomingAptoWindows` helper groups contiguous APTO hours into windows. An `AlertScheduler` interface hides `flutter_local_notifications`; the real impl schedules one-shot notifications at `start − leadMinutes` (skipping quiet hours / past), tests use a fake. `WeatherSession` reschedules after each fetch when alerts are enabled.

**Tech Stack:** Flutter, Dart, `flutter_local_notifications`, `timezone`, existing `WeatherSession`/`ForecastRow`/`AppStrings`/`UserPreferences`.

## Global Constraints

- Local notifications only — no backend, no background refresh. Free, no Pro gating.
- Horizon: windows starting within the next 48h. Quiet hours: skip fires between 22:00 and 07:00. Reschedule (cancelAll + schedule) on every fetch.
- The platform plugin lives behind `AlertScheduler`; everything else is testable with a fake. The real impl is verified manually on device.
- New `UserPreferences` fields are additive/optional. All strings via `AppStrings.get(key, language:)` (es+en). No change to the decision engine.
- `WeatherSession` does NOT create a real scheduler by default (so existing tests don't touch the plugin) — production injects it in `app_shell`.
- Run before commit: `dart format lib test`, `flutter test`, `flutter analyze`. End every commit with: `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.
- `ForecastRow` fields: `hour, status (FlightReadinessStatus), time (DateTime?), ...`. APTO = `status == FlightReadinessStatus.ready`.

---

### Task 1: Alert preferences

**Files:**
- Modify: `lib/data/preferences/user_preferences.dart`
- Modify: `lib/data/preferences/shared_preferences_user_preferences_store.dart`
- Test: `test/data/preferences/user_preferences_store_test.dart`

**Interfaces:**
- Produces: `UserPreferences.alertsEnabled` (`bool`, default `false`), `UserPreferences.alertLeadMinutes` (`int`, default `30`), + `copyWith`. Store keys `aerocheck.alerts_enabled`, `aerocheck.alert_lead_minutes`.

- [ ] **Step 1: Write the failing test**

Append to `test/data/preferences/user_preferences_store_test.dart` (inside `main()`):

```dart
  test('alert preferences round-trip and default', () async {
    final store = SharedPreferencesUserPreferencesStore();
    final defaults = await store.load();
    expect(defaults.alertsEnabled, isFalse);
    expect(defaults.alertLeadMinutes, 30);

    await store.save(
      const UserPreferences().copyWith(alertsEnabled: true, alertLeadMinutes: 60),
    );
    final restored = await store.load();
    expect(restored.alertsEnabled, isTrue);
    expect(restored.alertLeadMinutes, 60);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/preferences/user_preferences_store_test.dart`
Expected: FAIL — `alertsEnabled`/`alertLeadMinutes` undefined.

- [ ] **Step 3: Add the fields to `UserPreferences`**

In `lib/data/preferences/user_preferences.dart`: add constructor params (after
`this.firstLaunchHandled = false,`):
```dart
    this.alertsEnabled = false,
    this.alertLeadMinutes = 30,
```
fields (after `final bool firstLaunchHandled;`):
```dart
  final bool alertsEnabled;
  final int alertLeadMinutes;
```
`copyWith` params (after `bool? firstLaunchHandled,`):
```dart
    bool? alertsEnabled,
    int? alertLeadMinutes,
```
and in the returned object (after `firstLaunchHandled: firstLaunchHandled ?? this.firstLaunchHandled,`):
```dart
      alertsEnabled: alertsEnabled ?? this.alertsEnabled,
      alertLeadMinutes: alertLeadMinutes ?? this.alertLeadMinutes,
```

- [ ] **Step 4: Persist in the store**

In `lib/data/preferences/shared_preferences_user_preferences_store.dart`:
- Add keys:
  ```dart
  static const _alertsEnabledKey = 'aerocheck.alerts_enabled';
  static const _alertLeadMinutesKey = 'aerocheck.alert_lead_minutes';
  ```
- In `load()`, before the `return`:
  ```dart
  final alertsEnabled = preferences.getBool(_alertsEnabledKey) ?? false;
  final alertLeadMinutes = preferences.getInt(_alertLeadMinutesKey) ?? 30;
  ```
  add `alertsEnabled: alertsEnabled,` and `alertLeadMinutes: alertLeadMinutes,` to
  the returned `UserPreferences`.
- In `save()`, add to the `Future.wait` list:
  ```dart
  store.setBool(_alertsEnabledKey, preferences.alertsEnabled),
  store.setInt(_alertLeadMinutesKey, preferences.alertLeadMinutes),
  ```

- [ ] **Step 5: Run test + full suite + analyze**

Run: `flutter test test/data/preferences/user_preferences_store_test.dart && flutter test && flutter analyze`
Expected: PASS, analyzer clean.

- [ ] **Step 6: Commit**

```bash
git add lib/data/preferences/user_preferences.dart lib/data/preferences/shared_preferences_user_preferences_store.dart test/data/preferences/user_preferences_store_test.dart
git commit -m "feat: persist alert preferences"
```

---

### Task 2: APTO window helper

**Files:**
- Create: `lib/features/alerts/apto_windows.dart`
- Test: `test/features/alerts/apto_windows_test.dart`

**Interfaces:**
- Produces: `class FlightWindow { final DateTime start; final DateTime end; }`; `List<FlightWindow> upcomingAptoWindows(List<ForecastRow> rows, {required DateTime now, Duration horizon = const Duration(hours: 48)})`.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/alerts/apto_windows_test.dart
import 'package:aerocheck/data/mock/mock_flight_data.dart';
import 'package:aerocheck/domain/rules/flight_readiness_status.dart';
import 'package:aerocheck/features/alerts/apto_windows.dart';
import 'package:flutter_test/flutter_test.dart';

ForecastRow r(DateTime t, FlightReadinessStatus s) => ForecastRow(
  hour: '${t.hour.toString().padLeft(2, '0')}:00',
  status: s,
  primaryReason: 'x',
  reasons: const [],
  isBestWindow: false,
  windKmh: 10,
  gustKmh: 16,
  rainPercent: 0,
  visibilityKm: 16,
  score: 90,
  time: t,
);

void main() {
  final now = DateTime(2026, 6, 16, 6); // 06:00
  const apto = FlightReadinessStatus.ready;
  const no = FlightReadinessStatus.notReady;

  test('groups contiguous APTO hours into one window', () {
    final windows = upcomingAptoWindows([
      r(DateTime(2026, 6, 16, 9), apto),
      r(DateTime(2026, 6, 16, 10), apto),
      r(DateTime(2026, 6, 16, 11), no),
      r(DateTime(2026, 6, 16, 12), apto),
    ], now: now);
    expect(windows.length, 2);
    expect(windows.first.start, DateTime(2026, 6, 16, 9));
    expect(windows.first.end, DateTime(2026, 6, 16, 11)); // hour after last APTO
    expect(windows[1].start, DateTime(2026, 6, 16, 12));
  });

  test('excludes past windows and windows beyond the horizon', () {
    final windows = upcomingAptoWindows([
      r(DateTime(2026, 6, 16, 5), apto), // before now
      r(DateTime(2026, 6, 16, 9), apto), // in window
      r(DateTime(2026, 6, 19, 9), apto), // beyond 48h
    ], now: now);
    expect(windows.length, 1);
    expect(windows.first.start, DateTime(2026, 6, 16, 9));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/alerts/apto_windows_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Implement**

```dart
// lib/features/alerts/apto_windows.dart
import '../../data/mock/mock_flight_data.dart';
import '../../domain/rules/flight_readiness_status.dart';

class FlightWindow {
  const FlightWindow({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

List<FlightWindow> upcomingAptoWindows(
  List<ForecastRow> rows, {
  required DateTime now,
  Duration horizon = const Duration(hours: 48),
}) {
  final limit = now.add(horizon);
  final windows = <FlightWindow>[];
  DateTime? runStart;
  DateTime? lastHour;

  void close() {
    if (runStart != null && lastHour != null) {
      windows.add(
        FlightWindow(
          start: runStart!,
          end: lastHour!.add(const Duration(hours: 1)),
        ),
      );
    }
    runStart = null;
    lastHour = null;
  }

  for (final row in rows) {
    final t = row.time;
    if (t == null) continue;
    if (row.status == FlightReadinessStatus.ready) {
      runStart ??= t;
      lastHour = t;
    } else {
      close();
    }
  }
  close();

  return windows
      .where((w) => w.start.isAfter(now) && w.start.isBefore(limit))
      .toList();
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/alerts/apto_windows_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/alerts/apto_windows.dart test/features/alerts/apto_windows_test.dart
git commit -m "feat: compute upcoming APTO windows"
```

---

### Task 3: Scheduler interface + timing logic + fake

**Files:**
- Create: `lib/features/alerts/alert_scheduler.dart`
- Create: `lib/features/alerts/alert_timing.dart`
- Test: `test/features/alerts/alert_timing_test.dart`

**Interfaces:**
- Produces: `abstract class AlertScheduler { Future<bool> ensurePermission(); Future<void> scheduleWindowAlerts({required List<FlightWindow> windows, required int leadMinutes, required String locationLabel, required Language language}); Future<void> cancelAll(); }`; `DateTime alertFireTime(FlightWindow, int leadMinutes)`; `bool isQuietHour(DateTime)`; `bool shouldScheduleAlert(FlightWindow, int leadMinutes, DateTime now)`; `class FakeAlertScheduler implements AlertScheduler` (records calls).

- [ ] **Step 1: Write the failing test**

```dart
// test/features/alerts/alert_timing_test.dart
import 'package:aerocheck/features/alerts/apto_windows.dart';
import 'package:aerocheck/features/alerts/alert_timing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FlightWindow win(int hour) => FlightWindow(
    start: DateTime(2026, 6, 16, hour),
    end: DateTime(2026, 6, 16, hour + 2),
  );

  test('alertFireTime subtracts the lead time', () {
    expect(alertFireTime(win(9), 30), DateTime(2026, 6, 16, 8, 30));
  });

  test('isQuietHour covers 22:00-07:00', () {
    expect(isQuietHour(DateTime(2026, 6, 16, 5, 30)), isTrue);
    expect(isQuietHour(DateTime(2026, 6, 16, 23)), isTrue);
    expect(isQuietHour(DateTime(2026, 6, 16, 8)), isFalse);
  });

  test('shouldScheduleAlert skips quiet-hour and past fires', () {
    final now = DateTime(2026, 6, 16, 7);
    expect(shouldScheduleAlert(win(9), 30, now), isTrue); // fire 08:30
    expect(shouldScheduleAlert(win(6), 30, now), isFalse); // fire 05:30 (quiet + past)
    expect(shouldScheduleAlert(win(7), 30, now), isFalse); // fire 06:30 (quiet)
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/alerts/alert_timing_test.dart`
Expected: FAIL — `alert_timing.dart` does not exist.

- [ ] **Step 3: Implement the timing helpers**

```dart
// lib/features/alerts/alert_timing.dart
import 'apto_windows.dart';

DateTime alertFireTime(FlightWindow window, int leadMinutes) =>
    window.start.subtract(Duration(minutes: leadMinutes));

/// Quiet hours: 22:00 (inclusive) to 07:00 (exclusive).
bool isQuietHour(DateTime t) => t.hour >= 22 || t.hour < 7;

bool shouldScheduleAlert(FlightWindow window, int leadMinutes, DateTime now) {
  final fire = alertFireTime(window, leadMinutes);
  if (!fire.isAfter(now)) return false;
  if (isQuietHour(fire)) return false;
  return true;
}
```

- [ ] **Step 4: Implement the scheduler interface + fake**

```dart
// lib/features/alerts/alert_scheduler.dart
import '../../domain/i18n/language.dart';
import 'apto_windows.dart';

abstract class AlertScheduler {
  Future<bool> ensurePermission();
  Future<void> scheduleWindowAlerts({
    required List<FlightWindow> windows,
    required int leadMinutes,
    required String locationLabel,
    required Language language,
  });
  Future<void> cancelAll();
}

class FakeAlertScheduler implements AlertScheduler {
  bool permissionGranted = true;
  int cancelAllCalls = 0;
  List<FlightWindow> lastWindows = const [];
  int? lastLeadMinutes;

  @override
  Future<bool> ensurePermission() async => permissionGranted;

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
  }

  @override
  Future<void> scheduleWindowAlerts({
    required List<FlightWindow> windows,
    required int leadMinutes,
    required String locationLabel,
    required Language language,
  }) async {
    lastWindows = windows;
    lastLeadMinutes = leadMinutes;
  }
}
```

- [ ] **Step 5: Run test to verify it passes + analyze**

Run: `flutter test test/features/alerts/alert_timing_test.dart && flutter analyze`
Expected: PASS, analyzer clean.

- [ ] **Step 6: Commit**

```bash
git add lib/features/alerts/alert_scheduler.dart lib/features/alerts/alert_timing.dart test/features/alerts/alert_timing_test.dart
git commit -m "feat: add alert scheduler interface and timing logic"
```

---

### Task 4: Packages + real notifications scheduler + platform config

**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Create: `lib/features/alerts/local_notifications_alert_scheduler.dart`

**Interfaces:**
- Consumes: `AlertScheduler` (Task 3), `alertFireTime`/`shouldScheduleAlert` (Task 3), `FlightWindow` (Task 2).
- Produces: `class LocalNotificationsAlertScheduler implements AlertScheduler`.

- [ ] **Step 1: Add dependencies**

In `pubspec.yaml` under `dependencies:`, add:
```yaml
  flutter_local_notifications: ^18.0.1
  timezone: ^0.10.0
```
Run: `flutter pub get`
Expected: resolves successfully (if a newer compatible version is selected, that
is fine).

- [ ] **Step 2: Declare the Android permission**

In `android/app/src/main/AndroidManifest.xml`, add inside `<manifest>` next to the
location permissions:
```xml
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

- [ ] **Step 3: Implement the real scheduler**

```dart
// lib/features/alerts/local_notifications_alert_scheduler.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/i18n/app_strings.dart';
import '../../domain/i18n/language.dart';
import 'alert_timing.dart';
import 'apto_windows.dart';
import 'alert_scheduler.dart';

class LocalNotificationsAlertScheduler implements AlertScheduler {
  LocalNotificationsAlertScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const _channelId = 'apto_windows';

  Future<void> _init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  @override
  Future<bool> ensurePermission() async {
    await _init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return false;
  }

  @override
  Future<void> cancelAll() async {
    await _init();
    await _plugin.cancelAll();
  }

  @override
  Future<void> scheduleWindowAlerts({
    required List<FlightWindow> windows,
    required int leadMinutes,
    required String locationLabel,
    required Language language,
  }) async {
    await _init();
    final now = DateTime.now();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Ventanas aptas',
        channelDescription: 'Avisos de ventanas aptas para volar',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    var id = 1000;
    for (final window in windows) {
      if (!shouldScheduleAlert(window, leadMinutes, now)) continue;
      final fire = alertFireTime(window, leadMinutes);
      final title = AppStrings.get('alerta_ventana_titulo', language: language);
      final body =
          '${_hhmm(window.start)}–${_hhmm(window.end)} · $locationLabel';
      await _plugin.zonedSchedule(
        id++,
        title,
        body,
        tz.TZDateTime.from(fire, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
```
Add the i18n key `alerta_ventana_titulo` to both maps in
`lib/domain/i18n/app_strings.dart`:
```dart
// es
'alerta_ventana_titulo': 'Ventana apta para volar',
// en
'alerta_ventana_titulo': 'Suitable flight window',
```

- [ ] **Step 4: Verify it compiles**

Run: `flutter analyze`
Expected: No issues. If the installed `flutter_local_notifications` version renames
a method or parameter used above (e.g. `requestNotificationsPermission`,
`zonedSchedule`'s parameters, `AndroidScheduleMode`), adapt minimally to the
installed API — the analyzer pinpoints the mismatch. Do not change the
`AlertScheduler` interface.

- [ ] **Step 5: Run full suite**

Run: `flutter test`
Expected: all pass (the real scheduler is not exercised by tests; the fake is).

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock android/app/src/main/AndroidManifest.xml lib/features/alerts/local_notifications_alert_scheduler.dart lib/domain/i18n/app_strings.dart
git commit -m "feat: add local notifications scheduler and platform config"
```

---

### Task 5: Wire alerts into WeatherSession

**Files:**
- Modify: `lib/app/weather_session.dart`
- Modify: `lib/app/app_shell.dart` (inject the real scheduler)
- Test: `test/app/weather_session_alerts_test.dart` (create)

**Interfaces:**
- Consumes: `AlertScheduler`, `upcomingAptoWindows`, `alertsEnabled`/`alertLeadMinutes` (Tasks 1-3).
- Produces: `WeatherSession({..., AlertScheduler? alertScheduler})`; `Future<void> updateAlertPreferences({bool? enabled, int? leadMinutes})`; `Future<void> rescheduleAlerts()`.

- [ ] **Step 1: Write the failing test**

```dart
// test/app/weather_session_alerts_test.dart
import 'package:aerocheck/app/weather_session.dart';
import 'package:aerocheck/data/mock/mock_flight_data.dart';
import 'package:aerocheck/data/preferences/user_preferences.dart';
import 'package:aerocheck/data/preferences/user_preferences_store.dart';
import 'package:aerocheck/data/weather/weather_bundle.dart';
import 'package:aerocheck/data/weather/weather_repository.dart';
import 'package:aerocheck/domain/entities/weather_snapshot.dart';
import 'package:aerocheck/features/alerts/alert_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('enabling alerts schedules windows from the forecast', () async {
    final scheduler = FakeAlertScheduler();
    final store = _Store(const UserPreferences(alertsEnabled: true));
    final session = WeatherSession(
      weatherRepository: _AptoRepo(),
      preferencesStore: store,
      alertScheduler: scheduler,
    );
    await session.loadRealWeather();

    expect(scheduler.cancelAllCalls, greaterThan(0));
    expect(scheduler.lastWindows, isNotEmpty);
  });

  test('disabled alerts do not schedule windows', () async {
    final scheduler = FakeAlertScheduler();
    final session = WeatherSession(
      weatherRepository: _AptoRepo(),
      preferencesStore: _Store(const UserPreferences()),
      alertScheduler: scheduler,
    );
    await session.loadRealWeather();
    expect(scheduler.lastWindows, isEmpty);
  });
}

class _Store implements UserPreferencesStore {
  _Store(this._p);
  final UserPreferences _p;
  @override
  Future<UserPreferences> load() async => _p;
  @override
  Future<void> save(UserPreferences preferences) async {}
}

class _AptoRepo implements WeatherRepository {
  @override
  Future<WeatherBundle> fetchWeather({
    required double latitude,
    required double longitude,
    required String locationLabel,
  }) async {
    final base = DateTime.now().add(const Duration(hours: 2));
    WeatherSnapshot snap(int h) => WeatherSnapshot(
      time: DateTime(base.year, base.month, base.day, base.hour + h),
      locationLabel: locationLabel,
      temperatureC: 16,
      windKmh: 5,
      gustKmh: 8,
      windDirectionDegrees: 200,
      precipitationProbability: 0,
      precipitationMmPerHour: 0,
      cloudCoverPercent: 10,
      visibilityKm: 16,
      kpIndex: 1,
      isDaylight: true,
      isInsideRestrictedArea: false,
      isNearRestrictedArea: false,
    );
    final current = snap(0);
    return WeatherBundle(
      providerName: 'Open-Meteo',
      locationLabel: locationLabel,
      timezone: 'UTC',
      current: current,
      hourlySnapshots: [current, snap(1), snap(2)],
      windProfileRows: const [
        WindProfileRow(altitude: '10 m', windKmh: 5, gustKmh: 8, temperatureC: 16),
      ],
    );
  }
}
```
(The calm `_AptoRepo` weather yields APTO rows, so `upcomingAptoWindows` returns a
window. If `loadRealWeather`'s NOAA Kp call interferes in the test environment,
the fetch still resolves because the bundle is returned before Kp — leave it.)

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/app/weather_session_alerts_test.dart`
Expected: FAIL — `alertScheduler` param / scheduling not implemented.

- [ ] **Step 3: Add the injected scheduler + helpers**

In `lib/app/weather_session.dart`:
- Add imports:
  ```dart
  import '../features/alerts/alert_scheduler.dart';
  import '../features/alerts/apto_windows.dart';
  ```
- Constructor: add the param `AlertScheduler? alertScheduler,` and initializer
  `_alertScheduler = alertScheduler,`. Add the field:
  ```dart
  final AlertScheduler? _alertScheduler;
  ```
- Add the reschedule helper (swallows its own errors so it never breaks weather):
  ```dart
  Future<void> _maybeRescheduleAlerts() async {
    final scheduler = _alertScheduler;
    if (scheduler == null) return;
    try {
      await scheduler.cancelAll();
      if (!_userPreferences.alertsEnabled) return;
      final windows = upcomingAptoWindows(forecastRows, now: DateTime.now());
      await scheduler.scheduleWindowAlerts(
        windows: windows,
        leadMinutes: _userPreferences.alertLeadMinutes,
        locationLabel: _selectedLocation.label,
        language: _userPreferences.language,
      );
    } catch (_) {
      // Alerts must never break the weather flow.
    }
  }

  Future<void> rescheduleAlerts() => _maybeRescheduleAlerts();

  Future<void> updateAlertPreferences({bool? enabled, int? leadMinutes}) async {
    _userPreferences = _userPreferences.copyWith(
      alertsEnabled: enabled,
      alertLeadMinutes: leadMinutes,
    );
    await _preferencesStore.save(_userPreferences);
    notifyListeners();
    await _maybeRescheduleAlerts();
  }
  ```
- In `loadRealWeather`, after `_realBundle = bundle; _isLoadingReal = false; notifyListeners();`
  add:
  ```dart
      await _maybeRescheduleAlerts();
  ```

- [ ] **Step 4: Inject the real scheduler in production**

In `lib/app/app_shell.dart`, change `_weatherSession = WeatherSession();` to:
```dart
    _weatherSession = WeatherSession(
      alertScheduler: LocalNotificationsAlertScheduler(),
    );
```
and add `import '../features/alerts/local_notifications_alert_scheduler.dart';`.

- [ ] **Step 5: Run tests + full suite + analyze**

Run: `flutter test test/app/weather_session_alerts_test.dart && flutter test && flutter analyze`
Expected: PASS (existing session/forecast tests still pass because they pass no
`alertScheduler` → `_alertScheduler` is null → no scheduling); analyzer clean.

- [ ] **Step 6: Commit**

```bash
git add lib/app/weather_session.dart lib/app/app_shell.dart test/app/weather_session_alerts_test.dart
git commit -m "feat: reschedule APTO window alerts after each forecast fetch"
```

---

### Task 6: Alerts settings UI

**Files:**
- Modify: `lib/features/settings/screens/alerts_screen.dart`
- Modify: `lib/features/settings/settings_screen.dart` (pass the session to AlertsScreen)
- Modify: `lib/domain/i18n/app_strings.dart` (new keys)

**Interfaces:**
- Consumes: `WeatherSession.updateAlertPreferences`, `session.preferences.alertsEnabled/alertLeadMinutes`, the scheduler's `ensurePermission` (via the session).

- [ ] **Step 1: Add i18n keys**

In `lib/domain/i18n/app_strings.dart`, add to BOTH maps:
```dart
// es
'avisos_ventana_apta_titulo': 'Avisos de ventana apta',
'anticipacion': 'Anticipación',
'minutos_antes': 'min antes',
'permiso_notif_denegado': 'Permiso de notificaciones denegado',
// en
'avisos_ventana_apta_titulo': 'Suitable-window alerts',
'anticipacion': 'Lead time',
'minutos_antes': 'min before',
'permiso_notif_denegado': 'Notification permission denied',
```

- [ ] **Step 2: Implement the real config UI**

Rewrite `lib/features/settings/screens/alerts_screen.dart` so it takes the session
and drives the preferences. `AlertsScreen` becomes
`AlertsScreen({required Language language, required WeatherSession session})`,
an `AnimatedBuilder(animation: session, ...)`. The body:
- A title (`AppStrings.get('alertas', ...)`, headlineSmall — sub-screens keep
  their title).
- A `SwitchListTile` "Avisos de ventana apta" bound to
  `session.preferences.alertsEnabled`. `onChanged`:
  ```dart
  onChanged: (value) async {
    if (value) {
      final granted = await session.requestAlertPermission();
      if (!granted) {
        // keep it off; show a SnackBar
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.get('permiso_notif_denegado', language: language))),
          );
        }
        return;
      }
    }
    await session.updateAlertPreferences(enabled: value);
  },
  ```
- When enabled, a lead-time row with three choices 15 / 30 / 60 (use the existing
  segmented-style or simple `ChoiceChip`s) labelled with `AppStrings.get('anticipacion', ...)`
  and `${value} ${AppStrings.get('minutos_antes', ...)}`, calling
  `session.updateAlertPreferences(leadMinutes: value)`.
- Keep the three future locked rows (`_AlertOption` for viento fuerte / ráfagas /
  zona restringida) below.

Add to `WeatherSession` a passthrough so the UI does not import the scheduler:
```dart
  Future<bool> requestAlertPermission() async {
    final scheduler = _alertScheduler;
    if (scheduler == null) return true;
    return scheduler.ensurePermission();
  }
```
In `lib/features/settings/settings_screen.dart`, update the `alertas` case to pass
the session:
```dart
      case _SettingsView.alertas:
        return AlertsScreen(
          language: session.preferences.language,
          session: session,
        );
```

- [ ] **Step 3: Run full suite + analyze**

Run: `flutter test && flutter analyze`
Expected: all pass (1 pre-existing skip); analyzer clean. If
`test/features/settings/settings_screen_test.dart` constructs `AlertsScreen`
directly or asserts the old placeholder text, update it to the new constructor /
the toggle text.

- [ ] **Step 4: Commit**

```bash
git add lib/features/settings/screens/alerts_screen.dart lib/features/settings/settings_screen.dart lib/domain/i18n/app_strings.dart
git commit -m "feat: real alerts settings (toggle + lead time)"
```

---

### Task 7: Format, verify, build check

**Files:** none (verification only).

- [ ] **Step 1: Format** — `dart format lib test`
- [ ] **Step 2: Full suite + analyze** — `flutter test && flutter analyze` (all pass, 1 skip; clean).
- [ ] **Step 3: Manual device check** — fresh run: enable alerts (permission prompt appears; granting persists the toggle), confirm a scheduled notification fires before an APTO window; toggling off cancels. (Skip the `flutter build apk` here — handled separately.)
- [ ] **Step 4: Commit any formatting** — `git add -A && git commit -m "style: format APTO window alerts"` (skip if clean; trailer required).

---

## Self-Review

- **Spec coverage:** alert prefs (Task 1); `upcomingAptoWindows` (Task 2); scheduler interface + timing/quiet-hours + fake (Task 3); packages + real scheduler + `POST_NOTIFICATIONS` + timezone (Task 4); session reschedule-after-fetch + `updateAlertPreferences`/`rescheduleAlerts` + production injection (Task 5); real Alerts UI with permission-on-enable + i18n (Task 6); format/verify (Task 7). All spec sections mapped.
- **Placeholder scan:** none — full code for prefs, window helper, timing, fake, real scheduler, session wiring and UI logic. The real-plugin step explicitly flags adapting to the installed package version (analyzer-gated), which is not a placeholder but a version-robustness instruction.
- **Type consistency:** `AlertScheduler` method signatures match between Task 3's interface, the fake, the real impl (Task 4), and the session calls (Task 5); `FlightWindow{start,end}` and `upcomingAptoWindows(rows, {now, horizon})` match between Tasks 2 and 5; `alertFireTime`/`isQuietHour`/`shouldScheduleAlert` match between Task 3 and the real scheduler; `alertsEnabled`/`alertLeadMinutes` names match across Tasks 1, 5, 6; `WeatherSession({..., alertScheduler})` matches the app-shell injection and the tests.
- **Existing tests safe:** `WeatherSession` defaults `_alertScheduler` to null, so sessions built without it (all existing tests) never touch the plugin and never schedule.
- **Engine untouched:** only preferences, the alerts feature, session wiring, and the Alerts UI change; the evaluator/rules/`bestWindowFor` are not modified.

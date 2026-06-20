# APTO Window Alerts — Design Spec

Date: 2026-06-20
Status: Approved for planning
Topic: Local notifications that warn the pilot a configurable number of minutes
before each upcoming "APTO" (suitable) flight window, computed on-device from the
last forecast fetch. No backend, no background refresh.

## Goal

The Alerts settings screen is a placeholder ("Próxima fase: avisos por ventana
apta"). Build the first real alert: when the app fetches the forecast, compute
the upcoming APTO windows for the selected location and schedule local
notifications to fire a configurable lead time (e.g. 30 min) before each window
starts. The OS fires them even with the app closed. Free, no Pro gating.

## Decisions (locked during brainstorming)

1. **Mechanism:** local notifications only, scheduled from the latest forecast
   fetch. No server and no background refresh (the data is as fresh as the last
   app open; the OS still fires the pre-scheduled one-shots).
2. **Style:** one notification per upcoming APTO window, fired `leadMinutes`
   before the window starts (not a daily summary).
3. **Free**, no Pro gating hook.
4. **Horizon:** only windows starting within the next 48 hours.
5. **Quiet hours:** suppress notifications that would fire between 22:00 and
   07:00 (fixed in v1; configurable later).
6. **Re-schedule on every fetch:** cancel all previously scheduled alerts and
   reschedule from fresh data, so it self-corrects.

## Non-goals

- No background fetch (workmanager / BGTaskScheduler) — later phase.
- No daily-summary style, no threshold alerts (viento fuerte / ráfagas / zona
  restringida stay shown as "próximamente").
- No Pro gating; no server push (FCM).
- No change to the decision engine.

## Card / scope

Only the "ventana apta" alert is built. The other three placeholder rows
(viento fuerte, ráfagas altas, zona restringida) remain visible as future/locked
options.

## Architecture

### Window computation (pure, testable)
- `class FlightWindow { final DateTime start; final DateTime end; }` (end is the
  hour after the last contiguous APTO hour).
- `List<FlightWindow> upcomingAptoWindows(List<ForecastRow> rows, {required DateTime now, Duration horizon = const Duration(hours: 48)})`:
  - Group contiguous rows whose `status == FlightReadinessStatus.ready` (APTO)
    into windows by their `time`.
  - Keep only windows whose `start` is after `now` and within `now + horizon`.
- Pure function in `lib/features/alerts/apto_windows.dart`.

### Scheduler abstraction (testable boundary)
- `abstract class AlertScheduler` with:
  - `Future<bool> ensurePermission();` (returns granted)
  - `Future<void> scheduleWindowAlerts({required List<FlightWindow> windows, required int leadMinutes, required String locationLabel, required Language language});`
  - `Future<void> cancelAll();`
- The scheduler maps each window → a notification at `start − leadMinutes`,
  skipping any that fall in quiet hours (22:00–07:00) or in the past.
- Real impl `LocalNotificationsAlertScheduler` uses `flutter_local_notifications`
  + `timezone` (`zonedSchedule` with `AndroidScheduleMode.inexactAllowWhileIdle`
  to avoid the Android 12+ exact-alarm permission). Tests use a `FakeAlertScheduler`
  that records calls.

### Session wiring
- `WeatherSession` takes an optional `AlertScheduler? alertScheduler` (defaults
  to the real one). After a successful `loadRealWeather()`, if
  `_userPreferences.alertsEnabled`, it computes `upcomingAptoWindows(forecastRows, now)`
  and calls `scheduler.cancelAll()` then `scheduler.scheduleWindowAlerts(...)`.
  A public `Future<void> rescheduleAlerts()` lets the Alerts screen trigger it
  after a settings change.

### Preferences
- `UserPreferences`: add `bool alertsEnabled = false` and `int alertLeadMinutes = 30`,
  plus `copyWith`; persist both in the store
  (`aerocheck.alerts_enabled`, `aerocheck.alert_lead_minutes`).
- `WeatherSession.updateAlertPreferences({bool? enabled, int? leadMinutes})`
  mirrors `updateUnits`: guard, persist, notify, and reschedule (or cancel all if
  disabled).

### Permissions
- Android: add `POST_NOTIFICATIONS` to `AndroidManifest.xml`; request at runtime
  via the plugin when the user enables alerts.
- iOS: request notification permission via the plugin when enabling.
- Permission is requested on enable (not at startup). If denied, the toggle
  reverts to off.

## UI

Replace the placeholder body of `AlertsScreen` with real config (it becomes a
`StatefulWidget`-like view driven by the session):
- A master switch "Avisos de ventana apta" bound to `alertsEnabled`. Toggling on
  requests permission (revert if denied), then persists + reschedules.
- A lead-time selector (presets 15 / 30 / 60 min) bound to `alertLeadMinutes`,
  enabled only when alerts are on.
- Keep the three future rows (viento fuerte, ráfagas altas, zona restringida) as
  locked "próximamente" cards.
- All strings via `AppStrings` (es/en) — new keys for the toggle/lead labels.

## Packages

- `flutter_local_notifications` and `timezone` added to `pubspec.yaml`.
- App startup initializes the plugin + the timezone database once (in `main()` or
  the session's first use); the real scheduler initializes lazily on first use.

## Testing

- **`upcomingAptoWindows`:** contiguous APTO hours group into one window; non-APTO
  breaks windows; past windows and beyond-horizon windows are excluded; ties /
  single-hour windows handled.
- **Scheduler mapping (via a thin pure helper or the fake):** a window at 09:00
  with lead 30 → a notification time of 08:30; a window whose reminder lands in
  quiet hours (e.g. 06:00 window, lead 30 → 05:30) is skipped.
- **Session:** with `alertsEnabled` and a forecast containing an APTO window, the
  fake scheduler receives `cancelAll` + `scheduleWindowAlerts` with the expected
  windows; with alerts disabled, it is not scheduled (or cancelled).
- **Preferences round-trip:** `alertsEnabled` / `alertLeadMinutes` persist.
- The real `flutter_local_notifications` path is platform code — verified
  manually on device (permission prompt, a scheduled notification fires).
- `dart format lib test`, `flutter test`, `flutter analyze`.

## Implementation slices (anticipated)

1. **Preferences:** `alertsEnabled` + `alertLeadMinutes` on `UserPreferences` +
   store. Round-trip test.
2. **Window helper:** `FlightWindow` + `upcomingAptoWindows` + unit tests.
3. **Scheduler abstraction:** `AlertScheduler` interface + `FakeAlertScheduler` +
   the window→notification mapping/quiet-hours logic (pure, tested).
4. **Packages + real scheduler + platform config:** add deps, manifest
   `POST_NOTIFICATIONS`, init timezone, `LocalNotificationsAlertScheduler`.
5. **Session wiring:** inject scheduler, reschedule after fetch,
   `updateAlertPreferences` / `rescheduleAlerts`. Session tests with the fake.
6. **Alerts UI:** real toggle + lead-time config + permission-on-enable + i18n.
7. **Polish:** format, analyze, manual device check.

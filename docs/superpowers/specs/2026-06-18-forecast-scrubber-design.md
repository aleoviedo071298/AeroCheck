# Forecast Scrubber Redesign — Design Spec

Date: 2026-06-18
Status: Approved for planning
Topic: Replace the long hourly list in the Forecast tab with a draggable
time-scrubber that drives a live "focused hour" detail panel, keeping the full
list available collapsed.

## Goal

Today the Forecast tab is a long vertical list of hourly rows. Competitors (UAV
Forecast) use a horizontal scrubber the user drags to update a single focused
moment. Adopt that interaction in AeroCheck while preserving its differentiator
— the explainable per-hour decision — by keeping the full list one tap away.

The scrubber and focused panel reuse 100% of the data we already fetch and the
per-hour decisions the engine already computes. The only data change is the
forecast range (2 → 7 days) plus lifting the 12-hour display cap.

## Decisions (locked during brainstorming)

1. **Approach A** — interactive scrubber + live "focused hour" hero panel, with
   the full hourly list moved into a collapsible section (collapsed by default).
   Not a full replacement (keeps the explainable list) and not a minimal
   scroll-helper.
2. **Range: 7 days.** `forecast_days: 7`; the scrubber navigates days via day
   chips, and hours within the selected day.
3. **Best hour is per selected day**, not a single global best across the week.

## Non-goals

- No new weather API fields (we already fetch everything per hour).
- No change to the decision engine (`FlightReadinessEvaluator`) or rule config.
- No change to `bestWindowFor` (the global next-24h window Estado depends on).
- No Kp shown in Forecast (it is not shown today; unchanged).
- No offline caching/persistence of forecast beyond the in-memory bundle.

## Data, range, and performance

### API
`lib/data/weather/open_meteo_weather_repository.dart`: change
`forecast_days: '2'` → `'7'`. The hourly arrays (temperature, precipitation
probability, precipitation mm/h, cloud cover, visibility, wind at 10/80/120/180
m, wind direction, gusts, is_day) already cover the requested range — no new
parameters.

### Session
`lib/app/weather_session.dart`, `forecastRows`:
- Remove the `.take(12)` cap so it yields all future hours (up to ~168).
- **Memoize**: compute the evaluated rows once per `WeatherBundle` and cache
  them, recomputing only when a new bundle arrives. Today `forecastRows`
  re-evaluates every hour through the rule engine on every access, and it is
  called more than once per build; at 168 rows that is wasteful and can jank.
  Cache invalidation key: the current `_realBundle` instance.
- `bestWindowFor` is unchanged (still searches the next 24 h). Estado
  (`currentReport`) keeps using it.

### Kp note
Kp remains a single current value applied to all snapshots (existing behavior);
no per-hour Kp forecast. Forecast does not display Kp, so this is immaterial.

## UI structure

`ForecastScreen` changes from `StatelessWidget` to `StatefulWidget`. Vertical
order:

1. **Header** — unchanged (title + location/coordinates).
2. **Focused hour hero** (`_FocusedHourCard`) — the new primary element. Shows
   the full detail of the selected hour and updates live as the scrubber moves:
   large time + day (e.g. "09:00 · hoy"); status pill APTO / PRECAUCIÓN / NO APTO
   in its color, plus a ⭐ "Mejor hora" chip when the selected hour is the
   selected day's best; the primary reason (`localizedTitle`); and a 2×2 metric
   grid — Viento (with direction arrow), Ráfagas (with Δ), Lluvia %, Visibilidad
   — all via `UnitFormatters`.
3. **Scrubber** (`_HourScrubber`, evolves the current `_HourlyScoreTimeline`):
   - **Day chips** (Hoy/Sáb/Dom…) grouping rows by date; tapping a chip sets the
     active day and moves the selection to that day's best hour.
   - A **draggable horizontal hour track** for the active day: score-colored dots
     (red/amber/green by score, as today), a highlighted thumb at the selected
     hour, and the day's best-hour dot enlarged with a ring.
   - An **"Ir a mejor hora"** button that snaps day + hour to the active day's
     best hour.
4. **Full list** (collapsible, collapsed by default) — "Ver lista completa por
   hora" reveals the selected day's hours using the existing
   `_RedesignedForecastRowTile` cards, unchanged. The row matching the selected
   hour is highlighted to keep the scrubber↔list link.
5. **Tip card** — unchanged.

The old `_ForecastWindowStatsCard` (VENTANA SELECCIONADA / MEJOR HORA / LLUVIA EN
VENTANA) is removed; the hero plus the "Ir a mejor hora" anchor cover that
information without duplication.

## Interaction, state, and compatibility

`ForecastScreen` state: `selectedDay` (date) and `selectedHour` (DateTime), plus
`listExpanded` (bool). On load / when a new bundle arrives: `selectedDay = today`
and `selectedHour = today's best hour` (most useful default).

- **Scrubber drag**: a `GestureDetector` with `onHorizontalDragUpdate` + tap maps
  the x position to the nearest hour tick (snap) and updates `selectedHour`; the
  hero rebuilds live. Light haptic feedback on tick change is optional.
- **Day chips**: tapping sets `selectedDay` and moves `selectedHour` to that
  day's best hour.
- **"Ir a mejor hora"**: sets day + hour to the active day's best hour.
- **List toggle**: flips `listExpanded`; shows the selected day's rows with the
  selected hour highlighted.

**Per-day best hour** is computed in the screen by grouping `forecastRows` by
date and taking the highest-`score` row per day (ties → earliest hour). This
does not touch the engine and is independent of the global `bestWindowFor`. The
scrubber's ⭐ and the hero's "Mejor hora" chip use this per-day value (the
screen stops relying on the global `isBestWindow` flag for that marker).

**Compatibility**: the hero reuses the same status colors,
`localizedTitle`/`localizedDetails`, and `UnitFormatters` as the list. Only 2–3
new i18n keys are expected ("Ir a mejor hora", "Ver lista completa", "Ocultar
lista"), added to both `es` and `en`.

## Architecture and components

Files changed:
- `lib/data/weather/open_meteo_weather_repository.dart` — `forecast_days: '7'`.
- `lib/app/weather_session.dart` — `forecastRows`: drop `.take(12)`, memoize per
  bundle.
- `lib/features/forecast/forecast_screen.dart` — Stateless → Stateful; owns the
  day/hour/list state; composes hero + scrubber + collapsible list; removes
  `_ForecastWindowStatsCard`; adds a helper to group rows by day and pick each
  day's best hour.
- `lib/domain/i18n/app_strings.dart` — 2–3 new es/en keys.

New components extracted to their own files (because `forecast_screen.dart` is
already ~1160 lines and each new piece deserves a focused unit):
- `lib/features/forecast/widgets/focused_hour_card.dart` — `FocusedHourCard`.
- `lib/features/forecast/widgets/hour_scrubber.dart` — `HourScrubber` (day chips
  + draggable timeline + best-hour anchor), exposing
  `onHourSelected(DateTime)` / `onDaySelected(DateTime)` / `onGoToBest()`
  callbacks.

`_RedesignedForecastRowTile` and the shared helpers (`_statusColor`,
`_severityColor`, `_iconForReasonTitle`, etc.) stay and are reused by the
collapsible list; they may move alongside the list if that keeps files focused.

## Testing

- **Session**: `forecastRows` returns more than 12 hours (up to ~168 for a 7-day
  bundle) and is cached — successive reads over the same bundle return the same
  computed list without re-evaluating.
- **Widget** (`forecast_screen_test.dart`, using a fake session/bundle):
  1. The hero renders the selected hour's time, status, and metrics.
  2. Tapping/dragging to another hour updates the hero.
  3. Selecting a different day chip moves the selection to that day's best hour.
  4. "Ir a mejor hora" selects the active day's best hour.
  5. Toggling the list shows/hides it and highlights the selected row.
- `dart format lib test`, `flutter test`, `flutter analyze`; visual check in the
  running app/APK (light and dark).

## Implementation slices (anticipated)

1. **Data/range + memoization**: `forecast_days: 7`, lift `.take(12)`, memoize
   `forecastRows`; session test for count + caching.
2. **Focused hour hero + scrubber widgets**: build `FocusedHourCard` and
   `HourScrubber` (day chips, draggable timeline, per-day best hour, anchor) as
   isolated widgets with their own tests.
3. **Screen integration**: make `ForecastScreen` stateful, wire state +
   callbacks, add the collapsible list, remove `_ForecastWindowStatsCard`, add
   i18n keys; widget tests for the end-to-end interaction.
4. **Polish**: format, analyze, dark-mode pass, visual check.

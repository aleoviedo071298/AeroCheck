# Forecast Gradient Scrubber + Metrics Grid — Design Spec

Date: 2026-06-19
Status: Approved for planning
Topic: Enrich the Forecast tab — replace the collapsible hourly list with a
2-per-row metrics grid, and turn the dot scrubber into a real day/night gradient
driven by Open-Meteo sunrise/sunset. Plus remove the "Próximas horas" card from
the Estado (Conditions) screen.

## Context

The Forecast tab already has the scrubber redesign live (`feat/forecast-scrubber-impl`):
a `FocusedHourCard` hero (time + status + reason + 4 metrics), a draggable
`HourScrubber` (day chips + score dots + "Ir a mejor hora"), and a collapsible
full list. This iteration builds on that.

## Decisions (locked during brainstorming)

1. **Remove the collapsible hourly list** (`_ListToggle`, `_ForecastTableHeader`,
   `_RedesignedForecastRowTile`) from the Forecast tab.
2. **Add 4 metric cards** for the selected hour, 2 per row, in a new "conditions"
   card below the scrubber: **Temperatura, Nubosidad, Lluvia mm/h, Punto de
   rocío**. With the hero's existing 4 (Viento, Ráfagas, Lluvia %, Visibilidad)
   the tab shows 8 metrics total, all 2-per-row.
3. **Scrubber = day/night gradient bar on top + score dots below.** The gradient
   uses **real Open-Meteo sunrise/sunset** (`daily`); the score dots
   (red/amber/green per hour) are kept so flight-readiness stays visible.
4. **Remove the "Próximas horas" card** (`_HourlyTimelineWidget`) from Estado.

## Non-goals

- No change to the decision engine, `FlightRulesConfig`, or `bestWindowFor`.
- The 4 new metrics are informational; they do not affect the decision.
- No per-hour Kp; no humidity (not in the hourly response).

## Data layer

### API
`lib/data/weather/open_meteo_weather_repository.dart`: add
`'daily': 'sunrise,sunset'` to the request (with the existing `timezone: 'auto'`,
so sun times come in local time).

### DTO
`lib/data/weather/dto/open_meteo_forecast_response.dart`: parse the optional
`daily` object — `time[]` (date strings `YYYY-MM-DD`), `sunrise[]`, `sunset[]`
(ISO datetimes). Defensive: if `daily` is absent (test mocks), produce an empty
list — never throw.

### WeatherBundle
`lib/data/weather/weather_bundle.dart`: add
`class DaySunTimes { final DateTime date; final DateTime sunrise; final DateTime sunset; }`,
a `final List<DaySunTimes> dailySun;` field (default `const []`), and
`DaySunTimes? sunTimesFor(DateTime date)` that matches by calendar day.

### ForecastRow
`lib/data/mock/mock_flight_data.dart`: add 4 nullable fields to `ForecastRow`:
`double? temperatureC`, `double? cloudCoverPercent`,
`double? precipitationMmPerHour`, `double? dewPointC`.
`lib/app/weather_session.dart`, `_forecastRowFor`: populate them from the
snapshot (`weather.temperatureC`, `weather.cloudCoverPercent`,
`weather.precipitationMmPerHour`, `weather.dewPointC`). The existing memoization
already carries these on the cached rows. The engine is untouched.

## Metrics grid (Forecast)

- Delete the list block: `_ListToggle`, `_ForecastTableHeader`, the
  `_RedesignedForecastRowTile` usage and class, and any helper/sub-widget that
  becomes dead (e.g. `_ForecastReasonLine`, `_StatusIcon`). Keep shared helpers
  (`forecastStatusColor`, etc.) only if still referenced.
- Extract the hero's private `_metric` tile into a reusable
  `lib/features/forecast/widgets/metric_tile.dart` (`MetricTile`), used by both
  `FocusedHourCard` and the new conditions card (DRY).
- New `lib/features/forecast/widgets/conditions_metrics_card.dart`
  (`ConditionsMetricsCard`): a card with a 2×2 grid of `MetricTile`s for the
  selected `ForecastRow` — Temperatura (`UnitFormatters.formatTemperature`),
  Nubosidad (`%`), Lluvia mm/h (`UnitFormatters.formatPrecipitation` + `/h`),
  Punto de rocío (`formatTemperature`). Each tile shows `—` when its value is
  null.
- Screen order (`forecast_screen.dart`): Header → `FocusedHourCard` →
  `HourScrubber` → `ConditionsMetricsCard` → `_ForecastTipCard`.
- New i18n keys (es + en): `nubosidad`, `punto_rocio`. Temperatura reuses
  `temperatura`; the mm/h label reuses `precipitacion` (or a short `lluvia`
  variant) — labels via `AppStrings.get(..., language:)`.

## Gradient scrubber

### Pure helper
`lib/features/forecast/day_night_gradient.dart`:
`({List<Color> colors, List<double> stops}) dayNightGradient({required DateTime trackStart, required DateTime trackEnd, DateTime? sunrise, DateTime? sunset})`.
- `fraction(t) = ((t - trackStart) / (trackEnd - trackStart)).clamp(0,1)`.
- Bands: night → (dawn) → day → (dusk) → night, with a small transition width
  around the sunrise/sunset fractions. Colors readable in light and dark: night
  deep indigo, dawn/dusk amber-orange, day sky-blue.
- **Edge cases (explicit):**
  - The track only spans the day's *remaining* hours, so for afternoon/evening
    it is often entirely night (sunset ≤ trackStart, or sunrise ≥ trackEnd) →
    return a solid night gradient.
  - Full future days (00→23) show the whole cycle.
  - `sunrise`/`sunset` null (no `daily` data) → a neutral grey gradient; the dots
    still convey readiness.
- Returned stops are clamped to [0,1] and strictly non-decreasing.

### HourScrubber render
`lib/features/forecast/widgets/hour_scrubber.dart` gains `DateTime? sunrise` and
`DateTime? sunset` params. The track changes to:
1. A gradient bar (`Container` with the computed `LinearGradient`, rounded
   corners) replacing the plain grey line.
2. Sun/moon icons overlaid: ☀ centered in the day band, 🌙 in visible night
   band(s) (positions derived from the same fractions).
3. A white vertical thumb at the selected hour's fraction.
4. Hour labels every 3 h on the gradient axis.
5. The existing score-dot row kept below the gradient (`_ScrubberTick`,
   red/amber/green, selected/best emphasized).
The drag `GestureDetector` still maps x → nearest hour; selection / best-hour
logic is unchanged.

`forecast_screen.dart` passes the active day's sun times:
`session.realBundle?.sunTimesFor(activeDay.date)` → `sunrise`/`sunset`.

## Estado: remove "Próximas horas"

`lib/features/conditions/conditions_screen.dart`: remove the
`_HourlyTimelineWidget(session: session)` usage (and the preceding spacer/comment
at ~lines 99-102) and delete the `_HourlyTimelineWidget` class. Remove the
`proximas_horas` keys from `app_strings.dart` if no longer referenced. This is an
independent, low-risk deletion bundled with this UI batch.

## Architecture and components

Changed/created:
- `lib/data/weather/open_meteo_weather_repository.dart` (daily request)
- `lib/data/weather/dto/open_meteo_forecast_response.dart` (parse daily)
- `lib/data/weather/weather_bundle.dart` (`DaySunTimes`, `dailySun`, `sunTimesFor`)
- `lib/data/mock/mock_flight_data.dart` (`ForecastRow` fields)
- `lib/app/weather_session.dart` (`_forecastRowFor` populates fields)
- `lib/features/forecast/day_night_gradient.dart` (new pure helper)
- `lib/features/forecast/widgets/metric_tile.dart` (new, extracted)
- `lib/features/forecast/widgets/conditions_metrics_card.dart` (new)
- `lib/features/forecast/widgets/focused_hour_card.dart` (use `MetricTile`)
- `lib/features/forecast/widgets/hour_scrubber.dart` (gradient + sun/moon + dots)
- `lib/features/forecast/forecast_screen.dart` (remove list, add conditions card,
  pass sun times)
- `lib/features/conditions/conditions_screen.dart` (remove `_HourlyTimelineWidget`)
- `lib/domain/i18n/app_strings.dart` (`nubosidad`, `punto_rocio`; drop
  `proximas_horas` if unused)

## Testing

- **DTO:** parses `daily` sunrise/sunset into `dailySun`; missing `daily` →
  empty list, no throw.
- **`day_night_gradient`:** stops are non-decreasing and clamped; all-night track
  (sunset ≤ trackStart) → solid night; full-day track → contains dawn/day/dusk
  bands; null sun → neutral gradient.
- **ForecastRow:** `session.forecastRows` populate `temperatureC`,
  `cloudCoverPercent`, `precipitationMmPerHour`, `dewPointC`.
- **Widgets:** `ConditionsMetricsCard` renders the 4 metric labels/values for a
  sample row (and `—` for null); `HourScrubber` still shows the score dots and
  the "Ir a mejor hora" button.
- **Update existing tests:** remove/replace the Forecast tests that referenced
  the deleted list (`forecast-list-toggle`, `forecast-list`); confirm Estado
  tests still pass after `_HourlyTimelineWidget` removal.
- `dart format lib test`, `flutter test`, `flutter analyze`; visual check in the
  app/APK (light and dark, including an afternoon all-night track).

## Implementation slices (anticipated)

1. **Data:** API `daily`, DTO parse, `DaySunTimes`/`dailySun`/`sunTimesFor`,
   `ForecastRow` fields + session population. Unit/DTO tests.
2. **`day_night_gradient` helper** + unit tests.
3. **Metrics:** extract `MetricTile`, add `ConditionsMetricsCard`, remove the
   Forecast list, wire into the screen; update tests.
4. **Gradient scrubber:** render gradient + sun/moon + thumb + dots; pass sun
   times from the screen; widget test.
5. **Estado cleanup:** remove `_HourlyTimelineWidget` + unused keys.
6. **Polish:** format, analyze, visual check.

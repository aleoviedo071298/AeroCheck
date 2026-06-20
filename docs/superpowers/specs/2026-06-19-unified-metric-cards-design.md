# Unified Metric Cards (Estado + Forecast) — Design Spec

Date: 2026-06-19
Status: Approved for planning
Topic: Give Estado and Forecast the same 10-card, badge-style metric grid
(driven by current weather in Estado and by the selected forecast hour in
Forecast), add new real metrics from Open-Meteo, reorder by flight-decision
priority, and change the Forecast bottom tip to "Mejor hora: HH:MM".

## Goal

Today Estado shows an 8-card badge grid (`_MetricCard` with icon + accent line +
sub-value) and Forecast shows a different, simpler metric presentation. Unify
them: both screens use the same reusable badge card and the same 10-card layout,
ordered by what matters most for a drone go/no-go. Forecast cards reflect the
selected hour from the scrubber; Estado cards reflect the current weather. Add
the missing real metrics (pressure, sky condition, UV, per-hour humidity, real
apparent temperature). The decision engine is untouched.

## Decisions (locked during brainstorming)

1. **Both screens: 10 cards** (5 rows × 2), reusable Estado-style badge card.
2. **9 shared cards + a screen-specific 10th:** Kp in Estado (current-only), UV
   in Forecast (has a forecast).
3. **Order (both screens), by flight-decision priority, paired per row:**
   - Row 1: Viento · Ráfagas
   - Row 2: Precipitación · Visibilidad
   - Row 3: Nubosidad · Condición del cielo
   - Row 4: Temperatura · Humedad
   - Row 5: Presión · (UV in Forecast / Kp in Estado)
4. **New real metrics** fetched from Open-Meteo: `pressure_msl`, `weather_code`,
   `uv_index`, `relative_humidity_2m` (hourly), `apparent_temperature` (for a
   real "Sensación" instead of `temp−2`).
5. **Forecast layout:** header (time + status + reason) → 10-card grid →
   scrubber → bottom tip reading **"Mejor hora: HH:MM"** (the selected day's best
   hour) instead of "Ventana óptima…".

## Non-goals

- No change to the decision engine, `FlightRulesConfig`, or `bestWindowFor`. New
  metrics are informational.
- No Kp in Forecast (no Kp forecast); no per-hour cloud-base (Open-Meteo hourly
  doesn't provide it — Nubosidad sub degrades gracefully).

## Card inventory (both screens)

Each card: icon + label + value + sub-value + a colored accent line at the
bottom (the existing Estado `_MetricCard` look). Values via `UnitFormatters`.

| # | Card | Value | Sub-value | Icon | Accent |
| --- | --- | --- | --- | --- | --- |
| 1 | Viento | speed | `↗ {cardinal} {deg}°` | air_rounded | 0xFF0EA5E9 |
| 2 | Ráfagas | speed | `Δ {gust−wind}` / "sin ráfagas" | wind_power_rounded | 0xFFD97706 |
| 3 | Precipitación | `{prob}%` | `{mm}/h` / "sin lluvia" | water_drop_rounded | 0xFF06B6D4 |
| 4 | Visibilidad | distance | "" | visibility_rounded | 0xFF10B981 |
| 5 | Nubosidad | `{okta}/8 ({%})` | "" (no per-hour base) | cloud_rounded | 0xFF14B8A6 |
| 6 | Condición | sky label | "" | (per weather code) | 0xFFF59E0B |
| 7 | Temperatura | temp | `Sensación {apparent}` | device_thermostat_rounded | 0xFF3B82F6 |
| 8 | Humedad | `{rh}%` | `Rocío {dewpoint}` | opacity_rounded | 0xFF6366F1 |
| 9 | Presión | `{hPa/inHg}` | "" | speed_rounded | 0xFF64748B |
| 10 | UV (Forecast) | `{uv}` | "" | wb_sunny_rounded | 0xFFF97316 |
| 10 | Kp (Estado) | `{kp}` | "" | sensors_rounded | 0xFF8B5CF6 |

Estado uses current weather (`WeatherSnapshot`); Forecast uses the selected hour
(`ForecastRow`). Missing values render as `—` (AppStrings `sin_dato`).

### Sky condition (weather_code)
A pure helper maps the WMO `weather_code` to a condition: label key + icon.
Buckets: clear (0,1), partly cloudy (2), overcast (3), fog (45,48), drizzle
(51–57), rain (61–67, 80–82), snow (71–77, 85, 86), thunder (95–99). Each bucket
→ an `AppStrings` key (es/en) and a Material icon (e.g. `wb_sunny_rounded`,
`cloud_rounded`, `foggy`, `grain`, `water_drop_rounded`, `ac_unit_rounded`,
`thunderstorm_rounded`). Unknown code → "—".

## Data layer

- **API** `lib/data/weather/open_meteo_weather_repository.dart`:
  - `hourly`: add `relative_humidity_2m`, `apparent_temperature`, `pressure_msl`,
    `weather_code`, `uv_index`.
  - `current`: add `apparent_temperature`, `pressure_msl`, `uv_index`
    (`weather_code` and `relative_humidity_2m` are already requested).
- **WeatherSnapshot** `lib/domain/entities/weather_snapshot.dart`: add
  `double? apparentTemperatureC`, `double? pressureHpa`, `double? uvIndex`,
  `int? weatherCode` (it already has `relativeHumidityPercent`). Update
  `copyWith`.
- **DTO** `lib/data/weather/dto/open_meteo_forecast_response.dart`: populate the
  new fields for both current and hourly snapshots; hourly
  `relativeHumidityPercent` changes from `null` to the parsed value.
- **ForecastRow** `lib/data/mock/mock_flight_data.dart`: add
  `relativeHumidityPercent`, `apparentTemperatureC`, `pressureHpa`, `uvIndex`,
  `weatherCode` (it already has `temperatureC`, `cloudCoverPercent`,
  `precipitationMmPerHour`, `dewPointC`).
- **Session** `lib/app/weather_session.dart`, `_forecastRowFor`: populate the new
  fields from the snapshot.

All new fields are nullable/optional so existing constructions keep compiling.

## Shared widget

Extract Estado's private `_MetricCard` into a reusable
`lib/features/shared/widgets/metric_card.dart` (`MetricCard`) with the same
interface (`label`, `value`, `subValue`, `icon`, `accentColor`). Estado's
`_ReworkedMetricsGrid` and the new Forecast grid both use it. (Replaces the
`MetricTile`/`ConditionsMetricsCard` added in the previous iteration — those are
removed.)

## Estado screen

`lib/features/conditions/conditions_screen.dart`, `_ReworkedMetricsGrid`:
re-lay-out to the 10 cards in the order above using `MetricCard`. Keep Kp as #10.
Add Presión (#9) and Condición (#6). Sensación uses real
`apparentTemperatureC` when present, else the `temp−2` fallback. Humedad sub
shows the dew point (real `dewPointC` when present).

## Forecast screen

- Strip the metric grid out of `FocusedHourCard` (keep time + status +
  best-hour chip + reason).
- New `lib/features/forecast/widgets/forecast_metrics_grid.dart`
  (`ForecastMetricsGrid`): the 10 `MetricCard`s for the selected `ForecastRow`
  (UV as #10). Reuses the sky-condition helper and `UnitFormatters`.
- `forecast_screen.dart` order: Header → `FocusedHourCard` →
  `ForecastMetricsGrid` → `HourScrubber` → best-hour tip.
- Remove the old `MetricTile` and `ConditionsMetricsCard`.
- **Bottom tip:** replace `_ForecastTipCard`'s "Ventana óptima…" text with
  `"${AppStrings.get('mejor_hora')}: ${HH:mm of the selected day's best hour}"`
  (e.g. "Mejor hora: 09:00").

## i18n

Reuse existing keys (`viento`, `rafagas`, `precip`/`precipitacion`, `visibilidad`,
`nubosidad`, `temp`/`temperatura`, `humedad`, `presion`, `indice_kp`,
`punto_rocio`, `sensacion`, `sin_dato`, `sin_lluvia`, `sin_rafagas`,
`mejor_hora`). Add (es + en): `condicion` (label), `indice_uv`, and the sky
buckets: `cielo_despejado`, `cielo_parcial`, `cielo_nublado`, `cielo_niebla`,
`cielo_llovizna`, `cielo_lluvia`, `cielo_nieve`, `cielo_tormenta`.

## Testing

- **DTO:** parses `pressure_msl`, `weather_code`, `uv_index`,
  `apparent_temperature`, hourly `relative_humidity_2m` into the snapshots.
- **ForecastRow/session:** `forecastRows` carry the new fields.
- **Sky-condition helper:** representative codes map to the right label key
  (0→despejado, 3→nublado, 45→niebla, 61→lluvia, 95→tormenta, unknown→sin_dato).
- **Widgets:** `MetricCard` renders label/value/sub; `ForecastMetricsGrid`
  renders the 10 cards including Presión, Condición and UV (and no Kp); Estado
  grid renders Presión, Condición and Kp.
- **Forecast tip:** shows "Mejor hora: HH:MM".
- Update existing Forecast/Estado tests affected by the metric reorganization
  (e.g. assertions on the removed `MetricTile`/`ConditionsMetricsCard` or old
  Estado card text).
- `dart format lib test`, `flutter test`, `flutter analyze`; visual check
  (light/dark) on both screens.

## Implementation slices (anticipated)

1. **Data:** API params + `WeatherSnapshot` fields + DTO population + `ForecastRow`
   fields + session population. DTO/session tests.
2. **Sky-condition helper** (weather_code → label key + icon) + i18n sky keys.
   Unit tests.
3. **Shared `MetricCard`** extraction (move from Estado, repoint Estado to it).
4. **Estado grid** re-layout to the 10-card order with Presión + Condición + Kp;
   real apparent temperature. Update Estado tests.
5. **Forecast grid:** `ForecastMetricsGrid` (10 cards, UV), strip FocusedHourCard
   metrics, wire into the screen, remove `MetricTile`/`ConditionsMetricsCard`.
   Update Forecast tests.
6. **Forecast tip** → "Mejor hora: HH:MM".
7. **Polish:** format, analyze, visual check.

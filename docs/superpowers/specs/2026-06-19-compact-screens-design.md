# Compact Screens — Remove Redundant Titles, Header Location — Design Spec

Date: 2026-06-19
Status: Approved for planning
Topic: Remove the per-tab title headers (redundant with the bottom nav), move a
compact location into the global app bar, drop the Forecast "Mejor hora" tip, and
densify the metric cards so Estado/Forecast fit closer to a single viewport.

## Goal

Every weather tab currently starts with a tall header: a big title
("Forecast horario" / "Estado" / "Perfil vertical" / "Mapa operativo" / "Ajustes
MVP") plus a location block with name, lat/lon, elevation and "Open-Meteo". The
title repeats what the bottom nav already says, and the lat/lon/elev/provider is
noise. Remove this chrome so screens start directly with their content, keep the
**location name** always visible by moving it (compact) into the global app bar,
remove the now-redundant Forecast bottom tip, and tighten the metric cards so the
content fits closer to one screen.

## Decisions (locked during brainstorming)

1. **Remove the title header of all 5 tabs** (Estado, Forecast, Viento, Mapa,
   Ajustes-main). Screens start directly with content. The lat/lon/elevation/
   provider line is removed entirely.
2. **Keep the Ajustes sub-screen titles** (Unidades, Idioma, Datos, Alertas,
   Reglas de vuelo) — the bottom nav only says "Ajustes", so those titles are the
   sole indicator of which inline sub-view is open.
3. **Global app bar shows the location name** (compact, with a pin), on the
   weather tabs only (indices 0/1/2, mirroring the existing "Actualizado HH:MM"
   gating). Mapa/Ajustes keep just "AeroCheck".
4. **Remove the Forecast bottom tip** (`_ForecastTipCard`, "Mejor hora: …") —
   already conveyed by the scrubber ⭐ and the hero chip.
5. **Densify the metric cards** (best-effort single viewport; not forced on the
   smallest phones).

## Non-goals

- No merge of Estado and Forecast into one tab (kept separate).
- No change to the data layer, decision engine, or any metric values.
- No removal of the Ajustes sub-screen titles.

## Global app bar (location)

`lib/app/app_shell.dart`, the `AppBar`:
- Change the `title` from `[logo, "AeroCheck"]` to `[logo, Column]` where the
  column has `AeroCheck` (identity) on top and, on the weather tabs
  (`_index == 0 || 1 || 2`), a second compact line with a small pin icon +
  `_weatherSession.selectedLocation.label` (muted, ~12px, single line, ellipsis).
  On Mapa/Ajustes the column shows only `AeroCheck`.
- The app bar already rebuilds with the session (the "Actualizado HH:MM" text
  updates), so the location line updates when the selected location changes.
- The "Actualizado HH:MM" text, refresh and share actions are unchanged.

## Per-screen header removal

- `lib/features/conditions/conditions_screen.dart`: remove the `_ScreenHeader`
  usage and the `_ScreenHeader` class. The metrics/status content becomes the
  first child.
- `lib/features/forecast/forecast_screen.dart`: remove the `_ScreenHeader` usage
  and class; the `FocusedHourCard` becomes the first child.
- `lib/features/wind/wind_screen.dart`: remove its `_ScreenHeader` (the
  "Perfil vertical" title block); the wind stats become the first child.
- `lib/features/map/map_screen.dart`: remove the "Mapa operativo" title block; the
  map/content becomes the first child.
- `lib/features/settings/settings_screen.dart`: remove the main-list title
  ("Ajustes MVP" + its subtitle) from the `main` view only. The sub-views
  (Datos/Unidades/Idioma/Alertas/Reglas) keep their `headlineSmall` titles.
- Remove any now-unused `AppStrings` keys (e.g. `forecast_horario`,
  `perfil_vertical`, `mapa_operativo`, `ajustes_mvp`, `config_local_mvp`) **only
  if** a `grep` shows no remaining references; otherwise leave them.

Adjust top padding so content keeps a small, consistent top margin after the
header is gone (the screens currently start with `ListView(padding: ...16,16...)`
— keep that).

## Forecast bottom tip

`lib/features/forecast/forecast_screen.dart`: remove the `_ForecastTipCard` usage
and class, and the trailing `SizedBox`. The screen ends after the scrubber.

## Card density

- Both metric grids (`_ReworkedMetricsGrid` in Estado and `ForecastMetricsGrid`):
  raise the `SliverGridDelegateWithFixedCrossAxisCount.childAspectRatio` from
  `1.6` to about `2.1` (shorter cards). Keep the same `MetricCard` look; the card
  already ellipsises long values.
- Slim the Forecast `FocusedHourCard`: reduce its outer `Padding` from `16` to
  `12` and the time font from `30` to `26`.
- This is best-effort: the goal is to fit hero + 10 cards + scrubber within one
  viewport on standard/large phones; a short scroll on small phones is
  acceptable.

## Testing

- Update tests that asserted the removed titles/location: `find.text('Forecast horario')`,
  `'Perfil vertical'`, `'Mapa operativo'`, the conditions title, and the
  lat/lon/elevation strings — replace with the new expectations.
- Add an app-shell/widget test (or extend an existing one) asserting the location
  name renders in the app bar on a weather tab.
- Estado/Forecast/Viento/Mapa widget tests should still pass with content as the
  first child.
- `dart format lib test`, `flutter test`, `flutter analyze`; visual check
  (light/dark) on every tab, including the app-bar location line.

## Implementation slices (anticipated)

1. **App bar location:** two-line title with the compact location on weather tabs.
2. **Remove per-screen headers:** Estado, Forecast, Viento, Mapa, Ajustes-main
   (keep sub-screen titles); drop unused i18n keys.
3. **Forecast tip removal.**
4. **Card density + hero slimming.**
5. **Polish:** format, analyze, visual check; update affected tests alongside.

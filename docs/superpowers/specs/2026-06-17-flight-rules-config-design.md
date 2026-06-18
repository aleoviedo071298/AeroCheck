# Flight Rules Config — Design Spec

Date: 2026-06-17
Status: Approved for planning
Topic: User-editable flight decision rules

## Goal

Let the pilot personalize **every decision threshold** that drives the
`APTO / PRECAUCION / NO_APTO` status. Today the drone and mission profiles are
hardcoded to `MockFlightData.droneProfile` (Standard) and
`MockFlightData.missionProfile` (Photo/video), and several thresholds are fixed
constants inside `FlightReadinessEvaluator`. The pilot cannot change any of it.

After this work the pilot edits one active set of rules in a new Settings
screen, and those rules drive the decision everywhere the evaluator runs:
**Estado (ConditionsScreen)**, **Forecast** and **Viento**.

## Decisions (locked during brainstorming)

1. **Scope:** all variables editable (not just presets).
2. **Model:** a single active rules set (no multiple named profiles).
3. **Presets removed:** drone/mission selection is dropped entirely. The pilot
   edits final values directly; there is no live mission modifier.
4. **Editing control:** stepper rows (`−` / value / `+`) with tap-to-type for an
   exact value. Values shown/edited in the user's units; stored in metric.

## Non-goals

- Multiple saved/named rule profiles.
- Drone or mission preset pickers.
- Making `MISSING_DATA` or "inside restricted area" user-disableable
  (kept as hard blocks for data integrity / safety, per project boundaries).
- Changing the restricted-area geo logic.

## Architecture

### New model: `FlightRulesConfig`

Location: `lib/domain/rules/flight_rules_config.dart`

Immutable value object with `const FlightRulesConfig.defaults()`, `copyWith`,
`toJson` / `fromJson`, and value equality. All values stored in **metric**.
Holds every editable threshold (see "Editable parameters"). Defaults reproduce
clean Standard-class values (round numbers). This slightly changes the
out-of-the-box decision vs the current Standard×Photo (0.85) effective values;
the pilot adjusts freely.

### Evaluator refactor

`FlightReadinessEvaluator.evaluate(...)` and `WindProfileEvaluator` stop
receiving `DroneProfile` / `MissionProfile` and receive a `FlightRulesConfig`
instead. Each rule reads its cutoffs from the config rather than from the
current hardcoded constants (gust spread 10/18, precip 25/55, temperature, Kp,
cloud-base margins, wind/gust/visibility warning points).

`DroneProfile` / `MissionProfile` entities are removed from the decision path.
(They may remain only if still referenced by mock fixtures; the evaluator no
longer depends on them.)

### Persistence

- `FlightRulesConfig.toJson()` / `fromJson()`.
- Add `rulesConfig` field to `UserPreferences` (+ `copyWith`).
- Serialize the config in `SharedPreferencesUserPreferencesStore`.
- **Bug fix (in scope):** `WeatherSession._persistPreferences()`
  (`lib/app/weather_session.dart:493`) currently rebuilds `UserPreferences`
  from scratch and silently drops `language` and `units`. Change it to
  `_userPreferences.copyWith(...)` so nothing is lost — required for
  `rulesConfig` to survive location/radius changes.

### Session wiring

`WeatherSession` uses `_userPreferences.rulesConfig` at the three evaluation
points that today pass `MockFlightData.droneProfile/missionProfile`:
`currentReport`, `forecastRows` (`_forecastRowFor`), and `bestWindowFor`.
Add `Future<void> updateRulesConfig(FlightRulesConfig config)` mirroring
`updateUnits` / `updateLanguage` (guard on equality, persist via the store,
`notifyListeners`). Estado, Forecast and Viento update reactively.

## Editable parameters

Each rule exposes its **warning** (Precaución) and **blocked** (NO APTO) cutoff
where applicable. Stored metric, shown in user units.

### Wind
| Parameter | Warning | Blocked |
| --- | ---: | ---: |
| Sustained wind | 22 km/h | 28 km/h |
| Gusts | 32 km/h | 40 km/h |
| Gust − wind spread | 10 km/h | 18 km/h |

### Precipitation
| Parameter | Warning | Blocked |
| --- | ---: | ---: |
| Rain probability | 25 % | 55 % |
| Rain intensity | 0 mm/h (any rain) | 0.5 mm/h |

### Visibility & clouds
| Parameter | Warning | Blocked |
| --- | ---: | ---: |
| Visibility (warns below) | 4 km | 2.8 km |
| Cloud base — target altitude | 120 m | — |
| Cloud base — margin over altitude | < +120 m | < +60 m |

### Environmental
| Parameter | Warning | Blocked |
| --- | ---: | ---: |
| Minimum temperature | < 0 °C | < −5 °C |
| Maximum temperature | > 35 °C | > 40 °C |
| Kp index (GPS) | 4 | 6 |

### Operational (toggle)
| Parameter | Default |
| --- | --- |
| Allow night flight | Off (night = blocked) |

### Fixed (not editable)
- **Missing critical data** → always blocks. Data integrity, not a preference.
- **Restricted / sensitive area** → unchanged (inside = blocked, near = warning).
  Not disableable, per project boundaries (never hide the reason for NO_APTO,
  never present as official authorization).

## UI

### Placement & navigation
New entry in the Settings list next to Datos / Unidades / Idioma / Alertas:
**"Reglas de vuelo"**. Follows the existing inline pattern (`_SettingsView` enum
in `settings_screen.dart`): add a `reglas` case and a new
`lib/features/settings/screens/flight_rules_screen.dart`, shaped like
`units_screen.dart` — no Scaffold/AppBar, returns a `ListView`, `headlineSmall`
title, no back arrow, with `onBack` (Cancel) and `onSave`.

### Layout
- Sections per category (Viento · Precipitación · Visibilidad y nubes ·
  Ambientales · Operativas), each with a header.
- Each parameter is a stepper row. Where a rule has two cutoffs, two paired rows
  with **Precaución** / **Bloqueo** sublabels.

### `_StepperRow` component
Label + large value with unit + `−` / `+` buttons. Tapping the value opens a
numeric keyboard for an exact entry. Sensible increments per type: wind ±1,
rain % ±5, intensity ±0.1, temperature ±1, Kp ±0.5, altitude ±10.

### Units & i18n
- Display/edit in user units (wind km/h or mph, visibility km/mi, temperature
  °C/°F, altitude m/ft) via `UnitFormatters`; **always stored in metric**.
- All labels via `AppStrings.get(key, language: ...)`; new es/en keys added to
  `app_strings.dart`.

### Coherence guards
- Warning cannot cross Blocked (soft clamp on adjust). Sane min/max per field to
  prevent absurd values.

### Actions
- **Restaurar valores por defecto** → `FlightRulesConfig.defaults()`.
- **Cancelar** (`onBack`, discards) · **Guardar** (`session.updateRulesConfig`,
  persists and refreshes Estado/Forecast/Viento immediately).
- Local working-copy + Save/Cancel pattern, as in `units_screen.dart`.

### Safety note
A one-line reminder that AeroCheck helps plan and is not official authorization,
consistent with the rest of the app.

## Testing strategy

Test-first per project workflow; each slice green before the next.

- **Config:** defaults, JSON round-trip, `copyWith` isolation, equality.
- **Evaluator:** per rule, a custom config moves the cutoff (e.g. lowering the
  wind block to 10 flips the same weather to NO APTO). Update existing evaluator
  tests to the new signature.
- **Persistence:** preferences round-trip; `language`/`units` survive a
  location/radius change (covers the current bug).
- **Session:** changing the config changes `currentReport` and `forecastRows`.
- **UI widget tests:** sections render; `−`/`+` edits a value; Save calls
  `updateRulesConfig`; Restore returns to defaults; units reflected (km/h vs
  mph); i18n keys resolve.

Close-out: `dart format lib test docs`, `flutter test`, `flutter analyze`;
verify no secrets or build outputs are staged.

## Implementation slices

1. **Domain core** — `FlightRulesConfig` (defaults, copyWith, JSON).
2. **Evaluator refactor** — evaluators take `FlightRulesConfig`; rules read
   cutoffs from it; update existing tests.
3. **Persistence** — `rulesConfig` in `UserPreferences` + store; fix
   `_persistPreferences` to `copyWith`.
4. **Session wiring** — three eval points use the active config;
   `updateRulesConfig()`.
5. **UI** — `flight_rules_screen.dart` + `_StepperRow` + Settings entry + i18n
   keys.

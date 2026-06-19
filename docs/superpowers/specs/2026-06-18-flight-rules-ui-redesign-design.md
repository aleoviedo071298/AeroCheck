# Flight Rules Screen — UI/UX Redesign Design Spec

Date: 2026-06-18
Status: Approved for planning
Topic: Restyle the "Reglas de vuelo" settings screen to match the polished
Units screen, plus a Precaución ≤ Bloqueo coherence guard.

## Goal

The Flight Rules screen (`lib/features/settings/screens/flight_rules_screen.dart`)
is functional but visually flat: section headers are small grey text, the
Precaución/Bloqueo pairs have no color or grouping, and the steppers float in a
bare list. Bring it up to the visual quality of the Units screen
(`units_screen.dart`): grouped section cards, per-section icons, and colored
severity badges. Additionally add a soft coherence guard so the user cannot set
a Precaución threshold past its Bloqueo threshold.

This is a presentational refactor plus one small UX rule. **No changes to
`FlightRulesConfig`, the evaluators, persistence, or the decision logic.**

## Decisions (locked during brainstorming)

1. **Approach A — section cards + severity badges.** Each category becomes its
   own `Card` (Units-style), with a circular icon chip + title header. Each
   two-cutoff parameter shows its name plus two rows, each with a severity badge
   (Precaución = amber, Bloqueo = red) and the inline `−  value  +` stepper.
2. **Coherence guard included** (Precaución ≤ Bloqueo, polarity-aware). No
   descriptive per-parameter subtitles (kept out for scope).
3. Inline editing (`−`/`+` and tap-to-type) is preserved exactly.

## Non-goals

- No change to `FlightRulesConfig` fields, defaults, JSON, or equality.
- No change to `FlightReadinessEvaluator` / `WindProfileEvaluator` / decision
  output.
- No change to persistence or `WeatherSession`.
- No per-parameter description subtitles.
- No upper clamp / max bounds beyond the existing `allowNegative` floor and the
  new coherence guard.

## Visual structure

Mirrors `units_screen.dart` conventions (Card `elevation: 0`, radius 16, thin
border; existing dark palette: card `0xFF1E293B`, border `0xFF334155`, light
card `Colors.white`, border `0xFFE2E8F0`). Header (title `headlineSmall` w900 +
subtitle) and the fixed bottom bar (Restaurar / Cancelar / Guardar) are
unchanged.

### Section cards
One `Card` per category, each with a header row: a circular icon chip
(≈30 px, teal-tinted background in light, slate in dark) + section title
(w800, 14). Sections and icons:

| Section (key) | Icon |
| --- | --- |
| Viento (`viento`) | `Icons.air_rounded` |
| Precipitación (`precipitacion`) | `Icons.water_drop_outlined` |
| Visibilidad y nubes (`visibilidad_nubes`) | `Icons.visibility_outlined` |
| Ambientales (`ambientales`) | `Icons.thermostat_outlined` |
| Operativas (`operativas`) | `Icons.nightlight_round` |

### Two-cutoff parameters
Wind, gusts, gust spread, rain probability, rain intensity, visibility,
cloud-base margin, min temperature, max temperature, Kp. Layout per parameter:
parameter name (w800, 14) + two rows. Each row: severity badge on the left,
`−  value unit  +` stepper on the right. A thin divider separates parameters
within a card.

Badge styling (light mode; dark variants required):
- **Precaución** — bg `#FAEEDA`, text `#633806` (amber 50 / amber 800).
- **Bloqueo** — bg `#FCEBEB`, text `#791F1F` (red 50 / red 800).
- Dark mode: use a translucent tint of the same hue with a light text stop
  (amber/red 200-ish) so both badges stay legible on `0xFF1E293B`.

The `+` button keeps the teal accent (`0xFF0F766E`). Tapping the value opens the
exact-entry dialog (unchanged, already localized).

### Cloud-base margin (improvement)
Today it renders as two single rows with `· Precaución` / `· Bloqueo` suffixes
on the label. Redesign promotes it to a normal two-cutoff parameter named
"Margen base de nubes" with the two severity-badge rows, consistent with the
rest. (Reuses the existing `margen_base_nubes`, `precaucion`, `bloqueo` keys.)

### Single-value parameters
"Altitud objetivo" (`targetAltitudeMeters`) is a reference altitude, not a
severity threshold. It renders as a simple row: name + stepper, no badge, inside
the Visibilidad y nubes card.

### Operativas
A row inside the Operativas card: icon + "Permitir vuelo nocturno" label +
`Switch` (active color teal). Preserves `toggle-allowNightFlight` key.

### Safety note
The `aviso_no_oficial` line stays near the bottom of the scroll area (above the
fixed bar), in muted style.

### Dark mode
Every new color must work in both themes (the screen is shown in dark in the
reference screenshot). Follow the explicit `isDark` branching used in
`units_screen.dart` for card/border/text/icon colors; badges get dark-tint
variants as noted.

## Coherence guard (Precaución ≤ Bloqueo)

Correct ordering depends on each parameter's polarity (whether a higher number
is worse). The pair declares its polarity with an `inverted` flag.

| Parameter | Relationship | inverted |
| --- | --- | --- |
| Wind, gusts, gust spread, rain probability, rain intensity, max temperature, Kp | Precaución ≤ Bloqueo | false |
| Visibility, min temperature, cloud-base margin | Precaución ≥ Bloqueo | true |

Behavior — soft clamp applied in **metric** against the current `config`:
- Editing **Precaución** cannot cross the current Bloqueo (clamps to it).
- Editing **Bloqueo** cannot cross the current Precaución (clamps to it).
- Applies to both the `−`/`+` stepper and the exact-entry dialog result.
- Composes with the existing `allowNegative` floor (temperatures): apply the
  negative floor first, then the coherence clamp.

Concretely, for a non-inverted pair the warning setter does
`min(newValue, currentBlock)` and the block setter does
`max(newValue, currentWarn)`; for an inverted pair the comparisons flip
(`max` for warning, `min` for block). Because all unit conversions are
monotonic, clamping in metric is equivalent to clamping in display units and
avoids rounding drift.

This only prevents incoherent configs at the UI; the evaluator is untouched and
its behavior with any already-stored config is unchanged.

## Component architecture

Presentational refactor of `flight_rules_screen.dart`. New private widgets:

- `_SectionCard` — renders a category `Card`: header (icon chip + title) and a
  list of child rows with dividers.
- `_ThresholdParam` — a two-cutoff parameter: name + a Precaución
  `_BadgeStepperRow` + a Bloqueo `_BadgeStepperRow`. Owns the polarity-aware
  clamp wiring.
- `_BadgeStepperRow` — a severity badge + the existing stepper control.
- `_StepperRow` — kept as the core stepper (icons `−`/`+`, tap-to-type,
  `allowNegative`, localized dialog). Extended so its setter path runs through
  the coherence clamp supplied by `_ThresholdParam`.

The build method composes `_SectionCard`s. The unit-conversion helpers
(`_speed`, `_dist`, `_alt`, `_temp`, and their `*ToMetric` inverses) are reused
unchanged.

**Preserved widget keys** (tests and stability depend on them):
`plus-<field>`, `minus-<field>`, `value-<field>`, `flight-rules-save`,
`flight-rules-restore`, `toggle-allowNightFlight`.

No new i18n keys are expected; if the badge/label composition needs one it must
be added to both `es` and `en` maps.

## Testing

- Existing widget tests (`flight_rules_screen_test.dart`) must keep passing
  unchanged — same keys, same save/restore/toggle behavior, same negative-temp
  regression.
- New widget tests:
  1. Severity badges render: the Precaución and Bloqueo labels appear within the
     screen for at least one parameter.
  2. Direct coherence clamp: raising a Precaución (e.g. `windWarningKmh`) above
     its Bloqueo via repeated `+` then Save yields a saved warning ≤ block.
  3. Inverted coherence clamp: lowering a Precaución on visibility below its
     Bloqueo clamps so warning ≥ block.
- `flutter analyze` clean; `dart format`.
- Visual verification in the running app/APK (light and dark).

## Implementation slices (anticipated)

1. Presentational scaffolding: `_SectionCard` + `_BadgeStepperRow` + section
   icons + badges; recompose the build into cards (no behavior change). Keys
   preserved; existing tests green.
2. Coherence guard: `_ThresholdParam` polarity-aware clamp threaded through the
   pairs (including the cloud-base margin promotion); new clamp tests.
3. Polish + dark-mode pass + format/analyze + visual check.

# Compact Screens Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the redundant per-tab title headers, show a compact location in the global app bar, drop the Forecast "Mejor hora" tip, and densify the metric cards so Estado/Forecast fit closer to one viewport.

**Architecture:** Extract the app-bar title into a small testable `AppBarTitle` widget that shows the location on weather tabs. Delete each screen's title header block (keeping the Ajustes sub-screen titles). Remove the Forecast tip. Bump grid `childAspectRatio` and slim the hero.

**Tech Stack:** Flutter, Dart, existing `WeatherSession`/`AppStrings`. No new dependencies.

## Global Constraints

- No change to the data layer, decision engine, or metric values.
- Keep the Ajustes sub-screen titles (Datos/Unidades/Idioma/Alertas/Reglas).
- Do NOT remove i18n keys — `test/domain/i18n/app_strings_test.dart` references them; leaving them is harmless.
- Location in the app bar shows only on weather tabs (indices 0/1/2), mirroring the existing "Actualizado HH:MM" gating.
- Run before commit: `dart format lib test`, `flutter test`, `flutter analyze`. End every commit message with: `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.

---

### Task 1: Compact location in the app bar

**Files:**
- Create: `lib/app/widgets/app_bar_title.dart`
- Modify: `lib/app/app_shell.dart` (use `AppBarTitle`)
- Test: `test/app/app_bar_title_test.dart` (create)

**Interfaces:**
- Produces: `AppBarTitle({String? location})` — logo + "AeroCheck"; when `location != null`, a second line with a pin + the location (ellipsised).

- [ ] **Step 1: Write the failing test**

```dart
// test/app/app_bar_title_test.dart
import 'package:aerocheck/app/widgets/app_bar_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the location line when a location is given', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(56),
            child: AppBarTitle(location: 'Comodoro Rivadavia'),
          ),
        ),
      ),
    );
    expect(find.text('AeroCheck'), findsOneWidget);
    expect(find.text('Comodoro Rivadavia'), findsOneWidget);
  });

  testWidgets('hides the location line when null', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(56),
            child: AppBarTitle(),
          ),
        ),
      ),
    );
    expect(find.text('AeroCheck'), findsOneWidget);
    expect(find.text('Comodoro Rivadavia'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/app/app_bar_title_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Implement `AppBarTitle`**

```dart
// lib/app/widgets/app_bar_title.dart
import 'package:flutter/material.dart';

class AppBarTitle extends StatelessWidget {
  const AppBarTitle({super.key, this.location});

  final String? location;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/logo.png',
            height: 32,
            width: 32,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AeroCheck',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            if (location != null && location!.trim().isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.place_rounded,
                    size: 11,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 2),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Text(
                      location!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Wire it into the app bar**

In `lib/app/app_shell.dart`: add `import 'widgets/app_bar_title.dart';`. Replace
the `AppBar`'s `title: Row( ... logo ... Text('AeroCheck') ... )` with:

```dart
                    title: AppBarTitle(
                      location: (_index == 0 || _index == 1 || _index == 2)
                          ? _weatherSession.selectedLocation.label
                          : null,
                    ),
```

- [ ] **Step 5: Run tests + analyze**

Run: `flutter test test/app/app_bar_title_test.dart && flutter analyze`
Expected: PASS, analyzer clean.

- [ ] **Step 6: Commit**

```bash
git add lib/app/widgets/app_bar_title.dart lib/app/app_shell.dart test/app/app_bar_title_test.dart
git commit -m "feat: show compact location in the app bar on weather tabs"
```

---

### Task 2: Remove per-screen title headers

**Files:**
- Modify: `lib/features/conditions/conditions_screen.dart`
- Modify: `lib/features/forecast/forecast_screen.dart`
- Modify: `lib/features/wind/wind_screen.dart`
- Modify: `lib/features/map/map_screen.dart`
- Modify: `lib/features/settings/settings_screen.dart`
- Tests: `test/features/forecast/forecast_screen_test.dart`, `test/features/wind/wind_screen_test.dart`, `test/features/map/map_screen_test.dart`

**Interfaces:** none new.

- [ ] **Step 1: Update the title-asserting tests (RED)**

These tests currently assert the removed titles and will fail after removal; pre-edit them to the new expectations so they drive the change:
- `test/features/forecast/forecast_screen_test.dart`: replace each `expect(find.text('Forecast horario'), findsOneWidget);` and `expect(find.text('Hourly forecast'), findsOneWidget);` with an assertion that the screen rendered without that title — for the first test (no real weather), assert `expect(find.byType(ForecastScreen), findsOneWidget);`; for the English test, replace `find.text('Hourly forecast')` with `expect(find.text('Forecast horario'), findsNothing);` (the title is gone in both languages).
- `test/features/wind/wind_screen_test.dart`: replace `find.text('Perfil vertical')` / `'Vertical profile'` assertions with `expect(find.byType(WindScreen), findsOneWidget);`.
- `test/features/map/map_screen_test.dart`: remove the `expect(find.text('Mapa operativo'), findsOneWidget);` line only; keep the coordinate/location assertions.

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/forecast/ test/features/wind/ test/features/map/`
Expected: the edited tests FAIL (titles still present in the widgets).

- [ ] **Step 3: Remove the headers**

- `conditions_screen.dart`: delete the `_ScreenHeader(...)` usage (and the
  `const SizedBox(height: ...)` immediately after it) and delete the
  `class _ScreenHeader`. The first content widget (the status panel) becomes the
  first child of the `ListView`.
- `forecast_screen.dart`: delete the `_ScreenHeader(...)` usage and the
  `const SizedBox(height: 14)` after it, and delete the `class _ScreenHeader`.
  `FocusedHourCard` becomes the first child.
- `wind_screen.dart`: delete the `_ScreenHeader(...)` usage (renders
  `AppStrings.get('perfil_vertical')`) and the spacing after it, and delete its
  `class _ScreenHeader` (or `_ScreenHeader`-equivalent title widget). The wind
  stats become the first child.
- `map_screen.dart`: delete only the title widget that renders
  `AppStrings.get('mapa_operativo')` (and its immediate spacing). Keep the rest of
  the map screen (coordinates, location chips, radius, airspaces).
- `settings_screen.dart`: in the `main` settings view, delete the title that
  renders `AppStrings.get('ajustes_mvp')` and its subtitle
  `AppStrings.get('config_local_mvp')` (and their spacing). Do NOT touch the
  sub-view titles (Datos/Unidades/Idioma/Alertas/Reglas keep their
  `headlineSmall` titles).

After each deletion run `flutter analyze` and remove any symbol/import it reports
unused (e.g. a now-unused `_ScreenHeader` import or `UnitFormatters` used only by
the header). Do NOT remove the i18n keys.

- [ ] **Step 4: Run tests + analyze + full suite**

Run: `flutter test && flutter analyze`
Expected: all pass (1 pre-existing skip); analyzer clean. If any other test
asserted a removed title (search `grep -rn "Forecast horario\|Perfil vertical\|Mapa operativo\|Hourly forecast\|Vertical profile" test/`), update it the same way.

- [ ] **Step 5: Commit**

```bash
git add lib/features/conditions/conditions_screen.dart lib/features/forecast/forecast_screen.dart lib/features/wind/wind_screen.dart lib/features/map/map_screen.dart lib/features/settings/settings_screen.dart test/features/forecast/forecast_screen_test.dart test/features/wind/wind_screen_test.dart test/features/map/map_screen_test.dart
git commit -m "feat: remove redundant per-tab title headers"
```

---

### Task 3: Remove the Forecast bottom tip

**Files:**
- Modify: `lib/features/forecast/forecast_screen.dart`
- Test: `test/features/forecast/forecast_screen_test.dart`

**Interfaces:** none.

- [ ] **Step 1: Update the test (RED)**

In `test/features/forecast/forecast_screen_test.dart`, if any test asserts
`find.textContaining('Mejor hora:')`, change it to
`expect(find.textContaining('Mejor hora:'), findsNothing);`. (If no such
assertion exists after Task 2's edits, add this `findsNothing` assertion to the
test that loads real weather.)

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/forecast/forecast_screen_test.dart`
Expected: FAIL — the tip is still rendered.

- [ ] **Step 3: Remove the tip**

In `forecast_screen.dart`, in `_buildFocusedSection`, delete the
`_ForecastTipCard(...)` entry from the returned list and the `const SizedBox(height: 16)`
before it, and delete the `class _ForecastTipCard`. Also remove the
`final bestHourLabel = ...;` line if it becomes unused. The list ends after the
`HourScrubber`.

- [ ] **Step 4: Run tests + analyze**

Run: `flutter test test/features/forecast/forecast_screen_test.dart && flutter analyze`
Expected: PASS, analyzer clean (no unused symbols).

- [ ] **Step 5: Commit**

```bash
git add lib/features/forecast/forecast_screen.dart test/features/forecast/forecast_screen_test.dart
git commit -m "feat: remove redundant best-hour tip from forecast"
```

---

### Task 4: Densify the metric cards and slim the hero

**Files:**
- Modify: `lib/features/conditions/conditions_screen.dart` (`_ReworkedMetricsGrid`)
- Modify: `lib/features/forecast/widgets/forecast_metrics_grid.dart`
- Modify: `lib/features/forecast/widgets/focused_hour_card.dart`

**Interfaces:** none.

- [ ] **Step 1: Raise the grid density (Estado + Forecast)**

In both `_ReworkedMetricsGrid` (Estado) and `ForecastMetricsGrid`, change the
`SliverGridDelegateWithFixedCrossAxisCount` `childAspectRatio: 1.6` to
`childAspectRatio: 2.1`. Leave everything else unchanged.

- [ ] **Step 2: Slim the hero**

In `lib/features/forecast/widgets/focused_hour_card.dart`: change the outer
`Padding` `const EdgeInsets.all(16)` to `const EdgeInsets.all(12)`, and the time
`Text`'s `fontSize: 30` to `fontSize: 26`.

- [ ] **Step 3: Run full suite + analyze**

Run: `flutter test && flutter analyze`
Expected: all pass (1 pre-existing skip); analyzer clean. Widget tests are
layout-agnostic (they query by key/text), so density changes don't break them.

- [ ] **Step 4: Commit**

```bash
git add lib/features/conditions/conditions_screen.dart lib/features/forecast/widgets/forecast_metrics_grid.dart lib/features/forecast/widgets/focused_hour_card.dart
git commit -m "style: densify metric cards and slim the forecast hero"
```

---

### Task 5: Format, verify, visual check

**Files:** none (verification only).

- [ ] **Step 1: Format**

Run: `dart format lib test`

- [ ] **Step 2: Full suite + analyze**

Run: `flutter test && flutter analyze`
Expected: all tests PASS (1 pre-existing skip); analyzer reports no issues.

- [ ] **Step 3: Visual check (light and dark)**

Run the app / rebuild the APK and confirm:
- No screen shows a big title; the bottom nav is the only tab label.
- The app bar shows "AeroCheck" + the location name (with pin) on Estado/Forecast/
  Viento, and only "AeroCheck" on Mapa/Ajustes.
- Ajustes sub-screens (Unidades/Idioma/…) still show their titles.
- Forecast has no bottom "Mejor hora" tip; Estado and Forecast fit with little or
  no scroll on a standard phone.
- Works in light and dark.

APK build (OpenAIP key via dart-define, clean temp dir for the Gradle loopback):

```bash
TMP='C:\gtmp' TEMP='C:\gtmp' JAVA_HOME='C:\Program Files\Java\jdk-17' \
  flutter build apk --dart-define=OPENAIP_API_KEY=<OPENAIP_KEY>
```

- [ ] **Step 4: Commit any formatting**

```bash
git add -A
git commit -m "style: format compact screens"
```
(Skip if clean.)

---

## Self-Review

- **Spec coverage:** app-bar location via testable `AppBarTitle`, gated to weather tabs (Task 1); remove the 5 tab title headers, keep Ajustes sub-titles, keep i18n keys (Task 2); remove the Forecast tip (Task 3); densify cards + slim hero (Task 4); format/verify/visual (Task 5). All spec sections mapped.
- **Placeholder scan:** none — full code for `AppBarTitle` and the exact app-bar wiring; removals are keyed to unique markers (`_ScreenHeader`, `AppStrings.get('mapa_operativo')`, `'ajustes_mvp'`, `_ForecastTipCard`) with the analyzer as the unused-symbol gate; density changes give exact values. `<OPENAIP_KEY>` in Task 5 is an intentional secret placeholder (dart-define only).
- **Type consistency:** `AppBarTitle({String? location})` matches between Task 1's definition and the app-shell call site; the `_index` gating (0/1/2) matches the existing "Actualizado HH:MM" condition; no engine/data types touched.
- **Test impact:** the title-asserting tests (forecast/wind/map) are updated in Task 2; the i18n key test is unaffected because keys are kept; AppShell itself is not unit-tested (it builds its own session) — the location rendering is covered by the `AppBarTitle` test plus the visual check.

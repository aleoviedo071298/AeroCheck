# Remove Redundant Location/Source Blocks + Refresh Everywhere — Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Remove three remaining redundant location/source text blocks and make the refresh button visible on every tab.

**Design (approved in brainstorming):**
- The location name is no longer shown anywhere as a text label (it is still chosen from Map/Settings and seen on the map). Remove:
  1. The Map title block `_MapTitleBlock` (location + Lat/Lon/Elev + UTC-3).
  2. The Estado provider strip `_ProviderRow` (● "Clima real | Open-Meteo" + UTC-3 + AGL).
  3. The location line in the global app bar (`AppBarTitle` returns to logo + "AeroCheck" only, on every tab).
- The refresh button shows on all 5 tabs; the "Actualizado HH:MM" text stays only on the weather tabs (indices 0/1/2).

**Tech Stack:** Flutter, Dart. No data/engine changes.

## Global Constraints
- No change to the data layer, decision engine, or location-selection logic (map favorite chips, Settings location stay).
- Run before commit: `dart format lib test`, `flutter test`, `flutter analyze`. End every commit message with: `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.

---

### Task 1: Remove the three redundant blocks

**Files:**
- Modify: `lib/features/map/map_screen.dart` (remove `_MapTitleBlock`)
- Modify: `lib/features/conditions/conditions_screen.dart` (remove `_ProviderRow`)
- Modify: `lib/app/widgets/app_bar_title.dart` (drop the location line)
- Modify: `lib/app/app_shell.dart` (call `AppBarTitle()` without location)
- Tests: `test/app/app_bar_title_test.dart`, `test/features/map/map_screen_test.dart`

- [ ] **Step 1: Update the tests (RED)**

- `test/app/app_bar_title_test.dart`: replace both tests with a single one asserting the title renders without any location concept:
```dart
import 'package:aerocheck/app/widgets/app_bar_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the AeroCheck title', (tester) async {
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
  });
}
```
- `test/features/map/map_screen_test.dart`: in the test "map screen renders active location and coordinates", remove the two coordinate assertions (`find.textContaining('-45.8641')` and `find.textContaining('-67.4966')`) since the coordinates are being removed. Keep the `'5 km'` radius assertion. If `find.textContaining('Comodoro Rivadavia')` no longer matches after the title block is gone, change that line to `expect(find.byKey(const ValueKey('map-location-comodoro-rivadavia')), findsOneWidget);` (the favorite chip still renders the active location).

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/app/app_bar_title_test.dart test/features/map/map_screen_test.dart`
Expected: FAIL — `AppBarTitle` still requires/handles `location`; the map still renders coordinates.

- [ ] **Step 3: Drop the location from `AppBarTitle`**

Replace `lib/app/widgets/app_bar_title.dart` with (no `location` param, just logo + title):

```dart
import 'package:flutter/material.dart';

class AppBarTitle extends StatelessWidget {
  const AppBarTitle({super.key});

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
        const Text(
          'AeroCheck',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
      ],
    );
  }
}
```
In `lib/app/app_shell.dart`, change `title: AppBarTitle(location: ...)` to `title: const AppBarTitle(),`.

- [ ] **Step 4: Remove `_MapTitleBlock` (Map)**

In `lib/features/map/map_screen.dart`: delete the `_MapTitleBlock(session: session, location: location)` usage and the `const SizedBox(...)` immediately after it, and delete the entire `class _MapTitleBlock`. Run `flutter analyze` and remove anything it now reports unused (e.g. the `UnitFormatters` import if it was used only there, or the local `location` variable if now unused — but `location` is also used by other map widgets, so keep it if referenced).

- [ ] **Step 5: Remove `_ProviderRow` (Estado)**

In `lib/features/conditions/conditions_screen.dart`: delete the
`_ProviderRow(session: session, report: report)` usage (the "// 1. Weather provider row" entry) and the `const SizedBox(height: 12)` after it, and delete the entire `class _ProviderRow`. The status panel / loading / error branch becomes the first child of the `ListView`. Run `flutter analyze` and remove any now-unused import/symbol.

- [ ] **Step 6: Run tests + analyze + full suite**

Run: `flutter test && flutter analyze`
Expected: all pass (1 pre-existing skip); analyzer clean. If a conditions test asserted the `_ProviderRow` text (e.g. "Clima real" / "AGL"), update it to drop that assertion.

- [ ] **Step 7: Commit**

```bash
git add lib/features/map/map_screen.dart lib/features/conditions/conditions_screen.dart lib/app/widgets/app_bar_title.dart lib/app/app_shell.dart test/app/app_bar_title_test.dart test/features/map/map_screen_test.dart
git commit -m "feat: remove redundant location and data-source text blocks"
```

---

### Task 2: Show the refresh button on every tab

**Files:**
- Modify: `lib/app/app_shell.dart`

- [ ] **Step 1: Re-gate the app-bar actions**

In `lib/app/app_shell.dart`, the `AppBar.actions` currently wraps both the
"Actualizado HH:MM" `Text` and the refresh `IconButton` in
`if ((_index == 0 || _index == 1 || _index == 2) && updateTimeText.isNotEmpty) [...]`.
Restructure so the **refresh button always renders** and only the time text is
gated. Replace that block with:

```dart
                    actions: [
                      if ((_index == 0 || _index == 1 || _index == 2) &&
                          updateTimeText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            updateTimeText,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      IconButton(
                        tooltip: AppStrings.get('refrescar_clima'),
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        onPressed: () => _weatherSession.loadRealWeather(),
                      ),
                      IconButton(
                        tooltip: AppStrings.get('compartir'),
                        onPressed: () {},
                        icon: const Icon(Icons.ios_share_rounded),
                      ),
                    ],
```
(The refresh and share buttons now show on all tabs; only the time text remains gated to weather tabs.)

- [ ] **Step 2: Run full suite + analyze**

Run: `flutter test && flutter analyze`
Expected: all pass; analyzer clean.

- [ ] **Step 3: Commit**

```bash
git add lib/app/app_shell.dart
git commit -m "feat: show refresh button on every tab"
```

---

### Task 3: Format, verify, visual check

- [ ] **Step 1: Format** — `dart format lib test`
- [ ] **Step 2: Full suite + analyze** — `flutter test && flutter analyze` (all pass, 1 skip; clean).
- [ ] **Step 3: Visual check** — confirm: no location/coords/UTC/AGL text on Map or Estado; the app bar shows only "AeroCheck" everywhere; the refresh button appears on all 5 tabs; "Actualizado HH:MM" only on Estado/Forecast/Viento. (Skip the `flutter build apk` step — handled separately.)
- [ ] **Step 4: Commit any formatting** — `git add -A && git commit -m "style: format location-block removal"` (skip if clean).

---

## Self-Review
- **Coverage:** map block, Estado provider strip, app-bar location all removed (Task 1); refresh on every tab, time text still gated (Task 2); format/verify (Task 3).
- **Placeholders:** none — full `AppBarTitle` + actions code; removals keyed to `_MapTitleBlock`, `_ProviderRow`, the title `location` param.
- **Type consistency:** `AppBarTitle()` takes no args after the change; the app-shell call matches; the `_index` gating for the time text is unchanged.
- **Engine untouched:** only UI/app-shell changes; data layer, evaluator, location selection untouched.

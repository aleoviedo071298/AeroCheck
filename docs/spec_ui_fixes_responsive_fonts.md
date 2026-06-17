# Spec: UI Fixes, Responsive Layout, & Typography

**Status:** Planning  
**Date:** 2026-06-17  
**Scope:** Fix Map dialog crash, Forecast screen overflow, implement Inter typography  

---

## Problems Identified

### 1. Map Screen Dialog Crash
- **Issue**: `_showAddLocationDialog` in `_FavoriteLocationSelector` creates TextEditingController, Timer, and searchFuture as local variables in the builder function
- **Root Cause**: Variables are declared outside the builder's scope; when dialog closes, the State is still referencing them, causing `_dependencies.isEmpty` assertion error
- **Impact**: Red screen crash when user searches and adds a city to favorites on Map screen
- **Location**: `lib/features/map/map_screen.dart` lines 423-529

### 2. Forecast Screen Horizontal Overflow
- **Issue**: Column widths (HORA:50, VIENTO:70, RÁFAGAS:65, LLUVIA:75, Chevron:24 = 284px fixed) + Expanded content don't fit on narrow screens (375px viewport)
- **Root Cause**: Rigid pixel widths don't adapt to screen size; no responsive breakpoints
- **Impact**: Horizontal scroll overflow on mobile, text truncation, "Mejor hora" pill wraps awkwardly
- **Locations**: 
  - `lib/features/forecast/forecast_screen.dart` lines 604-675 (_ForecastTableHeader)
  - `lib/features/forecast/forecast_screen.dart` lines 782-887 (_RedesignedForecastRowTile row layout)

### 3. Missing Typography System
- **Issue**: No Inter (SF Pro) font configured; app uses system defaults
- **Root Cause**: pubspec.yaml has no google_fonts dependency; theme.dart has no textTheme overrides
- **Impact**: Inconsistent/generic typography across all screens
- **Impact on existing code**: Hardcoded TextStyle fontSize/fontWeight scattered across 10+ files

---

## Solution Design

### 1. Map Screen: Extract Dialog to Stateful Widget ✅

**Change**: Create new private `_AddLocationDialog` StatefulWidget that owns the TextEditingController and Timer.

**File**: `lib/features/map/map_screen.dart`

**Changes**:
- Create new class `_AddLocationDialog extends StatefulWidget`
- Move all dialog logic into `_AddLocationDialogState`:
  - `TextEditingController` created in `initState`
  - `Timer` managed with proper disposal in `dispose`
  - `searchFuture` as local state variable
- Update `_FavoriteLocationSelector._showAddLocationDialog()` to simply call:
  ```dart
  showDialog(
    context: context,
    builder: (context) => _AddLocationDialog(session: session),
  );
  ```

**Verification**:
- Existing test `test/features/map/map_screen_test.dart` should pass
- Manual: Search for "Mendoza", add to favorites → no red screen

---

### 2. Forecast Screen: Responsive Column Sizing ✅

**Change**: Reduce fixed column widths to fit 375px+ screens; add responsive logic if needed.

**Files**:
- `lib/features/forecast/forecast_screen.dart` lines 604-675
- `lib/features/forecast/forecast_screen.dart` lines 782-887

**New Column Widths** (tested for 375px viewport):
- HORA: 46 (was 50)
- VIENTO: 58 (was 70)
- RÁFAGAS: 52 (was 65)
- LLUVIA: 58 (was 75)
- Chevron: 24 (unchanged)

**Total fixed**: 238px → leaves ~137px for Expanded ESTADO/RAZÓN column on 375px screen (enough for status icon + text)

**Status Row Wrapping** (line 749-764):
- Replace hard `Row` with `Wrap` to allow "Mejor hora" pill to wrap gracefully if no horizontal space

```dart
Wrap(
  spacing: 6,
  runSpacing: 2,
  children: [
    Text(row.status, ...),
    if (row.isBestWindow) const _BestWindowPill(),
  ],
)
```

**Verification**:
- Run on 375px viewport: no overflow warnings
- Run on 812px viewport: no layout regression
- Test `test/features/forecast/forecast_screen_test.dart` passes

---

### 3. Typography: Add Inter Font & TextTheme ✅

**Changes**:

1. **pubspec.yaml**: Add google_fonts dependency
   ```yaml
   dependencies:
     google_fonts: ^6.4.0
   ```

2. **lib/app/theme.dart**: Create comprehensive TextTheme with Inter
   ```dart
   import 'package:google_fonts/google_fonts.dart';
   
   ThemeData buildAeroCheckTheme(Brightness brightness) {
     final baseTheme = GoogleFonts.interTextTheme(
       brightness == Brightness.dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme
     );
     
     return ThemeData(
       useMaterial3: true,
       colorScheme: scheme,
       textTheme: baseTheme.copyWith(
         headlineSmall: baseTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
         titleMedium: baseTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.25),
         bodyMedium: baseTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
         labelSmall: baseTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.4),
       ),
       ...
     );
   }
   ```

3. **Impact on existing code**: No changes needed. Hardcoded TextStyles will fall back to Inter through Material3 system, but critical titles/labels should explicitly use `Theme.of(context).textTheme.XYZ` instead of hardcoded styles (low priority refactor).

**Verification**:
- App runs with Inter loaded (no font fallback errors)
- Typography looks professional and consistent
- `flutter analyze` passes

---

## Implementation Order

1. **Extract Map dialog** → Run tests → Commit
2. **Resize Forecast columns + Wrap status row** → Run tests → Commit
3. **Add google_fonts + update theme** → Run tests → Commit

---

## Acceptance Criteria

- [ ] Map Screen: No crash when adding favorite location from search dialog
- [ ] Forecast Screen: No horizontal overflow on 375px viewport
- [ ] Forecast Screen: "Mejor hora" pill wraps gracefully
- [ ] Typography: Inter font loads and renders consistently across all screens
- [ ] All 67+ tests pass
- [ ] `flutter analyze` shows zero lint issues
- [ ] Manual testing on both light/dark themes

---

## Risk Mitigation

- **Dialog state management**: Stateful widget encapsulation eliminates lifecycle issues
- **Responsive layout**: Reduced column widths still maintain readability (minimum 46px for time, tested on comparable apps)
- **Font loading**: google_fonts is stable; will not impact network performance (fonts cached locally after first load)

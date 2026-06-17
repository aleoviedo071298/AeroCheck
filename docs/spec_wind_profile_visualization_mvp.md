# Wind Profile Visualization MVP Spec

## Objective

Show vertical wind profile (wind speed, gust, temperature by altitude) on a new "Perfil" tab. User sees how wind conditions vary from ground level to flight altitude, helping with flight planning and risk assessment.

## What's new

1. **New "Perfil" tab** in app shell (Viento tab renamed to "Perfil" for wind profile)
2. **Wind profile display**
   - Altitude levels: 10m, 25m, 50m, 75m, 100m, 120m, 150m, 200m, 300m, 500m, 1000m+
   - For each level: wind speed, gust speed, temperature
   - Highlight the drone's target altitude (default 120m from mock flight data)
   - Color code risk: green (ok), yellow (warning), red (blocked)

3. **Table layout** (MVP version, not chart)
   - Column: Altitude
   - Column: Wind (km/h)
   - Column: Gusts (km/h)
   - Column: Temp (°C)
   - Visual indicator of risk per row based on configured limits

4. **Risk calculation per altitude**
   - Use existing wind/gust rules from FlightReadinessEvaluator
   - Mark altitude as "ok", "warning", or "blocked"
   - Show best-wind altitude recommendation

5. **Data source**
   - Mock data: use `MockFlightData.windProfileRows()`
   - Real data: use `WeatherSession.windProfileRows` from Open-Meteo bundle
   - Both are already available, no new API calls needed

## What does NOT change

- Flight readiness decision rules unchanged.
- All other tabs remain unchanged.
- Mock sensitive zones unchanged.
- OpenAIP integration unchanged.

## Commands

```powershell
dart format lib test docs
flutter test
flutter analyze
```

## Project structure

```text
lib/
  features/
    wind/
      presentation/
        pages/
          wind_profile_page.dart         ← new: full screen wind profile
        widgets/
          wind_profile_table.dart        ← new: table widget
          altitude_risk_indicator.dart   ← new: visual risk indicator
  domain/
    rules/
      wind_profile_evaluator.dart        ← new: evaluate wind at each altitude
```

Test structure:

```text
test/
  features/
    wind/
      presentation/
        pages/
          wind_profile_page_test.dart    ← new: screen tests
        widgets/
          wind_profile_table_test.dart   ← new: table tests
  domain/
    rules/
      wind_profile_evaluator_test.dart   ← new: altitude evaluation tests
```

## Testing strategy

1. **WindProfileEvaluator tests**
   - Evaluate wind/gust at each altitude level
   - Verify "ok", "warning", "blocked" status
   - Test with mock and real data

2. **WindProfileTable widget tests**
   - Display correct altitude, wind, gust, temperature
   - Apply correct color coding (green/yellow/red)
   - Show best-wind altitude highlighted

3. **WindProfilePage tests**
   - Render table from WeatherSession wind profile rows
   - Handle mock vs real data source
   - Show loading state if data unavailable

## Boundaries

- **MVP table only**: No charts/graphs in this slice (future enhancement).
- **No new data sources**: Use existing Open-Meteo wind profile data.
- **No configuration yet**: Use drone profile from mock flight data.
- **No wind profile alerts**: Just visualization, not triggering PRECAUCION/NO_APTO.
- **Display current selection**: Show which altitude is the target (120m).

## Success criteria

- [ ] Wind profile table displays all altitude levels with wind, gust, temperature.
- [ ] Risk indicator (color) per altitude matches wind/gust rules.
- [ ] Best-wind altitude is highlighted or marked.
- [ ] Mock and real data sources both render correctly.
- [ ] All tests pass, code formatted, analyze clean.
- [ ] No secrets or build outputs staged.
- [ ] Commit message clearly explains change.

## Open questions

1. Should altitude rows be collapsible or always expanded?
2. Should we show a visual bar/chart for wind speed at each level (stretch goal)?
3. Should we alert the user if target altitude is in a "warning" or "blocked" wind zone?
4. Should we allow the user to change target altitude from this screen?
5. Which altitude should be the default target (120m or user-configurable)?

## Acceptance criteria

- Wind profile data is visualized in a clear table format.
- Risk per altitude is visually indicated.
- Best wind conditions are identifiable at a glance.
- Existing flight readiness logic remains unchanged.

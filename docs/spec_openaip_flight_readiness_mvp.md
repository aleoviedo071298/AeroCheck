# OpenAIP Flight Readiness Integration Spec

## Objective

Use OpenAIP airspace data in flight readiness decisions. When a location falls inside a restricted airspace or near a controlled zone, the decision changes from `APTO` to `PRECAUCION` or `NO_APTO` depending on airspace class and distance.

## What changes

1. **WeatherSession**
   - Detect if selected location is inside an OpenAIP airspace (point-in-polygon check).
   - Detect if selected location is within a warning distance of any airspace boundary.
   - Pass `isInsideRestrictedArea` and `isNearRestrictedArea` flags to `FlightReadinessEvaluator`.

2. **Flight readiness rules**
   - The existing `RESTRICTED_AREA` rule now incorporates both:
     - Mock sensitive-zone data (local test zones).
     - OpenAIP airspace data (real regulatory zones).
   - Decision logic unchanged:
     - Inside restricted area → `NO_APTO`.
     - Near restricted area → `PRECAUCION`.

3. **Airspace classification**
   - Class A, B, C, D (controlled airspace) → treat as restricted.
   - Class E, F, G (uncontrolled) → treat as warning zones.
   - This can be refined in future specs based on country regulations.

## What does NOT change

- Mock sensitive-zone rule remains active.
- User can still see both layers on the map.
- Copy remains: "AeroCheck is informational, verify official sources."
- No changes to other rules (wind, gust, rain, visibility, etc.).

## Commands

```powershell
dart format lib test docs
flutter test
flutter analyze
```

## Testing strategy

1. **Point-in-polygon tests**
   - Verify location inside airspace polygon → `isInsideRestrictedArea = true`.
   - Verify location outside polygon → `isInsideRestrictedArea = false`.
   - Test edge case: point on polygon boundary.

2. **Distance-based tests**
   - Verify location near airspace boundary (< 500 m) → `isNearRestrictedArea = true`.
   - Verify location far from boundary → `isNearRestrictedArea = false`.

3. **Flight readiness integration tests**
   - Location inside OpenAIP no-fly → status is `NO_APTO` with reason "Dentro de zona restringida (OpenAIP)".
   - Location near OpenAIP controlled airspace → status is `PRECAUCION` with reason "Zona regulada cercana (OpenAIP)".
   - Mock sensitive-zone + OpenAIP both active → both appear in reasons.

4. **Real scenario tests**
   - Load real airspaces and verify decision changes appropriately.

## Project structure

```text
lib/
  app/
    weather_session.dart         ← add airspace detection methods
    airspace_geom_helper.dart    ← new: point-in-polygon, distance calc
  domain/
    rules/
      flight_readiness_evaluator.dart  ← no changes to rule logic
```

Test structure:

```text
test/
  app/
    airspace_geom_helper_test.dart    ← new: point-in-polygon, distance tests
  domain/
    rules/
      flight_readiness_evaluator_test.dart  ← add OpenAIP integration tests
```

## Boundaries

- **No airspace API changes**: Use same OpenAIP repository.
- **No mock zone removal**: Both layers coexist.
- **No real-time updates**: Airspaces loaded once per location/radius change.
- **Conservative on controlled airspace**: Class E/F treated as warning, not blocking, to avoid false positives.
- **Clear attribution**: Reason messages include "(OpenAIP)" tag.

## Success criteria

- [ ] Point-in-polygon detection works for OpenAIP polygons.
- [ ] Distance-to-boundary calculation is accurate (within ±50m).
- [ ] Flight readiness status changes appropriately when location moves into/out of airspace.
- [ ] Reason messages include OpenAIP source attribution.
- [ ] Mock zones and OpenAIP zones can both affect the same decision.
- [ ] All tests pass, code formatted, analyze clean.
- [ ] No secrets or build outputs staged.
- [ ] Commit message clearly explains change.

## Open questions

1. Should we block on Class E/F airspace or just warn?
2. What is the "near" distance threshold for warnings? (Currently assume 500 m).
3. Should we expose airspace details in the reasons UI (name, class, altitude)?
4. Future: Should night flight rules interact with airspace class?

## Acceptance criteria

- OpenAIP airspaces now influence flight readiness decisions.
- User sees clear reasons when OpenAIP data blocks or warns.
- Existing mock zone behavior is unchanged.
- All existing tests continue to pass.

# OpenAIP Map Layer MVP Spec

## Objective

Connect OpenAIP airspace data as an informational visual layer on the `Mapa` tab, without affecting flight readiness decisions. The user sees nearby airspaces on the map, understands they are informational, and knows to verify official sources.

## What does not change

- Mock sensitive-zone rule remains active and unchanged.
- Flight readiness decisions (`APTO / PRECAUCION / NO_APTO`) are unaffected by OpenAIP data.
- Decision rules in `lib/domain/rules/` are not modified.
- Existing map behavior, location selection, and guide radius are unchanged.

## What is new

1. **WeatherSession injection**
   - `WeatherSession` receives an `AirspaceRepository` (e.g., `OpenAipAirspaceRepository`).
   - `WeatherSession` loads nearby airspaces asynchronously based on active location + guide radius.
   - Airspaces emit a state: `loading`, `error`, `empty`, or `loaded([airspaces])`.

2. **Mapa UI states**
   - **Loading**: "Cargando espacios aéreos..."
   - **Error**: "No se pudo cargar espacios aéreos. Verifica tu conexión."
   - **Empty**: No visible indicator; map shows with no airspace layer.
   - **Loaded**: Airspaces render as semi-transparent polygons on the map.

3. **Visual design**
   - Airspaces are polygon overlays with distinct colors by class (A, B, C, D, E, F, G).
   - Polygons are semi-transparent to avoid obscuring map features.
   - Optional: tap a polygon to show airspace details (name, class, altitude range).
   - Include attribution link to OpenAIP at map bottom.

4. **Legal/educational copy**
   - At map top or in a banner: "Los espacios aéreos mostrados son informativos. Verifica siempre con autoridades oficiales."
   - In Settings → About, add: "Datos de espacios aéreos cortesía de OpenAIP. AeroCheck no sustituye autorizaciones oficiales."

## Commands

```powershell
# Format
dart format lib test docs

# Test
flutter test

# Analyze
flutter analyze

# Run with OpenAIP key (optional)
flutter run --dart-define=OPENAIP_API_KEY=...
```

## Project structure

```text
lib/
  app/
    weather_session.dart           ← inject AirspaceRepository, add airspace state
  data/
    regulatory/
      openaip_airspace_repository.dart  ← already exists, use as-is
      airspace.dart                      ← model (check if exists)
  features/
    map/
      presentation/
        pages/
          mapa_page.dart           ← listen to airspace state, render layer
        widgets/
          airspace_layer_widget.dart ← new: render polygons with colors
          map_attribution_widget.dart ← new: OpenAIP attribution
```

Test structure:

```text
test/
  app/
    weather_session_test.dart      ← add tests for airspace loading
  features/
    map/
      presentation/
        pages/
          mapa_page_test.dart       ← add tests for airspace UI state
        widgets/
          airspace_layer_widget_test.dart ← new: polygon rendering
```

## Testing strategy

1. **WeatherSession tests**
   - Inject a mock `AirspaceRepository`.
   - Verify that `loadNearbyAirspaces()` is called when location/radius changes.
   - Verify state transitions: `loading` → `loaded` or `loading` → `error`.
   - Verify empty state when no airspaces found.

2. **Mapa page tests**
   - Mock `WeatherSession` with various airspace states.
   - Verify UI renders loading indicator when state is `loading`.
   - Verify UI renders error message when state is `error`.
   - Verify UI renders airspaces when state is `loaded([...])`.
   - Verify attribution is always visible.

3. **AirspaceLayerWidget tests**
   - Mock a list of airspaces with lat/lng bounds.
   - Verify polygons are rendered with correct colors by class.
   - Verify legal copy is displayed.

4. **Integration test (optional)**
   - Use a fake OpenAIP key in test.
   - Verify end-to-end: location change → airspace fetch → map renders.

## Boundaries

- **No decision logic change**: OpenAIP data is never used in `FlightReadinessEvaluator`.
- **No mock rule change**: Sensitive-zone mock rule remains active.
- **Informational only**: UI clearly states data is reference only.
- **Attribution required**: Every mention of OpenAIP includes link to OpenAIP.
- **No API key in code**: Key is passed only via `--dart-define`.
- **Error resilience**: If OpenAIP fails or returns empty, map still shows location and mock zones.

## Success criteria

- [ ] `WeatherSession` can load and expose airspace state.
- [ ] `Mapa` renders loading, error, empty, and loaded states.
- [ ] Airspace polygons render with correct colors by class.
- [ ] Legal/educational copy is visible and clear.
- [ ] Tests cover repository injection, state transitions, and UI rendering.
- [ ] `flutter test`, `flutter analyze`, and `dart format` all pass.
- [ ] No secrets or generated outputs are staged.
- [ ] Commit message clearly explains the change.

## Open questions

1. Should tapping an airspace polygon show details (name, class, alt range)?
2. Which airspace classes should be visible by default (all, or exclude G)?
3. Should the map include NOTAM/TFR layer in a future slice, or keep OpenAIP separate?
4. Should Settings include an option to toggle OpenAIP layer visibility?

## Acceptance criteria

- OpenAIP airspaces display on the map as informational layer.
- User cannot mistakenly think OpenAIP data replaces official authorization.
- Existing flight readiness and mock zone behavior are unaffected.
- All tests pass, code is formatted, no secrets are committed.

# AeroCheck Project Handoff For Claude

## Current Status (Session: 2026-06-17)

Repository:

```text
https://github.com/aleoviedo071298/AeroCheck
```

Local path:

```text
C:\Users\Alejandro\Desktop\local\dron
```

Current branch: `main` (ahead of origin by 16 commits)

Latest commits:

```text
eeb5432 Integrate NOAA Planetary K-Index for real geomagnetic activity data
1b57f42 Improve Conditions Screen UX/UI with clearer labels and better visual hierarchy
bf07ca5 Add Claude handoff documentation
3274985 Add OpenAIP airspace repository
```

Working tree: clean

## What Exists

AeroCheck is a Flutter MVP with five tabs:

- `Condiciones` (Estado) - Real-time weather & flight readiness
- `Forecast` - 12-hour forecast with best window highlighting
- `Viento` - Wind profile visualization
- `Mapa` - Location map with OpenAIP airspace display
- `Ajustes` - Favorite locations and settings

### Core Features

**Flight Readiness Engine:**
- Shared domain rules: wind, gust, variability checks
- Explainable `APTO / PRECAUCION / NO_APTO` decisions
- Score 0-100 (Aptitud) with reasons breakdown
- Best safe flight window detection with temporal awareness

**Weather Data:**
- Real Open-Meteo API (free, no auth)
- Real NOAA Planetary K-Index (geomagnetic activity)
- Kp interpretation: Quieto (0-2), Inestable (3-4), Tormenta Menor (5-6), Tormenta Mayor (7-8), Tormenta Severa (9+)
- Hourly snapshots with cloud base, visibility, precipitation
- Mock scenarios for testing

**Location Management:**
- OpenMeteo Geocoding API for worldwide city search (debounced 300ms)
- Favorite locations persisted with full coordinates (JSON serialization)
- Active location selection
- Local preferences stored via SharedPreferences

**UI/UX (Recent Improvements):**
- Clearer weather label: "Condiciones actuales · HH:MM"
- Score context: "Aptitud 0/100" below dial
- Best window temporal logic: shows "PRÓXIMA VENTANA" if window passed
- Rejection reasons with Actual/Limit values (e.g., "Viento: 15.2 km/h (límite: 12 km/h)")
- Reordered metrics: Temperature, Rain, Visibility, Cloud Coverage, Kp
- Profile section: "OPERACIÓN CONFIGURADA" with Dron | Misión | Altitud breakdown

**Regulatory Data:**
- OpenAIP Core adapter for airspace queries
- Mock sensitive-zone rule with configurable radius
- Airspace state management (loading/error/loaded)

**Forecast & Analysis:**
- 12-hour forecast rows with operational context
- Primary reason per hour (why APTO/PRECAUCION/NO_APTO)
- Expandable details with all active reasons
- Best-hour indicator and window recommendation
- Wind profile visualization (5-level altitude breakdown)

## Key Files

**Product & Workflow:**
- `CLAUDE.md` - Project rules & boundaries (ALWAYS read first)
- `AGENTS.md` - Team structure and responsibilities
- `README.md` - Getting started
- `plan_app_dron_multiplataforma.md` - Feature roadmap
- `docs/agent_workflow.md` - Collaboration process
- `docs/mvp_decision_rules.md` - Flight readiness logic

**Core App:**
- `lib/app/weather_session.dart` - State management (ChangeNotifier)
- `lib/app/app_shell.dart` - Tab navigation
- `lib/app/theme.dart` - Design tokens

**Weather Integration:**
- `lib/data/weather/open_meteo_weather_repository.dart` - Open-Meteo API
- `lib/data/kp_index/noaa_kp_index_service.dart` - NOAA geomagnetic data
- `lib/data/location/geocoding_repository.dart` - City search (OpenMeteo Geocoding)

**Regulatory:**
- `lib/data/regulatory/openaip_airspace_repository.dart` - OpenAIP Core adapter
- `lib/domain/rules/flight_readiness_evaluator.dart` - Decision engine

**Features (UI):**
- `lib/features/conditions/conditions_screen.dart` - Estado/Condiciones (784 lines, heavily refactored)
- `lib/features/forecast/forecast_screen.dart` - 12-hour forecast
- `lib/features/wind/wind_profile_screen.dart` - Wind analysis
- `lib/features/map/map_screen.dart` - Location & airspace map
- `lib/features/settings/settings_screen.dart` - Preferences & favorites

**Tests (67 total):**
- `test/app/weather_session_test.dart` - Session state
- `test/domain/rules/flight_readiness_evaluator_test.dart` - Decision rules
- `test/data/kp_index/noaa_kp_index_service_test.dart` - Kp interpretation (NEW)
- `test/features/conditions/conditions_screen_test.dart` - UI rendering
- `test/features/forecast/`, `test/features/map/`, `test/features/settings/`

## Recent Work (This Session)

**Commit: eeb5432** - Integrate NOAA Planetary K-Index for real geomagnetic activity data
- New: `lib/data/kp_index/noaa_kp_index_service.dart`
- Fetches real-time Kp from `https://services.swpc.noaa.gov/products/noaa-planetary-k-index.json`
- Interprets Kp: 0-2=Quieto, 3-4=Inestable, 5-6=Tormenta Menor, 7-8=Tormenta Mayor, 9+=Tormenta Severa
- `WeatherSession` now merges Kp into bundle after Open-Meteo fetch
- Display: "2.33 - Quieto" in Conditions Screen metric
- Added 5 tests, all passing

**Commit: 1b57f42** - Improve Conditions Screen UX/UI with clearer labels and better visual hierarchy
- Header: "Condiciones actuales · HH:MM" (was "Open-Meteo - HH:MM")
- Score: "Aptitud 0/100" label below dial for context
- Best Window: Temporal logic shows "PRÓXIMA VENTANA DISPONIBLE" if window passed
- Rejection Reasons: Added Actual/Limit display (e.g., "Viento: 15.2 km/h (límite: 12 km/h)")
- Metrics reordered: removed wind/gust/variation (moved to rejection reasons)
- Metric labels: "Temperatura" (was "Temp."), "°C" (was "C"), "Sin dato" (was "No disp.")
- Profile: Renamed "Modelo de dron" → "OPERACIÓN CONFIGURADA", restructured as columns
- All 62 tests passing, zero lint issues

**Previous commits:**
```text
bf07ca5 Add Claude handoff documentation
3274985 Add OpenAIP airspace repository
18015e9 Highlight best forecast hour
7d8b470 Add expandable forecast reasons
```

## OpenAIP Integration

**API Key Management:**
- Never commit the key. Pass only at runtime:

```powershell
flutter run --dart-define=OPENAIP_API_KEY=86c849e3ae73be7b4d66bf67d3116b29
```

or for builds:

```powershell
flutter build apk --dart-define=OPENAIP_API_KEY=86c849e3ae73be7b4d66bf67d3116b29
flutter build ios --dart-define=OPENAIP_API_KEY=86c849e3ae73be7b4d66bf67d3116b29
```

**Adapter Details:**
- Location: `lib/data/regulatory/openaip_airspace_repository.dart`
- Endpoint: `GET https://api.core.openaip.net/api/airspaces`
- Header: `x-openaip-api-key`
- Query params: `pos` (lat,lon), `dist` (km), `limit` (results), `fields` (JSON response fields)
- Status: Tested adapter exists, not yet connected to `WeatherSession` or `Mapa` UI

## Development Workflow

**After each change, run:**

```powershell
dart format lib test docs
flutter test
flutter analyze
```

**To run with OpenAIP key:**

```powershell
flutter run --dart-define=OPENAIP_API_KEY=86c849e3ae73be7b4d66bf67d3116b29
```

**Current test count:** 67 (all passing, zero lint issues)

## What's Next

### Recommended Next Slice: Connect OpenAIP to Map UI

The adapter exists and is tested. Now show real airspaces on `Mapa`.

**Spec to create:**
```text
docs/spec_openaip_map_layer_mvp.md
```

**Acceptance Criteria:**
- `WeatherSession.loadNearbyAirspaces()` uses `OpenAipAirspaceRepository` with active location + guide radius
- `Mapa` displays loading → loaded/error states
- Real airspaces render on map (different color/style than mock zones)
- Copy: "Información regulatoria. Verifica fuentes oficiales antes de volar."
- Mock sensitive-zone rule unchanged (keep both for now)
- Tests: repository injection, success, error, empty results, map rendering

**Scope Note:** Do NOT make OpenAIP data block or warn in `Condiciones` until a future spec validates polygon containment and legal language for regulatory blocking.

---

## Final Prompt For Next Session

> You are continuing AeroCheck, a Flutter MVP drone flight-readiness planner. Read `CLAUDE.md` first, then this file.
> 
> **Last work:** Improved Condiciones Screen UX/UI (better labels, score context, temporal window logic, rejection reasons with Actual/Limit). Integrated real NOAA Kp geomagnetic data (was null before).
> 
> **Current state:** 67 tests passing, zero lint. Branch is 16 commits ahead of origin/main.
> 
> **Next task:** Connect OpenAIP to Mapa as informational real airspace layer. Follow the spec-driven workflow:
> 1. Create `docs/spec_openaip_map_layer_mvp.md` with acceptance criteria
> 2. Write failing tests first (state, UI, error handling)
> 3. Implement WeatherSession airspace loading + Mapa UI
> 4. Run `dart format lib test docs && flutter test && flutter analyze`
> 5. Commit with clear message
> 
> **Key constraints:**
> - Keep mock sensitive-zone rule working (don't replace)
> - OpenAIP data is informational only (does NOT block flight in Condiciones yet)
> - All provider logic behind adapters
> - No secrets in files; use `--dart-define=OPENAIP_API_KEY=...` at runtime
> - Treat regulatory data as untrusted (incomplete, stale, may be wrong)
>
> **Files to review before starting:**
> - `docs/mvp_decision_rules.md` (decision engine)
> - `docs/spec_*.md` (existing patterns)
> - `lib/app/weather_session.dart` (state structure)
> - `lib/features/map/map_screen.dart` (current map UI)

## Safety Notes

- AeroCheck must never claim to be official flight authorization
- Weather and regulatory data are incomplete and can be stale
- All external data stays behind adapters for easier testing and replacement
- Decision rules must work offline without network
- Never commit API keys, tokens, keystores, or local config
- Always show the reason why a flight is `NO_APTO` or `PRECAUCION`

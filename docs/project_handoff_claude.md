# AeroCheck Project Handoff For Claude

## Current Status

Repository:

```text
https://github.com/aleoviedo071298/AeroCheck
```

Local path used in Codex:

```text
C:\Users\Alejandro\Desktop\local\dron
```

Current pushed head at handoff:

```text
3274985 Add OpenAIP airspace repository
```

Working tree was clean after the last push.

## What Exists

AeroCheck is now a Flutter MVP with five tabs:

- `Estado`
- `Forecast`
- `Viento`
- `Mapa`
- `Ajustes`

Implemented capabilities:

- Shared flight readiness rules.
- Explainable `APTO / PRECAUCION / NO_APTO` decisions.
- Mock weather scenarios.
- Real Open-Meteo weather adapter.
- Favorite locations and local catalog search.
- Active location selection.
- Persistent local preferences.
- Configurable guide radius.
- Mock sensitive-zone proximity rule.
- Map layer/list for detected mock sensitive zones.
- Risk summary in Estado header.
- Forecast rows evaluated with current operational context.
- Forecast primary reason per hour.
- Expandable Forecast details with all active reasons.
- Best-hour indicator in Forecast.
- OpenAIP Core airspace adapter, not yet connected to UI/state.

## Important Files

Product and workflow:

```text
AGENTS.md
CLAUDE.md
README.md
plan_app_dron_multiplataforma.md
docs/agent_workflow.md
docs/mvp_decision_rules.md
```

App/session:

```text
lib/app/weather_session.dart
lib/app/app_shell.dart
lib/app/aerocheck_app.dart
lib/app/theme.dart
```

Domain:

```text
lib/domain/entities/
lib/domain/rules/
```

Data providers:

```text
lib/data/weather/
lib/data/regulatory/
lib/data/mock/
lib/data/location/
lib/data/preferences/
```

Features:

```text
lib/features/conditions/
lib/features/forecast/
lib/features/map/
lib/features/settings/
lib/features/wind/
```

Tests:

```text
test/app/weather_session_test.dart
test/domain/rules/flight_readiness_evaluator_test.dart
test/data/weather/open_meteo_forecast_response_test.dart
test/data/regulatory/openaip_airspace_repository_test.dart
test/features/
```

## Recent Commit Timeline

```text
3274985 Add OpenAIP airspace repository
18015e9 Highlight best forecast hour
7d8b470 Add expandable forecast reasons
6705b83 Show primary forecast reasons
011fdde Evaluate forecast with operational context
c4a707b Show map risk summary in conditions
d763a83 Show mock sensitive zones on map
09e7504 Apply mock sensitive zone radius rule
b585d37 Make map guide radius configurable
4845b90 Connect map to active location
```

## OpenAIP Notes

The user provided an OpenAIP API key during Codex work. It was treated as a secret and was not committed.

Use only:

```powershell
flutter run --dart-define=OPENAIP_API_KEY=...
```

or pass a fake key in tests.

OpenAIP adapter:

```text
lib/data/regulatory/openaip_airspace_repository.dart
```

The adapter uses:

- `GET https://api.core.openaip.net/api/airspaces`
- Header: `x-openaip-api-key`
- Query: `pos`, `dist`, `limit`, `fields`

Current OpenAIP adapter is tested but not connected to `WeatherSession`, `Mapa`, or readiness rules.

## Verification Commands

Run after each meaningful change:

```powershell
dart format lib test docs
flutter test
flutter analyze
```

Optional run command with OpenAIP key:

```powershell
flutter run --dart-define=OPENAIP_API_KEY=...
```

## Recommended Next Slice

Connect OpenAIP as an informational map layer.

Suggested spec:

```text
docs/spec_openaip_map_layer_mvp.md
```

Acceptance criteria:

- `WeatherSession` can load nearby OpenAIP airspaces for the active location and guide radius.
- UI shows loading, error, empty, and loaded states on `Mapa`.
- The mock sensitive-zone rule remains unchanged.
- OpenAIP airspaces are informational only.
- Copy includes attribution and says pilots must verify official sources.
- Tests cover repository injection, success, error, and map rendering.

Do not make OpenAIP data block or warn in `Estado` until a separate spec validates distance/inside-polygon behavior and legal copy.

## Safety Notes

- AeroCheck must never claim to authorize flights.
- Regulatory and weather data can be incomplete or stale.
- Keep all provider data behind adapters.
- Keep decision rules testable without network access.
- Never commit secrets or generated build outputs.

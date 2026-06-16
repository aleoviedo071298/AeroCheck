# Spec: Flutter MVP Prototype

## Assumptions

1. The first app implementation will use Flutter for Android and iOS from one shared codebase.
2. The first prototype will use local mock data only, with no paid providers and no production API keys.
3. The first useful behavior is the `Conditions` screen powered by the MVP decision rules.
4. The flight-readiness evaluator must be pure Dart logic, independent from Flutter widgets, maps, device APIs, and network calls.
5. The prototype should be production-shaped, but not production-complete.

If any of these assumptions change, update this spec before implementation.

## Objective

Build the first runnable AeroCheck Flutter prototype.

The prototype should let a user open the app and immediately see:

- Current flight-readiness status: `APTO`, `PRECAUCION`, or `NO_APTO`.
- Main reasons behind the decision.
- A suggested best flight window.
- Basic weather cards for drone-relevant conditions.
- Bottom navigation for the MVP sections.

The goal is to prove the product shape and the core decision logic before integrating real weather, map, subscription, or regulatory providers.

## User Story

As a drone pilot, I want to open AeroCheck and quickly understand whether the current conditions are suitable for my drone and mission, so I can decide whether to fly now, wait for a better window, or avoid flying.

## MVP Screens

### 1. Conditions

Primary screen for the prototype.

Must show:

- Location label.
- Current time or forecast time.
- Big status module:
  - `APTO`
  - `PRECAUCION`
  - `NO_APTO`
- Score from 0 to 100.
- One-sentence summary.
- Reasons list.
- Best recommended window.
- Weather cards:
  - Wind.
  - Gusts.
  - Gust spread.
  - Temperature.
  - Precipitation probability.
  - Visibility.
  - Cloud base.
  - Kp.
- Drone profile and mission profile used for the result.

### 2. Forecast

Stub screen for MVP shell.

Must show:

- A simple list of mock hourly forecast rows.
- Hour.
- Status.
- Wind.
- Gust.
- Rain probability.
- Visibility.

The full forecast table can come later.

### 3. Wind

Stub screen for MVP shell.

Must show:

- Mock vertical wind profile.
- Altitude.
- Wind.
- Gust.
- Temperature.

### 4. Map

Stub screen for MVP shell.

Must show:

- Mock location panel.
- Placeholder map surface.
- Radius value.
- Warning that official airspace/restriction data is not connected yet.

Do not integrate Google Maps, Mapbox, MapLibre, or any paid provider in the first prototype unless explicitly approved.

### 5. Settings

Stub screen for MVP shell.

Must show:

- Selected drone profile.
- Selected mission profile.
- Placeholder threshold settings.
- Units: metric.
- Notice that thresholds are local mock settings in this prototype.

## Non-Goals

Do not build these in the first prototype:

- Real weather API integration.
- Real maps.
- NOTAM or official no-fly integrations.
- Authentication.
- Subscriptions.
- Push notifications.
- PDF/report exports.
- Native Android/iOS custom code beyond Flutter defaults.
- Offline storage beyond hardcoded mock data.

## Tech Stack

- Flutter.
- Dart.
- Material 3.
- Pure Dart unit tests for decision rules.
- Flutter widget tests only for critical UI smoke checks.

Avoid major dependencies in the first prototype. Add a dependency only when Flutter/Dart standard tooling cannot reasonably cover the need.

## Commands

These are the target commands after Flutter is scaffolded:

```powershell
flutter --version
flutter create --platforms=android,ios --project-name aerocheck .
flutter pub get
flutter test
flutter analyze
flutter run
```

If `flutter create .` cannot run because the directory is not empty, create into a temporary sibling folder and move the generated Flutter project files into this repo carefully, preserving existing docs and git history.

## Project Structure

Target Flutter structure:

```text
lib/
  main.dart
  app/
    aerocheck_app.dart
    app_shell.dart
    theme.dart
  core/
    formatting/
    units/
  data/
    mock/
      mock_flight_data.dart
  domain/
    entities/
      drone_profile.dart
      flight_rule_result.dart
      flight_window_recommendation.dart
      mission_profile.dart
      weather_snapshot.dart
    rules/
      flight_readiness_evaluator.dart
      flight_readiness_status.dart
      rule_severity.dart
  features/
    conditions/
      conditions_screen.dart
      widgets/
    forecast/
      forecast_screen.dart
    map/
      map_screen.dart
    settings/
      settings_screen.dart
    wind/
      wind_screen.dart

test/
  domain/
    rules/
      flight_readiness_evaluator_test.dart
  features/
    conditions/
      conditions_screen_test.dart
```

## Domain Model

### `FlightReadinessStatus`

Values:

- `ready`
- `caution`
- `notReady`

UI labels:

- `APTO`
- `PRECAUCION`
- `NO_APTO`

### `RuleSeverity`

Values:

- `ok`
- `warning`
- `blocked`

### `FlightRuleResult`

Fields:

- `code`
- `severity`
- `title`
- `details`
- `measuredValue`
- `threshold`

### `DroneProfile`

Fields:

- `id`
- `name`
- `maxWindKmh`
- `maxGustKmh`
- `preferredAltitudeMeters`
- `minVisibilityKm`

Default profiles:

- `micro`
- `standard`
- `professional`

### `MissionProfile`

Fields:

- `id`
- `name`
- `windModifier`
- `gustModifier`
- `description`

Default missions:

- `recreational`
- `photoVideo`
- `inspection`
- `mapping`
- `training`

### `WeatherSnapshot`

Fields:

- `time`
- `locationLabel`
- `temperatureC`
- `dewPointC`
- `windKmh`
- `gustKmh`
- `windDirectionDegrees`
- `precipitationProbability`
- `precipitationMmPerHour`
- `cloudCoverPercent`
- `cloudBaseMeters`
- `visibilityKm`
- `kpIndex`
- `isDaylight`
- `isInsideRestrictedArea`
- `isNearRestrictedArea`

### `FlightWindowRecommendation`

Fields:

- `start`
- `end`
- `score`
- `status`
- `summary`

## Decision Logic

Implement rules from `docs/mvp_decision_rules.md`:

- Wind speed.
- Wind gust.
- Gust spread.
- Precipitation probability.
- Precipitation intensity.
- Visibility.
- Cloud base.
- Temperature.
- Kp index.
- Daylight.
- Restricted area.
- Missing critical data.

Overall result:

```text
If any rule is blocked => NO_APTO
Else if any rule is warning => PRECAUCION
Else => APTO
```

Score can be simple in the prototype:

```text
Start at 100
Subtract 12 for each warning
Subtract 35 for each blocked rule
Clamp between 0 and 100
```

This score is only a UI aid. The status still comes from rule severity.

## Mock Data

Create at least three mock scenarios:

1. `goodToFly`
   - Low wind.
   - Low gust.
   - No rain.
   - Good visibility.
   - Daylight.
   - No nearby restriction.

2. `cautionWind`
   - Gusts near the configured limit.
   - No rain.
   - Good visibility.
   - Daylight.

3. `notReadyRainAndRestriction`
   - Active rain.
   - High precipitation probability.
   - Inside restricted area.

The first UI can default to `cautionWind` because it demonstrates explainability better than a fully green state.

## UI Direction

The first prototype should feel like an operational tool, not a landing page.

Guidelines:

- Dense but readable mobile interface.
- Clear hierarchy: status first, reasons second, details third.
- Avoid marketing hero sections.
- Use color carefully:
  - Green for `APTO`.
  - Amber for `PRECAUCION`.
  - Red for `NO_APTO`.
  - Neutral dark/light surfaces for supporting data.
- Every `PRECAUCION` or `NO_APTO` state must show reasons.
- Text must fit on small phone widths.

## Testing Strategy

### Unit Tests

Required for `FlightReadinessEvaluator`.

Minimum tests:

- Returns `ready` when all rules are ok.
- Returns `caution` when wind or gust is near limit.
- Returns `notReady` when gust exceeds limit.
- Returns `notReady` when precipitation intensity blocks flight.
- Returns `notReady` when inside restricted area.
- Returns `caution` when near restricted area.
- Applies mission modifiers to effective wind and gust thresholds.
- Does not return `ready` when critical data is missing.
- Produces user-facing rule reasons.

### Widget Tests

Minimum smoke test:

- Conditions screen renders status, summary, reasons, and best window with mock data.

### Manual Verification

Run the app and verify:

- Bottom navigation switches screens.
- Conditions screen is readable on a phone-sized viewport.
- Mock reasons match the selected mock scenario.
- No console/runtime errors are shown.

## Boundaries

### Always

- Keep decision logic independent from widgets.
- Keep mock data clearly separated from domain logic.
- Use Spanish user-facing labels for product copy.
- Keep code ready for Android and iOS from the same Flutter source.
- Keep safety/regulatory disclaimers visible where map/restriction placeholders appear.

### Ask First

- Adding a map SDK.
- Adding a weather provider SDK.
- Adding auth.
- Adding local database/storage.
- Adding subscription packages.
- Changing MVP decision thresholds.

### Never

- Put API keys in source code.
- Hardcode platform-specific business logic.
- Make a green `APTO` result when critical weather data is missing.
- Claim official flight authorization.
- Hide rule reasons from the user.

## Implementation Tasks

- [ ] Scaffold Flutter project.
  - Acceptance: `flutter test` runs on the generated project.
  - Verify: `flutter test`.
  - Files: Flutter scaffold files.

- [ ] Add domain entities and evaluator tests.
  - Acceptance: evaluator tests fail before implementation or are written before final evaluator code.
  - Verify: `flutter test test/domain/rules/flight_readiness_evaluator_test.dart`.
  - Files: `lib/domain/**`, `test/domain/**`.

- [ ] Implement evaluator.
  - Acceptance: all required decision tests pass.
  - Verify: `flutter test`.
  - Files: `lib/domain/rules/**`.

- [ ] Add mock data.
  - Acceptance: three scenarios are available and typed.
  - Verify: `flutter test`.
  - Files: `lib/data/mock/**`.

- [ ] Build app shell.
  - Acceptance: five bottom tabs render and can be switched.
  - Verify: `flutter test` plus manual run.
  - Files: `lib/app/**`, `lib/features/**`.

- [ ] Build Conditions screen.
  - Acceptance: selected mock scenario shows status, score, reasons, weather cards, and best window.
  - Verify: `flutter test` plus manual run.
  - Files: `lib/features/conditions/**`.

- [ ] Add stub Forecast, Wind, Map, and Settings screens.
  - Acceptance: each tab has useful mock content or placeholder content aligned with this spec.
  - Verify: manual run.
  - Files: `lib/features/forecast/**`, `lib/features/wind/**`, `lib/features/map/**`, `lib/features/settings/**`.

## Success Criteria

The first prototype is done when:

- Flutter project opens and runs.
- `flutter test` passes.
- `flutter analyze` passes or has only documented non-blocking warnings.
- Conditions screen displays a mock AeroCheck decision.
- Rule reasons are visible and understandable.
- Bottom navigation exposes five MVP sections.
- No real provider/API dependency is required.
- Existing planning docs remain intact.

## Open Questions

1. Should the first prototype default to Spanish-only UI, or include an internal path for future localization?
2. Should the first mock location be Comodoro Rivadavia because the competitor screenshots use that region?
3. Should the first visual style be dark-mode-first like the reference app, or system-theme-first?
4. Which Flutter channel/version should be standardized for the team?
5. Should the repo root contain the Flutter app directly, or should the app live under `apps/mobile/`?

## Recommended Answers for Prototype

To keep the first build moving:

- Use Spanish-only visible copy for now.
- Use Comodoro Rivadavia as the first mock location.
- Use system theme, with a polished dark theme available.
- Use the installed stable Flutter version on the machine that scaffolds the project.
- Put Flutter at the repo root unless a monorepo need appears later.

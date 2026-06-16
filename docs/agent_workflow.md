# Agent workflow for AeroCheck

This project should use an agent workflow inspired by `addyosmani/agent-skills`, adapted to AeroCheck's current phase.

## Why this matters

AeroCheck is not just a visual prototype. It makes safety-adjacent recommendations for drone pilots. That means the project needs written specs, testable rules, careful review, and clear boundaries from day one.

## Minimal skill set

Use these three workflows as the default operating mode:

1. **Spec-driven development**
   - Use before building new features or making architectural decisions.
   - Output: a spec in `docs/` with objective, commands, structure, testing, boundaries, success criteria, and open questions.

2. **Test-driven development**
   - Use for any behavior or logic.
   - Most important for the flight-readiness engine: wind, gusts, rain, visibility, Kp, daylight, restricted areas, and missing data.
   - Output: tests that prove the behavior before and after implementation.

3. **Code review and quality**
   - Use before merging or pushing meaningful changes.
   - Review correctness, readability, architecture, security, performance, and verification.

## Recommended lifecycle

For AeroCheck, the normal sequence should be:

```text
Idea or requirement
  -> short spec
  -> task breakdown
  -> failing tests for core behavior
  -> incremental implementation
  -> verification
  -> review
  -> commit and push
```

## First feature sequence

The next implementation milestone should be a Flutter prototype. Before coding it, create a spec for:

```text
docs/spec_flutter_mvp_prototype.md
```

That spec should define:

- App shell and navigation.
- First five tabs: Conditions, Forecast, Wind, Map, Settings.
- Mock data model.
- Flight-readiness domain classes.
- Test strategy for decision rules.
- Commands for Flutter create, test, analyze, and run.
- Acceptance criteria for the first screen.

## Agent checklist before implementation

Before writing code, confirm:

- The task has a written spec or acceptance criteria.
- The target files are clear.
- The behavior can be tested.
- Any assumptions are listed.
- External provider choices are not hardcoded prematurely.

## Agent checklist before commit

Before committing, confirm:

- Tests or relevant checks were run.
- The change matches the spec.
- No secrets or generated build outputs are staged.
- The README or docs are updated if workflow changed.
- The commit message explains the change clearly.

## Current priority

Create the Flutter MVP prototype with mock data, but keep the decision logic independent from UI and external APIs.

Suggested first modules:

- `FlightReadinessStatus`
- `RuleSeverity`
- `FlightRuleResult`
- `DroneProfile`
- `MissionProfile`
- `WeatherSnapshot`
- `FlightReadinessEvaluator`
- `FlightWindowRecommendation`

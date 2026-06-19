# Antigravity Handoff: Forecast Scrubber Implementation

Date: 2026-06-18

## Repository State

- Branch: `feat/forecast-scrubber-impl`
- Base from updated `main`: `94f75fb`
- Task 1 commit: `ea640e7 feat: extend forecast to 7 days and memoize forecastRows`
- Local `.claude/` is untracked configuration and must not be staged or committed.
- The branch has not been pushed yet. Push and open the PR only after Tasks 2-5.

## Completed

Task 1 from
`docs/superpowers/plans/2026-06-18-forecast-scrubber.md` is complete:

- Open-Meteo range changed from 2 to 7 days.
- `WeatherSession.forecastRows` no longer has the 12-hour cap.
- Forecast rows are memoized per `WeatherBundle` instance.
- Cache invalidation was added for rules changes and loaded/error regulatory
  context changes.
- Added `test/app/weather_session_forecast_test.dart`.

TDD evidence:

- RED: count was exactly 12 instead of greater than 12.
- GREEN: 2 focused tests passed.
- Full suite: 104 passed, 1 pre-existing map tile test skipped.
- `flutter analyze`: no issues.

## Continue From Task 2

Do not repeat Task 1. Start at **Task 2: Day-grouping helpers** and follow the
committed plan exactly, one task at a time, preserving its RED/GREEN sequence.

Before every task commit:

```powershell
dart format lib test
flutter test
flutter analyze
```

Every task commit must use the exact subject from the plan and end with:

```text
Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
```

Do not run the APK build in Task 5. Run the remaining formatting, test, and
analyzer checks. If Task 5 formatting produces changes, commit them as directed;
otherwise skip that optional commit.

## Locked Boundaries

- Do not change `FlightReadinessEvaluator`, `FlightRulesConfig`, or
  `bestWindowFor`.
- Do not add weather API fields.
- Per-day best hour belongs in the Forecast UI layer.
- Keep metric storage and use `UnitFormatters` for display.
- Add every visible string through `AppStrings.get(key, language:)` in both
  Spanish and English maps.
- Preserve widget keys from the plan.

## Ready-to-Paste Prompt

```text
Continue the AeroCheck forecast scrubber implementation from the existing
branch feat/forecast-scrubber-impl. First verify HEAD is ea640e7 and read
AGENTS.md, CLAUDE.md,
docs/superpowers/specs/2026-06-18-forecast-scrubber-design.md,
docs/superpowers/plans/2026-06-18-forecast-scrubber.md, and
docs/antigravity_forecast_scrubber_handoff.md.

Task 1 is complete and must not be repeated. Start at Task 2 and execute Tasks
2, 3, 4, and 5 strictly in order with TDD: write the planned failing test, run
the focused test and confirm the expected RED, implement only that task, then
reach GREEN. Before each task commit run dart format lib test, the full flutter
test suite, and flutter analyze. The suite should retain one pre-existing map
tile skip. Use each exact commit subject from the plan and append the trailer
Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>.

Do not run flutter build apk in Task 5. Do not touch the decision engine,
FlightRulesConfig, bestWindowFor, or add weather fields. Keep per-day best-hour
logic in the UI, use UnitFormatters, add visible strings to both es/en maps, and
preserve all specified widget keys. Keep the untracked .claude/ directory out
of every commit. After Task 5, push feat/forecast-scrubber-impl and open a PR
against main with the test/analyzer results.
```

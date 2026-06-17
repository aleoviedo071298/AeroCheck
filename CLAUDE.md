# AeroCheck Claude Rules

Use this file as the working instruction set when continuing AeroCheck in Claude.

## Project Context

AeroCheck is a Flutter MVP for Android and iOS that helps drone pilots plan flights using:

- Weather and hourly forecast.
- Wind and gust checks.
- Mock and real operational context.
- Map/favorite locations.
- Explainable `APTO / PRECAUCION / NO_APTO` decisions.
- OpenAIP adapter prepared for nearby airspace lookup.

Important source files:

- Product plan: `plan_app_dron_multiplataforma.md`
- Decision rules: `docs/mvp_decision_rules.md`
- Agent workflow: `docs/agent_workflow.md`
- Current handoff: `docs/project_handoff_claude.md`
- Specs: `docs/spec_*.md`

## Required Workflow

For every non-trivial change:

1. Read `AGENTS.md`, this file, `docs/agent_workflow.md`, and the relevant spec.
2. Create or update a short spec in `docs/` before implementation.
3. Break work into a small vertical slice.
4. Write failing tests first for behavior.
5. Implement incrementally in shared Flutter/domain code.
6. Run:

```powershell
dart format lib test docs
flutter test
flutter analyze
```

7. Check that no secrets or generated build outputs are staged.
8. Commit and push with a clear message.

## Skills To Use

The project workflow is based on these agent skills from `addyosmani/agent-skills`:

- `spec-driven-development`
- `planning-and-task-breakdown`
- `test-driven-development`
- `incremental-implementation`
- `code-review-and-quality`

If Claude has a skills/rules system, load those skills or paste their process into the session. If not, follow the workflow manually.

## Boundaries

Always:

- Keep Android and iOS behavior shared through Flutter.
- Keep business rules in domain/session code, not duplicated in UI.
- Keep decisions explainable to the user.
- Treat weather, map, regulatory, and device data as untrusted.
- Keep OpenAIP and other provider logic behind repositories/adapters.

Never:

- Present AeroCheck as official flight authorization.
- Hide the reason for `NO_APTO` or `PRECAUCION`.
- Commit API keys, tokens, keystores, provisioning profiles, `.env`, or local config.
- Hardcode the OpenAIP API key.
- Duplicate platform-specific decision rules for Android/iOS.

Ask first before:

- Adding paid external providers.
- Adding major dependencies.
- Changing legal/regulatory language.
- Changing monetization/subscription rules.
- Rewriting MVP decision rules.

## External Providers

Weather:

- Open-Meteo is already connected through `lib/data/weather/`.

Regulatory:

- OpenAIP Core adapter exists in `lib/data/regulatory/`.
- API docs: `https://docs.openaip.net/`
- Core schema: `https://api.core.openaip.net/api/system/specs/v1/schema.json`
- Local key should be passed only with:

```powershell
flutter run --dart-define=OPENAIP_API_KEY=...
```

Do not write the key into files.

## Next Suggested Slice

Connect `OpenAipAirspaceRepository` to `WeatherSession` as an informational real regulatory layer and show OpenAIP airspaces on `Mapa`, without replacing the mock sensitive-zone rule yet.

Expected shape:

- Spec: `docs/spec_openaip_map_layer_mvp.md`
- Tests before implementation.
- Informational UI only.
- Attribution/link to OpenAIP.
- Clear copy that AeroCheck is not official authorization.

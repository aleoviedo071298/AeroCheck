# Prompt Para Continuar En Claude

Copy and paste this prompt into Claude from the root of the AeroCheck repo.

```text
You are continuing work on AeroCheck, a Flutter MVP for Android/iOS drone flight planning.

Repository:
https://github.com/aleoviedo071298/AeroCheck

Local project root:
C:\Users\Alejandro\Desktop\local\dron

Before doing any work, read:
- AGENTS.md
- CLAUDE.md
- docs/project_handoff_claude.md
- docs/agent_workflow.md
- docs/mvp_decision_rules.md
- plan_app_dron_multiplataforma.md

Use the project skills/workflows:
- spec-driven-development
- planning-and-task-breakdown
- test-driven-development
- incremental-implementation
- code-review-and-quality

If your environment supports agent skills, load those skills. If not, follow them manually:
1. Write or update a short spec in docs/ before non-trivial implementation.
2. Break the work into a small vertical slice.
3. Write failing tests first for behavior.
4. Implement shared Flutter/domain logic, not platform-duplicated logic.
5. Run dart format, flutter test, and flutter analyze.
6. Check that no secrets are staged.
7. Commit and push with a clear message.

Project constraints:
- Never present AeroCheck as official flight authorization.
- Never hide the reason for PRECAUCION or NO_APTO.
- Never commit API keys, tokens, .env files, keystores, provisioning profiles, or generated build outputs.
- Treat weather, map, regulatory, and device data as untrusted.
- Keep provider-specific logic behind repositories/adapters.

Current status:
- Flutter MVP exists with Estado, Forecast, Viento, Mapa, Ajustes.
- Flight readiness rules are implemented and tested.
- Open-Meteo weather is connected.
- Mock sensitive-zone rule affects Estado and Forecast.
- Forecast has expandable reasons and best-hour indicator.
- OpenAIP Core airspace repository exists and is tested, but it is not connected to UI or readiness rules yet.

OpenAIP:
- Docs: https://docs.openaip.net/
- Core schema: https://api.core.openaip.net/api/system/specs/v1/schema.json
- API key must be supplied only via --dart-define=OPENAIP_API_KEY=...
- Do not write the key into repo files.

Next task:
Connect OpenAIP as an informational map layer.

Expected approach:
1. Create docs/spec_openaip_map_layer_mvp.md.
2. Add tests first.
3. Inject an AirspaceRepository into WeatherSession.
4. Load nearby OpenAIP airspaces for active location + guide radius.
5. Show OpenAIP airspaces in Mapa with loading/error/empty/loaded states.
6. Keep mock sensitive-zone rule unchanged.
7. Add OpenAIP attribution and legal caution copy.
8. Run:
   dart format lib test docs
   flutter test
   flutter analyze
9. Commit and push.

Important: Do not make OpenAIP data change APTO/PRECAUCION/NO_APTO yet. This slice is informational only.
```

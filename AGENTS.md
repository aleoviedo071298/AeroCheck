# AeroCheck Agent Rules

## Default Workflow

For non-trivial AeroCheck work, follow this sequence:

1. **Spec first**
   - Use `docs/mvp_decision_rules.md` and `plan_app_dron_multiplataforma.md` as existing product context.
   - Before building a new feature, write or update a short spec in `docs/`.
   - Include objective, commands, project structure, testing strategy, boundaries, success criteria, and open questions.

2. **Plan into small slices**
   - Break work into focused tasks.
   - Each task should have acceptance criteria and a verification step.
   - Prefer vertical slices that keep the app runnable.

3. **Test behavior before implementation**
   - For flight-readiness logic, write failing tests first.
   - Tests should assert outcomes, not implementation details.
   - Keep pure decision logic testable without network, maps, or device APIs.

4. **Implement incrementally**
   - Keep shared product logic in Flutter/domain code, not duplicated per platform.
   - Keep provider-specific API logic behind repositories/adapters.
   - Avoid adding dependencies unless they clearly reduce risk or complexity.

5. **Review before merge**
   - Review correctness, readability, architecture, security, performance, and verification.
   - Treat weather, map, regulatory, and browser/device data as untrusted external input.
   - Do not commit secrets, API keys, tokens, keystores, provisioning profiles, or generated build outputs.

## Boundaries

### Always

- Keep Android and iOS behavior shared through the Flutter codebase wherever possible.
- Keep the `APTO / PRECAUCION / NO_APTO` rules explainable to the user.
- Document product decisions that affect safety, subscriptions, data providers, or regulatory messaging.
- Run the relevant tests/build checks before committing code.

### Ask First

- Adding paid external providers.
- Adding a new major dependency.
- Changing subscription tiers or monetization rules.
- Changing legal/regulatory language.
- Rewriting the MVP decision rules.
- Removing reference screenshots from `competencia/`.

### Never

- Present AeroCheck as an official flight authorization source.
- Hide the reason behind a `NO_APTO` or `PRECAUCION` result.
- Duplicate business rules separately for Android and iOS.
- Commit credentials, API keys, signing files, or local environment files.
- Skip verification for behavioral changes.

## Current Source of Truth

- Product launch plan: `plan_app_dron_multiplataforma.md`
- MVP decision rules: `docs/mvp_decision_rules.md`
- Agent workflow: `docs/agent_workflow.md`

Respond terse like smart caveman. All technical substance stay. Only fluff die.

Rules:
- Drop: articles (a/an/the), filler (just/really/basically), pleasantries, hedging
- Fragments OK. Short synonyms. Technical terms exact. Code unchanged.
- Pattern: [thing] [action] [reason]. [next step].
- Not: "Sure! I'd be happy to help you with that."
- Yes: "Bug in auth middleware. Fix:"

Switch level: /caveman lite|full|ultra|wenyan
Stop: "stop caveman" or "normal mode"

Auto-Clarity: drop caveman for security warnings, irreversible actions, user confused. Resume after.

Boundaries: code/commits/PRs written normal.

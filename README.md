# AeroCheck

AeroCheck is a planned cross-platform mobile app for drone pilots. The goal is to help users decide when and where it is safe or convenient to fly by combining weather, wind-by-altitude, operational maps, alerts, and pre-flight checks.

## Planning

- [Multiplatform launch plan](./plan_app_dron_multiplataforma.md)
- [MVP decision rules](./docs/mvp_decision_rules.md)
- [Flutter MVP prototype spec](./docs/spec_flutter_mvp_prototype.md)
- [Agent workflow](./docs/agent_workflow.md)
- Competitive reference screenshots are stored in `competencia/`.

## Proposed Stack

- Flutter for Android and iOS.
- Shared flight-readiness logic across platforms.
- Backend API for weather aggregation, alerts, geospatial layers, users, and subscriptions.

## Development

```powershell
flutter pub get
flutter test
flutter analyze
flutter run
```

The current app is a mock-data Flutter MVP with five tabs: `Estado`, `Forecast`, `Viento`, `Mapa`, and `Ajustes`.

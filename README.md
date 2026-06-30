# AeroCheck

A cross-platform mobile app for drone pilots that helps decide when and where it is
safe or convenient to fly. AeroCheck combines weather forecasts, wind-by-altitude
data, geomagnetic K-index, regulatory/airspace layers, and pre-flight checks into a
single flight-readiness view.

## Status

Active development — Flutter app with a working MVP across five tabs: **Conditions**,
**Forecast**, **Wind**, **Map**, and **Settings**. Real data providers are wired in
for weather, wind, K-index, and airspace (OpenAIP); some flows still use mock data
while their providers are finalized.

## Features

- **Flight-readiness conditions header** — go/no-go style summary with the primary reason behind the recommendation.
- **Forecast** — hourly forecast with a "best hour to fly" indicator and expandable reasoning.
- **Wind by altitude** — wind speed/direction charts across altitude bands.
- **Geomagnetic K-index** — real data integration for atmospheric conditions relevant to flight risk.
- **Map** — airspace and regulatory layers via OpenAIP, with a sensitive-zone radius overlay and the user's active location.
- **Location search & favorites** — city search with persisted favorite locations.
- **Settings** — unit selection (metric/imperial) and full i18n support.
- **Notifications** — local alerts via `flutter_local_notifications`.

## Tech Stack

- **Framework**: Flutter (Dart), feature-based architecture (`domain/`, `data/`, `features/`).
- **Mapping**: `flutter_map` + airspace data via OpenAIP.
- **Location**: `geolocator`.
- **Persistence**: `shared_preferences` (settings, favorite locations).
- **Notifications**: `flutter_local_notifications` + `timezone`.
- **Networking**: `http`.

## Project Structure

```
lib/
  domain/      Entities, business rules, i18n, units — platform-agnostic core
  data/        Data sources: weather, location, kp_index, regulatory, mock
  features/    UI per feature: conditions, forecast, wind, map, alerts, settings, splash
  app/         App-level widgets/shell
docs/          MVP specs and planning documents (one per feature/decision)
competencia/   Competitive reference screenshots
```

## Development

```bash
flutter pub get
flutter test
flutter analyze
flutter run
```

## Planning & Specs

- [Multiplatform launch plan](./plan_app_dron_multiplataforma.md)
- [MVP decision rules](./docs/mvp_decision_rules.md)
- [Flutter MVP prototype spec](./docs/spec_flutter_mvp_prototype.md)
- [Weather provider MVP spec](./docs/spec_weather_provider_mvp.md)
- Individual feature specs (city search, favorites, map layers, K-index, units, i18n, etc.) live in [`docs/`](./docs).

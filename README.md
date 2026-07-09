# AeroCheck

> Flutter app for drone pilots — weather, wind-by-altitude, airspace data, K-index, and pre-flight checks in one flight-readiness view.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)

## About

AeroCheck consolidates everything a drone pilot needs before takeoff: weather forecasts, wind speed and direction by altitude layer, geomagnetic K-index (interference risk), regulatory airspace data, and a structured pre-flight checklist — all in a single flight-readiness view. Active development — working MVP across five tabs.

## Tech Stack

| Layer | Detail |
|---|---|
| **Framework** | Flutter (cross-platform — iOS, Android) |
| **Language** | Dart |
| **Maps** | `flutter_map` + OpenStreetMap |
| **Location** | `geolocator` |
| **Notifications** | `flutter_local_notifications` |
| **Airspace data** | OpenAIP API |
| **Architecture** | domain / data / features split |

## Features

- **Weather tab** — current conditions and forecast at pilot's location.
- **Wind-by-altitude tab** — wind speed and direction at multiple altitude layers.
- **Airspace tab** — map with regulatory zones, controlled airspace, and restrictions (OpenAIP).
- **K-index tab** — geomagnetic activity level and interference risk rating.
- **Pre-flight checklist** — structured checklist before every flight.

## Project Structure

```
AeroCheck/
└── app/
    ├── lib/
    │   ├── domain/      Entities and repository interfaces
    │   ├── data/        API clients and repository implementations
    │   └── features/    UI screens (weather, wind, airspace, kindex, checklist)
    ├── pubspec.yaml     Dependencies
    └── docs/            30+ spec documents and planning notes
```

## Setup

**Requirements:** Flutter SDK 3.x, Dart 3.x.

```bash
git clone https://github.com/aleoviedo071298/AeroCheck.git
cd AeroCheck/app
flutter pub get
flutter run
```

---

**Alejandro Oviedo** · [LinkedIn](https://www.linkedin.com/in/aleoviedo071298/) · [GitHub](https://github.com/aleoviedo071298)

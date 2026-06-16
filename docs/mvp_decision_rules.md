# AeroCheck MVP decision rules

## Objective

Define the first version of the AeroCheck flight-readiness logic. The MVP should answer:

> Can I fly here, at this time, with this drone and mission profile?

The output must be simple for the pilot, but explainable:

- `APTO`
- `PRECAUCION`
- `NO_APTO`

Each result must include the specific reasons that caused the decision.

## MVP principle

The MVP should not try to be legally authoritative or aviation-certified. It should be a decision-support tool that combines weather, wind, visibility, precipitation, geomagnetic conditions, and basic airspace warnings.

The app must always communicate:

- AeroCheck helps plan a flight.
- The pilot remains responsible for checking local regulations and official restrictions.
- Weather and airspace data can change.

## Inputs

### Location

- Latitude.
- Longitude.
- Location label.
- Elevation if available.
- Time zone.

### Time

- Current conditions.
- Hourly forecast.
- User-selected forecast hour.
- Optional desired flight duration.

### Weather

- Weather summary.
- Temperature.
- Dew point.
- Wind speed at ground or forecast reference height.
- Wind gust speed.
- Wind direction.
- Precipitation probability.
- Precipitation intensity.
- Cloud cover.
- Cloud base altitude if available.
- Visibility.
- Pressure if available.

### Drone profile

- Drone category.
- Max recommended wind.
- Max recommended gust.
- Typical flight altitude.
- Rain tolerance.
- Minimum visibility.

### Mission profile

- Recreational.
- Photo/video.
- Inspection.
- Mapping.
- Training.

### Operational context

- Distance to restricted areas.
- Inside or near a warning/no-fly zone.
- User-defined radius.
- Daylight status.
- Kp index.

## Default drone profiles

These values are conservative starting points. They should be configurable.

| Profile | Example drones | Max wind | Max gust | Preferred altitude | Min visibility |
| --- | --- | ---: | ---: | ---: | ---: |
| Micro | DJI Mini class | 20 km/h | 30 km/h | 50-120 m | 3 km |
| Standard | Air/Mavic class | 28 km/h | 40 km/h | 50-120 m | 4 km |
| Professional | Matrice/heavier class | 35 km/h | 50 km/h | 50-150 m | 5 km |

## Mission modifiers

Mission profiles adjust tolerance.

| Mission | Wind modifier | Gust modifier | Extra rules |
| --- | ---: | ---: | --- |
| Recreational | 1.00 | 1.00 | Keep default thresholds. |
| Photo/video | 0.85 | 0.85 | Prefer smoother conditions. |
| Inspection | 0.90 | 0.90 | Warn more aggressively near obstacles. |
| Mapping | 0.80 | 0.80 | Require stable wind and good visibility. |
| Training | 0.75 | 0.75 | Conservative limits for beginners. |

Example:

```text
Standard drone max wind: 28 km/h
Photo/video modifier: 0.85
Effective max wind: 23.8 km/h
```

## Decision levels

### APTO

Use when all required values are below warning thresholds and no blocking restriction is detected.

User-facing wording:

> Apto para volar. Las condiciones principales estan dentro de los limites configurados.

### PRECAUCION

Use when one or more variables are close to limits, uncertain, or operationally relevant but not blocking.

User-facing wording:

> Precaucion. Hay condiciones que requieren atencion antes de despegar.

### NO_APTO

Use when at least one blocking rule is triggered.

User-facing wording:

> No apto para volar. Una o mas condiciones superan los limites configurados.

## Rule severity

Each rule returns:

- `status`: `ok`, `warning`, or `blocked`.
- `code`: stable rule code for UI/backend.
- `title`: short user-facing reason.
- `details`: specific measured value and threshold.
- `source`: provider or system source.

Overall status:

```text
If any rule is blocked => NO_APTO
Else if any rule is warning => PRECAUCION
Else => APTO
```

## MVP rules

### Wind speed

Rule code: `WIND_SPEED`

| Condition | Result |
| --- | --- |
| Wind <= 80% of effective max wind | ok |
| Wind > 80% and <= 100% of effective max wind | warning |
| Wind > effective max wind | blocked |

Example details:

```text
Viento 26 km/h. Limite para este perfil: 24 km/h.
```

### Wind gust

Rule code: `WIND_GUST`

| Condition | Result |
| --- | --- |
| Gust <= 80% of effective max gust | ok |
| Gust > 80% and <= 100% of effective max gust | warning |
| Gust > effective max gust | blocked |

### Gust spread

Rule code: `GUST_SPREAD`

The difference between gust and sustained wind matters because sudden changes destabilize drones.

| Condition | Result |
| --- | --- |
| Gust - wind <= 10 km/h | ok |
| Gust - wind > 10 and <= 18 km/h | warning |
| Gust - wind > 18 km/h | blocked |

### Precipitation probability

Rule code: `PRECIP_PROBABILITY`

| Condition | Result |
| --- | --- |
| Probability < 25% | ok |
| Probability >= 25% and < 55% | warning |
| Probability >= 55% | blocked |

### Precipitation intensity

Rule code: `PRECIP_INTENSITY`

| Condition | Result |
| --- | --- |
| 0 mm/h | ok |
| > 0 and <= 0.5 mm/h | warning |
| > 0.5 mm/h | blocked |

For drones with no rain tolerance, any active precipitation should at least warn.

### Visibility

Rule code: `VISIBILITY`

| Condition | Result |
| --- | --- |
| Visibility >= profile min visibility | ok |
| Visibility >= 70% and < 100% of min visibility | warning |
| Visibility < 70% of min visibility | blocked |

### Cloud base

Rule code: `CLOUD_BASE`

This rule applies only when cloud-base data is available.

| Condition | Result |
| --- | --- |
| Cloud base >= target altitude + 120 m | ok |
| Cloud base >= target altitude + 60 m and < target altitude + 120 m | warning |
| Cloud base < target altitude + 60 m | blocked |

### Temperature

Rule code: `TEMPERATURE`

| Condition | Result |
| --- | --- |
| Temperature between 0 C and 35 C | ok |
| Temperature between -5 C and 0 C, or between 35 C and 40 C | warning |
| Temperature < -5 C or > 40 C | blocked |

This should become drone-specific later because batteries and manufacturer guidance vary.

### Kp index

Rule code: `KP_INDEX`

| Condition | Result |
| --- | --- |
| Kp < 4 | ok |
| Kp >= 4 and < 6 | warning |
| Kp >= 6 | blocked |

### Daylight

Rule code: `DAYLIGHT`

For MVP, default to daylight-only unless the user explicitly enables night flight in settings.

| Condition | Result |
| --- | --- |
| Daylight | ok |
| Civil twilight | warning |
| Night and night flight disabled | blocked |

### Restricted area

Rule code: `RESTRICTED_AREA`

| Condition | Result |
| --- | --- |
| No known restriction nearby | ok |
| Within warning radius of a restricted or sensitive area | warning |
| Inside known no-fly or restricted area | blocked |

This rule depends on available official or licensed data. If data is incomplete, the UI must say so.

### Missing critical data

Rule code: `MISSING_DATA`

| Condition | Result |
| --- | --- |
| Non-critical optional field missing | ok |
| Important field missing, but enough data remains | warning |
| Wind, gust, precipitation, visibility, or location unavailable | blocked |

For MVP, avoid showing `APTO` when critical data is missing.

## Flight window recommendation

The value-added feature should scan upcoming forecast hours and find the best windows.

Inputs:

- Location.
- Drone profile.
- Mission profile.
- Desired duration, default 30 minutes.
- Forecast range, default 48 hours for MVP.

Algorithm:

1. Evaluate each forecast hour with the same rules used for the main status.
2. Group consecutive `APTO` hours.
3. Allow `PRECAUCION` hours only if the user enables relaxed recommendations.
4. Rank windows by:
   - Fewest warnings.
   - Lowest wind.
   - Lowest gust spread.
   - Lower precipitation probability.
   - Better daylight.
   - Greater distance from restricted areas.
5. Return the top 3 windows.

Example:

```json
{
  "status": "APTO",
  "bestWindow": {
    "start": "2026-06-17T08:00:00-03:00",
    "end": "2026-06-17T10:00:00-03:00",
    "score": 92,
    "summary": "Mejor ventana por viento bajo, buena visibilidad y baja probabilidad de lluvia."
  },
  "reasons": [
    {
      "code": "WIND_SPEED",
      "status": "ok",
      "title": "Viento dentro del limite",
      "details": "12 km/h sobre limite de 24 km/h."
    }
  ]
}
```

## First UI copy

### Main status

```text
Apto para volar
Condiciones principales dentro de tus limites.
```

```text
Precaucion
Revisa estos puntos antes de despegar.
```

```text
No apto para volar
Hay condiciones que superan tus limites.
```

### Reason examples

```text
Rafagas altas: 42 km/h sobre limite de 34 km/h.
```

```text
Lluvia probable: 62% para esta hora.
```

```text
Zona sensible cercana: estas dentro del radio de advertencia configurado.
```

```text
Datos incompletos: no se pudo obtener viento para esta ubicacion.
```

## MVP API shape

The app can use this as the target response from a backend later.

```json
{
  "location": {
    "label": "Comodoro Rivadavia, Chubut",
    "lat": -45.8641,
    "lng": -67.4966,
    "timezone": "America/Argentina/Buenos_Aires"
  },
  "profile": {
    "drone": "standard",
    "mission": "photo_video",
    "targetAltitudeMeters": 120
  },
  "current": {
    "status": "PRECAUCION",
    "score": 74,
    "summary": "Precaucion por rafagas cercanas al limite.",
    "rules": []
  },
  "bestWindows": []
}
```

## Open decisions

1. Confirm initial country and regulatory data source.
2. Choose weather provider.
3. Decide whether the first MVP supports only metric units.
4. Decide which drone profiles ship by default.
5. Decide if free users get recommendations or only current status.

## Next implementation step

Create a Flutter prototype with local mock data using these rules:

- `FlightReadinessStatus`
- `FlightRuleResult`
- `DroneProfile`
- `MissionProfile`
- `FlightWindowRecommendation`

The first screen should render the mocked decision, reason list, and top flight window before connecting real APIs.

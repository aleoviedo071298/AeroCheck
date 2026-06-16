# Spec: Weather Provider MVP

## Assumptions

1. The first real weather provider will be Open-Meteo.
2. The first real integration will use a fixed/manual location before requesting GPS permissions.
3. Mock scenarios must remain available for UI QA.
4. The app must keep weather-provider code behind a repository interface.
5. The first provider integration must not include maps, auth, subscriptions, NOTAM, or official no-fly zones.

If any assumption changes, update this spec before implementation.

## Objective

Connect AeroCheck to a real weather forecast source while preserving the current mock-data workflow.

The first useful outcome:

> The user can switch the `Estado` screen from mock data to real Open-Meteo data for a fixed location, and AeroCheck evaluates that real data using the existing `FlightReadinessEvaluator`.

## Source Verification

Open-Meteo is suitable for this MVP because its official docs currently state:

- Forecast API endpoint: `https://api.open-meteo.com/v1/forecast`
- Inputs include `latitude` and `longitude`.
- Output can include `current`, `hourly`, and `daily` JSON sections.
- `forecast_days` supports up to 16 days.
- `timezone=auto` resolves local timestamps.
- Non-commercial use does not require an API key.
- Data is served via simple HTTP GET JSON responses.

Sources:

- [Open-Meteo Weather Forecast API docs](https://open-meteo.com/en/docs)
- [Open-Meteo home/features page](https://open-meteo.com/)

## Non-Goals

Do not build these in this milestone:

- GPS permission flow.
- Geocoding/search UI.
- User accounts.
- Favorites persistence.
- Map provider integration.
- Airspace, NOTAM, TFR, or legal flight authorization logic.
- Push alerts.
- Paid/commercial Open-Meteo subscription setup.
- Multiple weather providers.
- Background refresh.

## Current Data Gap

Open-Meteo provides strong MVP fields for AeroCheck:

- Temperature.
- Dew point.
- Wind speed.
- Wind direction.
- Wind speed at 80/120/180 m for wind-profile approximation.
- Gusts at 10 m.
- Precipitation probability.
- Precipitation amount.
- Cloud cover.
- Visibility.
- Day/night.

But it does **not** provide direct cloud-base altitude in the standard forecast variables selected for this MVP. For now:

- `WeatherSnapshot.cloudBaseMeters` should be `null` for real provider data.
- The evaluator already handles missing optional cloud-base data by skipping that specific rule.
- UI should show `-` or `No disponible` instead of inventing cloud-base values.

## Provider Request

Initial fixed location:

```text
Comodoro Rivadavia, Chubut
lat: -45.8641
lng: -67.4966
timezone: auto
```

Initial endpoint:

```text
https://api.open-meteo.com/v1/forecast
```

Initial query:

```text
latitude=-45.8641
longitude=-67.4966
timezone=auto
forecast_days=2
current=temperature_2m,relative_humidity_2m,dew_point_2m,is_day,precipitation,rain,weather_code,cloud_cover,wind_speed_10m,wind_direction_10m,wind_gusts_10m
hourly=temperature_2m,dew_point_2m,precipitation_probability,precipitation,cloud_cover,visibility,wind_speed_10m,wind_speed_80m,wind_speed_120m,wind_speed_180m,wind_direction_10m,wind_direction_80m,wind_direction_120m,wind_direction_180m,wind_gusts_10m,is_day
wind_speed_unit=kmh
temperature_unit=celsius
precipitation_unit=mm
```

Example full URL:

```text
https://api.open-meteo.com/v1/forecast?latitude=-45.8641&longitude=-67.4966&timezone=auto&forecast_days=2&current=temperature_2m,relative_humidity_2m,dew_point_2m,is_day,precipitation,rain,weather_code,cloud_cover,wind_speed_10m,wind_direction_10m,wind_gusts_10m&hourly=temperature_2m,dew_point_2m,precipitation_probability,precipitation,cloud_cover,visibility,wind_speed_10m,wind_speed_80m,wind_speed_120m,wind_speed_180m,wind_direction_10m,wind_direction_80m,wind_direction_120m,wind_direction_180m,wind_gusts_10m,is_day&wind_speed_unit=kmh&temperature_unit=celsius&precipitation_unit=mm
```

## Data Mapping

### `WeatherSnapshot`

| AeroCheck field | Open-Meteo source | Notes |
| --- | --- | --- |
| `time` | `current.time` | Parse local timestamp from `timezone=auto`. |
| `locationLabel` | fixed app label | `Comodoro Rivadavia, Chubut` for MVP. |
| `temperatureC` | `current.temperature_2m` | Celsius. |
| `dewPointC` | `current.dew_point_2m` | Celsius. |
| `windKmh` | `current.wind_speed_10m` | Ground/reference wind. |
| `gustKmh` | `current.wind_gusts_10m` | 10 m gusts, preceding period max. |
| `windDirectionDegrees` | `current.wind_direction_10m` | Degrees. |
| `precipitationProbability` | nearest hourly `precipitation_probability` | Current section does not include probability. |
| `precipitationMmPerHour` | `current.precipitation` | If unavailable, use nearest hourly `precipitation`. |
| `cloudCoverPercent` | `current.cloud_cover` | Percent. |
| `cloudBaseMeters` | none | Set `null`. |
| `visibilityKm` | nearest hourly `visibility / 1000` | Open-Meteo visibility is meters. |
| `kpIndex` | none | Set `null` until a geomagnetic provider is added. |
| `isDaylight` | `current.is_day == 1` | Boolean. |
| `isInsideRestrictedArea` | none | `false` until regulatory provider exists. |
| `isNearRestrictedArea` | none | `false` until regulatory provider exists. |

### Forecast Rows

Map each hourly entry to the current `ForecastRow` shape:

| Forecast row field | Open-Meteo source |
| --- | --- |
| `hour` | `hourly.time[index]` formatted `HH:mm` |
| `status` | Evaluate hourly snapshot with `FlightReadinessEvaluator` |
| `windKmh` | `hourly.wind_speed_10m[index]` |
| `gustKmh` | `hourly.wind_gusts_10m[index]` |
| `rainPercent` | `hourly.precipitation_probability[index]` |
| `visibilityKm` | `hourly.visibility[index] / 1000` |

### Wind Profile Rows

Use available Open-Meteo wind-height fields:

| AeroCheck altitude | Open-Meteo source |
| --- | --- |
| `10 m` | `wind_speed_10m`, `wind_direction_10m`, `wind_gusts_10m` |
| `80 m` | `wind_speed_80m`, `wind_direction_80m`, gust unavailable |
| `120 m` | `wind_speed_120m`, `wind_direction_120m`, gust unavailable |
| `180 m` | `wind_speed_180m`, `wind_direction_180m`, gust unavailable |

For heights without gusts:

- Display `-` for gust.
- Do not invent gust values.
- Keep the evaluator's main gust rule based on `wind_gusts_10m`.

## Architecture

Add a provider boundary:

```text
lib/data/weather/
  weather_repository.dart
  open_meteo_weather_repository.dart
  weather_repository_exception.dart
  dto/
    open_meteo_forecast_response.dart
```

Recommended interface:

```dart
abstract class WeatherRepository {
  Future<WeatherBundle> fetchWeather({
    required double latitude,
    required double longitude,
    required String locationLabel,
  });
}
```

`WeatherBundle` should contain:

- `WeatherSnapshot current`.
- `List<WeatherSnapshot> hourlySnapshots`.
- `List<WindProfileRow> windProfileRows`.
- Raw provider metadata if needed later:
  - provider name.
  - timezone.
  - utc offset.
  - generation time.

## UI Changes

Add a data-source control on `Estado`:

```text
Mock | Clima real
```

Behavior:

- Default remains `Mock` until real fetch is stable.
- In `Mock`, keep the scenario selector: `APTO / PRECAUCION / NO APTO`.
- In `Clima real`, hide scenario selector and fetch Open-Meteo for Comodoro Rivadavia.
- Show loading state.
- Show error state with retry.
- If real data is incomplete, the evaluator must not produce false confidence.

Suggested copy:

```text
Clima real
Comodoro Rivadavia - Open-Meteo
```

Error copy:

```text
No se pudo obtener clima real. Reintentar o volver a datos mock.
```

## Testing Strategy

### Unit Tests

Add tests for:

- Open-Meteo JSON parsing into DTO.
- Mapping DTO to `WeatherSnapshot`.
- Visibility conversion meters to km.
- Missing optional cloud base maps to `null`.
- Missing critical fields throw or return a controlled repository error.
- Hourly row conversion.

### Repository Tests

Do not hit the real network in unit tests.

Use a fake HTTP client or an injected fetch function that returns fixture JSON.

### Widget Tests

Add tests for:

- `Estado` starts in mock mode.
- Switching to real mode shows loading.
- Successful real mode renders provider label and evaluated status.
- Failed real mode shows retry/error copy.

## Dependencies

Preferred first implementation:

- Use Dart/Flutter standard `HttpClient` or `package:http` if added deliberately.

If adding `package:http`, update:

- `pubspec.yaml`
- this spec if the API shape changes.
- tests to inject a mockable client.

Ask before adding heavier networking/state-management dependencies.

## Implementation Tasks

- [ ] Add repository interface and weather bundle model.
  - Acceptance: domain/UI no longer depends on provider-specific JSON.
  - Verify: `flutter analyze`.

- [ ] Add Open-Meteo DTO/parser with fixture tests.
  - Acceptance: fixture JSON maps to typed values.
  - Verify: `flutter test test/data/weather`.

- [ ] Add Open-Meteo repository.
  - Acceptance: fetches fixed Comodoro Rivadavia data and maps current/hourly fields.
  - Verify: repository tests use fake response; optional manual run can hit real API.

- [ ] Add data-source selector to `Estado`.
  - Acceptance: mock mode remains current behavior; real mode fetches and evaluates data.
  - Verify: widget tests and manual emulator run.

- [ ] Update `Forecast` and `Wind` screens to read the selected data source if practical.
  - Acceptance: at minimum, `Estado` uses real data; secondary tabs may remain mock if scope gets too large.
  - Verify: `flutter test`, `flutter analyze`, manual run.

## Success Criteria

This milestone is done when:

- App still runs with mock data.
- User can switch to real Open-Meteo weather for Comodoro Rivadavia.
- Real current weather maps into `WeatherSnapshot`.
- Existing evaluator produces a status from real data.
- Missing cloud base and Kp do not crash the UI.
- Errors are visible and recoverable.
- `flutter test` passes.
- `flutter analyze` passes.

## Open Questions

1. Should real mode become the default once stable, or remain opt-in until location permissions exist?
2. Should we add `package:http` now, or use `dart:io`/Flutter built-ins for the first pass?
3. Do we want one fixed location only, or a small hardcoded location picker?
4. Should Kp be integrated immediately after weather, or after real location/GPS?
5. Should cloud base be estimated later from humidity/cloud layers, or only shown when a provider gives it directly?

## Recommended Answers for MVP

- Keep mock mode as default for now.
- Use `package:http` only if it keeps tests cleaner.
- Use one fixed location first.
- Add Kp later as a separate provider.
- Do not estimate cloud base in MVP.

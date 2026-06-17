# Spec: Fix Real Data (Kp Index & Temporal Synchronization)

## Objective

Fix the NOAA Kp geomagnetic index integration and ensure the `Estado`, `Forecast`, and `Viento` screens display actual, synchronized real-time data instead of stale/midnight values or empty results.

## Key Changes

1. **NOAA Kp Index Service Deserialization**
   - The NOAA SWPC API returns a JSON list of objects (ordered chronologically), not a single JSON object.
   - Update `NoaaKpIndexService.fetchCurrentKpIndex` to decode the response as a list, fetch the last (most recent) element, and parse the `Kp` number.
   - Add unit tests validating this behavior against the real API response structure.

2. **Temporal Synchronization for Wind Profile**
   - Currently, `OpenMeteoForecastResponse._windProfileRows()` extracts wind data from the first hour (index 0, usually midnight).
   - Find the index of the hourly forecast snapshot closest to the current weather time (`current.time`).
   - Construct the wind profile using that nearest hour's index.

3. **Temporal Filtering for Forecast Screen**
   - Filter `hourlySnapshots` in `WeatherSession.forecastRows` to only return the current and future hours (discarding past hours).
   - Show the next 12 hours starting from the current hour.

4. **Future-Only Best Window Recommendation**
   - Update `WeatherSession.bestWindowFor` to accept an optional `referenceTime` (falling back to `DateTime.now()`).
   - Discard snapshots before the current hour of the `referenceTime` to ensure AeroCheck does not recommend a flight window in the past.

5. **Proper Support for Mock Data Source**
   - In `WeatherSession`, ensure that `currentReport`, `forecastRows`, and `windProfileRows` return mock data when `_dataSource == WeatherDataSource.mock`.

## Project Structure & Key Files

- [noaa_kp_index_service.dart](file:///c:/Users/Alejandro/Desktop/local/dron/lib/data/kp_index/noaa_kp_index_service.dart) - NOAA API fetch and parse.
- [open_meteo_forecast_response.dart](file:///c:/Users/Alejandro/Desktop/local/dron/lib/data/weather/dto/open_meteo_forecast_response.dart) - Open-Meteo DTO parsing.
- [weather_session.dart](file:///c:/Users/Alejandro/Desktop/local/dron/lib/app/weather_session.dart) - Weather state management.
- [noaa_kp_index_service_test.dart](file:///c:/Users/Alejandro/Desktop/local/dron/test/data/kp_index/noaa_kp_index_service_test.dart) - Unit tests for Kp index.
- [weather_session_test.dart](file:///c:/Users/Alejandro/Desktop/local/dron/test/app/weather_session_test.dart) - Weather session tests.

## Boundaries & Constraints

- Do not change the flight readiness decision rules themselves.
- Keep NOAA and Open-Meteo logic decoupled and isolated behind repositories.
- Do not introduce new third-party packages.

## Testing Strategy

1. **Unit Tests**:
   - Test JSON list parsing in `NoaaKpIndexService` using a mock client / fixture JSON.
   - Test wind profile extraction for the correct hour in `OpenMeteoForecastResponse`.
   - Test future-only filtering of forecast rows and best window recommendation in `WeatherSession`.
2. **Integration Verification**:
   - Run `flutter test` and `flutter analyze` to ensure all checks pass.

# Unified Metric Cards Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give Estado and Forecast the same 10-card badge-style metric grid (current weather in Estado, selected forecast hour in Forecast), add real metrics (pressure, sky condition, UV, per-hour humidity, real apparent temperature), order by flight priority, and change the Forecast tip to "Mejor hora: HH:MM".

**Architecture:** Add the new fields to the Open-Meteo request, `WeatherSnapshot`, the DTO, and `ForecastRow`. A pure helper maps `weather_code` to a condition (label key + icon). Estado's private `_MetricCard` becomes a shared `MetricCard`; Estado's grid and a new `ForecastMetricsGrid` both use it.

**Tech Stack:** Flutter, Dart, existing `WeatherSession`/`WeatherSnapshot`/`ForecastRow`/`UnitFormatters`/`AppStrings`. No new dependencies.

## Global Constraints

- No change to the decision engine, `FlightRulesConfig`, or `bestWindowFor`. New metrics are informational.
- New `WeatherSnapshot`/`ForecastRow` fields are nullable/optional so existing constructions compile.
- All values display via `UnitFormatters`; all strings via `AppStrings.get(key, language:)`; new keys in both `es` and `en`.
- Card order (both screens, 5 rows × 2): Viento·Ráfagas / Precipitación·Visibilidad / Nubosidad·Condición / Temperatura·Humedad / Presión·(UV Forecast | Kp Estado).
- Missing values render `—` via `AppStrings.get('sin_dato')`.
- Run before commit: `dart format lib test`, `flutter test`, `flutter analyze`. End every commit message with: `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.

---

### Task 1: Data — new weather fields

**Files:**
- Modify: `lib/data/weather/open_meteo_weather_repository.dart`
- Modify: `lib/domain/entities/weather_snapshot.dart`
- Modify: `lib/data/weather/dto/open_meteo_forecast_response.dart`
- Modify: `lib/data/mock/mock_flight_data.dart` (`ForecastRow`)
- Modify: `lib/app/weather_session.dart` (`_forecastRowFor`)
- Test: `test/data/weather/open_meteo_metrics_test.dart` (create)

**Interfaces:**
- Produces: `WeatherSnapshot.apparentTemperatureC/pressureHpa/uvIndex` (`double?`), `WeatherSnapshot.weatherCode` (`int?`); `ForecastRow.relativeHumidityPercent/apparentTemperatureC/pressureHpa/uvIndex` (`double?`), `ForecastRow.weatherCode` (`int?`).

- [ ] **Step 1: Write the failing test**

```dart
// test/data/weather/open_meteo_metrics_test.dart
import 'package:aerocheck/data/weather/dto/open_meteo_forecast_response.dart';
import 'package:flutter_test/flutter_test.dart';

const _json = '''
{
 "timezone":"UTC","utc_offset_seconds":0,
 "current":{"time":"2026-06-16T13:00","temperature_2m":16,"apparent_temperature":14,
   "relative_humidity_2m":70,"pressure_msl":1013,"uv_index":4,"weather_code":3,"is_day":1},
 "hourly":{"time":["2026-06-16T13:00"],"temperature_2m":[16],"apparent_temperature":[14],
   "relative_humidity_2m":[70],"pressure_msl":[1012],"uv_index":[5],"weather_code":[61]}
}''';

void main() {
  test('parses pressure, uv, weather_code, apparent temp and hourly humidity', () {
    final bundle = OpenMeteoForecastResponse.fromJsonString(
      _json,
    ).toWeatherBundle(locationLabel: 'x');
    expect(bundle.current.pressureHpa, 1013);
    expect(bundle.current.uvIndex, 4);
    expect(bundle.current.weatherCode, 3);
    expect(bundle.current.apparentTemperatureC, 14);
    final h = bundle.hourlySnapshots.first;
    expect(h.relativeHumidityPercent, 70);
    expect(h.pressureHpa, 1012);
    expect(h.uvIndex, 5);
    expect(h.weatherCode, 61);
    expect(h.apparentTemperatureC, 14);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/weather/open_meteo_metrics_test.dart`
Expected: FAIL — `pressureHpa`/`uvIndex`/`weatherCode`/`apparentTemperatureC` don't exist.

- [ ] **Step 3: Add fields to `WeatherSnapshot`**

In `lib/domain/entities/weather_snapshot.dart`: add to the constructor (after
`this.relativeHumidityPercent,`):

```dart
    this.apparentTemperatureC,
    this.pressureHpa,
    this.uvIndex,
    this.weatherCode,
```
add the fields (after `final double? relativeHumidityPercent;`):

```dart
  final double? apparentTemperatureC;
  final double? pressureHpa;
  final double? uvIndex;
  final int? weatherCode;
```
and in `copyWith` add the params (after `double? relativeHumidityPercent,`):

```dart
    double? apparentTemperatureC,
    double? pressureHpa,
    double? uvIndex,
    int? weatherCode,
```
and in the returned object (after `relativeHumidityPercent: relativeHumidityPercent ?? this.relativeHumidityPercent,`):

```dart
      apparentTemperatureC: apparentTemperatureC ?? this.apparentTemperatureC,
      pressureHpa: pressureHpa ?? this.pressureHpa,
      uvIndex: uvIndex ?? this.uvIndex,
      weatherCode: weatherCode ?? this.weatherCode,
```

- [ ] **Step 4: Populate in the DTO**

In `lib/data/weather/dto/open_meteo_forecast_response.dart`:
- In `_currentSnapshot`, add to the returned `WeatherSnapshot` (after
  `relativeHumidityPercent: _optionalDouble(current, 'relative_humidity_2m'),`):
  ```dart
        apparentTemperatureC: _optionalDouble(current, 'apparent_temperature'),
        pressureHpa: _optionalDouble(current, 'pressure_msl'),
        uvIndex: _optionalDouble(current, 'uv_index'),
        weatherCode: _optionalInt(current, 'weather_code'),
  ```
- In `_hourlySnapshots`, change `relativeHumidityPercent: null,` to:
  ```dart
          relativeHumidityPercent: _optionalDoubleAt(hourly, 'relative_humidity_2m', index),
  ```
  and add after it:
  ```dart
          apparentTemperatureC: _optionalDoubleAt(hourly, 'apparent_temperature', index),
          pressureHpa: _optionalDoubleAt(hourly, 'pressure_msl', index),
          uvIndex: _optionalDoubleAt(hourly, 'uv_index', index),
          weatherCode: _optionalIntAt(hourly, 'weather_code', index),
  ```

- [ ] **Step 5: Add the request params**

In `lib/data/weather/open_meteo_weather_repository.dart`:
- In the `current` list, add `'apparent_temperature'`, `'pressure_msl'`, `'uv_index'`.
- In the `hourly` list, add `'relative_humidity_2m'`, `'apparent_temperature'`, `'pressure_msl'`, `'weather_code'`, `'uv_index'`.

- [ ] **Step 6: Add fields to `ForecastRow` + populate**

In `lib/data/mock/mock_flight_data.dart`, `ForecastRow` constructor add (after
`this.dewPointC,`):

```dart
    this.relativeHumidityPercent,
    this.apparentTemperatureC,
    this.pressureHpa,
    this.uvIndex,
    this.weatherCode,
```
and fields (after `final double? dewPointC;`):

```dart
  final double? relativeHumidityPercent;
  final double? apparentTemperatureC;
  final double? pressureHpa;
  final double? uvIndex;
  final int? weatherCode;
```
In `lib/app/weather_session.dart`, `_forecastRowFor`, add to the `ForecastRow(...)`
(after `dewPointC: weather.dewPointC,`):

```dart
      relativeHumidityPercent: weather.relativeHumidityPercent,
      apparentTemperatureC: weather.apparentTemperatureC,
      pressureHpa: weather.pressureHpa,
      uvIndex: weather.uvIndex,
      weatherCode: weather.weatherCode,
```

- [ ] **Step 7: Run tests + analyze + full suite**

Run: `flutter test test/data/weather/open_meteo_metrics_test.dart && flutter test && flutter analyze`
Expected: new test PASS; full suite green (1 pre-existing skip); analyzer clean.

- [ ] **Step 8: Commit**

```bash
git add lib/data/weather/open_meteo_weather_repository.dart lib/domain/entities/weather_snapshot.dart lib/data/weather/dto/open_meteo_forecast_response.dart lib/data/mock/mock_flight_data.dart lib/app/weather_session.dart test/data/weather/open_meteo_metrics_test.dart
git commit -m "feat: fetch pressure, uv, weather code, apparent temp and hourly humidity"
```

---

### Task 2: Sky-condition helper + i18n keys

**Files:**
- Create: `lib/features/shared/weather_condition.dart`
- Modify: `lib/domain/i18n/app_strings.dart`
- Test: `test/features/shared/weather_condition_test.dart` (create)

**Interfaces:**
- Produces: `class WeatherCondition { final String labelKey; final IconData icon; }` and `WeatherCondition weatherConditionFor(int? code)`.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/shared/weather_condition_test.dart
import 'package:aerocheck/features/shared/weather_condition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps WMO codes to condition label keys', () {
    expect(weatherConditionFor(0).labelKey, 'cielo_despejado');
    expect(weatherConditionFor(2).labelKey, 'cielo_parcial');
    expect(weatherConditionFor(3).labelKey, 'cielo_nublado');
    expect(weatherConditionFor(45).labelKey, 'cielo_niebla');
    expect(weatherConditionFor(53).labelKey, 'cielo_llovizna');
    expect(weatherConditionFor(61).labelKey, 'cielo_lluvia');
    expect(weatherConditionFor(73).labelKey, 'cielo_nieve');
    expect(weatherConditionFor(95).labelKey, 'cielo_tormenta');
    expect(weatherConditionFor(null).labelKey, 'sin_dato');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/shared/weather_condition_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Implement the helper**

```dart
// lib/features/shared/weather_condition.dart
import 'package:flutter/material.dart';

class WeatherCondition {
  const WeatherCondition({required this.labelKey, required this.icon});

  final String labelKey;
  final IconData icon;
}

WeatherCondition weatherConditionFor(int? code) {
  if (code == null) {
    return const WeatherCondition(
      labelKey: 'sin_dato',
      icon: Icons.help_outline_rounded,
    );
  }
  if (code == 0 || code == 1) {
    return const WeatherCondition(
      labelKey: 'cielo_despejado',
      icon: Icons.wb_sunny_rounded,
    );
  }
  if (code == 2) {
    return const WeatherCondition(
      labelKey: 'cielo_parcial',
      icon: Icons.partly_cloudy_day_rounded,
    );
  }
  if (code == 3) {
    return const WeatherCondition(
      labelKey: 'cielo_nublado',
      icon: Icons.cloud_rounded,
    );
  }
  if (code == 45 || code == 48) {
    return const WeatherCondition(
      labelKey: 'cielo_niebla',
      icon: Icons.foggy,
    );
  }
  if (code >= 51 && code <= 57) {
    return const WeatherCondition(
      labelKey: 'cielo_llovizna',
      icon: Icons.grain_rounded,
    );
  }
  if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82)) {
    return const WeatherCondition(
      labelKey: 'cielo_lluvia',
      icon: Icons.water_drop_rounded,
    );
  }
  if ((code >= 71 && code <= 77) || code == 85 || code == 86) {
    return const WeatherCondition(
      labelKey: 'cielo_nieve',
      icon: Icons.ac_unit_rounded,
    );
  }
  if (code >= 95 && code <= 99) {
    return const WeatherCondition(
      labelKey: 'cielo_tormenta',
      icon: Icons.thunderstorm_rounded,
    );
  }
  return const WeatherCondition(
    labelKey: 'sin_dato',
    icon: Icons.help_outline_rounded,
  );
}
```

- [ ] **Step 4: Add i18n keys**

In `lib/domain/i18n/app_strings.dart`, add to BOTH maps:
```dart
// es
'condicion': 'Condición',
'indice_uv': 'Índice UV',
'cielo_despejado': 'Despejado',
'cielo_parcial': 'Parcial',
'cielo_nublado': 'Nublado',
'cielo_niebla': 'Niebla',
'cielo_llovizna': 'Llovizna',
'cielo_lluvia': 'Lluvia',
'cielo_nieve': 'Nieve',
'cielo_tormenta': 'Tormenta',
```
```dart
// en
'condicion': 'Condition',
'indice_uv': 'UV index',
'cielo_despejado': 'Clear',
'cielo_parcial': 'Partly cloudy',
'cielo_nublado': 'Cloudy',
'cielo_niebla': 'Fog',
'cielo_llovizna': 'Drizzle',
'cielo_lluvia': 'Rain',
'cielo_nieve': 'Snow',
'cielo_tormenta': 'Thunderstorm',
```

- [ ] **Step 5: Run test + analyze**

Run: `flutter test test/features/shared/weather_condition_test.dart && flutter analyze`
Expected: PASS, analyzer clean.

- [ ] **Step 6: Commit**

```bash
git add lib/features/shared/weather_condition.dart lib/domain/i18n/app_strings.dart test/features/shared/weather_condition_test.dart
git commit -m "feat: add WMO weather-code condition helper and i18n keys"
```

---

### Task 3: Extract shared `MetricCard`

**Files:**
- Create: `lib/features/shared/widgets/metric_card.dart`
- Modify: `lib/features/conditions/conditions_screen.dart` (use the shared card)
- Test: `test/features/shared/metric_card_test.dart` (create)

**Interfaces:**
- Produces: `MetricCard({required String label, required String value, required String subValue, required IconData icon, required Color accentColor})` — identical look to Estado's current `_MetricCard`.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/shared/metric_card_test.dart
import 'package:aerocheck/features/shared/widgets/metric_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders label, value and sub-value', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MetricCard(
            label: 'VIENTO',
            value: '14 km/h',
            subValue: '↗ NO 274°',
            icon: Icons.air_rounded,
            accentColor: Color(0xFF0EA5E9),
          ),
        ),
      ),
    );
    expect(find.text('VIENTO'), findsOneWidget);
    expect(find.text('14 km/h'), findsOneWidget);
    expect(find.text('↗ NO 274°'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/shared/metric_card_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Create `MetricCard`**

Copy the body of the current private `_MetricCard` (in `conditions_screen.dart`)
into a public widget:

```dart
// lib/features/shared/widgets/metric_card.dart
import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.subValue,
    required this.icon,
    required this.accentColor,
  });

  final String label;
  final String value;
  final String subValue;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 4,
              child: Container(color: accentColor),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subValue,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Repoint Estado to the shared card**

In `lib/features/conditions/conditions_screen.dart`: add
`import '../shared/widgets/metric_card.dart';`, replace every `_MetricCard(`
with `MetricCard(`, and DELETE the private `class _MetricCard`.

- [ ] **Step 5: Run tests + analyze + full suite**

Run: `flutter test test/features/shared/metric_card_test.dart && flutter test && flutter analyze`
Expected: PASS, analyzer clean (Estado renders unchanged).

- [ ] **Step 6: Commit**

```bash
git add lib/features/shared/widgets/metric_card.dart lib/features/conditions/conditions_screen.dart test/features/shared/metric_card_test.dart
git commit -m "refactor: extract shared MetricCard widget"
```

---

### Task 4: Re-lay-out the Estado grid (10 cards, new order)

**Files:**
- Modify: `lib/features/conditions/conditions_screen.dart` (`_ReworkedMetricsGrid`)
- Test: `test/features/conditions/conditions_screen_test.dart` (add/adjust)

**Interfaces:**
- Consumes: `MetricCard` (Task 3), `weatherConditionFor` (Task 2), `WeatherSnapshot` new fields (Task 1).

- [ ] **Step 1: Add a render test**

Append to `test/features/conditions/conditions_screen_test.dart` a test asserting
the new cards render. Use the existing test setup in that file (a `WeatherSession`
with a fake repository); if none exists, mirror the pattern from
`test/features/forecast/forecast_screen_test.dart`. The assertion:

```dart
    expect(find.text('PRESIÓN'), findsOneWidget);
    expect(find.text('CONDICIÓN'), findsOneWidget);
```
(Place these after pumping the Conditions screen with loaded real weather.)

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/conditions/conditions_screen_test.dart`
Expected: FAIL — no PRESIÓN/CONDICIÓN cards yet.

- [ ] **Step 3: Rebuild the grid in the new order**

In `_ReworkedMetricsGrid.build`, replace the two `GridView`s with one 10-card
`GridView` in the priority order, using `MetricCard`. Add
`import '../shared/weather_condition.dart';`. Compute the condition and
apparent-temp sensation:

```dart
    final units = session.preferences.units;
    final condition = weatherConditionFor(weather.weatherCode);

    String dewPointStr = AppStrings.get('sin_dato');
    if (weather.dewPointC != null) {
      dewPointStr = UnitFormatters.formatTemperature(weather.dewPointC, units);
    } else if (weather.temperatureC != null &&
        weather.relativeHumidityPercent != null) {
      final dp = weather.temperatureC! -
          ((100 - weather.relativeHumidityPercent!) / 5.0);
      dewPointStr = UnitFormatters.formatTemperature(dp, units);
    }

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      children: [
        MetricCard(
          label: AppStrings.get('viento').toUpperCase(),
          value: UnitFormatters.formatSpeed(weather.windKmh, units),
          subValue:
              '↗ ${weather.windDirectionCardinal ?? ""} ${_fmt(weather.windDirectionDegrees)}°',
          icon: Icons.air_rounded,
          accentColor: const Color(0xFF0EA5E9),
        ),
        MetricCard(
          label: AppStrings.get('rafagas').toUpperCase(),
          value: UnitFormatters.formatSpeed(weather.gustKmh, units),
          subValue: _formatGustDelta(weather, session),
          icon: Icons.wind_power_rounded,
          accentColor: const Color(0xFFD97706),
        ),
        MetricCard(
          label: AppStrings.get('precip').toUpperCase(),
          value: weather.precipitationProbability == null
              ? '0%'
              : '${_fmt(weather.precipitationProbability!)}%',
          subValue:
              weather.precipitationMmPerHour != null &&
                  weather.precipitationMmPerHour! > 0
              ? '${_fmt(weather.precipitationMmPerHour!)} mm/h'
              : AppStrings.get('sin_lluvia'),
          icon: Icons.water_drop_rounded,
          accentColor: const Color(0xFF06B6D4),
        ),
        MetricCard(
          label: AppStrings.get('visibilidad').toUpperCase(),
          value: weather.visibilityKm == null
              ? AppStrings.get('sin_dato')
              : UnitFormatters.formatDistance(weather.visibilityKm, units),
          subValue: '',
          icon: Icons.visibility_rounded,
          accentColor: const Color(0xFF10B981),
        ),
        MetricCard(
          label: AppStrings.get('nubosidad').toUpperCase(),
          value: weather.cloudCoverPercent == null
              ? AppStrings.get('sin_dato')
              : '${_cloudCoverFraction(weather.cloudCoverPercent!)} (${_fmt(weather.cloudCoverPercent!)}%)',
          subValue: weather.cloudBaseMeters != null
              ? 'Base: ${UnitFormatters.formatAltitude(weather.cloudBaseMeters, units, decimals: 0)}'
              : '',
          icon: Icons.cloud_rounded,
          accentColor: const Color(0xFF14B8A6),
        ),
        MetricCard(
          label: AppStrings.get('condicion').toUpperCase(),
          value: AppStrings.get(condition.labelKey),
          subValue: '',
          icon: condition.icon,
          accentColor: const Color(0xFFF59E0B),
        ),
        MetricCard(
          label: AppStrings.get('temp').toUpperCase(),
          value: UnitFormatters.formatTemperature(weather.temperatureC, units),
          subValue: _formatSensation(weather, session),
          icon: Icons.device_thermostat_rounded,
          accentColor: const Color(0xFF3B82F6),
        ),
        MetricCard(
          label: AppStrings.get('humedad').toUpperCase(),
          value: weather.relativeHumidityPercent == null
              ? AppStrings.get('sin_dato')
              : UnitFormatters.formatPercentage(weather.relativeHumidityPercent),
          subValue: '${AppStrings.get('punto_rocio')} $dewPointStr',
          icon: Icons.opacity_rounded,
          accentColor: const Color(0xFF6366F1),
        ),
        MetricCard(
          label: AppStrings.get('presion').toUpperCase(),
          value: weather.pressureHpa == null
              ? AppStrings.get('sin_dato')
              : UnitFormatters.formatPressure(weather.pressureHpa, units),
          subValue: '',
          icon: Icons.speed_rounded,
          accentColor: const Color(0xFF64748B),
        ),
        MetricCard(
          label: AppStrings.get('indice_kp').toUpperCase(),
          value: weather.kpIndex == null
              ? AppStrings.get('sin_dato')
              : _fmt(weather.kpIndex!),
          subValue: '',
          icon: Icons.sensors_rounded,
          accentColor: const Color(0xFF8B5CF6),
        ),
      ],
    );
```
Update `_formatSensation` to prefer the real apparent temperature:

```dart
  String _formatSensation(WeatherSnapshot weather, WeatherSession session) {
    final sensation = weather.apparentTemperatureC ??
        (weather.temperatureC != null ? weather.temperatureC! - 2.0 : null);
    if (sensation != null) {
      return '${AppStrings.get('sensacion')} ${UnitFormatters.formatTemperature(sensation, session.preferences.units)}';
    }
    return AppStrings.get('sin_dato');
  }
```
(Keep `_cloudCoverFraction`, `_formatGustDelta`, and the file's `_fmt` helper.)

- [ ] **Step 4: Run tests + analyze + full suite**

Run: `flutter test test/features/conditions/ && flutter test && flutter analyze`
Expected: PASS, analyzer clean. If an existing Estado test asserted old card text/order, update it.

- [ ] **Step 5: Commit**

```bash
git add lib/features/conditions/conditions_screen.dart test/features/conditions/conditions_screen_test.dart
git commit -m "feat: Estado 10-card grid with pressure and sky condition, priority order"
```

---

### Task 5: Forecast metrics grid + screen wiring

**Files:**
- Create: `lib/features/forecast/widgets/forecast_metrics_grid.dart`
- Modify: `lib/features/forecast/widgets/focused_hour_card.dart` (strip metrics)
- Modify: `lib/features/forecast/forecast_screen.dart` (use the grid; new order)
- Delete: `lib/features/forecast/widgets/conditions_metrics_card.dart`, `lib/features/forecast/widgets/metric_tile.dart`
- Test: `test/features/forecast/forecast_metrics_grid_test.dart` (create); adjust `test/features/forecast/forecast_screen_test.dart`

**Interfaces:**
- Consumes: `MetricCard` (Task 3), `weatherConditionFor` (Task 2), `ForecastRow` new fields (Task 1).
- Produces: `ForecastMetricsGrid({required ForecastRow row, required UnitPreferences units, required Language language})`.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/forecast/forecast_metrics_grid_test.dart
import 'package:aerocheck/data/mock/mock_flight_data.dart';
import 'package:aerocheck/domain/i18n/language.dart';
import 'package:aerocheck/domain/rules/flight_readiness_status.dart';
import 'package:aerocheck/domain/units/unit_preferences.dart';
import 'package:aerocheck/features/forecast/widgets/forecast_metrics_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the 10 forecast metric cards incl. UV and pressure', (
    tester,
  ) async {
    final row = ForecastRow(
      hour: '09:00',
      status: FlightReadinessStatus.ready,
      primaryReason: 'x',
      reasons: const [],
      isBestWindow: false,
      windKmh: 14,
      gustKmh: 23,
      rainPercent: 14,
      visibilityKm: 16,
      score: 90,
      windDirectionDegrees: 274,
      time: DateTime(2026, 6, 16, 9),
      temperatureC: 11,
      cloudCoverPercent: 73,
      precipitationMmPerHour: 0,
      dewPointC: 3,
      relativeHumidityPercent: 73,
      apparentTemperatureC: 9,
      pressureHpa: 1013,
      uvIndex: 4,
      weatherCode: 0,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ForecastMetricsGrid(
              row: row,
              units: const UnitPreferences(),
              language: Language.es,
            ),
          ),
        ),
      ),
    );
    expect(find.text('PRESIÓN'), findsOneWidget);
    expect(find.text('ÍNDICE UV'), findsOneWidget);
    expect(find.text('CONDICIÓN'), findsOneWidget);
    expect(find.text('KP'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/forecast/forecast_metrics_grid_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Implement `ForecastMetricsGrid`**

```dart
// lib/features/forecast/widgets/forecast_metrics_grid.dart
import 'package:flutter/material.dart';

import '../../../data/mock/mock_flight_data.dart';
import '../../../domain/i18n/app_strings.dart';
import '../../../domain/i18n/language.dart';
import '../../../domain/units/unit_formatters.dart';
import '../../../domain/units/unit_preferences.dart';
import '../../shared/weather_condition.dart';
import '../../shared/widgets/metric_card.dart';

class ForecastMetricsGrid extends StatelessWidget {
  const ForecastMetricsGrid({
    super.key,
    required this.row,
    required this.units,
    required this.language,
  });

  final ForecastRow row;
  final UnitPreferences units;
  final Language language;

  String _t(String k) => AppStrings.get(k, language: language);
  String _none() => AppStrings.get('sin_dato', language: language);

  String _fmt(num? v) {
    if (v == null) return _none();
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  String _cardinal(double? deg) {
    if (deg == null) return '';
    const dirs = ['N','NNE','NE','ENE','E','ESE','SE','SSE','S','SSO','SO','OSO','O','ONO','NO','NNO'];
    final n = (deg % 360 + 360) % 360;
    return dirs[((n + 11.25) / 22.5).floor() % 16];
  }

  @override
  Widget build(BuildContext context) {
    final condition = weatherConditionFor(row.weatherCode);
    final gustDelta = row.gustKmh - row.windKmh;
    final sensation = row.apparentTemperatureC ?? (row.temperatureC == null ? null : row.temperatureC! - 2.0);

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      children: [
        MetricCard(
          label: _t('viento').toUpperCase(),
          value: UnitFormatters.formatSpeed(row.windKmh, units, decimals: 0),
          subValue: '↗ ${_cardinal(row.windDirectionDegrees)} ${_fmt(row.windDirectionDegrees)}°',
          icon: Icons.air_rounded,
          accentColor: const Color(0xFF0EA5E9),
        ),
        MetricCard(
          label: _t('rafagas').toUpperCase(),
          value: UnitFormatters.formatSpeed(row.gustKmh, units, decimals: 0),
          subValue: gustDelta > 0
              ? 'Δ ${UnitFormatters.formatSpeed(gustDelta, units, decimals: 0)}'
              : _t('sin_rafagas'),
          icon: Icons.wind_power_rounded,
          accentColor: const Color(0xFFD97706),
        ),
        MetricCard(
          label: _t('precip').toUpperCase(),
          value: '${_fmt(row.rainPercent)}%',
          subValue: (row.precipitationMmPerHour ?? 0) > 0
              ? '${_fmt(row.precipitationMmPerHour)} mm/h'
              : _t('sin_lluvia'),
          icon: Icons.water_drop_rounded,
          accentColor: const Color(0xFF06B6D4),
        ),
        MetricCard(
          label: _t('visibilidad').toUpperCase(),
          value: UnitFormatters.formatDistance(row.visibilityKm, units, decimals: 0),
          subValue: '',
          icon: Icons.visibility_rounded,
          accentColor: const Color(0xFF10B981),
        ),
        MetricCard(
          label: _t('nubosidad').toUpperCase(),
          value: row.cloudCoverPercent == null
              ? _none()
              : '${(row.cloudCoverPercent! / 12.5).round()}/8 (${_fmt(row.cloudCoverPercent)}%)',
          subValue: '',
          icon: Icons.cloud_rounded,
          accentColor: const Color(0xFF14B8A6),
        ),
        MetricCard(
          label: _t('condicion').toUpperCase(),
          value: _t(condition.labelKey),
          subValue: '',
          icon: condition.icon,
          accentColor: const Color(0xFFF59E0B),
        ),
        MetricCard(
          label: _t('temp').toUpperCase(),
          value: UnitFormatters.formatTemperature(row.temperatureC, units, decimals: 0),
          subValue: sensation == null
              ? ''
              : '${_t('sensacion')} ${UnitFormatters.formatTemperature(sensation, units, decimals: 0)}',
          icon: Icons.device_thermostat_rounded,
          accentColor: const Color(0xFF3B82F6),
        ),
        MetricCard(
          label: _t('humedad').toUpperCase(),
          value: row.relativeHumidityPercent == null
              ? _none()
              : UnitFormatters.formatPercentage(row.relativeHumidityPercent),
          subValue: row.dewPointC == null
              ? ''
              : '${_t('punto_rocio')} ${UnitFormatters.formatTemperature(row.dewPointC, units, decimals: 0)}',
          icon: Icons.opacity_rounded,
          accentColor: const Color(0xFF6366F1),
        ),
        MetricCard(
          label: _t('presion').toUpperCase(),
          value: row.pressureHpa == null
              ? _none()
              : UnitFormatters.formatPressure(row.pressureHpa, units),
          subValue: '',
          icon: Icons.speed_rounded,
          accentColor: const Color(0xFF64748B),
        ),
        MetricCard(
          label: _t('indice_uv').toUpperCase(),
          value: _fmt(row.uvIndex),
          subValue: '',
          icon: Icons.wb_sunny_rounded,
          accentColor: const Color(0xFFF97316),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Strip the metric grid from `FocusedHourCard`**

In `lib/features/forecast/widgets/focused_hour_card.dart`: delete everything from
the `const SizedBox(height: 14),` that precedes the first `Row(children: [ MetricTile(...` (right after the reason `Text`) through the end of the two metric `Row`s — i.e. keep the header `Row` and the reason `Text`, and end the outer `Column` there. Remove the now-unused imports `metric_tile.dart`, `unit_formatters.dart`, and `dart:math` if the analyzer flags them.

- [ ] **Step 5: Wire the grid into the screen (new order) + delete old widgets**

In `lib/features/forecast/forecast_screen.dart`: add
`import 'widgets/forecast_metrics_grid.dart';` and remove
`import 'widgets/conditions_metrics_card.dart';`. In `_buildFocusedSection`, change
the returned list so the grid sits between the hero and the scrubber:

```dart
    return [
      FocusedHourCard(
        row: selectedRow,
        units: units,
        language: language,
        isBestHour: selectedRow.time == bestTime,
        dayLabel: forecastDayLabel(activeDay.date, today, language),
      ),
      const SizedBox(height: 14),
      ForecastMetricsGrid(row: selectedRow, units: units, language: language),
      const SizedBox(height: 14),
      HourScrubber(
        days: days,
        selectedDate: activeDay.date,
        selectedHour: selectedRow.time ?? activeDay.rows.first.time!,
        today: today,
        language: language,
        onHourSelected: (t) => setState(() => _selectedHour = t),
        onDaySelected: (date) => setState(() {
          _selectedDate = date;
          final day = days.firstWhere((d) => d.date == date);
          _selectedHour = day.bestHour?.time ?? day.rows.first.time;
        }),
        onGoToBest: () => setState(() {
          _selectedHour = activeDay.bestHour?.time;
        }),
        sunrise: sun?.sunrise,
        sunset: sun?.sunset,
      ),
      const SizedBox(height: 16),
      _ForecastTipCard(language: language),
    ];
```
Delete the files `conditions_metrics_card.dart` and `metric_tile.dart`:
```bash
git rm lib/features/forecast/widgets/conditions_metrics_card.dart lib/features/forecast/widgets/metric_tile.dart
```

- [ ] **Step 6: Adjust the Forecast screen test**

In `test/features/forecast/forecast_screen_test.dart`, the "conditions metrics
card" assertion (`find.text('TEMPERATURA')`) still holds — the grid renders
`TEMPERATURA`. If any test imported `conditions_metrics_card.dart` or
`metric_tile.dart` directly, remove that import/test (the dedicated grid test in
Step 1 covers the new widget).

- [ ] **Step 7: Run tests + analyze + full suite**

Run: `flutter test test/features/forecast/ && flutter test && flutter analyze`
Expected: PASS, analyzer clean (no unused imports/symbols — delete any it flags).

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat: Forecast 10-card metrics grid above the scrubber"
```

---

### Task 6: Forecast tip → "Mejor hora: HH:MM"

**Files:**
- Modify: `lib/features/forecast/forecast_screen.dart` (`_ForecastTipCard` + call site)
- Test: `test/features/forecast/forecast_screen_test.dart` (assert the label)

**Interfaces:** none new.

- [ ] **Step 1: Add the assertion**

In `test/features/forecast/forecast_screen_test.dart`, in the test that loads real
weather, add:

```dart
    expect(find.textContaining('Mejor hora:'), findsOneWidget);
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/forecast/forecast_screen_test.dart`
Expected: FAIL — the tip still says "Ventana óptima…".

- [ ] **Step 3: Change the tip to show the best hour**

In `forecast_screen.dart`, change `_ForecastTipCard` to take a label string:

```dart
class _ForecastTipCard extends StatelessWidget {
  const _ForecastTipCard({required this.language, required this.bestHourLabel});

  final Language language;
  final String bestHourLabel;
```
and replace the `Text(AppStrings.get('ventana_optima_tip'), ...)` with:

```dart
              child: Text(
                '${AppStrings.get('mejor_hora', language: language)}: $bestHourLabel',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF475569),
                ),
              ),
```
At the call site in `_buildFocusedSection`, compute the best-hour label and pass it:

```dart
    final bestHourLabel = activeDay.bestHour?.hour ?? '—';
```
and change the tip to:

```dart
      _ForecastTipCard(language: language, bestHourLabel: bestHourLabel),
```
(`bestHour.hour` is already the `HH:mm` string.)

- [ ] **Step 4: Run tests + analyze**

Run: `flutter test test/features/forecast/forecast_screen_test.dart && flutter analyze`
Expected: PASS, analyzer clean.

- [ ] **Step 5: Commit**

```bash
git add lib/features/forecast/forecast_screen.dart test/features/forecast/forecast_screen_test.dart
git commit -m "feat: forecast tip shows the best hour"
```

---

### Task 7: Format, verify, visual check

**Files:** none (verification only).

- [ ] **Step 1: Format**

Run: `dart format lib test`

- [ ] **Step 2: Full suite + analyze**

Run: `flutter test && flutter analyze`
Expected: all tests PASS (1 pre-existing skip); analyzer reports no issues.

- [ ] **Step 3: Visual check (light and dark)**

Run the app / rebuild the APK and confirm on both screens:
- Estado and Forecast show the same 10-card grid in the order Viento·Ráfagas /
  Precipitación·Visibilidad / Nubosidad·Condición / Temperatura·Humedad /
  Presión·(UV in Forecast | Kp in Estado), with badge accent lines and sub-values.
- Forecast cards update with the selected hour; the bottom tip reads
  "Mejor hora: HH:MM".
- Works in light and dark.

APK build (OpenAIP key via dart-define, clean temp dir for the Gradle loopback):

```bash
TMP='C:\gtmp' TEMP='C:\gtmp' JAVA_HOME='C:\Program Files\Java\jdk-17' \
  flutter build apk --dart-define=OPENAIP_API_KEY=<OPENAIP_KEY>
```

- [ ] **Step 4: Commit any formatting**

```bash
git add -A
git commit -m "style: format unified metric cards"
```
(Skip if clean. End every commit with the `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>` trailer.)

---

## Self-Review

- **Spec coverage:** new data fields + API/DTO/snapshot/row/session (Task 1); sky-condition helper + sky i18n keys (Task 2); shared `MetricCard` (Task 3); Estado 10-card priority grid with Presión/Condición/real apparent temp, Kp kept (Task 4); `ForecastMetricsGrid` (UV #10), FocusedHourCard stripped, screen reorder, old widgets removed (Task 5); tip "Mejor hora: HH:MM" (Task 6); format/verify/visual (Task 7). All spec sections mapped.
- **Placeholder scan:** none — complete code for data layer, helper, shared card, both grids, screen wiring, tip; `<OPENAIP_KEY>` in Task 7 is an intentional secret placeholder (dart-define only, never written to a file).
- **Type consistency:** `MetricCard({label,value,subValue,icon,accentColor})` matches between Task 3's definition and its uses in Tasks 4-5; `weatherConditionFor(int?)→WeatherCondition{labelKey,icon}` matches between Task 2 and Tasks 4-5; new `WeatherSnapshot`/`ForecastRow` field names (`apparentTemperatureC`, `pressureHpa`, `uvIndex`, `weatherCode`, `relativeHumidityPercent`) match between Task 1 and their readers; card order is identical across both grids; widget keys (`focused-hour-time`, `scrubber-track`, `scrubber-gradient`) preserved.
- **Engine untouched:** only the weather data layer, shared/forecast/conditions UI, and i18n change; `FlightReadinessEvaluator`, `FlightRulesConfig`, and `bestWindowFor` are not modified.

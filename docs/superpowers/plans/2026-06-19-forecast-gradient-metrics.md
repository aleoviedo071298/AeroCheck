# Forecast Gradient Scrubber + Metrics Grid Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Forecast hourly list with an 8-metric 2-per-row grid, turn the dot scrubber into a real day/night gradient driven by Open-Meteo sunrise/sunset, and remove the "Próximas horas" card from Estado.

**Architecture:** Add `daily: sunrise,sunset` to the weather fetch and carry it as `DaySunTimes` on `WeatherBundle`; add 4 informational fields to `ForecastRow`. A pure `dayNightGradient` helper computes gradient colors/stops. The hero and a new `ConditionsMetricsCard` share a reusable `MetricTile`; `HourScrubber` renders the gradient + score dots.

**Tech Stack:** Flutter, Dart, existing `WeatherSession`/`WeatherBundle`/`UnitFormatters`/`AppStrings`/`ForecastRow`. No new dependencies.

## Global Constraints

- No change to the decision engine, `FlightRulesConfig`, or `bestWindowFor`. The 4 new metrics are informational.
- All metrics stored metric; display via `UnitFormatters`. All user-facing strings via `AppStrings.get(key, language:)`; new keys in both `es` and `en`.
- New `ForecastRow` fields, `HourScrubber` sun params, and `WeatherBundle.dailySun` are additive/optional so existing constructions keep compiling.
- The Forecast track shows only the day's remaining hours, so afternoon/evening tracks are often entirely night — the gradient helper must return solid night in that case.
- Run before commit: `dart format lib test`, `flutter test`, `flutter analyze`. End every commit message with: `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.
- `ForecastRow` existing fields: `hour, status, primaryReason, reasons, isBestWindow, windKmh, gustKmh, rainPercent, visibilityKm, score, windDirectionDegrees, time`.

---

### Task 1: Data layer — sunrise/sunset + ForecastRow metrics

**Files:**
- Modify: `lib/data/weather/open_meteo_weather_repository.dart` (add `daily`)
- Modify: `lib/data/weather/dto/open_meteo_forecast_response.dart` (parse `daily`)
- Modify: `lib/data/weather/weather_bundle.dart` (`DaySunTimes`, `dailySun`, `sunTimesFor`)
- Modify: `lib/data/mock/mock_flight_data.dart` (`ForecastRow` 4 fields)
- Modify: `lib/app/weather_session.dart` (`_forecastRowFor` populates fields)
- Test: `test/data/weather/open_meteo_daily_test.dart` (create)
- Test: `test/app/weather_session_forecast_metrics_test.dart` (create)

**Interfaces:**
- Produces: `WeatherBundle.dailySun` (`List<DaySunTimes>`), `WeatherBundle.sunTimesFor(DateTime)`, `DaySunTimes{date,sunrise,sunset}`; `ForecastRow.temperatureC/cloudCoverPercent/precipitationMmPerHour/dewPointC` (all `double?`).

- [ ] **Step 1: Write the failing tests**

```dart
// test/data/weather/open_meteo_daily_test.dart
import 'package:aerocheck/data/weather/dto/open_meteo_forecast_response.dart';
import 'package:flutter_test/flutter_test.dart';

const _withDaily = '''
{
 "timezone":"America/Argentina/Catamarca","utc_offset_seconds":-10800,
 "current":{"time":"2026-06-16T13:00","temperature_2m":16,"is_day":1},
 "hourly":{"time":["2026-06-16T13:00"],"temperature_2m":[16]},
 "daily":{"time":["2026-06-16","2026-06-17"],
   "sunrise":["2026-06-16T08:10","2026-06-17T08:11"],
   "sunset":["2026-06-16T18:05","2026-06-17T18:06"]}
}''';

const _noDaily = '''
{
 "timezone":"UTC","utc_offset_seconds":0,
 "current":{"time":"2026-06-16T13:00","temperature_2m":16,"is_day":1},
 "hourly":{"time":["2026-06-16T13:00"],"temperature_2m":[16]}
}''';

void main() {
  test('parses daily sunrise/sunset into dailySun', () {
    final bundle = OpenMeteoForecastResponse.fromJsonString(
      _withDaily,
    ).toWeatherBundle(locationLabel: 'x');
    expect(bundle.dailySun.length, 2);
    final day = bundle.sunTimesFor(DateTime(2026, 6, 16))!;
    expect(day.sunrise, DateTime(2026, 6, 16, 8, 10));
    expect(day.sunset, DateTime(2026, 6, 16, 18, 5));
  });

  test('missing daily yields an empty dailySun, no throw', () {
    final bundle = OpenMeteoForecastResponse.fromJsonString(
      _noDaily,
    ).toWeatherBundle(locationLabel: 'x');
    expect(bundle.dailySun, isEmpty);
    expect(bundle.sunTimesFor(DateTime(2026, 6, 16)), isNull);
  });
}
```

```dart
// test/app/weather_session_forecast_metrics_test.dart
import 'package:aerocheck/app/weather_session.dart';
import 'package:aerocheck/data/mock/mock_flight_data.dart';
import 'package:aerocheck/data/preferences/user_preferences.dart';
import 'package:aerocheck/data/preferences/user_preferences_store.dart';
import 'package:aerocheck/data/weather/weather_bundle.dart';
import 'package:aerocheck/data/weather/weather_repository.dart';
import 'package:aerocheck/domain/entities/weather_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('forecastRows carry temperature, cloud, precip mm/h and dew point', () async {
    final session = WeatherSession(
      weatherRepository: _Repo(),
      preferencesStore: _Store(),
    );
    await session.loadRealWeather();
    final row = session.forecastRows.first;
    expect(row.temperatureC, 18);
    expect(row.cloudCoverPercent, 40);
    expect(row.precipitationMmPerHour, 0.2);
    expect(row.dewPointC, 9);
  });
}

class _Store implements UserPreferencesStore {
  @override
  Future<UserPreferences> load() async => const UserPreferences();
  @override
  Future<void> save(UserPreferences preferences) async {}
}

class _Repo implements WeatherRepository {
  @override
  Future<WeatherBundle> fetchWeather({
    required double latitude,
    required double longitude,
    required String locationLabel,
  }) async {
    final s = WeatherSnapshot(
      time: DateTime(2026, 6, 16, 13),
      locationLabel: locationLabel,
      temperatureC: 18,
      dewPointC: 9,
      windKmh: 10,
      gustKmh: 16,
      windDirectionDegrees: 230,
      precipitationProbability: 0,
      precipitationMmPerHour: 0.2,
      cloudCoverPercent: 40,
      cloudBaseMeters: 600,
      visibilityKm: 16,
      kpIndex: 1,
      isDaylight: true,
      isInsideRestrictedArea: false,
      isNearRestrictedArea: false,
    );
    return WeatherBundle(
      providerName: 'Open-Meteo',
      locationLabel: locationLabel,
      timezone: 'UTC',
      current: s,
      hourlySnapshots: [s, s.copyWith(time: DateTime(2026, 6, 16, 14))],
      windProfileRows: const [
        WindProfileRow(altitude: '10 m', windKmh: 10, gustKmh: 16, temperatureC: 18),
      ],
    );
  }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/data/weather/open_meteo_daily_test.dart test/app/weather_session_forecast_metrics_test.dart`
Expected: FAIL — `dailySun`/`sunTimesFor` and the `ForecastRow` metric fields don't exist yet.

- [ ] **Step 3: Add `DaySunTimes` + `dailySun` + `sunTimesFor` to WeatherBundle**

In `lib/data/weather/weather_bundle.dart`, add the class and field. Full file:

```dart
import '../../domain/entities/weather_snapshot.dart';
import '../mock/mock_flight_data.dart';

class DaySunTimes {
  const DaySunTimes({
    required this.date,
    required this.sunrise,
    required this.sunset,
  });

  final DateTime date; // normalized to midnight
  final DateTime sunrise;
  final DateTime sunset;
}

class WeatherBundle {
  const WeatherBundle({
    required this.providerName,
    required this.locationLabel,
    required this.timezone,
    required this.current,
    required this.hourlySnapshots,
    required this.windProfileRows,
    this.dailySun = const [],
  });

  final String providerName;
  final String locationLabel;
  final String timezone;
  final WeatherSnapshot current;
  final List<WeatherSnapshot> hourlySnapshots;
  final List<WindProfileRow> windProfileRows;
  final List<DaySunTimes> dailySun;

  DaySunTimes? sunTimesFor(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    for (final d in dailySun) {
      if (d.date == key) return d;
    }
    return null;
  }

  WeatherBundle copyWithKpIndex(double kpIndex) {
    return WeatherBundle(
      providerName: providerName,
      locationLabel: locationLabel,
      timezone: timezone,
      current: current.copyWith(kpIndex: kpIndex),
      hourlySnapshots: hourlySnapshots
          .map((snapshot) => snapshot.copyWith(kpIndex: kpIndex))
          .toList(),
      windProfileRows: windProfileRows,
      dailySun: dailySun,
    );
  }
}
```

- [ ] **Step 4: Parse `daily` in the DTO**

In `lib/data/weather/dto/open_meteo_forecast_response.dart`:
1. Add a `daily` field. Change the constructor to add `this.daily`, the field
   `final Map<String, Object?>? daily;`, and in `fromJson` add:
   ```dart
   daily: json['daily'] is Map<String, Object?>
       ? json['daily'] as Map<String, Object?>
       : null,
   ```
2. In `toWeatherBundle`, pass `dailySun: _dailySun(),` to the `WeatherBundle(...)`.
3. Add the parser method:

```dart
  List<DaySunTimes> _dailySun() {
    final d = daily;
    if (d == null) return const [];
    final times = d['time'];
    final sunrises = d['sunrise'];
    final sunsets = d['sunset'];
    if (times is! List || sunrises is! List || sunsets is! List) {
      return const [];
    }
    final out = <DaySunTimes>[];
    for (var i = 0; i < times.length; i++) {
      if (i >= sunrises.length || i >= sunsets.length) break;
      final dateStr = times[i];
      final sr = sunrises[i];
      final ss = sunsets[i];
      if (dateStr is! String || sr is! String || ss is! String) continue;
      try {
        final date = DateTime.parse(dateStr);
        out.add(
          DaySunTimes(
            date: DateTime(date.year, date.month, date.day),
            sunrise: DateTime.parse(sr),
            sunset: DateTime.parse(ss),
          ),
        );
      } catch (_) {
        // Skip malformed entries.
      }
    }
    return out;
  }
```
(The `DaySunTimes` symbol comes from the existing `import '../weather_bundle.dart';`.)

- [ ] **Step 5: Add the `daily` request param**

In `lib/data/weather/open_meteo_weather_repository.dart`, inside `queryParameters`,
add (next to `'hourly': [...]`):

```dart
        'daily': 'sunrise,sunset',
```

- [ ] **Step 6: Add the 4 fields to `ForecastRow`**

In `lib/data/mock/mock_flight_data.dart`, in the `ForecastRow` constructor add
after `this.time,`:

```dart
    this.temperatureC,
    this.cloudCoverPercent,
    this.precipitationMmPerHour,
    this.dewPointC,
```
and after `final DateTime? time;` add the fields:

```dart
  final double? temperatureC;
  final double? cloudCoverPercent;
  final double? precipitationMmPerHour;
  final double? dewPointC;
```

- [ ] **Step 7: Populate them in `_forecastRowFor`**

In `lib/app/weather_session.dart`, in the `ForecastRow(...)` returned by
`_forecastRowFor`, add after `windDirectionDegrees: weather.windDirectionDegrees,`:

```dart
      temperatureC: weather.temperatureC,
      cloudCoverPercent: weather.cloudCoverPercent,
      precipitationMmPerHour: weather.precipitationMmPerHour,
      dewPointC: weather.dewPointC,
```

- [ ] **Step 8: Run tests + analyze + full suite**

Run: `flutter test test/data/weather/open_meteo_daily_test.dart test/app/weather_session_forecast_metrics_test.dart && flutter test && flutter analyze`
Expected: the 2 new tests PASS; full suite green (1 pre-existing skip); analyzer clean. Existing `WeatherBundle` constructions still compile (`dailySun` defaults to `[]`).

- [ ] **Step 9: Commit**

```bash
git add lib/data/weather/open_meteo_weather_repository.dart lib/data/weather/dto/open_meteo_forecast_response.dart lib/data/weather/weather_bundle.dart lib/data/mock/mock_flight_data.dart lib/app/weather_session.dart test/data/weather/open_meteo_daily_test.dart test/app/weather_session_forecast_metrics_test.dart
git commit -m "feat: fetch sunrise/sunset and carry extra metrics on ForecastRow"
```

---

### Task 2: `dayNightGradient` helper

**Files:**
- Create: `lib/features/forecast/day_night_gradient.dart`
- Test: `test/features/forecast/day_night_gradient_test.dart`

**Interfaces:**
- Produces: `class DayNightGradient { final List<Color> colors; final List<double> stops; }` and `DayNightGradient dayNightGradient({required DateTime trackStart, required DateTime trackEnd, DateTime? sunrise, DateTime? sunset})`.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/forecast/day_night_gradient_test.dart
import 'package:aerocheck/features/forecast/day_night_gradient.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool nonDecreasing(List<double> s) {
    for (var i = 1; i < s.length; i++) {
      if (s[i] < s[i - 1]) return false;
    }
    return true;
  }

  test('full day produces a multi-stop gradient within [0,1]', () {
    final g = dayNightGradient(
      trackStart: DateTime(2026, 6, 16, 0),
      trackEnd: DateTime(2026, 6, 16, 23),
      sunrise: DateTime(2026, 6, 16, 6),
      sunset: DateTime(2026, 6, 16, 18),
    );
    expect(g.colors.length, g.stops.length);
    expect(g.stops.length, greaterThan(2));
    expect(g.stops.first, 0.0);
    expect(g.stops.last, 1.0);
    expect(nonDecreasing(g.stops), isTrue);
  });

  test('evening-only track (sunset before start) is solid night', () {
    final g = dayNightGradient(
      trackStart: DateTime(2026, 6, 16, 20),
      trackEnd: DateTime(2026, 6, 16, 23),
      sunrise: DateTime(2026, 6, 16, 6),
      sunset: DateTime(2026, 6, 16, 18),
    );
    expect(g.stops, [0.0, 1.0]);
    expect(g.colors.first, g.colors.last);
  });

  test('null sun returns a neutral 2-stop gradient', () {
    final g = dayNightGradient(
      trackStart: DateTime(2026, 6, 16, 0),
      trackEnd: DateTime(2026, 6, 16, 23),
    );
    expect(g.stops, [0.0, 1.0]);
    expect(g.colors.first, g.colors.last);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/forecast/day_night_gradient_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Implement**

```dart
// lib/features/forecast/day_night_gradient.dart
import 'package:flutter/material.dart';

const Color _night = Color(0xFF1E293B);
const Color _twilight = Color(0xFFF59E0B);
const Color _day = Color(0xFF38BDF8);
const Color _neutral = Color(0xFF94A3B8);

class DayNightGradient {
  const DayNightGradient({required this.colors, required this.stops});

  final List<Color> colors;
  final List<double> stops;
}

DayNightGradient dayNightGradient({
  required DateTime trackStart,
  required DateTime trackEnd,
  DateTime? sunrise,
  DateTime? sunset,
}) {
  final totalMs = trackEnd.difference(trackStart).inMilliseconds;
  if (sunrise == null || sunset == null || totalMs <= 0) {
    return const DayNightGradient(colors: [_neutral, _neutral], stops: [0, 1]);
  }

  double frac(DateTime t) =>
      (t.difference(trackStart).inMilliseconds / totalMs).clamp(0.0, 1.0);

  // Day band entirely outside the visible track -> solid night.
  if (!sunset.isAfter(trackStart) ||
      !sunrise.isBefore(trackEnd) ||
      !sunset.isAfter(sunrise)) {
    return const DayNightGradient(colors: [_night, _night], stops: [0, 1]);
  }

  final sr = frac(sunrise);
  final ss = frac(sunset);
  const t = 0.04; // transition half-width

  final raw = <(double, Color)>[
    (0.0, _night),
    ((sr - t).clamp(0.0, 1.0), _night),
    (sr, _twilight),
    ((sr + t).clamp(0.0, 1.0), _day),
    ((ss - t).clamp(0.0, 1.0), _day),
    (ss, _twilight),
    ((ss + t).clamp(0.0, 1.0), _night),
    (1.0, _night),
  ];

  final colors = <Color>[];
  final stops = <double>[];
  for (final (s, c) in raw) {
    if (stops.isNotEmpty && s <= stops.last) {
      // At/behind the previous stop after clamping: keep the later band color.
      colors[colors.length - 1] = c;
    } else {
      stops.add(s);
      colors.add(c);
    }
  }
  return DayNightGradient(colors: colors, stops: stops);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/forecast/day_night_gradient_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/forecast/day_night_gradient.dart test/features/forecast/day_night_gradient_test.dart
git commit -m "feat: add day/night gradient helper for forecast scrubber"
```

---

### Task 3: MetricTile + ConditionsMetricsCard, remove the Forecast list

**Files:**
- Create: `lib/features/forecast/widgets/metric_tile.dart`
- Create: `lib/features/forecast/widgets/conditions_metrics_card.dart`
- Modify: `lib/features/forecast/widgets/focused_hour_card.dart` (use `MetricTile`)
- Modify: `lib/features/forecast/forecast_screen.dart` (remove list, add card)
- Modify: `lib/domain/i18n/app_strings.dart` (add `nubosidad`, `punto_rocio`)
- Test: `test/features/forecast/conditions_metrics_card_test.dart` (create)
- Modify: `test/features/forecast/forecast_screen_test.dart` (drop list assertions)

**Interfaces:**
- Consumes: `ForecastRow` metric fields (Task 1).
- Produces: `MetricTile({required bool isDark, required String label, required String value, Widget? leading})`; `ConditionsMetricsCard({required ForecastRow row, required UnitPreferences units, required Language language})`.

- [ ] **Step 1: Add i18n keys**

In `lib/domain/i18n/app_strings.dart`, add to BOTH maps:
```dart
// es
'nubosidad': 'Nubosidad',
'punto_rocio': 'Punto de rocío',
```
```dart
// en
'nubosidad': 'Cloud cover',
'punto_rocio': 'Dew point',
```

- [ ] **Step 2: Write the failing test**

```dart
// test/features/forecast/conditions_metrics_card_test.dart
import 'package:aerocheck/data/mock/mock_flight_data.dart';
import 'package:aerocheck/domain/i18n/language.dart';
import 'package:aerocheck/domain/rules/flight_readiness_status.dart';
import 'package:aerocheck/domain/units/unit_preferences.dart';
import 'package:aerocheck/features/forecast/widgets/conditions_metrics_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the four secondary metrics', (tester) async {
    final row = ForecastRow(
      hour: '09:00',
      status: FlightReadinessStatus.ready,
      primaryReason: 'x',
      reasons: const [],
      isBestWindow: false,
      windKmh: 10,
      gustKmh: 16,
      rainPercent: 0,
      visibilityKm: 16,
      score: 90,
      time: DateTime(2026, 6, 16, 9),
      temperatureC: 18,
      cloudCoverPercent: 40,
      precipitationMmPerHour: 0.2,
      dewPointC: 9,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConditionsMetricsCard(
            row: row,
            units: const UnitPreferences(),
            language: Language.es,
          ),
        ),
      ),
    );
    expect(find.text('TEMPERATURA'), findsOneWidget);
    expect(find.text('NUBOSIDAD'), findsOneWidget);
    expect(find.text('PUNTO DE ROCÍO'), findsOneWidget);
    expect(find.textContaining('40'), findsWidgets); // cloud cover %
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/features/forecast/conditions_metrics_card_test.dart`
Expected: FAIL — `conditions_metrics_card.dart` does not exist.

- [ ] **Step 4: Create `MetricTile`**

```dart
// lib/features/forecast/widgets/metric_tile.dart
import 'package:flutter/material.dart';

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.isDark,
    required this.label,
    required this.value,
    this.leading,
  });

  final bool isDark;
  final String label;
  final String value;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 4)],
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Create `ConditionsMetricsCard`**

```dart
// lib/features/forecast/widgets/conditions_metrics_card.dart
import 'package:flutter/material.dart';

import '../../../data/mock/mock_flight_data.dart';
import '../../../domain/i18n/app_strings.dart';
import '../../../domain/i18n/language.dart';
import '../../../domain/units/unit_formatters.dart';
import '../../../domain/units/unit_preferences.dart';
import 'metric_tile.dart';

class ConditionsMetricsCard extends StatelessWidget {
  const ConditionsMetricsCard({
    super.key,
    required this.row,
    required this.units,
    required this.language,
  });

  final ForecastRow row;
  final UnitPreferences units;
  final Language language;

  String _temp(double? c) =>
      c == null ? '—' : UnitFormatters.formatTemperature(c, units, decimals: 0);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cloud = row.cloudCoverPercent;
    final mm = row.precipitationMmPerHour;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                MetricTile(
                  isDark: isDark,
                  label: AppStrings.get(
                    'temperatura',
                    language: language,
                  ).toUpperCase(),
                  value: _temp(row.temperatureC),
                ),
                const SizedBox(width: 10),
                MetricTile(
                  isDark: isDark,
                  label: AppStrings.get(
                    'nubosidad',
                    language: language,
                  ).toUpperCase(),
                  value: cloud == null ? '—' : '${cloud.round()} %',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                MetricTile(
                  isDark: isDark,
                  label: AppStrings.get(
                    'precipitacion',
                    language: language,
                  ).toUpperCase(),
                  value: mm == null
                      ? '—'
                      : '${UnitFormatters.formatPrecipitation(mm, units, decimals: 1)}/h',
                ),
                const SizedBox(width: 10),
                MetricTile(
                  isDark: isDark,
                  label: AppStrings.get(
                    'punto_rocio',
                    language: language,
                  ).toUpperCase(),
                  value: _temp(row.dewPointC),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Use `MetricTile` in `FocusedHourCard`**

In `lib/features/forecast/widgets/focused_hour_card.dart`: add
`import 'metric_tile.dart';`. Replace each `_metric(isDark, LABEL, VALUE, leading: ...)`
call with `MetricTile(isDark: isDark, label: LABEL, value: VALUE, leading: ...)`,
and DELETE the private `Widget _metric(...)` method (now unused). The 4 existing
metric calls (Viento/Ráfagas/Lluvia/Visibilidad) are unchanged otherwise.

- [ ] **Step 7: Remove the list and add the conditions card in the screen**

In `lib/features/forecast/forecast_screen.dart`:
1. Add `import 'widgets/conditions_metrics_card.dart';`.
2. In `_buildFocusedSection`, replace the block from `_ForecastTableHeader(...)`
   through the `if (_listExpanded) ...` Column (the list) with the conditions
   card. The returned list becomes:

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
      ),
      const SizedBox(height: 14),
      ConditionsMetricsCard(row: selectedRow, units: units, language: language),
      const SizedBox(height: 16),
      _ForecastTipCard(language: language),
    ];
```
3. Delete the now-unused `_ListToggle` class, the `_ForecastTableHeader` class,
   the `_RedesignedForecastRowTile` class and its helpers used ONLY by the list
   (`_ForecastReasonLine`, `_StatusIcon`, `_BestWindowPill` if unused elsewhere),
   and the `bool _listExpanded` state field. Run `flutter analyze` after to find
   any remaining unused symbol and delete it. Keep `forecastStatusColor`,
   `_severityColor`, `_iconForReasonTitle`, `_statusColor`,
   `_windDirectionCardinal` only if still referenced (the hero uses
   `forecastStatusColor`; remove the others if the analyzer flags them unused).

- [ ] **Step 8: Update the Forecast screen tests**

In `test/features/forecast/forecast_screen_test.dart`, remove the two tests that
referenced the deleted list — the one asserting
`find.byKey(const ValueKey('forecast-list-toggle'))` and the one toggling
`forecast-list`. Replace them with one test that the conditions card renders:

```dart
  testWidgets('forecast shows the conditions metrics card', (tester) async {
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository(),
      preferencesStore: _FakePreferencesStore(),
    );
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ForecastScreen(session: session))),
    );
    await session.loadRealWeather();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('focused-hour-time')), findsOneWidget);
    expect(find.text('TEMPERATURA'), findsOneWidget);
  });
```
(Keep the other existing tests and the `_FakeWeatherRepository`. Its snapshots
have `temperatureC: 16`, so the conditions card renders.)

- [ ] **Step 9: Run tests + analyze + full suite**

Run: `flutter test test/features/forecast/ && flutter test && flutter analyze`
Expected: PASS, analyzer clean (no unused-symbol warnings — delete any it flags).

- [ ] **Step 10: Commit**

```bash
git add lib/features/forecast/widgets/metric_tile.dart lib/features/forecast/widgets/conditions_metrics_card.dart lib/features/forecast/widgets/focused_hour_card.dart lib/features/forecast/forecast_screen.dart lib/domain/i18n/app_strings.dart test/features/forecast/conditions_metrics_card_test.dart test/features/forecast/forecast_screen_test.dart
git commit -m "feat: replace forecast list with an 8-metric conditions grid"
```

---

### Task 4: Gradient day/night scrubber

**Files:**
- Modify: `lib/features/forecast/widgets/hour_scrubber.dart`
- Modify: `lib/features/forecast/forecast_screen.dart` (pass sun times)
- Test: `test/features/forecast/forecast_widgets_test.dart` (keep passing; add gradient assertion)

**Interfaces:**
- Consumes: `dayNightGradient` (Task 2), `WeatherBundle.sunTimesFor` (Task 1).
- Produces: `HourScrubber` gains optional `DateTime? sunrise` and `DateTime? sunset` params; renders the gradient bar + score dots.

- [ ] **Step 1: Add a gradient assertion to the widget test**

In `test/features/forecast/forecast_widgets_test.dart`, the existing `HourScrubber`
test still passes (sun params are optional). Add this test to `main()`:

```dart
  testWidgets('HourScrubber renders a gradient track container', (tester) async {
    final rows = [
      row(DateTime(2026, 6, 16, 8), 30),
      row(DateTime(2026, 6, 16, 9), 90, best: true),
      row(DateTime(2026, 6, 16, 10), 40),
    ];
    final days = groupForecastByDay(rows);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HourScrubber(
            days: days,
            selectedDate: DateTime(2026, 6, 16),
            selectedHour: DateTime(2026, 6, 16, 9),
            today: DateTime(2026, 6, 16),
            language: Language.es,
            sunrise: DateTime(2026, 6, 16, 7),
            sunset: DateTime(2026, 6, 16, 18),
            onHourSelected: (_) {},
            onDaySelected: (_) {},
            onGoToBest: () {},
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('scrubber-gradient')), findsOneWidget);
    expect(find.byKey(const ValueKey('scrubber-track')), findsOneWidget);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/forecast/forecast_widgets_test.dart`
Expected: FAIL — no `scrubber-gradient` key yet (the `sunrise`/`sunset` params also don't exist, so it won't compile).

- [ ] **Step 3: Add sun params + gradient render to `HourScrubber`**

In `lib/features/forecast/widgets/hour_scrubber.dart`:
1. Add `import 'package:flutter/material.dart';` already present; add
   `import '../day_night_gradient.dart';`.
2. Add two fields to the constructor and class:

```dart
    this.sunrise,
    this.sunset,
```
```dart
  final DateTime? sunrise;
  final DateTime? sunset;
```
3. Replace the `// Draggable timeline` `LayoutBuilder(...)` block (the one that
   builds the `GestureDetector` with key `scrubber-track`) with:

```dart
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final hasRange =
                    rows.isNotEmpty && rows.first.time != null && rows.last.time != null;
                final trackStart = hasRange ? rows.first.time! : selectedHour;
                final trackEnd = hasRange ? rows.last.time! : selectedHour;
                final totalMs = trackEnd.difference(trackStart).inMilliseconds;
                double fracOf(DateTime t) => totalMs <= 0
                    ? 0
                    : (t.difference(trackStart).inMilliseconds / totalMs)
                          .clamp(0.0, 1.0);
                final gradient = dayNightGradient(
                  trackStart: trackStart,
                  trackEnd: trackEnd,
                  sunrise: sunrise,
                  sunset: sunset,
                );

                void selectFromDx(double dx) {
                  if (rows.isEmpty) return;
                  final clamped = dx.clamp(0.0, width);
                  final index = (clamped / width * rows.length).floor().clamp(
                    0,
                    rows.length - 1,
                  );
                  final t = rows[index].time;
                  if (t != null) onHourSelected(t);
                }

                return GestureDetector(
                  key: const ValueKey('scrubber-track'),
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => selectFromDx(d.localPosition.dx),
                  onHorizontalDragUpdate: (d) =>
                      selectFromDx(d.localPosition.dx),
                  child: Column(
                    children: [
                      // Gradient bar with thumb + sun/moon.
                      SizedBox(
                        height: 38,
                        width: width,
                        child: Stack(
                          children: [
                            Container(
                              key: const ValueKey('scrubber-gradient'),
                              height: 38,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: LinearGradient(
                                  colors: gradient.colors,
                                  stops: gradient.stops,
                                ),
                              ),
                            ),
                            if (sunrise != null && sunset != null) ...[
                              _sunMoon(
                                Icons.wb_sunny_rounded,
                                (fracOf(sunrise!) + fracOf(sunset!)) / 2,
                                width,
                                const Color(0xFFFDE68A),
                              ),
                              _sunMoon(
                                Icons.nightlight_round,
                                fracOf(sunrise!) > 0.25
                                    ? fracOf(sunrise!) / 2
                                    : (fracOf(sunset!) + 1) / 2,
                                width,
                                const Color(0xFFCBD5E1),
                              ),
                            ],
                            // Thumb
                            Positioned(
                              left: (fracOf(selectedHour) * width - 1.5).clamp(
                                0.0,
                                width - 3,
                              ),
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 3,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x66000000),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Hour labels + score dots.
                      Row(
                        children: [
                          for (final row in rows)
                            Expanded(
                              child: _ScrubberTick(
                                hourLabel:
                                    int.parse(row.hour.split(':').first) % 3 == 0
                                    ? row.hour.split(':').first
                                    : null,
                                color: _scoreColor(row.score),
                                selected: row.time == selectedHour,
                                isBest: row.time == bestTime,
                                isDark: isDark,
                                mutedColor: mutedColor,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
```
4. Add this helper method to the `HourScrubber` class (after `_scoreColor`):

```dart
  Widget _sunMoon(IconData icon, double frac, double width, Color color) {
    final left = (frac.clamp(0.0, 1.0) * width - 9).clamp(0.0, width - 18);
    return Positioned(
      left: left,
      top: 10,
      child: Icon(icon, size: 16, color: color),
    );
  }
```
(`_ScrubberTick` is unchanged — it already renders the hour label above the dot.)

- [ ] **Step 4: Pass sun times from the screen**

In `lib/features/forecast/forecast_screen.dart`, in `_buildFocusedSection`, before
the `return [`, compute the active day's sun times:

```dart
    final sun = session.realBundle?.sunTimesFor(activeDay.date);
```
and add to the `HourScrubber(...)` the two params:

```dart
        sunrise: sun?.sunrise,
        sunset: sun?.sunset,
```

- [ ] **Step 5: Run tests + analyze + full suite**

Run: `flutter test test/features/forecast/forecast_widgets_test.dart && flutter test && flutter analyze`
Expected: PASS (the gradient test finds `scrubber-gradient`), full suite green, analyzer clean.

- [ ] **Step 6: Commit**

```bash
git add lib/features/forecast/widgets/hour_scrubber.dart lib/features/forecast/forecast_screen.dart test/features/forecast/forecast_widgets_test.dart
git commit -m "feat: render day/night gradient in the forecast scrubber"
```

---

### Task 5: Remove "Próximas horas" from Estado

**Files:**
- Modify: `lib/features/conditions/conditions_screen.dart`
- Modify: `lib/domain/i18n/app_strings.dart` (drop `proximas_horas` if unused)
- Test: `test/features/conditions/conditions_screen_test.dart` (confirm still green)

**Interfaces:** none new.

- [ ] **Step 1: Remove the widget usage**

In `lib/features/conditions/conditions_screen.dart`, delete the
`_HourlyTimelineWidget(session: session)` usage and the preceding spacer/comment
(around `const SizedBox(height: 16),` + `// 6. Hourly timeline table`). The
`_ReworkedMetricsGrid` becomes the last child of that column.

- [ ] **Step 2: Delete the class**

Delete the entire `class _HourlyTimelineWidget` (and any private sub-widget or
helper used ONLY by it — run `flutter analyze` to confirm what becomes unused and
delete it).

- [ ] **Step 3: Drop the now-unused i18n keys**

Run `grep -rn "proximas_horas" lib test`. If only `app_strings.dart` matches,
remove the `'proximas_horas': ...` line from both `es` and `en` maps. If
anything else references it, leave it.

- [ ] **Step 4: Run analyze + the conditions tests + full suite**

Run: `flutter analyze && flutter test test/features/conditions/conditions_screen_test.dart && flutter test`
Expected: analyzer clean (no unused symbols), conditions tests pass (if a test
asserted the "Próximas horas"/"Next hours" text, remove that assertion), full
suite green.

- [ ] **Step 5: Commit**

```bash
git add lib/features/conditions/conditions_screen.dart lib/domain/i18n/app_strings.dart test/features/conditions/conditions_screen_test.dart
git commit -m "feat: remove Proximas horas card from Estado"
```

---

### Task 6: Format, verify, and visual check

**Files:** none (verification only).

- [ ] **Step 1: Format**

Run: `dart format lib test`

- [ ] **Step 2: Full suite + analyze**

Run: `flutter test && flutter analyze`
Expected: all tests PASS (1 pre-existing skip); analyzer reports no issues.

- [ ] **Step 3: Visual check (light and dark)**

Run the app / rebuild the APK and open Forecast. Confirm:
- The scrubber shows a day/night gradient that matches sunrise/sunset; an
  afternoon/evening day shows a solid-night bar; a future full day shows the
  whole cycle. Score dots remain below.
- Dragging updates the hero and the conditions card (Temperatura, Nubosidad,
  Lluvia mm/h, Punto de rocío) live.
- The full hourly list is gone; Estado no longer shows "Próximas horas".
- Works in light and dark.

APK build (OpenAIP key via dart-define, clean temp dir for the Gradle loopback):

```bash
TMP='C:\gtmp' TEMP='C:\gtmp' JAVA_HOME='C:\Program Files\Java\jdk-17' \
  flutter build apk --dart-define=OPENAIP_API_KEY=<OPENAIP_KEY>
```

- [ ] **Step 4: Commit any formatting**

```bash
git add -A
git commit -m "style: format forecast gradient and metrics changes"
```
(Skip if clean.)

---

## Self-Review

- **Spec coverage:** API daily + DTO + `DaySunTimes`/`dailySun`/`sunTimesFor` + `ForecastRow` fields + session population (Task 1); `dayNightGradient` with all-night/full-day/null cases (Task 2); `MetricTile` + `ConditionsMetricsCard` + list removal + 8 metrics + i18n keys (Task 3); gradient scrubber render + sun-time wiring (Task 4); Estado `_HourlyTimelineWidget` removal + key cleanup (Task 5); format/verify/visual (Task 6). All spec sections mapped.
- **Placeholder scan:** none — full code for data layer, helper, both new widgets, the scrubber gradient, and removals; `<OPENAIP_KEY>` in Task 6 is an intentional secret placeholder (passed only via dart-define, never written to a file).
- **Type consistency:** `DaySunTimes{date,sunrise,sunset}` and `WeatherBundle.dailySun`/`sunTimesFor` are defined in Task 1 and consumed in Task 4; `ForecastRow` new field names (`temperatureC`, `cloudCoverPercent`, `precipitationMmPerHour`, `dewPointC`) match between Task 1's definition, the session population, and Task 3's `ConditionsMetricsCard`; `MetricTile({isDark,label,value,leading})` matches between Task 3's definition and its uses in `ConditionsMetricsCard` and `FocusedHourCard`; `HourScrubber` gains optional `sunrise`/`sunset` (additive — existing callers/tests still compile); the `scrubber-track` key is preserved and `scrubber-gradient` added.
- **Engine untouched:** only the weather data layer, forecast/conditions UI, and i18n change; `FlightReadinessEvaluator`, `FlightRulesConfig`, and `bestWindowFor` are not modified.

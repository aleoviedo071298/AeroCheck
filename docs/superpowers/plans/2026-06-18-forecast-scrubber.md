# Forecast Scrubber Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Forecast tab's long hourly list with a draggable day/hour scrubber that drives a live "focused hour" detail panel, keeping the full list collapsed below.

**Architecture:** Extend the forecast range to 7 days and memoize the per-hour evaluation in `WeatherSession`. Add pure day-grouping helpers, a `FocusedHourCard` hero widget, and a draggable `HourScrubber`. `ForecastScreen` becomes stateful, owns the selected day/hour and list-expanded state, and computes each day's best hour locally.

**Tech Stack:** Flutter, Dart, existing `WeatherSession`, `UnitFormatters`, `AppStrings`, `ForecastRow`. No new dependencies.

## Global Constraints

- No new weather API fields and no change to the decision engine or rule config.
- `bestWindowFor` (global next-24h window) is unchanged — Estado depends on it.
- Best hour shown in Forecast is per selected day (max `score` in that day's rows; ties → earliest), computed in the UI layer, not the engine.
- All thresholds/metrics stored metric; display via `UnitFormatters`. All user-facing strings via `AppStrings.get(key, language:)`; new keys added to both `es` and `en`.
- Forecast does not display Kp (unchanged).
- Run before commit: `dart format lib test`, `flutter test`, `flutter analyze`.
- `ForecastRow` fields (from `lib/data/mock/mock_flight_data.dart`): `String hour`, `FlightReadinessStatus status`, `String primaryReason`, `List<ForecastReason> reasons`, `bool isBestWindow`, `double windKmh`, `double gustKmh`, `double rainPercent`, `double visibilityKm`, `int score`, `double? windDirectionDegrees`, `DateTime? time`.

---

### Task 1: Extend range to 7 days and memoize `forecastRows`

**Files:**
- Modify: `lib/data/weather/open_meteo_weather_repository.dart:28`
- Modify: `lib/app/weather_session.dart` (`forecastRows` getter ~116-133; add cache fields + invalidation)
- Test: `test/app/weather_session_forecast_test.dart` (create)

**Interfaces:**
- Produces: `session.forecastRows` returns all future hours (no 12-cap), memoized per `WeatherBundle`; cache invalidated on `updateRulesConfig` and after `_loadNearbyAirspaces`.

- [ ] **Step 1: Write the failing test**

```dart
// test/app/weather_session_forecast_test.dart
import 'package:aerocheck/app/weather_session.dart';
import 'package:aerocheck/data/mock/mock_flight_data.dart';
import 'package:aerocheck/data/preferences/user_preferences.dart';
import 'package:aerocheck/data/preferences/user_preferences_store.dart';
import 'package:aerocheck/data/weather/weather_bundle.dart';
import 'package:aerocheck/data/weather/weather_repository.dart';
import 'package:aerocheck/domain/entities/weather_snapshot.dart';
import 'package:aerocheck/domain/rules/flight_rules_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('forecastRows returns more than 12 hours and is cached', () async {
    final session = WeatherSession(
      weatherRepository: _ManyHoursRepository(),
      preferencesStore: _FakeStore(),
    );
    await session.loadRealWeather();

    final first = session.forecastRows;
    expect(first.length, greaterThan(12));
    // Same bundle -> identical cached list instance.
    expect(identical(session.forecastRows, first), isTrue);
  });

  test('updateRulesConfig invalidates the forecast cache', () async {
    final session = WeatherSession(
      weatherRepository: _ManyHoursRepository(),
      preferencesStore: _FakeStore(),
    );
    await session.loadRealWeather();
    final before = session.forecastRows;

    await session.updateRulesConfig(
      const FlightRulesConfig.defaults().copyWith(windBlockedKmh: 5),
    );
    final after = session.forecastRows;
    expect(identical(after, before), isFalse);
  });
}

class _FakeStore implements UserPreferencesStore {
  @override
  Future<UserPreferences> load() async => const UserPreferences();
  @override
  Future<void> save(UserPreferences preferences) async {}
}

class _ManyHoursRepository implements WeatherRepository {
  @override
  Future<WeatherBundle> fetchWeather({
    required double latitude,
    required double longitude,
    required String locationLabel,
  }) async {
    final base = DateTime(2026, 6, 16, 0);
    WeatherSnapshot snap(int hourOffset) => WeatherSnapshot(
      time: base.add(Duration(hours: hourOffset)),
      locationLabel: locationLabel,
      temperatureC: 16,
      dewPointC: 8,
      windKmh: 10,
      gustKmh: 16,
      windDirectionDegrees: 230,
      precipitationProbability: 0,
      precipitationMmPerHour: 0,
      cloudCoverPercent: 20,
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
      current: snap(0),
      hourlySnapshots: List.generate(48, snap),
      windProfileRows: const [
        WindProfileRow(altitude: '10 m', windKmh: 10, gustKmh: 16, temperatureC: 16),
      ],
    );
  }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/app/weather_session_forecast_test.dart`
Expected: FAIL — `forecastRows` is currently capped at 12 (`first.length` would be 12, not >12) and is recomputed each call (the `identical` check fails).

- [ ] **Step 3: Bump the API range**

In `lib/data/weather/open_meteo_weather_repository.dart`, change the line
`'forecast_days': '2',` to `'forecast_days': '7',`.

- [ ] **Step 4: Memoize `forecastRows` and add invalidation**

In `lib/app/weather_session.dart`, add cache fields near the other private
fields (after `UserPreferences _userPreferences = const UserPreferences();`):

```dart
  WeatherBundle? _cachedRowsBundle;
  List<ForecastRow>? _cachedRows;
```

Replace the `forecastRows` getter body with (note: `.take(12)` removed,
memoization added):

```dart
  List<ForecastRow> get forecastRows {
    final bundle = _realBundle;
    if (bundle == null) {
      return const [];
    }
    if (identical(bundle, _cachedRowsBundle) && _cachedRows != null) {
      return _cachedRows!;
    }
    final bestWindow = bestWindowFor(
      bundle.hourlySnapshots,
      referenceTime: bundle.current.time,
    );
    final now = bundle.current.time;
    final currentHour = DateTime(now.year, now.month, now.day, now.hour);
    final rows = bundle.hourlySnapshots
        .where((snapshot) => !snapshot.time.isBefore(currentHour))
        .map((snapshot) => _forecastRowFor(snapshot, bestWindow))
        .toList();
    _cachedRowsBundle = bundle;
    _cachedRows = rows;
    return rows;
  }

  void _invalidateForecastCache() {
    _cachedRowsBundle = null;
    _cachedRows = null;
  }
```

In `updateRulesConfig`, after `_userPreferences = _userPreferences.copyWith(rulesConfig: config);`, add:

```dart
    _invalidateForecastCache();
```

In `_loadNearbyAirspaces`, call `_invalidateForecastCache();` immediately before
each `notifyListeners();` that follows a state change (the success branch that
sets `AirspaceLoadedState`/`AirspaceEmptyState`, and the `catch` branch that
sets `AirspaceErrorState`) — forecast rows depend on loaded airspaces via
`_withOperationalContext`.

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/app/weather_session_forecast_test.dart && flutter analyze`
Expected: PASS, analyzer clean.

- [ ] **Step 6: Run full suite (existing forecast test still green)**

Run: `flutter test`
Expected: all pass (1 pre-existing skip). The existing `forecast_screen_test.dart` still passes — it only checks the title and that `mph` renders.

- [ ] **Step 7: Commit**

```bash
git add lib/data/weather/open_meteo_weather_repository.dart lib/app/weather_session.dart test/app/weather_session_forecast_test.dart
git commit -m "feat: extend forecast to 7 days and memoize forecastRows"
```
(End every commit message with: `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.)

---

### Task 2: Day-grouping helpers

**Files:**
- Create: `lib/features/forecast/forecast_day_grouping.dart`
- Test: `test/features/forecast/forecast_day_grouping_test.dart`

**Interfaces:**
- Produces:
  - `class ForecastDay { final DateTime date; final List<ForecastRow> rows; ForecastRow? get bestHour; }`
  - `List<ForecastDay> groupForecastByDay(List<ForecastRow> rows)` — groups by calendar day, sorted ascending; rows with null `time` skipped.
  - `String forecastDayLabel(DateTime date, DateTime today, Language language)` — "Hoy"/"Today", "Mañana"/"Tomorrow", else short weekday.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/forecast/forecast_day_grouping_test.dart
import 'package:aerocheck/data/mock/mock_flight_data.dart';
import 'package:aerocheck/domain/i18n/language.dart';
import 'package:aerocheck/domain/rules/flight_readiness_status.dart';
import 'package:aerocheck/features/forecast/forecast_day_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

ForecastRow row(DateTime time, int score) => ForecastRow(
  hour:
      '${time.hour.toString().padLeft(2, '0')}:00',
  status: FlightReadinessStatus.caution,
  primaryReason: 'x',
  reasons: const [],
  isBestWindow: false,
  windKmh: 10,
  gustKmh: 16,
  rainPercent: 0,
  visibilityKm: 16,
  score: score,
  time: time,
);

void main() {
  test('groups rows by calendar day, sorted', () {
    final rows = [
      row(DateTime(2026, 6, 16, 22), 50),
      row(DateTime(2026, 6, 17, 9), 80),
      row(DateTime(2026, 6, 16, 23), 60),
    ];
    final days = groupForecastByDay(rows);
    expect(days.length, 2);
    expect(days.first.date, DateTime(2026, 6, 16));
    expect(days.first.rows.length, 2);
    expect(days[1].date, DateTime(2026, 6, 17));
  });

  test('bestHour returns the highest score, earliest on ties', () {
    final day = ForecastDay(
      date: DateTime(2026, 6, 16),
      rows: [
        row(DateTime(2026, 6, 16, 8), 70),
        row(DateTime(2026, 6, 16, 9), 90),
        row(DateTime(2026, 6, 16, 10), 90),
      ],
    );
    expect(day.bestHour!.time, DateTime(2026, 6, 16, 9));
  });

  test('day label is Hoy/Mañana then weekday', () {
    final today = DateTime(2026, 6, 16); // Tuesday
    expect(forecastDayLabel(DateTime(2026, 6, 16), today, Language.es), 'Hoy');
    expect(forecastDayLabel(DateTime(2026, 6, 17), today, Language.es), 'Mañana');
    expect(forecastDayLabel(DateTime(2026, 6, 16), today, Language.en), 'Today');
    expect(forecastDayLabel(DateTime(2026, 6, 19), today, Language.es), 'Vie');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/forecast/forecast_day_grouping_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Implement**

```dart
// lib/features/forecast/forecast_day_grouping.dart
import '../../data/mock/mock_flight_data.dart';
import '../../domain/i18n/language.dart';

class ForecastDay {
  const ForecastDay({required this.date, required this.rows});

  final DateTime date; // normalized to midnight
  final List<ForecastRow> rows;

  ForecastRow? get bestHour {
    if (rows.isEmpty) return null;
    var best = rows.first;
    for (final r in rows.skip(1)) {
      if (r.score > best.score) best = r;
    }
    return best;
  }
}

List<ForecastDay> groupForecastByDay(List<ForecastRow> rows) {
  final map = <DateTime, List<ForecastRow>>{};
  for (final row in rows) {
    final t = row.time;
    if (t == null) continue;
    final key = DateTime(t.year, t.month, t.day);
    (map[key] ??= <ForecastRow>[]).add(row);
  }
  final days = map.entries
      .map((e) => ForecastDay(date: e.key, rows: e.value))
      .toList();
  days.sort((a, b) => a.date.compareTo(b.date));
  return days;
}

String forecastDayLabel(DateTime date, DateTime today, Language language) {
  final d = DateTime(date.year, date.month, date.day);
  final t = DateTime(today.year, today.month, today.day);
  final diff = d.difference(t).inDays;
  final isEs = language == Language.es;
  if (diff == 0) return isEs ? 'Hoy' : 'Today';
  if (diff == 1) return isEs ? 'Mañana' : 'Tomorrow';
  const esShort = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  const enShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return (isEs ? esShort : enShort)[date.weekday - 1];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/forecast/forecast_day_grouping_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/forecast/forecast_day_grouping.dart test/features/forecast/forecast_day_grouping_test.dart
git commit -m "feat: add forecast day-grouping helpers"
```

---

### Task 3: FocusedHourCard and HourScrubber widgets

**Files:**
- Create: `lib/features/forecast/widgets/focused_hour_card.dart`
- Create: `lib/features/forecast/widgets/hour_scrubber.dart`
- Modify: `lib/domain/i18n/app_strings.dart` (add 3 keys to es + en)
- Test: `test/features/forecast/forecast_widgets_test.dart`

**Interfaces:**
- Consumes: `ForecastRow`, `ForecastDay` (Task 2), `UnitFormatters`, `AppStrings`, `Language`, `FlightReadinessStatus`.
- Produces:
  - `FocusedHourCard({required ForecastRow row, required UnitPreferences units, required Language language, required bool isBestHour, required String dayLabel})`
  - `HourScrubber({required List<ForecastDay> days, required DateTime selectedDate, required DateTime selectedHour, required Language language, required DateTime today, required ValueChanged<DateTime> onHourSelected, required ValueChanged<DateTime> onDaySelected, required VoidCallback onGoToBest})`

- [ ] **Step 1: Add the i18n keys**

In `lib/domain/i18n/app_strings.dart`, add to BOTH the `'es'` and `'en'` maps:

```dart
// es
'ir_a_mejor_hora': 'Ir a mejor hora',
'ver_lista_completa': 'Ver lista completa por hora',
'ocultar_lista': 'Ocultar lista',
```
```dart
// en
'ir_a_mejor_hora': 'Go to best hour',
'ver_lista_completa': 'See full hourly list',
'ocultar_lista': 'Hide list',
```

- [ ] **Step 2: Write the failing widget test**

```dart
// test/features/forecast/forecast_widgets_test.dart
import 'package:aerocheck/data/mock/mock_flight_data.dart';
import 'package:aerocheck/domain/i18n/language.dart';
import 'package:aerocheck/domain/rules/flight_readiness_status.dart';
import 'package:aerocheck/domain/units/unit_preferences.dart';
import 'package:aerocheck/features/forecast/forecast_day_grouping.dart';
import 'package:aerocheck/features/forecast/widgets/focused_hour_card.dart';
import 'package:aerocheck/features/forecast/widgets/hour_scrubber.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ForecastRow row(DateTime time, int score, {bool best = false}) => ForecastRow(
  hour: '${time.hour.toString().padLeft(2, '0')}:00',
  status: best ? FlightReadinessStatus.ready : FlightReadinessStatus.notReady,
  primaryReason: 'Viento sobre el limite',
  reasons: const [],
  isBestWindow: false,
  windKmh: 14,
  gustKmh: 23,
  rainPercent: 0,
  visibilityKm: 16,
  score: score,
  windDirectionDegrees: 270,
  time: time,
);

void main() {
  testWidgets('FocusedHourCard shows the hour and metrics', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusedHourCard(
            row: row(DateTime(2026, 6, 16, 9), 90, best: true),
            units: const UnitPreferences(),
            language: Language.es,
            isBestHour: true,
            dayLabel: 'Hoy',
          ),
        ),
      ),
    );
    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('Hoy'), findsWidgets);
    expect(find.textContaining('14'), findsWidgets); // wind value
  });

  testWidgets('HourScrubber taps select an hour and the best-hour button fires',
      (tester) async {
    DateTime? selectedHour;
    var wentToBest = false;
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
            selectedHour: DateTime(2026, 6, 16, 8),
            today: DateTime(2026, 6, 16),
            language: Language.es,
            onHourSelected: (t) => selectedHour = t,
            onDaySelected: (_) {},
            onGoToBest: () => wentToBest = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('scrubber-track')));
    await tester.pump();
    expect(selectedHour, isNotNull);

    await tester.tap(find.byKey(const ValueKey('go-to-best-hour')));
    await tester.pump();
    expect(wentToBest, isTrue);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/features/forecast/forecast_widgets_test.dart`
Expected: FAIL — widget files do not exist.

- [ ] **Step 4: Implement `FocusedHourCard`**

```dart
// lib/features/forecast/widgets/focused_hour_card.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/mock/mock_flight_data.dart';
import '../../../domain/i18n/app_strings.dart';
import '../../../domain/i18n/language.dart';
import '../../../domain/rules/flight_readiness_status.dart';
import '../../../domain/units/unit_formatters.dart';
import '../../../domain/units/unit_preferences.dart';

Color forecastStatusColor(FlightReadinessStatus status) => switch (status) {
  FlightReadinessStatus.ready => const Color(0xFF16A34A),
  FlightReadinessStatus.caution => const Color(0xFFF59E0B),
  FlightReadinessStatus.notReady => const Color(0xFFDC2626),
};

class FocusedHourCard extends StatelessWidget {
  const FocusedHourCard({
    super.key,
    required this.row,
    required this.units,
    required this.language,
    required this.isBestHour,
    required this.dayLabel,
  });

  final ForecastRow row;
  final UnitPreferences units;
  final Language language;
  final bool isBestHour;
  final String dayLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = forecastStatusColor(row.status);

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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.hour,
                      key: const ValueKey('focused-hour-time'),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dayLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        row.status
                            .getLocalizedLabel(language: language)
                            .toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (isBestHour) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: Color(0xFF0F766E),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              AppStrings.get('mejor_hora', language: language),
                              style: const TextStyle(
                                color: Color(0xFF0F766E),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              row.reasons.isNotEmpty
                  ? row.reasons.first.localizedTitle(language)
                  : row.primaryReason,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _metric(
                  isDark,
                  AppStrings.get('viento', language: language).toUpperCase(),
                  UnitFormatters.formatSpeed(row.windKmh, units, decimals: 0),
                  leading: row.windDirectionDegrees == null
                      ? null
                      : Transform.rotate(
                          angle: row.windDirectionDegrees! * math.pi / 180.0,
                          child: const Icon(
                            Icons.navigation_rounded,
                            size: 13,
                            color: Color(0xFF0EA5E9),
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                _metric(
                  isDark,
                  AppStrings.get('rafagas', language: language).toUpperCase(),
                  UnitFormatters.formatSpeed(row.gustKmh, units, decimals: 0),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _metric(
                  isDark,
                  AppStrings.get('lluvia', language: language).toUpperCase(),
                  '${row.rainPercent.round()} %',
                ),
                const SizedBox(width: 10),
                _metric(
                  isDark,
                  AppStrings.get('visibilidad', language: language).toUpperCase(),
                  UnitFormatters.formatDistance(row.visibilityKm, units, decimals: 0),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(bool isDark, String label, String value, {Widget? leading}) {
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
                if (leading != null) ...[leading, const SizedBox(width: 4)],
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

- [ ] **Step 5: Implement `HourScrubber`**

```dart
// lib/features/forecast/widgets/hour_scrubber.dart
import 'package:flutter/material.dart';

import '../../../data/mock/mock_flight_data.dart';
import '../../../domain/i18n/app_strings.dart';
import '../../../domain/i18n/language.dart';
import '../forecast_day_grouping.dart';
import 'focused_hour_card.dart';

class HourScrubber extends StatelessWidget {
  const HourScrubber({
    super.key,
    required this.days,
    required this.selectedDate,
    required this.selectedHour,
    required this.today,
    required this.language,
    required this.onHourSelected,
    required this.onDaySelected,
    required this.onGoToBest,
  });

  final List<ForecastDay> days;
  final DateTime selectedDate;
  final DateTime selectedHour;
  final DateTime today;
  final Language language;
  final ValueChanged<DateTime> onHourSelected;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onGoToBest;

  Color _scoreColor(int score) {
    if (score >= 80) return const Color(0xFF16A34A);
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeDay = days.firstWhere(
      (d) => d.date == selectedDate,
      orElse: () => days.isNotEmpty
          ? days.first
          : ForecastDay(date: selectedDate, rows: const []),
    );
    final rows = activeDay.rows;
    final bestTime = activeDay.bestHour?.time;
    final mutedColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

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
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final day in days) ...[
                    _DayChip(
                      label: forecastDayLabel(day.date, today, language),
                      selected: day.date == selectedDate,
                      isDark: isDark,
                      onTap: () => onDaySelected(day.date),
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Draggable timeline
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                void selectFromDx(double dx) {
                  if (rows.isEmpty) return;
                  final clamped = dx.clamp(0.0, width);
                  final index = (clamped / width * rows.length)
                      .floor()
                      .clamp(0, rows.length - 1);
                  final t = rows[index].time;
                  if (t != null) onHourSelected(t);
                }

                return GestureDetector(
                  key: const ValueKey('scrubber-track'),
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => selectFromDx(d.localPosition.dx),
                  onHorizontalDragUpdate: (d) =>
                      selectFromDx(d.localPosition.dx),
                  child: SizedBox(
                    height: 56,
                    width: width,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          left: 4,
                          right: 4,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            for (final row in rows)
                              Expanded(
                                child: _ScrubberTick(
                                  hourLabel: int.parse(
                                            row.hour.split(':').first,
                                          ) %
                                          3 ==
                                      0
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
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const ValueKey('go-to-best-hour'),
                onPressed: onGoToBest,
                icon: const Icon(Icons.center_focus_strong_rounded, size: 16),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0F766E),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                label: Text(
                  AppStrings.get('ir_a_mejor_hora', language: language),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF0F766E)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? const Color(0xFF0F766E)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: selected
                ? Colors.white
                : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }
}

class _ScrubberTick extends StatelessWidget {
  const _ScrubberTick({
    required this.hourLabel,
    required this.color,
    required this.selected,
    required this.isBest,
    required this.isDark,
    required this.mutedColor,
  });

  final String? hourLabel;
  final Color color;
  final bool selected;
  final bool isBest;
  final bool isDark;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    final dotSize = selected ? 18.0 : (isBest ? 14.0 : 8.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 14,
          child: hourLabel == null
              ? null
              : Text(
                  hourLabel!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                    color: selected ? const Color(0xFF0F766E) : mutedColor,
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              width: selected || isBest ? 3 : 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/features/forecast/forecast_widgets_test.dart && flutter analyze`
Expected: PASS, analyzer clean.

- [ ] **Step 7: Commit**

```bash
git add lib/features/forecast/widgets/focused_hour_card.dart lib/features/forecast/widgets/hour_scrubber.dart lib/domain/i18n/app_strings.dart test/features/forecast/forecast_widgets_test.dart
git commit -m "feat: add FocusedHourCard and HourScrubber forecast widgets"
```

---

### Task 4: Integrate the scrubber into ForecastScreen

**Files:**
- Modify: `lib/features/forecast/forecast_screen.dart` (make stateful; compose hero + scrubber + collapsible list; remove `_ForecastWindowStatsCard`)
- Test: `test/features/forecast/forecast_screen_test.dart` (add interaction tests; keep existing 3)

**Interfaces:**
- Consumes: `session.forecastRows` (Task 1), `groupForecastByDay`/`ForecastDay`/`forecastDayLabel` (Task 2), `FocusedHourCard`/`HourScrubber` (Task 3), existing `_RedesignedForecastRowTile`.

- [ ] **Step 1: Add interaction tests (RED for the new ones)**

Append to `test/features/forecast/forecast_screen_test.dart` inside `main()`
(keep the existing 3 tests and the `_FakeWeatherRepository`/`_FakePreferencesStore`):

```dart
  testWidgets('forecast shows the focused hour hero and a draggable scrubber',
      (tester) async {
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
    expect(find.byKey(const ValueKey('scrubber-track')), findsOneWidget);
    // List is collapsed by default: the toggle is visible.
    expect(find.byKey(const ValueKey('forecast-list-toggle')), findsOneWidget);
  });

  testWidgets('tapping the list toggle reveals the hourly rows', (tester) async {
    final session = WeatherSession(
      weatherRepository: _FakeWeatherRepository(),
      preferencesStore: _FakePreferencesStore(),
    );
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ForecastScreen(session: session))),
    );
    await session.loadRealWeather();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('forecast-list')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('forecast-list-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('forecast-list')), findsOneWidget);
  });
```

(The existing `_FakeWeatherRepository` returns two hours on 2026-06-16, both
on the same day, so grouping yields one day — enough for these assertions.)

- [ ] **Step 2: Run test to verify the new tests fail**

Run: `flutter test test/features/forecast/forecast_screen_test.dart`
Expected: the 2 new tests FAIL (no `focused-hour-time` / `scrubber-track` /
`forecast-list-toggle` keys yet); the existing 3 pass.

- [ ] **Step 3: Rewrite `ForecastScreen` as stateful and compose the new layout**

Replace the `ForecastScreen` class (the `StatelessWidget` at the top of
`lib/features/forecast/forecast_screen.dart`, lines 15-105) with the following.
Add these imports at the top of the file (next to the existing imports):

```dart
import 'forecast_day_grouping.dart';
import 'widgets/focused_hour_card.dart';
import 'widgets/hour_scrubber.dart';
```

Then the new screen class:

```dart
class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key, required this.session});

  final WeatherSession session;

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  DateTime? _selectedDate;
  DateTime? _selectedHour;
  bool _listExpanded = false;

  WeatherSession get session => widget.session;

  void _syncSelection(List<ForecastDay> days) {
    // Keep the selection valid against the latest data; default to today's best.
    if (days.isEmpty) {
      _selectedDate = null;
      _selectedHour = null;
      return;
    }
    final hasDate = days.any((d) => d.date == _selectedDate);
    if (!hasDate) {
      final first = days.first;
      _selectedDate = first.date;
      _selectedHour = first.bestHour?.time ?? first.rows.first.time;
      return;
    }
    final day = days.firstWhere((d) => d.date == _selectedDate);
    final hasHour = day.rows.any((r) => r.time == _selectedHour);
    if (!hasHour) {
      _selectedHour = day.bestHour?.time ?? day.rows.first.time;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentBg = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF1F5F9);

    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        AppStrings.currentLanguage = session.preferences.language;
        final language = session.preferences.language;
        final units = session.preferences.units;
        final report = session.currentReport;
        final rows = session.forecastRows;
        final days = groupForecastByDay(rows);
        _syncSelection(days);

        return Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: contentBg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    children: [
                      _ScreenHeader(
                        title: AppStrings.get('forecast_horario'),
                        session: session,
                      ),
                      const SizedBox(height: 14),
                      if (session.isLoadingReal)
                        const _RealWeatherLoadingCard()
                      else if (session.dataSource == WeatherDataSource.real &&
                          session.realError != null)
                        _RealWeatherErrorCard(onRetry: session.loadRealWeather)
                      else if (report == null || days.isEmpty)
                        const _StaticLoadingCard()
                      else ...[
                        ..._buildFocusedSection(days, units, language),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildFocusedSection(
    List<ForecastDay> days,
    UnitPreferences units,
    Language language,
  ) {
    final today = DateTime.now();
    final activeDay = days.firstWhere(
      (d) => d.date == _selectedDate,
      orElse: () => days.first,
    );
    final selectedRow = activeDay.rows.firstWhere(
      (r) => r.time == _selectedHour,
      orElse: () => activeDay.bestHour ?? activeDay.rows.first,
    );
    final bestTime = activeDay.bestHour?.time;

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
      _ForecastTableHeader(units: units),
      const SizedBox(height: 4),
      _ListToggle(
        expanded: _listExpanded,
        language: language,
        onTap: () => setState(() => _listExpanded = !_listExpanded),
      ),
      if (_listExpanded)
        Column(
          key: const ValueKey('forecast-list'),
          children: [
            const SizedBox(height: 8),
            for (final row in activeDay.rows)
              _RedesignedForecastRowTile(row: row, units: units),
          ],
        ),
      const SizedBox(height: 16),
      _ForecastTipCard(language: language),
    ];
  }
}

class _ListToggle extends StatelessWidget {
  const _ListToggle({
    required this.expanded,
    required this.language,
    required this.onTap,
  });

  final bool expanded;
  final Language language;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    return Center(
      child: TextButton.icon(
        key: const ValueKey('forecast-list-toggle'),
        onPressed: onTap,
        style: TextButton.styleFrom(foregroundColor: color),
        icon: Icon(
          expanded
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          size: 18,
        ),
        label: Text(
          AppStrings.get(
            expanded ? 'ocultar_lista' : 'ver_lista_completa',
            language: language,
          ),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
```

Then DELETE the `_ForecastWindowStatsCard` class (lines ~153-304) — it is no
longer referenced. Add the import for `UnitPreferences`/`Language` if the
analyzer reports them missing (they are already imported in this file).

- [ ] **Step 4: Run the screen tests (GREEN)**

Run: `flutter test test/features/forecast/forecast_screen_test.dart`
Expected: PASS — existing 3 + 2 new. If the `mph` scroll test fails because the
list is collapsed, the test taps nothing new; the `mph` unit text now renders in
the hero/scrubber header, so `find.text('mph')` still resolves — if it does not,
the existing test's `scrollUntilVisible` still finds the `mph` in the table
header (`_ForecastTableHeader`), which is always present.

- [ ] **Step 5: Full suite + analyze**

Run: `flutter test && flutter analyze`
Expected: all pass (1 pre-existing skip); analyzer clean. Remove any now-unused
imports the analyzer flags (e.g. `mock_flight_data.dart` if no longer needed —
but `_RedesignedForecastRowTile` uses `ForecastRow`, so it stays).

- [ ] **Step 6: Commit**

```bash
git add lib/features/forecast/forecast_screen.dart test/features/forecast/forecast_screen_test.dart
git commit -m "feat: scrubber-driven forecast with focused hour and collapsible list"
```

---

### Task 5: Format, verify, and visual check

**Files:** none (verification only).

- [ ] **Step 1: Format**

Run: `dart format lib test`

- [ ] **Step 2: Full suite + analyze**

Run: `flutter test && flutter analyze`
Expected: all tests PASS (1 pre-existing skip); analyzer reports no issues.

- [ ] **Step 3: Visual check (light and dark)**

Run the app / rebuild the APK and open Forecast. Confirm:
- The focused-hour hero updates as you drag the scrubber.
- Day chips switch the day and jump to that day's best hour; the ⭐ marks the
  selected day's best hour.
- "Ir a mejor hora" snaps to the active day's best hour.
- "Ver lista completa por hora" expands/collapses the list.
- Works in light and dark.

APK build (OpenAIP key via dart-define, clean temp dir for the Gradle loopback):

```bash
TMP='C:\gtmp' TEMP='C:\gtmp' JAVA_HOME='C:\Program Files\Java\jdk-17' \
  flutter build apk --dart-define=OPENAIP_API_KEY=<OPENAIP_KEY>
```

- [ ] **Step 4: Commit any formatting**

```bash
git add -A
git commit -m "style: format forecast scrubber redesign"
```
(Skip if clean. End every commit with the `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>` trailer.)

---

## Self-Review

- **Spec coverage:** 7-day range + memoization (Task 1), per-day grouping/best/label helpers (Task 2), `FocusedHourCard` + `HourScrubber` with day chips, draggable timeline, best-hour anchor (Task 3), stateful screen integration with default-to-today's-best, collapsible list, removal of `_ForecastWindowStatsCard`, i18n keys (Tasks 3-4), testing + visual (Task 5). `bestWindowFor` untouched (Task 1 keeps it). All spec sections mapped.
- **Placeholder scan:** none — full code for helpers, both widgets, and the screen; `<OPENAIP_KEY>` in Task 5 is an intentional secret placeholder (passed only via dart-define, never written to a file).
- **Type consistency:** `ForecastDay`/`groupForecastByDay`/`forecastDayLabel` signatures match between Task 2 and their consumers in Tasks 3-4; `FocusedHourCard` and `HourScrubber` constructor params match between Task 3's definitions and Task 4's call sites; `ForecastRow` field names (`hour`, `status`, `reasons`, `windKmh`, `gustKmh`, `rainPercent`, `visibilityKm`, `score`, `windDirectionDegrees`, `time`) are used verbatim; widget keys (`focused-hour-time`, `scrubber-track`, `go-to-best-hour`, `forecast-list-toggle`, `forecast-list`) are consistent between widgets, tests, and the screen.
- **Engine untouched:** only weather repo (range), session (`forecastRows` memoization), forecast feature files, and i18n are changed; `FlightReadinessEvaluator`, `FlightRulesConfig`, and `bestWindowFor` are not modified.

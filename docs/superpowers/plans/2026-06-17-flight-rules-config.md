# Flight Rules Config Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the pilot edit every flight-decision threshold in a new Settings screen, with those rules driving Estado, Forecast and Viento.

**Architecture:** Introduce an immutable `FlightRulesConfig` holding all thresholds. The evaluators read from it instead of from `DroneProfile`/`MissionProfile` and hardcoded constants. The config is persisted in `UserPreferences` and edited through a new stepper-based Settings screen.

**Tech Stack:** Flutter, Dart, `shared_preferences`, existing `UnitConverters`/`UnitFormatters`/`AppStrings`.

## Global Constraints

- Business rules live in domain/session code, never duplicated in UI (CLAUDE.md).
- Decisions stay explainable: never hide the reason for `NO_APTO`/`PRECAUCION`.
- Never present AeroCheck as official flight authorization.
- All thresholds stored in **metric**; converted only for display/edit.
- All user-facing strings via `AppStrings.get(key, language: ...)` (es + en).
- Run before each commit: `dart format lib test docs`, `flutter test`, `flutter analyze`.
- Do not stage secrets, keystores, `.env`, or build outputs.

---

### Task 1: `FlightRulesConfig` domain model

**Files:**
- Create: `lib/domain/rules/flight_rules_config.dart`
- Test: `test/domain/rules/flight_rules_config_test.dart`

**Interfaces:**
- Produces: `FlightRulesConfig` with named-arg constructor, `const FlightRulesConfig.defaults()`, `copyWith(...)`, `Map<String, dynamic> toJson()`, `static FlightRulesConfig fromJson(Map<String, dynamic>)`, value equality. Fields (all `double` unless noted):
  `windWarningKmh=22, windBlockedKmh=28, gustWarningKmh=32, gustBlockedKmh=40, gustSpreadWarningKmh=10, gustSpreadBlockedKmh=18, precipProbabilityWarningPercent=25, precipProbabilityBlockedPercent=55, precipIntensityWarningMmPerHour=0, precipIntensityBlockedMmPerHour=0.5, visibilityWarningKm=4, visibilityBlockedKm=2.8, targetAltitudeMeters=120 (int), cloudBaseWarningMarginMeters=120 (int), cloudBaseBlockedMarginMeters=60 (int), temperatureMinWarningC=0, temperatureMinBlockedC=-5, temperatureMaxWarningC=35, temperatureMaxBlockedC=40, kpWarning=4, kpBlocked=6, allowNightFlight=false (bool)`.

- [ ] **Step 1: Write the failing test**

```dart
// test/domain/rules/flight_rules_config_test.dart
import 'package:aerocheck/domain/rules/flight_rules_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults match the documented baseline values', () {
    const config = FlightRulesConfig.defaults();
    expect(config.windWarningKmh, 22);
    expect(config.windBlockedKmh, 28);
    expect(config.gustBlockedKmh, 40);
    expect(config.precipProbabilityBlockedPercent, 55);
    expect(config.visibilityBlockedKm, 2.8);
    expect(config.targetAltitudeMeters, 120);
    expect(config.kpBlocked, 6);
    expect(config.allowNightFlight, isFalse);
  });

  test('copyWith changes only the named field', () {
    const config = FlightRulesConfig.defaults();
    final updated = config.copyWith(windBlockedKmh: 35);
    expect(updated.windBlockedKmh, 35);
    expect(updated.windWarningKmh, config.windWarningKmh);
    expect(updated.gustBlockedKmh, config.gustBlockedKmh);
  });

  test('round-trips through JSON', () {
    final config = const FlightRulesConfig.defaults().copyWith(
      windBlockedKmh: 30,
      allowNightFlight: true,
      targetAltitudeMeters: 90,
    );
    final restored = FlightRulesConfig.fromJson(config.toJson());
    expect(restored, config);
  });

  test('fromJson falls back to defaults for missing keys', () {
    final restored = FlightRulesConfig.fromJson(const {});
    expect(restored, const FlightRulesConfig.defaults());
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/rules/flight_rules_config_test.dart`
Expected: FAIL — `Target of URI doesn't exist: flight_rules_config.dart`.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/domain/rules/flight_rules_config.dart
class FlightRulesConfig {
  const FlightRulesConfig({
    this.windWarningKmh = 22,
    this.windBlockedKmh = 28,
    this.gustWarningKmh = 32,
    this.gustBlockedKmh = 40,
    this.gustSpreadWarningKmh = 10,
    this.gustSpreadBlockedKmh = 18,
    this.precipProbabilityWarningPercent = 25,
    this.precipProbabilityBlockedPercent = 55,
    this.precipIntensityWarningMmPerHour = 0,
    this.precipIntensityBlockedMmPerHour = 0.5,
    this.visibilityWarningKm = 4,
    this.visibilityBlockedKm = 2.8,
    this.targetAltitudeMeters = 120,
    this.cloudBaseWarningMarginMeters = 120,
    this.cloudBaseBlockedMarginMeters = 60,
    this.temperatureMinWarningC = 0,
    this.temperatureMinBlockedC = -5,
    this.temperatureMaxWarningC = 35,
    this.temperatureMaxBlockedC = 40,
    this.kpWarning = 4,
    this.kpBlocked = 6,
    this.allowNightFlight = false,
  });

  const FlightRulesConfig.defaults() : this();

  final double windWarningKmh;
  final double windBlockedKmh;
  final double gustWarningKmh;
  final double gustBlockedKmh;
  final double gustSpreadWarningKmh;
  final double gustSpreadBlockedKmh;
  final double precipProbabilityWarningPercent;
  final double precipProbabilityBlockedPercent;
  final double precipIntensityWarningMmPerHour;
  final double precipIntensityBlockedMmPerHour;
  final double visibilityWarningKm;
  final double visibilityBlockedKm;
  final int targetAltitudeMeters;
  final int cloudBaseWarningMarginMeters;
  final int cloudBaseBlockedMarginMeters;
  final double temperatureMinWarningC;
  final double temperatureMinBlockedC;
  final double temperatureMaxWarningC;
  final double temperatureMaxBlockedC;
  final double kpWarning;
  final double kpBlocked;
  final bool allowNightFlight;

  FlightRulesConfig copyWith({
    double? windWarningKmh,
    double? windBlockedKmh,
    double? gustWarningKmh,
    double? gustBlockedKmh,
    double? gustSpreadWarningKmh,
    double? gustSpreadBlockedKmh,
    double? precipProbabilityWarningPercent,
    double? precipProbabilityBlockedPercent,
    double? precipIntensityWarningMmPerHour,
    double? precipIntensityBlockedMmPerHour,
    double? visibilityWarningKm,
    double? visibilityBlockedKm,
    int? targetAltitudeMeters,
    int? cloudBaseWarningMarginMeters,
    int? cloudBaseBlockedMarginMeters,
    double? temperatureMinWarningC,
    double? temperatureMinBlockedC,
    double? temperatureMaxWarningC,
    double? temperatureMaxBlockedC,
    double? kpWarning,
    double? kpBlocked,
    bool? allowNightFlight,
  }) {
    return FlightRulesConfig(
      windWarningKmh: windWarningKmh ?? this.windWarningKmh,
      windBlockedKmh: windBlockedKmh ?? this.windBlockedKmh,
      gustWarningKmh: gustWarningKmh ?? this.gustWarningKmh,
      gustBlockedKmh: gustBlockedKmh ?? this.gustBlockedKmh,
      gustSpreadWarningKmh: gustSpreadWarningKmh ?? this.gustSpreadWarningKmh,
      gustSpreadBlockedKmh: gustSpreadBlockedKmh ?? this.gustSpreadBlockedKmh,
      precipProbabilityWarningPercent:
          precipProbabilityWarningPercent ?? this.precipProbabilityWarningPercent,
      precipProbabilityBlockedPercent:
          precipProbabilityBlockedPercent ?? this.precipProbabilityBlockedPercent,
      precipIntensityWarningMmPerHour:
          precipIntensityWarningMmPerHour ?? this.precipIntensityWarningMmPerHour,
      precipIntensityBlockedMmPerHour:
          precipIntensityBlockedMmPerHour ?? this.precipIntensityBlockedMmPerHour,
      visibilityWarningKm: visibilityWarningKm ?? this.visibilityWarningKm,
      visibilityBlockedKm: visibilityBlockedKm ?? this.visibilityBlockedKm,
      targetAltitudeMeters: targetAltitudeMeters ?? this.targetAltitudeMeters,
      cloudBaseWarningMarginMeters:
          cloudBaseWarningMarginMeters ?? this.cloudBaseWarningMarginMeters,
      cloudBaseBlockedMarginMeters:
          cloudBaseBlockedMarginMeters ?? this.cloudBaseBlockedMarginMeters,
      temperatureMinWarningC: temperatureMinWarningC ?? this.temperatureMinWarningC,
      temperatureMinBlockedC: temperatureMinBlockedC ?? this.temperatureMinBlockedC,
      temperatureMaxWarningC: temperatureMaxWarningC ?? this.temperatureMaxWarningC,
      temperatureMaxBlockedC: temperatureMaxBlockedC ?? this.temperatureMaxBlockedC,
      kpWarning: kpWarning ?? this.kpWarning,
      kpBlocked: kpBlocked ?? this.kpBlocked,
      allowNightFlight: allowNightFlight ?? this.allowNightFlight,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'windWarningKmh': windWarningKmh,
      'windBlockedKmh': windBlockedKmh,
      'gustWarningKmh': gustWarningKmh,
      'gustBlockedKmh': gustBlockedKmh,
      'gustSpreadWarningKmh': gustSpreadWarningKmh,
      'gustSpreadBlockedKmh': gustSpreadBlockedKmh,
      'precipProbabilityWarningPercent': precipProbabilityWarningPercent,
      'precipProbabilityBlockedPercent': precipProbabilityBlockedPercent,
      'precipIntensityWarningMmPerHour': precipIntensityWarningMmPerHour,
      'precipIntensityBlockedMmPerHour': precipIntensityBlockedMmPerHour,
      'visibilityWarningKm': visibilityWarningKm,
      'visibilityBlockedKm': visibilityBlockedKm,
      'targetAltitudeMeters': targetAltitudeMeters,
      'cloudBaseWarningMarginMeters': cloudBaseWarningMarginMeters,
      'cloudBaseBlockedMarginMeters': cloudBaseBlockedMarginMeters,
      'temperatureMinWarningC': temperatureMinWarningC,
      'temperatureMinBlockedC': temperatureMinBlockedC,
      'temperatureMaxWarningC': temperatureMaxWarningC,
      'temperatureMaxBlockedC': temperatureMaxBlockedC,
      'kpWarning': kpWarning,
      'kpBlocked': kpBlocked,
      'allowNightFlight': allowNightFlight,
    };
  }

  static FlightRulesConfig fromJson(Map<String, dynamic> json) {
    const d = FlightRulesConfig.defaults();
    double num(String k, double fallback) =>
        (json[k] as num?)?.toDouble() ?? fallback;
    int integer(String k, int fallback) =>
        (json[k] as num?)?.toInt() ?? fallback;
    return FlightRulesConfig(
      windWarningKmh: num('windWarningKmh', d.windWarningKmh),
      windBlockedKmh: num('windBlockedKmh', d.windBlockedKmh),
      gustWarningKmh: num('gustWarningKmh', d.gustWarningKmh),
      gustBlockedKmh: num('gustBlockedKmh', d.gustBlockedKmh),
      gustSpreadWarningKmh: num('gustSpreadWarningKmh', d.gustSpreadWarningKmh),
      gustSpreadBlockedKmh: num('gustSpreadBlockedKmh', d.gustSpreadBlockedKmh),
      precipProbabilityWarningPercent:
          num('precipProbabilityWarningPercent', d.precipProbabilityWarningPercent),
      precipProbabilityBlockedPercent:
          num('precipProbabilityBlockedPercent', d.precipProbabilityBlockedPercent),
      precipIntensityWarningMmPerHour:
          num('precipIntensityWarningMmPerHour', d.precipIntensityWarningMmPerHour),
      precipIntensityBlockedMmPerHour:
          num('precipIntensityBlockedMmPerHour', d.precipIntensityBlockedMmPerHour),
      visibilityWarningKm: num('visibilityWarningKm', d.visibilityWarningKm),
      visibilityBlockedKm: num('visibilityBlockedKm', d.visibilityBlockedKm),
      targetAltitudeMeters: integer('targetAltitudeMeters', d.targetAltitudeMeters),
      cloudBaseWarningMarginMeters:
          integer('cloudBaseWarningMarginMeters', d.cloudBaseWarningMarginMeters),
      cloudBaseBlockedMarginMeters:
          integer('cloudBaseBlockedMarginMeters', d.cloudBaseBlockedMarginMeters),
      temperatureMinWarningC: num('temperatureMinWarningC', d.temperatureMinWarningC),
      temperatureMinBlockedC: num('temperatureMinBlockedC', d.temperatureMinBlockedC),
      temperatureMaxWarningC: num('temperatureMaxWarningC', d.temperatureMaxWarningC),
      temperatureMaxBlockedC: num('temperatureMaxBlockedC', d.temperatureMaxBlockedC),
      kpWarning: num('kpWarning', d.kpWarning),
      kpBlocked: num('kpBlocked', d.kpBlocked),
      allowNightFlight: (json['allowNightFlight'] as bool?) ?? d.allowNightFlight,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FlightRulesConfig &&
      other.windWarningKmh == windWarningKmh &&
      other.windBlockedKmh == windBlockedKmh &&
      other.gustWarningKmh == gustWarningKmh &&
      other.gustBlockedKmh == gustBlockedKmh &&
      other.gustSpreadWarningKmh == gustSpreadWarningKmh &&
      other.gustSpreadBlockedKmh == gustSpreadBlockedKmh &&
      other.precipProbabilityWarningPercent == precipProbabilityWarningPercent &&
      other.precipProbabilityBlockedPercent == precipProbabilityBlockedPercent &&
      other.precipIntensityWarningMmPerHour == precipIntensityWarningMmPerHour &&
      other.precipIntensityBlockedMmPerHour == precipIntensityBlockedMmPerHour &&
      other.visibilityWarningKm == visibilityWarningKm &&
      other.visibilityBlockedKm == visibilityBlockedKm &&
      other.targetAltitudeMeters == targetAltitudeMeters &&
      other.cloudBaseWarningMarginMeters == cloudBaseWarningMarginMeters &&
      other.cloudBaseBlockedMarginMeters == cloudBaseBlockedMarginMeters &&
      other.temperatureMinWarningC == temperatureMinWarningC &&
      other.temperatureMinBlockedC == temperatureMinBlockedC &&
      other.temperatureMaxWarningC == temperatureMaxWarningC &&
      other.temperatureMaxBlockedC == temperatureMaxBlockedC &&
      other.kpWarning == kpWarning &&
      other.kpBlocked == kpBlocked &&
      other.allowNightFlight == allowNightFlight;

  @override
  int get hashCode => Object.hashAll([
        windWarningKmh, windBlockedKmh, gustWarningKmh, gustBlockedKmh,
        gustSpreadWarningKmh, gustSpreadBlockedKmh,
        precipProbabilityWarningPercent, precipProbabilityBlockedPercent,
        precipIntensityWarningMmPerHour, precipIntensityBlockedMmPerHour,
        visibilityWarningKm, visibilityBlockedKm, targetAltitudeMeters,
        cloudBaseWarningMarginMeters, cloudBaseBlockedMarginMeters,
        temperatureMinWarningC, temperatureMinBlockedC,
        temperatureMaxWarningC, temperatureMaxBlockedC,
        kpWarning, kpBlocked, allowNightFlight,
      ]);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/domain/rules/flight_rules_config_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/domain/rules/flight_rules_config.dart test/domain/rules/flight_rules_config_test.dart
git commit -m "feat: add FlightRulesConfig domain model"
```

---

### Task 2: Persist `rulesConfig` in preferences + fix `_persistPreferences`

**Files:**
- Modify: `lib/data/preferences/user_preferences.dart`
- Modify: `lib/data/preferences/shared_preferences_user_preferences_store.dart`
- Modify: `lib/app/weather_session.dart:493` (`_persistPreferences`)
- Test: `test/data/preferences/user_preferences_store_test.dart` (create)
- Test: `test/app/weather_session_preferences_test.dart` (create)

**Interfaces:**
- Consumes: `FlightRulesConfig` (Task 1).
- Produces: `UserPreferences.rulesConfig` (`FlightRulesConfig`, default `const FlightRulesConfig.defaults()`) + `copyWith({FlightRulesConfig? rulesConfig})`. Store key `aerocheck.rules_config` (JSON string).

- [ ] **Step 1: Write the failing tests**

```dart
// test/data/preferences/user_preferences_store_test.dart
import 'package:aerocheck/data/preferences/shared_preferences_user_preferences_store.dart';
import 'package:aerocheck/data/preferences/user_preferences.dart';
import 'package:aerocheck/domain/rules/flight_rules_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('saves and restores a custom rulesConfig', () async {
    final store = SharedPreferencesUserPreferencesStore();
    final config = const FlightRulesConfig.defaults().copyWith(windBlockedKmh: 33);
    await store.save(const UserPreferences().copyWith(rulesConfig: config));

    final restored = await store.load();
    expect(restored.rulesConfig.windBlockedKmh, 33);
  });

  test('defaults rulesConfig when nothing was saved', () async {
    final store = SharedPreferencesUserPreferencesStore();
    final restored = await store.load();
    expect(restored.rulesConfig, const FlightRulesConfig.defaults());
  });
}
```

```dart
// test/app/weather_session_preferences_test.dart
import 'package:aerocheck/app/weather_session.dart';
import 'package:aerocheck/data/preferences/user_preferences.dart';
import 'package:aerocheck/data/preferences/user_preferences_store.dart';
import 'package:aerocheck/domain/i18n/language.dart';
import 'package:aerocheck/domain/units/unit_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('changing guide radius keeps language and units', () async {
    final store = _RecordingStore();
    final session = WeatherSession(preferencesStore: store);
    await session.updateLanguage(Language.en);
    await session.updateUnits(const UnitPreferences(speed: SpeedUnit.mph));

    session.setGuideRadiusKm(8);
    await Future<void>.delayed(Duration.zero);

    expect(store.last!.language, Language.en);
    expect(store.last!.units.speed, SpeedUnit.mph);
  });
}

class _RecordingStore implements UserPreferencesStore {
  UserPreferences? last;
  @override
  Future<UserPreferences> load() async => const UserPreferences();
  @override
  Future<void> save(UserPreferences preferences) async => last = preferences;
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/data/preferences/user_preferences_store_test.dart test/app/weather_session_preferences_test.dart`
Expected: FAIL — `rulesConfig` getter undefined; recording store sees `language: es`/default units (current bug).

- [ ] **Step 3: Implement**

In `lib/data/preferences/user_preferences.dart` add the import and field:

```dart
import '../../domain/rules/flight_rules_config.dart';
```
Add constructor param `this.rulesConfig = const FlightRulesConfig.defaults(),`, the field `final FlightRulesConfig rulesConfig;`, the `copyWith` param `FlightRulesConfig? rulesConfig,`, and in the returned object `rulesConfig: rulesConfig ?? this.rulesConfig,`.

In `shared_preferences_user_preferences_store.dart` add:

```dart
import '../../domain/rules/flight_rules_config.dart';
```
```dart
static const _rulesConfigKey = 'aerocheck.rules_config';
```
In `load()`, before the `return`:

```dart
FlightRulesConfig rulesConfig = const FlightRulesConfig.defaults();
final rulesJson = preferences.getString(_rulesConfigKey);
if (rulesJson != null) {
  try {
    rulesConfig = FlightRulesConfig.fromJson(
      jsonDecode(rulesJson) as Map<String, dynamic>,
    );
  } catch (_) {
    // Keep defaults if corrupted.
  }
}
```
Add `rulesConfig: rulesConfig,` to the returned `UserPreferences`. In `save()`, add to the `Future.wait` list:

```dart
store.setString(_rulesConfigKey, jsonEncode(preferences.rulesConfig.toJson())),
```

In `lib/app/weather_session.dart`, replace the body of `_persistPreferences()` so it preserves all fields:

```dart
void _persistPreferences() {
  _userPreferences = _userPreferences.copyWith(
    selectedLocationId: _selectedLocation.id,
    favoriteLocationsJson:
        _favoriteLocations.map((location) => location.toJson()).toList(),
    guideRadiusKm: _guideRadiusKm,
    dataSourceName: _dataSource.name,
  );
  unawaited(_preferencesStore.save(_userPreferences).catchError((_) {}));
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/data/preferences/user_preferences_store_test.dart test/app/weather_session_preferences_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/preferences/user_preferences.dart lib/data/preferences/shared_preferences_user_preferences_store.dart lib/app/weather_session.dart test/data/preferences/user_preferences_store_test.dart test/app/weather_session_preferences_test.dart
git commit -m "feat: persist rulesConfig and stop dropping language/units on save"
```

---

### Task 3: Refactor `FlightReadinessEvaluator` + report to use `FlightRulesConfig`

**Files:**
- Modify: `lib/domain/rules/flight_readiness_evaluator.dart`
- Modify: `lib/domain/entities/flight_readiness_report.dart`
- Modify: `lib/data/mock/mock_flight_data.dart`
- Modify: `lib/app/weather_session.dart` (3 `evaluate(...)` callsites)
- Test: `test/domain/rules/flight_readiness_evaluator_test.dart` (rewrite)

**Interfaces:**
- Consumes: `FlightRulesConfig` (Task 1), `UserPreferences.rulesConfig` (Task 2).
- Produces: `FlightReadinessEvaluator.evaluate({required WeatherSnapshot weather, required FlightRulesConfig config, required FlightWindowRecommendation bestWindow})`. `FlightReadinessReport.config` (`FlightRulesConfig`) replaces `droneProfile`/`missionProfile`.

- [ ] **Step 1: Rewrite the evaluator test (failing)**

Replace the whole file `test/domain/rules/flight_readiness_evaluator_test.dart`:

```dart
import 'package:aerocheck/domain/entities/flight_window_recommendation.dart';
import 'package:aerocheck/domain/entities/weather_snapshot.dart';
import 'package:aerocheck/domain/rules/flight_readiness_evaluator.dart';
import 'package:aerocheck/domain/rules/flight_readiness_status.dart';
import 'package:aerocheck/domain/rules/flight_rules_config.dart';
import 'package:aerocheck/domain/rules/rule_severity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const evaluator = FlightReadinessEvaluator();
  const config = FlightRulesConfig.defaults();
  final bestWindow = FlightWindowRecommendation(
    start: DateTime(2026, 6, 17, 8),
    end: DateTime(2026, 6, 17, 10),
    score: 92,
    status: FlightReadinessStatus.ready,
    summary: 'Mejor ventana por viento bajo y buena visibilidad.',
  );

  WeatherSnapshot baseWeather({
    double? windKmh = 10,
    double? gustKmh = 16,
    double? precipitationProbability = 0,
    double? precipitationMmPerHour = 0,
    double? visibilityKm = 12,
    double? cloudBaseMeters = 400,
    double? temperatureC = 18,
    double? kpIndex = 2,
    bool isDaylight = true,
    bool isInsideRestrictedArea = false,
    bool isNearRestrictedArea = false,
  }) {
    return WeatherSnapshot(
      time: DateTime(2026, 6, 16, 9),
      locationLabel: 'Comodoro Rivadavia, Chubut',
      temperatureC: temperatureC,
      dewPointC: 8,
      windKmh: windKmh,
      gustKmh: gustKmh,
      windDirectionDegrees: 210,
      precipitationProbability: precipitationProbability,
      precipitationMmPerHour: precipitationMmPerHour,
      cloudCoverPercent: 30,
      cloudBaseMeters: cloudBaseMeters,
      visibilityKm: visibilityKm,
      kpIndex: kpIndex,
      isDaylight: isDaylight,
      isInsideRestrictedArea: isInsideRestrictedArea,
      isNearRestrictedArea: isNearRestrictedArea,
    );
  }

  test('returns ready when all rules are ok', () {
    final report = evaluator.evaluate(
      weather: baseWeather(),
      config: config,
      bestWindow: bestWindow,
    );
    expect(report.status, FlightReadinessStatus.ready);
    expect(report.score, 100);
  });

  test('returns caution when wind is in the warning band', () {
    final report = evaluator.evaluate(
      weather: baseWeather(windKmh: 24),
      config: config,
      bestWindow: bestWindow,
    );
    expect(report.status, FlightReadinessStatus.caution);
    expect(
      report.rules.singleWhere((r) => r.code == 'WIND_SPEED').severity,
      RuleSeverity.warning,
    );
  });

  test('a custom lower wind block flips the same weather to notReady', () {
    final report = evaluator.evaluate(
      weather: baseWeather(windKmh: 15),
      config: config.copyWith(windWarningKmh: 8, windBlockedKmh: 12),
      bestWindow: bestWindow,
    );
    expect(report.status, FlightReadinessStatus.notReady);
    expect(
      report.rules.singleWhere((r) => r.code == 'WIND_SPEED').threshold,
      12,
    );
  });

  test('night flight is blocked by default but allowed when enabled', () {
    final blocked = evaluator.evaluate(
      weather: baseWeather(isDaylight: false),
      config: config,
      bestWindow: bestWindow,
    );
    expect(
      blocked.rules.singleWhere((r) => r.code == 'DAYLIGHT').severity,
      RuleSeverity.blocked,
    );

    final allowed = evaluator.evaluate(
      weather: baseWeather(isDaylight: false),
      config: config.copyWith(allowNightFlight: true),
      bestWindow: bestWindow,
    );
    expect(
      allowed.rules.singleWhere((r) => r.code == 'DAYLIGHT').severity,
      RuleSeverity.ok,
    );
  });

  test('does not return ready when critical data is missing', () {
    final report = evaluator.evaluate(
      weather: baseWeather(windKmh: null),
      config: config,
      bestWindow: bestWindow,
    );
    expect(report.status, FlightReadinessStatus.notReady);
    expect(
      report.rules.singleWhere((r) => r.code == 'MISSING_DATA').severity,
      RuleSeverity.blocked,
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/rules/flight_readiness_evaluator_test.dart`
Expected: FAIL — `evaluate` has no `config` parameter.

- [ ] **Step 3: Implement the report change**

In `lib/domain/entities/flight_readiness_report.dart` remove the `drone_profile.dart` and `mission_profile.dart` imports, add `import '../rules/flight_rules_config.dart';`, and replace the two profile fields/params with one:

```dart
final FlightRulesConfig config;
```
(Constructor: replace `required this.droneProfile,` and `required this.missionProfile,` with `required this.config,`.)

- [ ] **Step 4: Implement the evaluator change**

In `lib/domain/rules/flight_readiness_evaluator.dart`: replace the entity imports with `import 'flight_rules_config.dart';`, change the signature, and route every rule through the config. Full new `evaluate` head and the changed rule helpers:

```dart
FlightReadinessReport evaluate({
  required WeatherSnapshot weather,
  required FlightRulesConfig config,
  required FlightWindowRecommendation bestWindow,
}) {
  final rules = <FlightRuleResult>[];

  rules.add(_missingData(weather));

  if (weather.windKmh != null) {
    rules.add(_thresholdRule(
      code: 'WIND_SPEED',
      value: weather.windKmh!,
      warning: config.windWarningKmh,
      blocked: config.windBlockedKmh,
      okTitle: 'Viento dentro del limite',
      warningTitle: 'Viento cerca del limite',
      blockedTitle: 'Viento sobre el limite',
      unit: 'km/h',
    ));
  }
  if (weather.gustKmh != null) {
    rules.add(_thresholdRule(
      code: 'WIND_GUST',
      value: weather.gustKmh!,
      warning: config.gustWarningKmh,
      blocked: config.gustBlockedKmh,
      okTitle: 'Rafagas dentro del limite',
      warningTitle: 'Rafagas cerca del limite',
      blockedTitle: 'Rafagas sobre el limite',
      unit: 'km/h',
    ));
  }
  if (weather.windKmh != null && weather.gustKmh != null) {
    rules.add(_gustSpread(weather.gustKmh! - weather.windKmh!, config));
  }
  if (weather.precipitationProbability != null) {
    rules.add(_precipitationProbability(weather.precipitationProbability!, config));
  }
  if (weather.precipitationMmPerHour != null) {
    rules.add(_precipitationIntensity(weather.precipitationMmPerHour!, config));
  }
  if (weather.visibilityKm != null) {
    rules.add(_visibility(weather.visibilityKm!, config));
  }
  if (weather.cloudBaseMeters != null) {
    rules.add(_cloudBase(weather.cloudBaseMeters!, config));
  }
  if (weather.temperatureC != null) {
    rules.add(_temperature(weather.temperatureC!, config));
  }
  if (weather.kpIndex != null) {
    rules.add(_kpIndex(weather.kpIndex!, config));
  }

  rules.add(_daylight(weather.isDaylight, config));
  rules.add(_restrictedArea(weather));

  final status = _statusFor(rules);
  final score = _scoreFor(rules);

  return FlightReadinessReport(
    status: status,
    score: score,
    summary: _summaryFor(status, rules),
    rules: rules,
    weather: weather,
    config: config,
    bestWindow: bestWindow,
  );
}
```

Replace `_thresholdRule` to take explicit warning/blocked:

```dart
FlightRuleResult _thresholdRule({
  required String code,
  required double value,
  required double warning,
  required double blocked,
  required String okTitle,
  required String warningTitle,
  required String blockedTitle,
  required String unit,
}) {
  final severity = value > blocked
      ? RuleSeverity.blocked
      : value > warning
          ? RuleSeverity.warning
          : RuleSeverity.ok;
  final title = switch (severity) {
    RuleSeverity.ok => okTitle,
    RuleSeverity.warning => warningTitle,
    RuleSeverity.blocked => blockedTitle,
  };
  return FlightRuleResult(
    code: code,
    severity: severity,
    title: title,
    details: '${_fmt(value)} $unit sobre limite de ${_fmt(blocked)} $unit.',
    measuredValue: value,
    threshold: blocked,
  );
}
```

Update the remaining helpers to read cutoffs from `config` (signatures change to accept `FlightRulesConfig config`):

```dart
FlightRuleResult _gustSpread(double spread, FlightRulesConfig config) {
  final severity = spread > config.gustSpreadBlockedKmh
      ? RuleSeverity.blocked
      : spread > config.gustSpreadWarningKmh
          ? RuleSeverity.warning
          : RuleSeverity.ok;
  return FlightRuleResult(
    code: 'GUST_SPREAD',
    severity: severity,
    title: switch (severity) {
      RuleSeverity.ok => 'Rafagas estables',
      RuleSeverity.warning => 'Variacion de rafagas relevante',
      RuleSeverity.blocked => 'Variacion de rafagas alta',
    },
    details: 'Diferencia entre viento y rafaga: ${_fmt(spread)} km/h.',
    measuredValue: spread,
    threshold: config.gustSpreadBlockedKmh,
  );
}

FlightRuleResult _precipitationProbability(double probability, FlightRulesConfig config) {
  final severity = probability >= config.precipProbabilityBlockedPercent
      ? RuleSeverity.blocked
      : probability >= config.precipProbabilityWarningPercent
          ? RuleSeverity.warning
          : RuleSeverity.ok;
  return FlightRuleResult(
    code: 'PRECIP_PROBABILITY',
    severity: severity,
    title: switch (severity) {
      RuleSeverity.ok => 'Baja probabilidad de lluvia',
      RuleSeverity.warning => 'Lluvia posible',
      RuleSeverity.blocked => 'Lluvia probable',
    },
    details: 'Probabilidad de lluvia: ${_fmt(probability)}%.',
    measuredValue: probability,
    threshold: config.precipProbabilityBlockedPercent,
  );
}

FlightRuleResult _precipitationIntensity(double intensity, FlightRulesConfig config) {
  final severity = intensity > config.precipIntensityBlockedMmPerHour
      ? RuleSeverity.blocked
      : intensity > config.precipIntensityWarningMmPerHour
          ? RuleSeverity.warning
          : RuleSeverity.ok;
  return FlightRuleResult(
    code: 'PRECIP_INTENSITY',
    severity: severity,
    title: switch (severity) {
      RuleSeverity.ok => 'Sin lluvia activa',
      RuleSeverity.warning => 'Llovizna o lluvia leve',
      RuleSeverity.blocked => 'Lluvia activa',
    },
    details: 'Intensidad de lluvia: ${_fmt(intensity)} mm/h.',
    measuredValue: intensity,
    threshold: config.precipIntensityBlockedMmPerHour,
  );
}

FlightRuleResult _visibility(double visibility, FlightRulesConfig config) {
  final severity = visibility < config.visibilityBlockedKm
      ? RuleSeverity.blocked
      : visibility < config.visibilityWarningKm
          ? RuleSeverity.warning
          : RuleSeverity.ok;
  return FlightRuleResult(
    code: 'VISIBILITY',
    severity: severity,
    title: switch (severity) {
      RuleSeverity.ok => 'Buena visibilidad',
      RuleSeverity.warning => 'Visibilidad reducida',
      RuleSeverity.blocked => 'Visibilidad insuficiente',
    },
    details:
        '${_fmt(visibility)} km disponibles; minimo ${_fmt(config.visibilityWarningKm)} km.',
    measuredValue: visibility,
    threshold: config.visibilityWarningKm,
  );
}

FlightRuleResult _cloudBase(double cloudBase, FlightRulesConfig config) {
  final okThreshold = config.targetAltitudeMeters + config.cloudBaseWarningMarginMeters;
  final blockedThreshold = config.targetAltitudeMeters + config.cloudBaseBlockedMarginMeters;
  final severity = cloudBase < blockedThreshold
      ? RuleSeverity.blocked
      : cloudBase < okThreshold
          ? RuleSeverity.warning
          : RuleSeverity.ok;
  return FlightRuleResult(
    code: 'CLOUD_BASE',
    severity: severity,
    title: switch (severity) {
      RuleSeverity.ok => 'Base de nubes suficiente',
      RuleSeverity.warning => 'Base de nubes cercana',
      RuleSeverity.blocked => 'Base de nubes baja',
    },
    details:
        'Base ${_fmt(cloudBase)} m; altura objetivo ${config.targetAltitudeMeters} m.',
    measuredValue: cloudBase,
    threshold: okThreshold.toDouble(),
  );
}

FlightRuleResult _temperature(double temperature, FlightRulesConfig config) {
  final severity = temperature < config.temperatureMinBlockedC ||
          temperature > config.temperatureMaxBlockedC
      ? RuleSeverity.blocked
      : temperature < config.temperatureMinWarningC ||
              temperature > config.temperatureMaxWarningC
          ? RuleSeverity.warning
          : RuleSeverity.ok;
  return FlightRuleResult(
    code: 'TEMPERATURE',
    severity: severity,
    title: switch (severity) {
      RuleSeverity.ok => 'Temperatura operativa',
      RuleSeverity.warning => 'Temperatura exigente',
      RuleSeverity.blocked => 'Temperatura extrema',
    },
    details: 'Temperatura: ${_fmt(temperature)} C.',
    measuredValue: temperature,
  );
}

FlightRuleResult _kpIndex(double kp, FlightRulesConfig config) {
  final severity = kp >= config.kpBlocked
      ? RuleSeverity.blocked
      : kp >= config.kpWarning
          ? RuleSeverity.warning
          : RuleSeverity.ok;
  return FlightRuleResult(
    code: 'KP_INDEX',
    severity: severity,
    title: switch (severity) {
      RuleSeverity.ok => 'Kp normal',
      RuleSeverity.warning => 'Actividad geomagnetica elevada',
      RuleSeverity.blocked => 'Actividad geomagnetica alta',
    },
    details: 'Indice Kp: ${_fmt(kp)}.',
    measuredValue: kp,
    threshold: config.kpBlocked,
  );
}

FlightRuleResult _daylight(bool isDaylight, FlightRulesConfig config) {
  final ok = isDaylight || config.allowNightFlight;
  return FlightRuleResult(
    code: 'DAYLIGHT',
    severity: ok ? RuleSeverity.ok : RuleSeverity.blocked,
    title: isDaylight
        ? 'Luz diurna disponible'
        : ok
            ? 'Vuelo nocturno habilitado'
            : 'Vuelo nocturno no habilitado',
    details: isDaylight
        ? 'La ventana esta dentro de horario diurno.'
        : ok
            ? 'Activaste vuelo nocturno en tus reglas. Verifica permisos.'
            : 'Activa vuelo nocturno solo si corresponde y tenes permiso.',
  );
}
```

(`_restrictedArea`, `_missingData`, `_statusFor`, `_scoreFor`, `_summaryFor`, `_fmt` are unchanged.)

- [ ] **Step 5: Update the callsites so the build compiles**

In `lib/data/mock/mock_flight_data.dart`: add `import '../../domain/rules/flight_rules_config.dart';`, add `static const rulesConfig = FlightRulesConfig.defaults();`, and change every `evaluator.evaluate(... droneProfile: ..., missionProfile: ...)` call to pass `config: rulesConfig` instead. Keep `droneProfile`/`missionProfile` consts only if still referenced elsewhere in the file; otherwise remove them.

In `lib/app/weather_session.dart`, change the three `_evaluator.evaluate(...)` / `_evaluator.evaluate` calls inside `currentReport`-path (`_evaluateWeather`), `_forecastRowFor`, and `bestWindowFor` to:

```dart
config: _userPreferences.rulesConfig,
```
removing the `droneProfile:`/`missionProfile:` args. Remove the now-unused `MockFlightData` profile references if any remain in that file.

- [ ] **Step 6: Run tests + analyze**

Run: `flutter test test/domain/rules/flight_readiness_evaluator_test.dart && flutter analyze`
Expected: PASS, no analyzer errors.

- [ ] **Step 7: Commit**

```bash
git add lib/domain/rules/flight_readiness_evaluator.dart lib/domain/entities/flight_readiness_report.dart lib/data/mock/mock_flight_data.dart lib/app/weather_session.dart test/domain/rules/flight_readiness_evaluator_test.dart
git commit -m "refactor: evaluator reads thresholds from FlightRulesConfig"
```

---

### Task 4: Refactor `WindProfileEvaluator` + Viento screen to use the config

**Files:**
- Modify: `lib/domain/rules/wind_profile_evaluator.dart`
- Modify: `lib/features/wind/wind_screen.dart:32-34, 147-149`
- Test: `test/domain/rules/wind_profile_evaluator_test.dart` (rewrite)

**Interfaces:**
- Consumes: `FlightRulesConfig`, `session.preferences.rulesConfig`.
- Produces: `WindProfileEvaluator({required FlightRulesConfig config})`; warning/blocked use `config.windWarningKmh/windBlockedKmh` and `config.gustWarningKmh/gustBlockedKmh`.

- [ ] **Step 1: Rewrite the test (failing)**

Replace `test/domain/rules/wind_profile_evaluator_test.dart`:

```dart
import 'package:aerocheck/data/mock/mock_flight_data.dart';
import 'package:aerocheck/domain/rules/flight_rules_config.dart';
import 'package:aerocheck/domain/rules/wind_profile_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const config = FlightRulesConfig.defaults(); // wind warn 22, block 28

  group('WindProfileEvaluator', () {
    test('marks blocked when wind exceeds the configured block', () {
      final evaluator = WindProfileEvaluator(config: config);
      final evaluated = evaluator.evaluateRow(const WindProfileRow(
        altitude: '100 m', windKmh: 50, gustKmh: 60, temperatureC: 20,
      ));
      expect(evaluated.status, 'blocked');
    });

    test('marks warning when wind is in the warning band', () {
      final evaluator = WindProfileEvaluator(config: config);
      final evaluated = evaluator.evaluateRow(const WindProfileRow(
        altitude: '100 m', windKmh: 24, gustKmh: 30, temperatureC: 20,
      ));
      expect(evaluated.status, 'warning');
    });

    test('marks ok when wind is below the warning band', () {
      final evaluator = WindProfileEvaluator(config: config);
      final evaluated = evaluator.evaluateRow(const WindProfileRow(
        altitude: '100 m', windKmh: 10, gustKmh: 15, temperatureC: 20,
      ));
      expect(evaluated.status, 'ok');
    });

    test('a custom lower block flips a previously-ok row to blocked', () {
      final evaluator = WindProfileEvaluator(
        config: config.copyWith(windWarningKmh: 6, windBlockedKmh: 9),
      );
      final evaluated = evaluator.evaluateRow(const WindProfileRow(
        altitude: '100 m', windKmh: 10, gustKmh: 12, temperatureC: 20,
      ));
      expect(evaluated.status, 'blocked');
    });

    test('finds best-wind altitude in profile', () {
      final evaluator = WindProfileEvaluator(config: config);
      final best = evaluator.findBestWindAltitude(const [
        WindProfileRow(altitude: '10 m', windKmh: 15, gustKmh: 22, temperatureC: 15),
        WindProfileRow(altitude: '50 m', windKmh: 8, gustKmh: 12, temperatureC: 14),
        WindProfileRow(altitude: '100 m', windKmh: 20, gustKmh: 28, temperatureC: 12),
      ]);
      expect(best.altitude, '50 m');
    });

    test('evaluates a real mock profile without error', () {
      final evaluator = WindProfileEvaluator(config: config);
      final rows = MockFlightData.windProfileRows();
      final evaluated = evaluator.evaluateProfile(rows);
      expect(evaluated, hasLength(rows.length));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/rules/wind_profile_evaluator_test.dart`
Expected: FAIL — `WindProfileEvaluator` has no `config` parameter.

- [ ] **Step 3: Implement the evaluator change**

In `lib/domain/rules/wind_profile_evaluator.dart`: replace the `drone_profile.dart`/`mission_profile.dart` imports with `import 'flight_rules_config.dart';`. Replace the constructor and fields:

```dart
class WindProfileEvaluator {
  const WindProfileEvaluator({required this.config});

  final FlightRulesConfig config;
```
Replace the body of `evaluateRow` threshold logic:

```dart
EvaluatedWindProfileRow evaluateRow(WindProfileRow row) {
  String status = 'ok';
  String? limitExceededAt;

  if (row.windKmh > config.windBlockedKmh) {
    status = 'blocked';
    limitExceededAt = 'wind';
  } else if (row.gustKmh > config.gustBlockedKmh) {
    status = 'blocked';
    limitExceededAt = 'gust';
  } else if (row.windKmh > config.windWarningKmh) {
    status = 'warning';
    limitExceededAt = 'wind';
  } else if (row.gustKmh > config.gustWarningKmh) {
    status = 'warning';
    limitExceededAt = 'gust';
  }

  return EvaluatedWindProfileRow(
    altitude: row.altitude,
    windKmh: row.windKmh,
    gustKmh: row.gustKmh,
    temperatureC: row.temperatureC,
    status: status,
    limitExceededAt: limitExceededAt,
    windDirectionDegrees: row.windDirectionDegrees,
  );
}
```
(`findBestWindAltitude` / `_scoreAltitude` unchanged.)

- [ ] **Step 4: Update the Viento screen**

In `lib/features/wind/wind_screen.dart` replace the evaluator construction (lines ~32-35):

```dart
final evaluator = WindProfileEvaluator(
  config: session.preferences.rulesConfig,
);
```
and the target-altitude comparison (lines ~146-149):

```dart
isTarget: _altitudeMeters(row.altitude) ==
    session.preferences.rulesConfig.targetAltitudeMeters,
```
Remove the now-unused `MockFlightData` import if the analyzer flags it.

- [ ] **Step 5: Run tests + analyze**

Run: `flutter test test/domain/rules/wind_profile_evaluator_test.dart && flutter analyze`
Expected: PASS, no analyzer errors.

- [ ] **Step 6: Commit**

```bash
git add lib/domain/rules/wind_profile_evaluator.dart lib/features/wind/wind_screen.dart test/domain/rules/wind_profile_evaluator_test.dart
git commit -m "refactor: wind profile evaluator reads from FlightRulesConfig"
```

---

### Task 5: `WeatherSession.updateRulesConfig` + propagation

**Files:**
- Modify: `lib/app/weather_session.dart`
- Test: `test/app/weather_session_rules_test.dart` (create)

**Interfaces:**
- Consumes: `FlightRulesConfig`, `UserPreferences.copyWith(rulesConfig:)`.
- Produces: `Future<void> WeatherSession.updateRulesConfig(FlightRulesConfig config)` — guards on equality, persists via store, `notifyListeners()`.

- [ ] **Step 1: Write the failing test**

```dart
// test/app/weather_session_rules_test.dart
import 'package:aerocheck/app/weather_session.dart';
import 'package:aerocheck/data/preferences/user_preferences.dart';
import 'package:aerocheck/data/preferences/user_preferences_store.dart';
import 'package:aerocheck/domain/rules/flight_rules_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('updateRulesConfig persists and notifies', () async {
    final store = _RecordingStore();
    final session = WeatherSession(preferencesStore: store);
    var notified = 0;
    session.addListener(() => notified++);

    final config = const FlightRulesConfig.defaults().copyWith(windBlockedKmh: 31);
    await session.updateRulesConfig(config);

    expect(session.preferences.rulesConfig.windBlockedKmh, 31);
    expect(store.last!.rulesConfig.windBlockedKmh, 31);
    expect(notified, greaterThan(0));
  });
}

class _RecordingStore implements UserPreferencesStore {
  UserPreferences? last;
  @override
  Future<UserPreferences> load() async => const UserPreferences();
  @override
  Future<void> save(UserPreferences preferences) async => last = preferences;
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/app/weather_session_rules_test.dart`
Expected: FAIL — `updateRulesConfig` is undefined.

- [ ] **Step 3: Implement**

In `lib/app/weather_session.dart`, add `import '../domain/rules/flight_rules_config.dart';` and, next to `updateUnits`:

```dart
Future<void> updateRulesConfig(FlightRulesConfig config) async {
  if (_userPreferences.rulesConfig == config) {
    return;
  }
  _userPreferences = _userPreferences.copyWith(rulesConfig: config);
  await _preferencesStore.save(_userPreferences);
  notifyListeners();
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/app/weather_session_rules_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/app/weather_session.dart test/app/weather_session_rules_test.dart
git commit -m "feat: add WeatherSession.updateRulesConfig"
```

---

### Task 6: "Reglas de vuelo" Settings screen

**Files:**
- Create: `lib/features/settings/screens/flight_rules_screen.dart`
- Modify: `lib/features/settings/settings_screen.dart` (add `reglas` view + list entry)
- Modify: `lib/domain/i18n/app_strings.dart` (new es/en keys)
- Test: `test/features/settings/flight_rules_screen_test.dart` (create)

**Interfaces:**
- Consumes: `FlightRulesConfig`, `UnitPreferences`, `UnitConverters`, `Language`, `AppStrings`, `session.updateRulesConfig`.
- Produces: `FlightRulesScreen({required FlightRulesConfig initialConfig, required UnitPreferences units, required Language language, required void Function(FlightRulesConfig) onSave, required VoidCallback onBack})`.

- [ ] **Step 1: Add i18n keys**

In `lib/domain/i18n/app_strings.dart`, add to BOTH the `'es'` and `'en'` maps:

```dart
// es
'reglas_de_vuelo': 'Reglas de vuelo',
'reglas_subtitulo': 'Personalizá los umbrales que deciden APTO, PRECAUCIÓN y NO APTO.',
'rafagas': 'Ráfagas',
'viento_sostenido': 'Viento sostenido',
'dif_rafaga_viento': 'Diferencia ráfaga-viento',
'prob_lluvia': 'Probabilidad de lluvia',
'intensidad_lluvia': 'Intensidad de lluvia',
'visibilidad': 'Visibilidad',
'altitud_objetivo': 'Altitud objetivo',
'margen_base_nubes': 'Margen base de nubes',
'temp_minima': 'Temperatura mínima',
'temp_maxima': 'Temperatura máxima',
'indice_kp': 'Índice Kp (GPS)',
'permitir_nocturno': 'Permitir vuelo nocturno',
'visibilidad_nubes': 'Visibilidad y nubes',
'ambientales': 'Ambientales',
'operativas': 'Operativas',
'bloqueo': 'Bloqueo',
'restaurar_defaults': 'Restaurar valores por defecto',
'aviso_no_oficial': 'AeroCheck ayuda a planificar. No es autorización oficial de vuelo.',
```
```dart
// en
'reglas_de_vuelo': 'Flight rules',
'reglas_subtitulo': 'Customize the thresholds that decide SUITABLE, CAUTION and NOT SUITABLE.',
'rafagas': 'Gusts',
'viento_sostenido': 'Sustained wind',
'dif_rafaga_viento': 'Gust-wind spread',
'prob_lluvia': 'Rain probability',
'intensidad_lluvia': 'Rain intensity',
'visibilidad': 'Visibility',
'altitud_objetivo': 'Target altitude',
'margen_base_nubes': 'Cloud base margin',
'temp_minima': 'Minimum temperature',
'temp_maxima': 'Maximum temperature',
'indice_kp': 'Kp index (GPS)',
'permitir_nocturno': 'Allow night flight',
'visibilidad_nubes': 'Visibility & clouds',
'ambientales': 'Environmental',
'operativas': 'Operational',
'bloqueo': 'Block',
'restaurar_defaults': 'Restore defaults',
'aviso_no_oficial': 'AeroCheck helps you plan. It is not official flight authorization.',
```

- [ ] **Step 2: Write the failing widget test**

```dart
// test/features/settings/flight_rules_screen_test.dart
import 'package:aerocheck/domain/i18n/language.dart';
import 'package:aerocheck/domain/rules/flight_rules_config.dart';
import 'package:aerocheck/domain/units/unit_preferences.dart';
import 'package:aerocheck/features/settings/screens/flight_rules_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host({
    required void Function(FlightRulesConfig) onSave,
    VoidCallback? onBack,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: FlightRulesScreen(
          initialConfig: const FlightRulesConfig.defaults(),
          units: const UnitPreferences(),
          language: Language.es,
          onSave: onSave,
          onBack: onBack ?? () {},
        ),
      ),
    );
  }

  testWidgets('renders the title and section headers', (tester) async {
    await tester.pumpWidget(host(onSave: (_) {}));
    expect(find.text('Reglas de vuelo'), findsOneWidget);
    expect(find.text('Viento'), findsWidgets);
  });

  testWidgets('increment then save returns a higher wind block', (tester) async {
    FlightRulesConfig? saved;
    await tester.pumpWidget(host(onSave: (c) => saved = c));

    await tester.tap(find.byKey(const ValueKey('plus-windBlockedKmh')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('flight-rules-save')));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.windBlockedKmh, greaterThan(28));
  });

  testWidgets('restore defaults reverts edits', (tester) async {
    FlightRulesConfig? saved;
    await tester.pumpWidget(host(onSave: (c) => saved = c));

    await tester.tap(find.byKey(const ValueKey('plus-windBlockedKmh')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('flight-rules-restore')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('flight-rules-save')));
    await tester.pump();

    expect(saved, const FlightRulesConfig.defaults());
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/features/settings/flight_rules_screen_test.dart`
Expected: FAIL — `flight_rules_screen.dart` does not exist.

- [ ] **Step 4: Implement the screen**

Create `lib/features/settings/screens/flight_rules_screen.dart`. The screen keeps a working-copy `config`, renders grouped `_StepperRow`s, and converts metric↔display via `UnitConverters`. Each row gets stable keys `plus-<field>` / `minus-<field>` / `value-<field>`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/i18n/app_strings.dart';
import '../../../domain/i18n/language.dart';
import '../../../domain/rules/flight_rules_config.dart';
import '../../../domain/units/unit_converters.dart';
import '../../../domain/units/unit_preferences.dart';

class FlightRulesScreen extends StatefulWidget {
  const FlightRulesScreen({
    super.key,
    required this.initialConfig,
    required this.units,
    required this.language,
    required this.onSave,
    required this.onBack,
  });

  final FlightRulesConfig initialConfig;
  final UnitPreferences units;
  final Language language;
  final void Function(FlightRulesConfig) onSave;
  final VoidCallback onBack;

  @override
  State<FlightRulesScreen> createState() => _FlightRulesScreenState();
}

class _FlightRulesScreenState extends State<FlightRulesScreen> {
  late FlightRulesConfig config;

  @override
  void initState() {
    super.initState();
    config = widget.initialConfig;
  }

  String _t(String key) => AppStrings.get(key, language: widget.language);

  // Display helpers: metric value -> shown number in user units.
  double _speed(double kmh) =>
      UnitConverters.convertSpeed(kmh, SpeedUnit.kmh, widget.units.speed);
  double _speedToMetric(double shown) =>
      UnitConverters.convertSpeed(shown, widget.units.speed, SpeedUnit.kmh);
  double _dist(double km) =>
      UnitConverters.convertDistance(km, DistanceUnit.km, widget.units.distance);
  double _distToMetric(double shown) =>
      UnitConverters.convertDistance(shown, widget.units.distance, DistanceUnit.km);
  double _alt(double m) =>
      UnitConverters.convertAltitude(m, AltitudeUnit.m, widget.units.altitude);
  double _altToMetric(double shown) =>
      UnitConverters.convertAltitude(shown, widget.units.altitude, AltitudeUnit.m);
  double _temp(double c) =>
      UnitConverters.convertTemperature(c, TemperatureUnit.c, widget.units.temperature);
  double _tempToMetric(double shown) =>
      UnitConverters.convertTemperature(shown, widget.units.temperature, TemperatureUnit.c);

  @override
  Widget build(BuildContext context) {
    final speedUnit = widget.units.speed.shortName;
    final distUnit = widget.units.distance.shortName;
    final altUnit = widget.units.altitude.shortName;
    final tempUnit = widget.units.temperature.shortName;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Text(
          _t('reglas_de_vuelo'),
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(_t('reglas_subtitulo'),
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        const SizedBox(height: 18),

        _section(_t('viento')),
        _stepperPair(
          label: _t('viento_sostenido'), unit: speedUnit, decimals: 0, step: 1,
          warnField: 'windWarningKmh', blockField: 'windBlockedKmh',
          warn: _speed(config.windWarningKmh), block: _speed(config.windBlockedKmh),
          onWarn: (v) => _set((c) => c.copyWith(windWarningKmh: _speedToMetric(v))),
          onBlock: (v) => _set((c) => c.copyWith(windBlockedKmh: _speedToMetric(v))),
        ),
        _stepperPair(
          label: _t('rafagas'), unit: speedUnit, decimals: 0, step: 1,
          warnField: 'gustWarningKmh', blockField: 'gustBlockedKmh',
          warn: _speed(config.gustWarningKmh), block: _speed(config.gustBlockedKmh),
          onWarn: (v) => _set((c) => c.copyWith(gustWarningKmh: _speedToMetric(v))),
          onBlock: (v) => _set((c) => c.copyWith(gustBlockedKmh: _speedToMetric(v))),
        ),
        _stepperPair(
          label: _t('dif_rafaga_viento'), unit: speedUnit, decimals: 0, step: 1,
          warnField: 'gustSpreadWarningKmh', blockField: 'gustSpreadBlockedKmh',
          warn: _speed(config.gustSpreadWarningKmh),
          block: _speed(config.gustSpreadBlockedKmh),
          onWarn: (v) => _set((c) => c.copyWith(gustSpreadWarningKmh: _speedToMetric(v))),
          onBlock: (v) => _set((c) => c.copyWith(gustSpreadBlockedKmh: _speedToMetric(v))),
        ),

        _section(_t('precipitacion')),
        _stepperPair(
          label: _t('prob_lluvia'), unit: '%', decimals: 0, step: 5,
          warnField: 'precipProbabilityWarningPercent',
          blockField: 'precipProbabilityBlockedPercent',
          warn: config.precipProbabilityWarningPercent,
          block: config.precipProbabilityBlockedPercent,
          onWarn: (v) => _set((c) => c.copyWith(precipProbabilityWarningPercent: v)),
          onBlock: (v) => _set((c) => c.copyWith(precipProbabilityBlockedPercent: v)),
        ),
        _stepperPair(
          label: _t('intensidad_lluvia'), unit: 'mm/h', decimals: 1, step: 0.1,
          warnField: 'precipIntensityWarningMmPerHour',
          blockField: 'precipIntensityBlockedMmPerHour',
          warn: config.precipIntensityWarningMmPerHour,
          block: config.precipIntensityBlockedMmPerHour,
          onWarn: (v) => _set((c) => c.copyWith(precipIntensityWarningMmPerHour: v)),
          onBlock: (v) => _set((c) => c.copyWith(precipIntensityBlockedMmPerHour: v)),
        ),

        _section(_t('visibilidad_nubes')),
        _stepperPair(
          label: _t('visibilidad'), unit: distUnit, decimals: 1, step: 0.5,
          warnField: 'visibilityWarningKm', blockField: 'visibilityBlockedKm',
          warn: _dist(config.visibilityWarningKm), block: _dist(config.visibilityBlockedKm),
          onWarn: (v) => _set((c) => c.copyWith(visibilityWarningKm: _distToMetric(v))),
          onBlock: (v) => _set((c) => c.copyWith(visibilityBlockedKm: _distToMetric(v))),
        ),
        _stepperSingle(
          label: _t('altitud_objetivo'), unit: altUnit, decimals: 0, step: 10,
          field: 'targetAltitudeMeters', value: _alt(config.targetAltitudeMeters.toDouble()),
          onChanged: (v) => _set((c) =>
              c.copyWith(targetAltitudeMeters: _altToMetric(v).round())),
        ),

        _section(_t('ambientales')),
        _stepperPair(
          label: _t('temp_minima'), unit: tempUnit, decimals: 0, step: 1,
          warnField: 'temperatureMinWarningC', blockField: 'temperatureMinBlockedC',
          warn: _temp(config.temperatureMinWarningC),
          block: _temp(config.temperatureMinBlockedC),
          onWarn: (v) => _set((c) => c.copyWith(temperatureMinWarningC: _tempToMetric(v))),
          onBlock: (v) => _set((c) => c.copyWith(temperatureMinBlockedC: _tempToMetric(v))),
        ),
        _stepperPair(
          label: _t('temp_maxima'), unit: tempUnit, decimals: 0, step: 1,
          warnField: 'temperatureMaxWarningC', blockField: 'temperatureMaxBlockedC',
          warn: _temp(config.temperatureMaxWarningC),
          block: _temp(config.temperatureMaxBlockedC),
          onWarn: (v) => _set((c) => c.copyWith(temperatureMaxWarningC: _tempToMetric(v))),
          onBlock: (v) => _set((c) => c.copyWith(temperatureMaxBlockedC: _tempToMetric(v))),
        ),
        _stepperPair(
          label: _t('indice_kp'), unit: '', decimals: 1, step: 0.5,
          warnField: 'kpWarning', blockField: 'kpBlocked',
          warn: config.kpWarning, block: config.kpBlocked,
          onWarn: (v) => _set((c) => c.copyWith(kpWarning: v)),
          onBlock: (v) => _set((c) => c.copyWith(kpBlocked: v)),
        ),

        _section(_t('operativas')),
        SwitchListTile(
          key: const ValueKey('toggle-allowNightFlight'),
          contentPadding: EdgeInsets.zero,
          title: Text(_t('permitir_nocturno')),
          value: config.allowNightFlight,
          onChanged: (v) => _set((c) => c.copyWith(allowNightFlight: v)),
        ),

        const SizedBox(height: 8),
        Text(_t('aviso_no_oficial'),
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        const SizedBox(height: 16),
        TextButton(
          key: const ValueKey('flight-rules-restore'),
          onPressed: () => setState(() => config = const FlightRulesConfig.defaults()),
          child: Text(_t('restaurar_defaults')),
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onBack,
                child: Text(_t('cancelar')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                key: const ValueKey('flight-rules-save'),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
                onPressed: () => widget.onSave(config),
                child: Text(_t('guardar')),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _set(FlightRulesConfig Function(FlightRulesConfig) update) {
    setState(() => config = update(config));
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
        child: Text(title,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
      );

  Widget _stepperSingle({
    required String label,
    required String unit,
    required int decimals,
    required double step,
    required String field,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return _StepperRow(
      label: label,
      sublabel: null,
      unit: unit,
      decimals: decimals,
      step: step,
      field: field,
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _stepperPair({
    required String label,
    required String unit,
    required int decimals,
    required double step,
    required String warnField,
    required String blockField,
    required double warn,
    required double block,
    required ValueChanged<double> onWarn,
    required ValueChanged<double> onBlock,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        ),
        _StepperRow(
          label: _t('precaucion'),
          sublabel: null,
          unit: unit, decimals: decimals, step: step,
          field: warnField, value: warn, onChanged: onWarn,
        ),
        _StepperRow(
          label: _t('bloqueo'),
          sublabel: null,
          unit: unit, decimals: decimals, step: step,
          field: blockField, value: block, onChanged: onBlock,
        ),
      ],
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.sublabel,
    required this.unit,
    required this.decimals,
    required this.step,
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String? sublabel;
  final String unit;
  final int decimals;
  final double step;
  final String field;
  final double value;
  final ValueChanged<double> onChanged;

  String get _shown => decimals == 0
      ? value.round().toString()
      : value.toStringAsFixed(decimals);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          IconButton(
            key: ValueKey('minus-$field'),
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => onChanged(_clampStep(value - step)),
          ),
          GestureDetector(
            onTap: () => _editExact(context),
            child: SizedBox(
              width: 70,
              child: Text('$_shown $unit',
                  key: ValueKey('value-$field'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
          IconButton(
            key: ValueKey('plus-$field'),
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => onChanged(value + step),
          ),
        ],
      ),
    );
  }

  double _clampStep(double v) => v < 0 ? 0 : v;

  Future<void> _editExact(BuildContext context) async {
    final controller = TextEditingController(text: _shown);
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, double.tryParse(controller.text)),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result != null) onChanged(_clampStep(result));
  }
}
```

- [ ] **Step 5: Wire the screen into Settings**

In `lib/features/settings/settings_screen.dart`: add `import 'screens/flight_rules_screen.dart';`, add `reglas` to the `_SettingsView` enum, add a list tile that does `setState(() => _activeView = _SettingsView.reglas)` with title `AppStrings.get('reglas_de_vuelo', language: ...)`, and in the view switch render:

```dart
case _SettingsView.reglas:
  return FlightRulesScreen(
    initialConfig: session.preferences.rulesConfig,
    units: session.preferences.units,
    language: session.preferences.language,
    onSave: (config) {
      session.updateRulesConfig(config);
      setState(() => _activeView = _SettingsView.main);
    },
    onBack: () => setState(() => _activeView = _SettingsView.main),
  );
```
(Match the exact field/getter names already used by the neighbouring `unidades` case — e.g. `session`/`widget.session` and the enum-switch style in that file.)

- [ ] **Step 6: Run the widget test + analyze**

Run: `flutter test test/features/settings/flight_rules_screen_test.dart && flutter analyze`
Expected: PASS, no analyzer errors.

- [ ] **Step 7: Commit**

```bash
git add lib/features/settings/screens/flight_rules_screen.dart lib/features/settings/settings_screen.dart lib/domain/i18n/app_strings.dart test/features/settings/flight_rules_screen_test.dart
git commit -m "feat: add editable Flight Rules settings screen"
```

---

### Task 7: Full suite green + format

**Files:** none (verification).

- [ ] **Step 1: Format**

Run: `dart format lib test docs`

- [ ] **Step 2: Full test run**

Run: `flutter test`
Expected: all tests PASS. If a previously-passing test referenced `DroneProfile`/`MissionProfile` through the evaluator, update it to the config API (search `droneProfile:`/`missionProfile:` in `test/`).

- [ ] **Step 3: Analyze**

Run: `flutter analyze`
Expected: no errors. Remove any unused imports it flags (e.g. `MockFlightData` in `wind_screen.dart`).

- [ ] **Step 4: Confirm no secrets/build outputs staged**

Run: `git status --porcelain`
Expected: only source/test/doc files from this plan.

- [ ] **Step 5: Commit any formatting**

```bash
git add -A
git commit -m "style: format flight rules config feature"
```

---

## Self-Review

- **Spec coverage:** model (T1) · persistence + `_persistPreferences` bug (T2) · evaluator refactor + report (T3) · wind evaluator + Viento (T4) · session wiring (T5) · UI/i18n/units/reset (T6) · format+analyze close-out (T7). All spec sections mapped.
- **Placeholders:** none — each step ships real code/commands.
- **Type consistency:** `FlightRulesConfig` field names are reused verbatim across T1/T3/T4/T6; `evaluate({weather, config, bestWindow})` and `WindProfileEvaluator({config})` match between implementation and tests; `FlightReadinessReport.config` replaces both profile fields and no remaining reader references `report.droneProfile`/`report.missionProfile` (only the entity defined them).
- **Open follow-up (not in scope):** Viento screen still shows a hardcoded `122 m` max-altitude stat (`wind_screen.dart:84`); unrelated to rules config, left untouched.

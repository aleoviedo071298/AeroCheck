# Flight Rules Screen UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restyle the "Reglas de vuelo" settings screen into Units-style section cards with severity badges, and add a Precaución ≤ Bloqueo coherence guard — without touching the config, evaluators, persistence, or decision logic.

**Architecture:** Presentational refactor of a single file, `lib/features/settings/screens/flight_rules_screen.dart`. The flat list becomes one `Card` per category (`_sectionCard`) with an icon header; each two-cutoff parameter (`_thresholdParam`) renders its name plus two stepper rows whose left label is a colored severity badge (`_severityBadge`). The existing `_StepperRow` keeps the `−`/`+` and tap-to-type mechanics; its `label` becomes a `Widget`. A polarity-aware soft clamp (`_clampWarn`/`_clampBlock`) keeps warning and block thresholds coherent.

**Tech Stack:** Flutter, Dart, existing `UnitConverters`/`AppStrings`. No new dependencies.

## Global Constraints

- No changes to `FlightRulesConfig`, `FlightReadinessEvaluator`, `WindProfileEvaluator`, persistence, or `WeatherSession`. Presentational only.
- All thresholds stored in METRIC; convert for display, convert back on input. Coherence clamp runs in metric.
- Preserve widget keys verbatim: `plus-<field>`, `minus-<field>`, `value-<field>`, `flight-rules-save`, `flight-rules-restore`, `toggle-allowNightFlight`.
- Badge colors — Precaución (amber): light bg `0xFFFAEEDA` / text `0xFF633806`; Bloqueo (red): light bg `0xFFFCEBEB` / text `0xFF791F1F`. Dark variants required (translucent tint + light text).
- Section card palette mirrors `units_screen.dart`: dark card `0xFF1E293B`, dark border `0xFF334155`; light card `Colors.white`, light border `0xFFE2E8F0`. Teal accent `0xFF0F766E`.
- Coherence polarity — Precaución ≤ Bloqueo for: wind, gusts, gust spread, rain probability, rain intensity, max temperature, Kp. Precaución ≥ Bloqueo (inverted) for: visibility, min temperature, cloud-base margin.
- All user-facing strings via `AppStrings.get(key, language:)`; new keys (if any) added to both `es` and `en`. No new keys are expected.
- Run before commit: `dart format lib test`, `flutter test`, `flutter analyze`.

---

### Task 1: Redesign the screen (section cards + badges + coherence guard)

**Files:**
- Modify (full rewrite): `lib/features/settings/screens/flight_rules_screen.dart`
- Test: `test/features/settings/flight_rules_screen_test.dart` (add 3 tests; keep the existing 4)

**Interfaces:**
- Consumes: `FlightRulesConfig` (all existing fields + `copyWith`), `UnitConverters`, `AppStrings`, `Language`, `UnitPreferences`. Screen constructor unchanged: `FlightRulesScreen({required FlightRulesConfig initialConfig, required UnitPreferences units, required Language language, required void Function(FlightRulesConfig) onSave, required VoidCallback onBack})`.
- Produces: same public widget + same widget keys. New private helpers `_sectionCard`, `_severityBadge`, `_thresholdParam`, `_singleParam`, `_clampWarn`, `_clampBlock`; `_StepperRow.label` is now `Widget`.

- [ ] **Step 1: Add the 3 new tests (RED)**

Append these inside `main()` in `test/features/settings/flight_rules_screen_test.dart` (keep the existing 4 tests unchanged):

```dart
  testWidgets('renders severity badges for parameters', (tester) async {
    await tester.pumpWidget(host(onSave: (_) {}));
    expect(find.text('Precaución'), findsWidgets);
    expect(find.text('Bloqueo'), findsWidgets);
  });

  testWidgets('warning cannot exceed block (direct polarity)', (tester) async {
    FlightRulesConfig? saved;
    await tester.pumpWidget(host(onSave: (c) => saved = c));

    // Default wind warning 22, block 28. Raising warning past block clamps it.
    for (var i = 0; i < 12; i++) {
      await tester.tap(find.byKey(const ValueKey('plus-windWarningKmh')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const ValueKey('flight-rules-save')));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.windWarningKmh, lessThanOrEqualTo(saved!.windBlockedKmh));
  });

  testWidgets('warning cannot drop below block (inverted polarity)', (
    tester,
  ) async {
    FlightRulesConfig? saved;
    await tester.pumpWidget(host(onSave: (c) => saved = c));

    // Visibility is inverted: warning (4 km) must stay >= block (2.8 km).
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('minus-visibilityWarningKm')),
      100,
    );
    await tester.pump();
    for (var i = 0; i < 8; i++) {
      await tester.tap(find.byKey(const ValueKey('minus-visibilityWarningKm')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const ValueKey('flight-rules-save')));
    await tester.pump();

    expect(saved, isNotNull);
    expect(
      saved!.visibilityWarningKm,
      greaterThanOrEqualTo(saved!.visibilityBlockedKm),
    );
  });
```

- [ ] **Step 2: Run the tests to verify the new ones fail**

Run: `flutter test test/features/settings/flight_rules_screen_test.dart`
Expected: the 3 new tests FAIL — badges not found yet; `plus-windWarningKmh` is currently keyed but raising it past block is not clamped (warning would exceed block); visibility warning not clamped. The existing 4 still pass.

- [ ] **Step 3: Rewrite the screen file**

Replace the entire contents of `lib/features/settings/screens/flight_rules_screen.dart` with:

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
  double _dist(double km) => UnitConverters.convertDistance(
    km,
    DistanceUnit.km,
    widget.units.distance,
  );
  double _distToMetric(double shown) => UnitConverters.convertDistance(
    shown,
    widget.units.distance,
    DistanceUnit.km,
  );
  double _alt(double m) =>
      UnitConverters.convertAltitude(m, AltitudeUnit.m, widget.units.altitude);
  double _altToMetric(double shown) => UnitConverters.convertAltitude(
    shown,
    widget.units.altitude,
    AltitudeUnit.m,
  );
  double _temp(double c) => UnitConverters.convertTemperature(
    c,
    TemperatureUnit.c,
    widget.units.temperature,
  );
  double _tempToMetric(double shown) => UnitConverters.convertTemperature(
    shown,
    widget.units.temperature,
    TemperatureUnit.c,
  );

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  // Coherence clamps (metric). inverted == true means Precaución >= Bloqueo.
  double _clampWarn(double v, double block, bool inverted) =>
      inverted ? (v < block ? block : v) : (v > block ? block : v);
  double _clampBlock(double v, double warn, bool inverted) =>
      inverted ? (v > warn ? warn : v) : (v < warn ? warn : v);

  @override
  Widget build(BuildContext context) {
    final speedUnit = widget.units.speed.shortName;
    final distUnit = widget.units.distance.shortName;
    final altUnit = widget.units.altitude.shortName;
    final tempUnit = widget.units.temperature.shortName;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            children: [
              Text(
                _t('reglas_de_vuelo'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _t('reglas_subtitulo'),
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 18),

              _sectionCard(
                icon: Icons.air_rounded,
                title: _t('viento'),
                children: [
                  _thresholdParam(
                    name: _t('viento_sostenido'),
                    unit: speedUnit,
                    decimals: 0,
                    step: 1,
                    warnField: 'windWarningKmh',
                    blockField: 'windBlockedKmh',
                    warn: _speed(config.windWarningKmh),
                    block: _speed(config.windBlockedKmh),
                    onWarn: (v) => _set(
                      (c) => c.copyWith(
                        windWarningKmh: _clampWarn(
                          _speedToMetric(v),
                          c.windBlockedKmh,
                          false,
                        ),
                      ),
                    ),
                    onBlock: (v) => _set(
                      (c) => c.copyWith(
                        windBlockedKmh: _clampBlock(
                          _speedToMetric(v),
                          c.windWarningKmh,
                          false,
                        ),
                      ),
                    ),
                  ),
                  _divider(),
                  _thresholdParam(
                    name: _t('rafagas'),
                    unit: speedUnit,
                    decimals: 0,
                    step: 1,
                    warnField: 'gustWarningKmh',
                    blockField: 'gustBlockedKmh',
                    warn: _speed(config.gustWarningKmh),
                    block: _speed(config.gustBlockedKmh),
                    onWarn: (v) => _set(
                      (c) => c.copyWith(
                        gustWarningKmh: _clampWarn(
                          _speedToMetric(v),
                          c.gustBlockedKmh,
                          false,
                        ),
                      ),
                    ),
                    onBlock: (v) => _set(
                      (c) => c.copyWith(
                        gustBlockedKmh: _clampBlock(
                          _speedToMetric(v),
                          c.gustWarningKmh,
                          false,
                        ),
                      ),
                    ),
                  ),
                  _divider(),
                  _thresholdParam(
                    name: _t('dif_rafaga_viento'),
                    unit: speedUnit,
                    decimals: 0,
                    step: 1,
                    warnField: 'gustSpreadWarningKmh',
                    blockField: 'gustSpreadBlockedKmh',
                    warn: _speed(config.gustSpreadWarningKmh),
                    block: _speed(config.gustSpreadBlockedKmh),
                    onWarn: (v) => _set(
                      (c) => c.copyWith(
                        gustSpreadWarningKmh: _clampWarn(
                          _speedToMetric(v),
                          c.gustSpreadBlockedKmh,
                          false,
                        ),
                      ),
                    ),
                    onBlock: (v) => _set(
                      (c) => c.copyWith(
                        gustSpreadBlockedKmh: _clampBlock(
                          _speedToMetric(v),
                          c.gustSpreadWarningKmh,
                          false,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              _sectionCard(
                icon: Icons.water_drop_outlined,
                title: _t('precipitacion'),
                children: [
                  _thresholdParam(
                    name: _t('prob_lluvia'),
                    unit: '%',
                    decimals: 0,
                    step: 5,
                    warnField: 'precipProbabilityWarningPercent',
                    blockField: 'precipProbabilityBlockedPercent',
                    warn: config.precipProbabilityWarningPercent,
                    block: config.precipProbabilityBlockedPercent,
                    onWarn: (v) => _set(
                      (c) => c.copyWith(
                        precipProbabilityWarningPercent: _clampWarn(
                          v,
                          c.precipProbabilityBlockedPercent,
                          false,
                        ),
                      ),
                    ),
                    onBlock: (v) => _set(
                      (c) => c.copyWith(
                        precipProbabilityBlockedPercent: _clampBlock(
                          v,
                          c.precipProbabilityWarningPercent,
                          false,
                        ),
                      ),
                    ),
                  ),
                  _divider(),
                  _thresholdParam(
                    name: _t('intensidad_lluvia'),
                    unit: 'mm/h',
                    decimals: 1,
                    step: 0.1,
                    warnField: 'precipIntensityWarningMmPerHour',
                    blockField: 'precipIntensityBlockedMmPerHour',
                    warn: config.precipIntensityWarningMmPerHour,
                    block: config.precipIntensityBlockedMmPerHour,
                    onWarn: (v) => _set(
                      (c) => c.copyWith(
                        precipIntensityWarningMmPerHour: _clampWarn(
                          v,
                          c.precipIntensityBlockedMmPerHour,
                          false,
                        ),
                      ),
                    ),
                    onBlock: (v) => _set(
                      (c) => c.copyWith(
                        precipIntensityBlockedMmPerHour: _clampBlock(
                          v,
                          c.precipIntensityWarningMmPerHour,
                          false,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              _sectionCard(
                icon: Icons.visibility_outlined,
                title: _t('visibilidad_nubes'),
                children: [
                  _thresholdParam(
                    name: _t('visibilidad'),
                    unit: distUnit,
                    decimals: 1,
                    step: 0.5,
                    warnField: 'visibilityWarningKm',
                    blockField: 'visibilityBlockedKm',
                    warn: _dist(config.visibilityWarningKm),
                    block: _dist(config.visibilityBlockedKm),
                    inverted: true,
                    onWarn: (v) => _set(
                      (c) => c.copyWith(
                        visibilityWarningKm: _clampWarn(
                          _distToMetric(v),
                          c.visibilityBlockedKm,
                          true,
                        ),
                      ),
                    ),
                    onBlock: (v) => _set(
                      (c) => c.copyWith(
                        visibilityBlockedKm: _clampBlock(
                          _distToMetric(v),
                          c.visibilityWarningKm,
                          true,
                        ),
                      ),
                    ),
                  ),
                  _divider(),
                  _singleParam(
                    name: _t('altitud_objetivo'),
                    unit: altUnit,
                    decimals: 0,
                    step: 10,
                    field: 'targetAltitudeMeters',
                    value: _alt(config.targetAltitudeMeters.toDouble()),
                    onChanged: (v) => _set(
                      (c) =>
                          c.copyWith(targetAltitudeMeters: _altToMetric(v).round()),
                    ),
                  ),
                  _divider(),
                  _thresholdParam(
                    name: _t('margen_base_nubes'),
                    unit: altUnit,
                    decimals: 0,
                    step: 10,
                    warnField: 'cloudBaseWarningMarginMeters',
                    blockField: 'cloudBaseBlockedMarginMeters',
                    warn: _alt(config.cloudBaseWarningMarginMeters.toDouble()),
                    block: _alt(config.cloudBaseBlockedMarginMeters.toDouble()),
                    inverted: true,
                    onWarn: (v) => _set(
                      (c) => c.copyWith(
                        cloudBaseWarningMarginMeters: _clampWarn(
                          _altToMetric(v),
                          c.cloudBaseBlockedMarginMeters.toDouble(),
                          true,
                        ).round(),
                      ),
                    ),
                    onBlock: (v) => _set(
                      (c) => c.copyWith(
                        cloudBaseBlockedMarginMeters: _clampBlock(
                          _altToMetric(v),
                          c.cloudBaseWarningMarginMeters.toDouble(),
                          true,
                        ).round(),
                      ),
                    ),
                  ),
                ],
              ),

              _sectionCard(
                icon: Icons.thermostat_outlined,
                title: _t('ambientales'),
                children: [
                  _thresholdParam(
                    name: _t('temp_minima'),
                    unit: tempUnit,
                    decimals: 0,
                    step: 1,
                    warnField: 'temperatureMinWarningC',
                    blockField: 'temperatureMinBlockedC',
                    warn: _temp(config.temperatureMinWarningC),
                    block: _temp(config.temperatureMinBlockedC),
                    allowNegative: true,
                    inverted: true,
                    onWarn: (v) => _set(
                      (c) => c.copyWith(
                        temperatureMinWarningC: _clampWarn(
                          _tempToMetric(v),
                          c.temperatureMinBlockedC,
                          true,
                        ),
                      ),
                    ),
                    onBlock: (v) => _set(
                      (c) => c.copyWith(
                        temperatureMinBlockedC: _clampBlock(
                          _tempToMetric(v),
                          c.temperatureMinWarningC,
                          true,
                        ),
                      ),
                    ),
                  ),
                  _divider(),
                  _thresholdParam(
                    name: _t('temp_maxima'),
                    unit: tempUnit,
                    decimals: 0,
                    step: 1,
                    warnField: 'temperatureMaxWarningC',
                    blockField: 'temperatureMaxBlockedC',
                    warn: _temp(config.temperatureMaxWarningC),
                    block: _temp(config.temperatureMaxBlockedC),
                    allowNegative: true,
                    onWarn: (v) => _set(
                      (c) => c.copyWith(
                        temperatureMaxWarningC: _clampWarn(
                          _tempToMetric(v),
                          c.temperatureMaxBlockedC,
                          false,
                        ),
                      ),
                    ),
                    onBlock: (v) => _set(
                      (c) => c.copyWith(
                        temperatureMaxBlockedC: _clampBlock(
                          _tempToMetric(v),
                          c.temperatureMaxWarningC,
                          false,
                        ),
                      ),
                    ),
                  ),
                  _divider(),
                  _thresholdParam(
                    name: _t('indice_kp_regla'),
                    unit: '',
                    decimals: 1,
                    step: 0.5,
                    warnField: 'kpWarning',
                    blockField: 'kpBlocked',
                    warn: config.kpWarning,
                    block: config.kpBlocked,
                    onWarn: (v) => _set(
                      (c) =>
                          c.copyWith(kpWarning: _clampWarn(v, c.kpBlocked, false)),
                    ),
                    onBlock: (v) => _set(
                      (c) =>
                          c.copyWith(kpBlocked: _clampBlock(v, c.kpWarning, false)),
                    ),
                  ),
                ],
              ),

              _sectionCard(
                icon: Icons.nightlight_round,
                title: _t('operativas'),
                children: [
                  SwitchListTile(
                    key: const ValueKey('toggle-allowNightFlight'),
                    contentPadding: EdgeInsets.zero,
                    activeColor: const Color(0xFF0F766E),
                    title: Text(
                      _t('permitir_nocturno'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    value: config.allowNightFlight,
                    onChanged: (v) => _set((c) => c.copyWith(allowNightFlight: v)),
                  ),
                ],
              ),

              const SizedBox(height: 4),
              Text(
                _t('aviso_no_oficial'),
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
        // Fixed bottom bar — always visible regardless of scroll position.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                key: const ValueKey('flight-rules-restore'),
                onPressed: () =>
                    setState(() => config = const FlightRulesConfig.defaults()),
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
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                      ),
                      onPressed: () => widget.onSave(config),
                      child: Text(_t('guardar')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _set(FlightRulesConfig Function(FlightRulesConfig) update) {
    setState(() => config = update(config));
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: _isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _isDark
                        ? const Color(0xFF0F766E)
                        : const Color(0xFFE1F5EE),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 17,
                    color: _isDark ? Colors.white : const Color(0xFF0F6E56),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _divider() => Divider(
    height: 18,
    color: _isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
  );

  Widget _severityBadge(String text, {required bool blocked}) {
    final Color bg;
    final Color fg;
    if (blocked) {
      bg = _isDark ? const Color(0x33EF4444) : const Color(0xFFFCEBEB);
      fg = _isDark ? const Color(0xFFFCA5A5) : const Color(0xFF791F1F);
    } else {
      bg = _isDark ? const Color(0x33F59E0B) : const Color(0xFFFAEEDA);
      fg = _isDark ? const Color(0xFFFCD34D) : const Color(0xFF633806);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }

  Widget _thresholdParam({
    required String name,
    required String unit,
    required int decimals,
    required double step,
    required String warnField,
    required String blockField,
    required double warn,
    required double block,
    required ValueChanged<double> onWarn,
    required ValueChanged<double> onBlock,
    bool allowNegative = false,
    bool inverted = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
        _StepperRow(
          label: _severityBadge(_t('precaucion'), blocked: false),
          unit: unit,
          decimals: decimals,
          step: step,
          field: warnField,
          value: warn,
          onChanged: onWarn,
          language: widget.language,
          allowNegative: allowNegative,
        ),
        _StepperRow(
          label: _severityBadge(_t('bloqueo'), blocked: true),
          unit: unit,
          decimals: decimals,
          step: step,
          field: blockField,
          value: block,
          onChanged: onBlock,
          language: widget.language,
          allowNegative: allowNegative,
        ),
      ],
    );
  }

  Widget _singleParam({
    required String name,
    required String unit,
    required int decimals,
    required double step,
    required String field,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return _StepperRow(
      label: Text(
        name,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: _isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
      unit: unit,
      decimals: decimals,
      step: step,
      field: field,
      value: value,
      onChanged: onChanged,
      language: widget.language,
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.unit,
    required this.decimals,
    required this.step,
    required this.field,
    required this.value,
    required this.onChanged,
    required this.language,
    this.allowNegative = false,
  });

  final Widget label;
  final String unit;
  final int decimals;
  final double step;
  final String field;
  final double value;
  final ValueChanged<double> onChanged;
  final Language language;
  final bool allowNegative;

  String get _shown => decimals == 0
      ? value.round().toString()
      : value.toStringAsFixed(decimals);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          label,
          const Spacer(),
          IconButton(
            key: ValueKey('minus-$field'),
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => onChanged(_clampStep(value - step)),
          ),
          GestureDetector(
            onTap: () => _editExact(context),
            child: SizedBox(
              width: 70,
              child: Text(
                '$_shown $unit',
                key: ValueKey('value-$field'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          IconButton(
            key: ValueKey('plus-$field'),
            icon: const Icon(Icons.add_circle_outline),
            color: const Color(0xFF0F766E),
            onPressed: () => onChanged(value + step),
          ),
        ],
      ),
    );
  }

  double _clampStep(double v) => (!allowNegative && v < 0) ? 0 : v;

  Future<void> _editExact(BuildContext context) async {
    final controller = TextEditingController(text: _shown);
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.numberWithOptions(
            decimal: true,
            signed: allowNegative,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              allowNegative ? RegExp(r'[0-9.\-]') : RegExp(r'[0-9.]'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.get('cancelar', language: language)),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, double.tryParse(controller.text)),
            child: Text(AppStrings.get('aceptar', language: language)),
          ),
        ],
      ),
    );
    if (result != null) onChanged(_clampStep(result));
  }
}
```

- [ ] **Step 4: Run the full screen test file (GREEN)**

Run: `flutter test test/features/settings/flight_rules_screen_test.dart`
Expected: PASS — all 7 tests (4 existing + 3 new). If `warning cannot exceed block` still fails, confirm the `onWarn` closures route through `_clampWarn`; if the inverted test fails, confirm visibility/temp-min/cloud-margin pass `inverted: true` and their closures use `true`.

- [ ] **Step 5: Run the full suite + analyze**

Run: `flutter test && flutter analyze`
Expected: full suite PASS (1 pre-existing skip), analyzer clean. The Settings wiring (`settings_screen.dart`) constructs `FlightRulesScreen` with the same constructor, so it is unaffected.

- [ ] **Step 6: Commit**

```bash
git add lib/features/settings/screens/flight_rules_screen.dart test/features/settings/flight_rules_screen_test.dart
git commit -m "feat: redesign flight rules screen with section cards, badges and coherence guard"
```
(End the commit message with the trailer: `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.)

---

### Task 2: Format, verify, and visual check

**Files:** none (verification only).

- [ ] **Step 1: Format**

Run: `dart format lib test`
Expected: only `flight_rules_screen.dart` (and possibly the test) reformatted.

- [ ] **Step 2: Full suite + analyze**

Run: `flutter test && flutter analyze`
Expected: all tests PASS (1 pre-existing skip); analyzer reports no issues.

- [ ] **Step 3: Visual check (light and dark)**

Run the app (or rebuild the APK) and open Ajustes → Reglas de vuelo. Confirm:
- Each category is a card with an icon header (Viento/Precipitación/Visibilidad y nubes/Ambientales/Operativas).
- Each parameter shows its name with amber "Precaución" and red "Bloqueo" badges next to the steppers.
- "Altitud objetivo" is a single row (no badge); "Margen base de nubes" shows the two badges.
- The night-flight toggle, Restaurar / Cancelar / Guardar, and the safety note are present.
- Tapping `+` past the block (or `−` below it) pins the warning at the block value (coherence guard).
- Looks correct in both light and dark themes.

Command (release APK with the OpenAIP key, using a clean temp dir to avoid the Gradle loopback issue):

```bash
TMP='C:\gtmp' TEMP='C:\gtmp' JAVA_HOME='C:\Program Files\Java\jdk-17' \
  flutter build apk --dart-define=OPENAIP_API_KEY=<OPENAIP_KEY>
```

- [ ] **Step 4: Commit any formatting**

```bash
git add -A
git commit -m "style: format flight rules screen redesign"
```
(Skip if `git status` is clean after formatting. End any commit with the `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>` trailer.)

---

## Self-Review

- **Spec coverage:** section cards + icons (Task 1 `_sectionCard`), severity badges (`_severityBadge`), two-cutoff params with badges (`_thresholdParam`), single-value altitude row (`_singleParam`), cloud-base margin promoted to a badged pair (Task 1), night toggle in Operativas, dark-mode colors, preserved keys, coherence guard with polarity table (`_clampWarn`/`_clampBlock` + `inverted` on visibility/temp-min/cloud-margin), tests (3 new + 4 existing), format/analyze/visual (Task 2). All spec sections mapped.
- **Placeholders:** none — full file and full test code provided; `<OPENAIP_KEY>` in Task 2 is an intentional secret placeholder (the key is passed only via `--dart-define`, never written to a file).
- **Type consistency:** `_StepperRow.label` is `Widget` everywhere it is constructed (`_severityBadge` returns a `Widget`, `_singleParam` passes a `Text`); `_clampWarn(double, double, bool)` / `_clampBlock(double, double, bool)` signatures match every callsite; widget keys (`plus-/minus-/value-<field>`, `flight-rules-save/-restore`, `toggle-allowNightFlight`) are unchanged from the existing file and from the tests. No `FlightRulesConfig` field names changed.
- **No-domain-change check:** only `flight_rules_screen.dart` and its test are touched; `FlightRulesConfig`, evaluators, persistence, and `WeatherSession` are untouched, satisfying the presentational-only constraint.

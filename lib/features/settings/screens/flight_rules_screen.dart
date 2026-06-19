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

              _section(_t('viento')),
              _stepperPair(
                label: _t('viento_sostenido'),
                unit: speedUnit,
                decimals: 0,
                step: 1,
                warnField: 'windWarningKmh',
                blockField: 'windBlockedKmh',
                warn: _speed(config.windWarningKmh),
                block: _speed(config.windBlockedKmh),
                onWarn: (v) =>
                    _set((c) => c.copyWith(windWarningKmh: _speedToMetric(v))),
                onBlock: (v) =>
                    _set((c) => c.copyWith(windBlockedKmh: _speedToMetric(v))),
              ),
              _stepperPair(
                label: _t('rafagas'),
                unit: speedUnit,
                decimals: 0,
                step: 1,
                warnField: 'gustWarningKmh',
                blockField: 'gustBlockedKmh',
                warn: _speed(config.gustWarningKmh),
                block: _speed(config.gustBlockedKmh),
                onWarn: (v) =>
                    _set((c) => c.copyWith(gustWarningKmh: _speedToMetric(v))),
                onBlock: (v) =>
                    _set((c) => c.copyWith(gustBlockedKmh: _speedToMetric(v))),
              ),
              _stepperPair(
                label: _t('dif_rafaga_viento'),
                unit: speedUnit,
                decimals: 0,
                step: 1,
                warnField: 'gustSpreadWarningKmh',
                blockField: 'gustSpreadBlockedKmh',
                warn: _speed(config.gustSpreadWarningKmh),
                block: _speed(config.gustSpreadBlockedKmh),
                onWarn: (v) => _set(
                  (c) => c.copyWith(gustSpreadWarningKmh: _speedToMetric(v)),
                ),
                onBlock: (v) => _set(
                  (c) => c.copyWith(gustSpreadBlockedKmh: _speedToMetric(v)),
                ),
              ),

              _section(_t('precipitacion')),
              _stepperPair(
                label: _t('prob_lluvia'),
                unit: '%',
                decimals: 0,
                step: 5,
                warnField: 'precipProbabilityWarningPercent',
                blockField: 'precipProbabilityBlockedPercent',
                warn: config.precipProbabilityWarningPercent,
                block: config.precipProbabilityBlockedPercent,
                onWarn: (v) =>
                    _set((c) => c.copyWith(precipProbabilityWarningPercent: v)),
                onBlock: (v) =>
                    _set((c) => c.copyWith(precipProbabilityBlockedPercent: v)),
              ),
              _stepperPair(
                label: _t('intensidad_lluvia'),
                unit: 'mm/h',
                decimals: 1,
                step: 0.1,
                warnField: 'precipIntensityWarningMmPerHour',
                blockField: 'precipIntensityBlockedMmPerHour',
                warn: config.precipIntensityWarningMmPerHour,
                block: config.precipIntensityBlockedMmPerHour,
                onWarn: (v) =>
                    _set((c) => c.copyWith(precipIntensityWarningMmPerHour: v)),
                onBlock: (v) =>
                    _set((c) => c.copyWith(precipIntensityBlockedMmPerHour: v)),
              ),

              _section(_t('visibilidad_nubes')),
              _stepperPair(
                label: _t('visibilidad'),
                unit: distUnit,
                decimals: 1,
                step: 0.5,
                warnField: 'visibilityWarningKm',
                blockField: 'visibilityBlockedKm',
                warn: _dist(config.visibilityWarningKm),
                block: _dist(config.visibilityBlockedKm),
                onWarn: (v) => _set(
                  (c) => c.copyWith(visibilityWarningKm: _distToMetric(v)),
                ),
                onBlock: (v) => _set(
                  (c) => c.copyWith(visibilityBlockedKm: _distToMetric(v)),
                ),
              ),
              _stepperSingle(
                label: _t('altitud_objetivo'),
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
              _stepperSingle(
                label: '${_t('margen_base_nubes')} · ${_t('precaucion')}',
                unit: altUnit,
                decimals: 0,
                step: 10,
                field: 'cloudBaseWarningMarginMeters',
                value: _alt(config.cloudBaseWarningMarginMeters.toDouble()),
                onChanged: (v) => _set(
                  (c) => c.copyWith(
                    cloudBaseWarningMarginMeters: _altToMetric(v).round(),
                  ),
                ),
              ),
              _stepperSingle(
                label: '${_t('margen_base_nubes')} · ${_t('bloqueo')}',
                unit: altUnit,
                decimals: 0,
                step: 10,
                field: 'cloudBaseBlockedMarginMeters',
                value: _alt(config.cloudBaseBlockedMarginMeters.toDouble()),
                onChanged: (v) => _set(
                  (c) => c.copyWith(
                    cloudBaseBlockedMarginMeters: _altToMetric(v).round(),
                  ),
                ),
              ),

              _section(_t('ambientales')),
              _stepperPair(
                label: _t('temp_minima'),
                unit: tempUnit,
                decimals: 0,
                step: 1,
                warnField: 'temperatureMinWarningC',
                blockField: 'temperatureMinBlockedC',
                warn: _temp(config.temperatureMinWarningC),
                block: _temp(config.temperatureMinBlockedC),
                onWarn: (v) => _set(
                  (c) => c.copyWith(temperatureMinWarningC: _tempToMetric(v)),
                ),
                onBlock: (v) => _set(
                  (c) => c.copyWith(temperatureMinBlockedC: _tempToMetric(v)),
                ),
                allowNegative: true,
              ),
              _stepperPair(
                label: _t('temp_maxima'),
                unit: tempUnit,
                decimals: 0,
                step: 1,
                warnField: 'temperatureMaxWarningC',
                blockField: 'temperatureMaxBlockedC',
                warn: _temp(config.temperatureMaxWarningC),
                block: _temp(config.temperatureMaxBlockedC),
                onWarn: (v) => _set(
                  (c) => c.copyWith(temperatureMaxWarningC: _tempToMetric(v)),
                ),
                onBlock: (v) => _set(
                  (c) => c.copyWith(temperatureMaxBlockedC: _tempToMetric(v)),
                ),
                allowNegative: true,
              ),
              _stepperPair(
                label: _t('indice_kp_regla'),
                unit: '',
                decimals: 1,
                step: 0.5,
                warnField: 'kpWarning',
                blockField: 'kpBlocked',
                warn: config.kpWarning,
                block: config.kpBlocked,
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

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Color(0xFF64748B),
      ),
    ),
  );

  Widget _stepperSingle({
    required String label,
    required String unit,
    required int decimals,
    required double step,
    required String field,
    required double value,
    required ValueChanged<double> onChanged,
    bool allowNegative = false,
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
      language: widget.language,
      allowNegative: allowNegative,
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
    bool allowNegative = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ),
        _StepperRow(
          label: _t('precaucion'),
          sublabel: null,
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
          label: _t('bloqueo'),
          sublabel: null,
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
    required this.language,
    this.allowNegative = false,
  });

  final String label;
  final String? sublabel;
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

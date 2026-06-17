import 'package:flutter/material.dart';

import '../../../domain/i18n/app_strings.dart';
import '../../../domain/i18n/language.dart';
import '../../../domain/units/unit_preferences.dart';

class UnitsScreen extends StatefulWidget {
  const UnitsScreen({
    super.key,
    required this.initialUnits,
    required this.language,
    required this.onSave,
  });

  final UnitPreferences initialUnits;
  final Language language;
  final void Function(UnitPreferences) onSave;

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  late UnitPreferences units;

  @override
  void initState() {
    super.initState();
    units = widget.initialUnits;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('unidades', language: widget.language)),
        centerTitle: false,
      ),
      body: Container(
        color: const Color(0xFFF1F5F9),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _buildSection(
              'Velocidad de viento',
              SpeedUnit.values,
              units.speed,
              (unit) => setState(() => units = units.copyWith(speed: unit)),
            ),
            _buildSection(
              'Altura / altitud',
              AltitudeUnit.values,
              units.altitude,
              (unit) => setState(() => units = units.copyWith(altitude: unit)),
            ),
            _buildSection(
              'Distancia / visibilidad',
              DistanceUnit.values,
              units.distance,
              (unit) => setState(() => units = units.copyWith(distance: unit)),
            ),
            _buildSection(
              'Temperatura',
              TemperatureUnit.values,
              units.temperature,
              (unit) =>
                  setState(() => units = units.copyWith(temperature: unit)),
            ),
            _buildSection(
              'Presión',
              PressureUnit.values,
              units.pressure,
              (unit) => setState(() => units = units.copyWith(pressure: unit)),
            ),
            _buildSection(
              'Precipitación',
              PrecipitationUnit.values,
              units.precipitation,
              (unit) =>
                  setState(() => units = units.copyWith(precipitation: unit)),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      AppStrings.get('cancelar', language: widget.language),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => widget.onSave(units),
                    child: Text(
                      AppStrings.get('guardar', language: widget.language),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection<T extends Enum>(
    String title,
    List<T> options,
    T selected,
    Function(T) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: options.asMap().entries.map((entry) {
                  final unit = entry.value;
                  final isSelected = selected == unit;
                  final displayName = unit is SpeedUnit
                      ? unit.displayName
                      : unit is AltitudeUnit
                      ? unit.displayName
                      : unit is DistanceUnit
                      ? unit.displayName
                      : unit is TemperatureUnit
                      ? unit.displayName
                      : unit is PressureUnit
                      ? unit.displayName
                      : (unit as PrecipitationUnit).displayName;

                  return FilterChip(
                    label: Text(
                      displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF475569),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    selected: isSelected,
                    onSelected: (_) => onChanged(unit),
                    backgroundColor: const Color(0xFFF1F5F9),
                    selectedColor: const Color(0xFF0F766E),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF0F766E)
                          : const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

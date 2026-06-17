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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UnitSelector(
                title: AppStrings.get(
                  'velocidad_viento',
                  language: widget.language,
                ),
                options: SpeedUnit.values.map((u) => u.displayName).toList(),
                selectedIndex: units.speed.index,
                onChanged: (index) {
                  setState(() {
                    units = units.copyWith(speed: SpeedUnit.values[index]);
                  });
                },
                isDark: false,
              ),
              const SizedBox(height: 16),
              _UnitSelector(
                title: AppStrings.get(
                  'altura_altitud',
                  language: widget.language,
                ),
                options: AltitudeUnit.values.map((u) => u.displayName).toList(),
                selectedIndex: units.altitude.index,
                onChanged: (index) {
                  setState(() {
                    units = units.copyWith(
                      altitude: AltitudeUnit.values[index],
                    );
                  });
                },
                isDark: false,
              ),
              const SizedBox(height: 16),
              _UnitSelector(
                title: AppStrings.get(
                  'distancia_visibilidad',
                  language: widget.language,
                ),
                options: DistanceUnit.values.map((u) => u.displayName).toList(),
                selectedIndex: units.distance.index,
                onChanged: (index) {
                  setState(() {
                    units = units.copyWith(
                      distance: DistanceUnit.values[index],
                    );
                  });
                },
                isDark: false,
              ),
              const SizedBox(height: 16),
              _UnitSelector(
                title: AppStrings.get('temperatura', language: widget.language),
                options: TemperatureUnit.values
                    .map((u) => u.displayName)
                    .toList(),
                selectedIndex: units.temperature.index,
                onChanged: (index) {
                  setState(() {
                    units = units.copyWith(
                      temperature: TemperatureUnit.values[index],
                    );
                  });
                },
                isDark: false,
              ),
              const SizedBox(height: 16),
              _UnitSelector(
                title: AppStrings.get('presion', language: widget.language),
                options: PressureUnit.values.map((u) => u.displayName).toList(),
                selectedIndex: units.pressure.index,
                onChanged: (index) {
                  setState(() {
                    units = units.copyWith(
                      pressure: PressureUnit.values[index],
                    );
                  });
                },
                isDark: false,
              ),
              const SizedBox(height: 16),
              _UnitSelector(
                title: AppStrings.get(
                  'precipitacion',
                  language: widget.language,
                ),
                options: PrecipitationUnit.values
                    .map((u) => u.displayName)
                    .toList(),
                selectedIndex: units.precipitation.index,
                onChanged: (index) {
                  setState(() {
                    units = units.copyWith(
                      precipitation: PrecipitationUnit.values[index],
                    );
                  });
                },
                isDark: false,
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
                      onPressed: () {
                        widget.onSave(units);
                        Navigator.pop(context, units);
                      },
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
      ),
    );
  }
}

class _UnitSelector extends StatelessWidget {
  const _UnitSelector({
    required this.title,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
    required this.isDark,
  });

  final String title;
  final List<String> options;
  final int selectedIndex;
  final void Function(int) onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  options.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        options[index],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: selectedIndex == index
                              ? Colors.white
                              : const Color(0xFF475569),
                        ),
                      ),
                      selected: selectedIndex == index,
                      onSelected: (_) => onChanged(index),
                      backgroundColor: const Color(0xFFF1F5F9),
                      selectedColor: const Color(0xFF0F766E),
                      side: BorderSide(
                        color: selectedIndex == index
                            ? const Color(0xFF0F766E)
                            : const Color(0xFFE2E8F0),
                        width: 2,
                      ),
                    ),
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

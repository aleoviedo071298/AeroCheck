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
    required this.onBack,
  });

  final UnitPreferences initialUnits;
  final Language language;
  final void Function(UnitPreferences) onSave;
  final VoidCallback onBack;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSpanish = widget.language == Language.es;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        // Title
        Text(
          AppStrings.get('unidades', language: widget.language),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        // Subtitle
        Text(
          isSpanish
              ? 'Definí cómo se muestran los datos meteorológicos y operativos.'
              : 'Define how meteorological and operational data are displayed.',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 18),

        // Unified Card
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: [
              // 1. Wind speed
              _buildUnitRow(
                icon: Icons.air_rounded,
                title: AppStrings.get(
                  'velocidad_viento',
                  language: widget.language,
                ),
                subtitle: isSpanish
                    ? 'Usada en Estado, Forecast y Viento'
                    : 'Used in Status, Forecast and Wind',
                options: SpeedUnit.values,
                selected: units.speed,
                onChanged: (unit) =>
                    setState(() => units = units.copyWith(speed: unit)),
              ),
              const Divider(height: 1),

              // 2. Altitude
              _buildUnitRow(
                icon: Icons.filter_hdr_outlined,
                title: AppStrings.get(
                  'altura_altitud',
                  language: widget.language,
                ),
                subtitle: isSpanish
                    ? 'Altura operativa y límites de vuelo'
                    : 'Operating altitude and flight limits',
                options: AltitudeUnit.values,
                selected: units.altitude,
                onChanged: (unit) =>
                    setState(() => units = units.copyWith(altitude: unit)),
              ),
              const Divider(height: 1),

              // 3. Distance
              _buildUnitRow(
                icon: Icons.visibility_outlined,
                title: AppStrings.get(
                  'distancia_visibilidad',
                  language: widget.language,
                ),
                subtitle: isSpanish
                    ? 'Distancias meteorológicas y navegación'
                    : 'Meteorological and navigation distances',
                options: DistanceUnit.values,
                selected: units.distance,
                onChanged: (unit) =>
                    setState(() => units = units.copyWith(distance: unit)),
              ),
              const Divider(height: 1),

              // 4. Temperature
              _buildUnitRow(
                icon: Icons.thermostat_outlined,
                title: AppStrings.get('temperatura', language: widget.language),
                subtitle: isSpanish
                    ? 'Lecturas meteorológicas'
                    : 'Meteorological readings',
                options: TemperatureUnit.values,
                selected: units.temperature,
                onChanged: (unit) =>
                    setState(() => units = units.copyWith(temperature: unit)),
              ),
              const Divider(height: 1),

              // 5. Pressure
              _buildUnitRow(
                icon: Icons.speed_outlined,
                title: AppStrings.get('presion', language: widget.language),
                subtitle: isSpanish ? 'Datos barométricos' : 'Barometric data',
                options: PressureUnit.values,
                selected: units.pressure,
                onChanged: (unit) =>
                    setState(() => units = units.copyWith(pressure: unit)),
              ),
              const Divider(height: 1),

              // 6. Precipitation
              _buildUnitRow(
                icon: Icons.cloudy_snowing,
                title: AppStrings.get(
                  'precipitacion',
                  language: widget.language,
                ),
                subtitle: isSpanish
                    ? 'Acumulados y probabilidad de lluvia'
                    : 'Accumulations and rain probability',
                options: PrecipitationUnit.values,
                selected: units.precipitation,
                onChanged: (unit) =>
                    setState(() => units = units.copyWith(precipitation: unit)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onBack,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppStrings.get('cancelar', language: widget.language),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => widget.onSave(units),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppStrings.get('guardar', language: widget.language),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUnitRow<T extends Enum>({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<T> options,
    required T selected,
    required Function(T) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildSegmentedSelector<T>(
            options: options,
            selected: selected,
            getLabel: _getUnitLabel,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedSelector<T extends Enum>({
    required List<T> options,
    required T selected,
    required String Function(T) getLabel,
    required Function(T) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Widget> children = [];
    List<T> currentInactiveGroup = [];

    for (int i = 0; i < options.length; i++) {
      final option = options[i];
      final isSelected = option == selected;

      if (isSelected) {
        if (currentInactiveGroup.isNotEmpty) {
          children.add(
            _buildInactiveCapsule<T>(
              items: currentInactiveGroup,
              getLabel: getLabel,
              onChanged: onChanged,
              isDark: isDark,
            ),
          );
          currentInactiveGroup = [];
        }
        children.add(_buildActivePill<T>(option: option, getLabel: getLabel));
      } else {
        currentInactiveGroup.add(option);
      }
    }

    if (currentInactiveGroup.isNotEmpty) {
      children.add(
        _buildInactiveCapsule<T>(
          items: currentInactiveGroup,
          getLabel: getLabel,
          onChanged: onChanged,
          isDark: isDark,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children.map((w) {
        final index = children.indexOf(w);
        if (index == 0) return w;
        return Padding(padding: const EdgeInsets.only(left: 6), child: w);
      }).toList(),
    );
  }

  Widget _buildActivePill<T extends Enum>({
    required T option,
    required String Function(T) getLabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F766E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF0F766E), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            getLabel(option),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInactiveCapsule<T extends Enum>({
    required List<T> items,
    required String Function(T) getLabel,
    required Function(T) onChanged,
    required bool isDark,
  }) {
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final bgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(items.length * 2 - 1, (index) {
          if (index.isOdd) {
            return Container(width: 1.5, height: 16, color: borderColor);
          }

          final itemIndex = index ~/ 2;
          final item = items[itemIndex];

          return GestureDetector(
            onTap: () => onChanged(item),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                getLabel(item),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF475569),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  String _getUnitLabel<T extends Enum>(T unit) {
    if (unit is SpeedUnit) return unit.displayName;
    if (unit is AltitudeUnit) return unit.displayName;
    if (unit is DistanceUnit) return unit.displayName;
    if (unit is TemperatureUnit) return unit.displayName;
    if (unit is PressureUnit) return unit.displayName;
    if (unit is PrecipitationUnit) return unit.displayName;
    return '';
  }
}

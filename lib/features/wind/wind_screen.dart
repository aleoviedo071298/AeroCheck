import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/weather_session.dart';
import '../../data/location/flight_location.dart';
import '../../data/mock/mock_flight_data.dart';
import '../../domain/entities/flight_readiness_report.dart';
import '../../domain/i18n/app_strings.dart';
import '../../domain/rules/rule_severity.dart';
import '../../domain/rules/wind_profile_evaluator.dart';
import '../../domain/units/unit_formatters.dart';
import '../../domain/units/unit_preferences.dart';

class WindScreen extends StatelessWidget {
  const WindScreen({super.key, required this.session});

  final WeatherSession session;

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
        final report = session.currentReport;
        final location = session.selectedLocation;
        final rows = session.windProfileRows;

        final evaluator = WindProfileEvaluator(
          droneProfile: MockFlightData.droneProfile,
          missionProfile: MockFlightData.missionProfile,
        );

        final evaluatedRows = evaluator.evaluateProfile(rows);
        final bestWindRow = evaluator.findBestWindAltitude(rows);
        final units = session.preferences.units;
        final targetAltitude = UnitFormatters.formatAltitude(
          MockFlightData.droneProfile.preferredAltitudeMeters.toDouble(),
          units,
          decimals: 0,
        );

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
                      // 1. Collapsible Location Card
                      _CollapsibleLocationCard(
                        session: session,
                        report: report,
                      ),
                      const SizedBox(height: 14),

                      // 2. Redesigned Title & Subtitle block
                      _VerticalProfileTitleBlock(
                        session: session,
                        location: location,
                      ),
                      const SizedBox(height: 14),

                      if (session.isLoadingReal)
                        const _RealWeatherLoadingCard()
                      else if (session.dataSource == WeatherDataSource.real &&
                          session.realError != null)
                        _RealWeatherErrorCard(onRetry: session.loadRealWeather)
                      else if (rows.isEmpty)
                        const _StaticLoadingCard()
                      else ...[
                        // 3. Side-by-side Wind Stats cards
                        Row(
                          children: [
                            Expanded(
                              child: _WindStatsCard(
                                label: AppStrings.get(
                                  'altitud_objetivo',
                                ).toUpperCase(),
                                value: targetAltitude,
                                subValue: AppStrings.get('nivel_seleccionado'),
                                icon: Icons.gps_fixed_rounded,
                                iconColor: const Color(0xFF0284C7),
                                iconBg: const Color(0xFFE0F2FE),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _WindStatsCard(
                                label: AppStrings.get(
                                  'mejor_viento',
                                ).toUpperCase(),
                                value: _formatAltitude(
                                  bestWindRow.altitude,
                                  units,
                                ),
                                subValue: AppStrings.get(
                                  'viento_mas_favorable',
                                ),
                                icon: Icons.air_rounded,
                                iconColor: const Color(0xFF16A34A),
                                iconBg: const Color(0xFFDCFCE7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 4. Vertical Profile Table
                        Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                _WindTableHeader(units: units),
                                const SizedBox(height: 4),
                                const Divider(height: 1),
                                const SizedBox(height: 4),
                                ...List.generate(evaluatedRows.length, (index) {
                                  final row = evaluatedRows[index];
                                  return _RedesignedWindRow(
                                    row: row,
                                    index: index,
                                    isTarget:
                                        _altitudeMeters(row.altitude) ==
                                        MockFlightData
                                            .droneProfile
                                            .preferredAltitudeMeters,
                                    isBestWind:
                                        row.altitude == bestWindRow.altitude,
                                    units: units,
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 5. Legend Card
                        const _WindLegendCard(),
                        const SizedBox(height: 14),

                        // 6. Bottom optimal window tip card
                        const _WindTipCard(),
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
}

class _CollapsibleLocationCard extends StatefulWidget {
  const _CollapsibleLocationCard({required this.session, this.report});

  final WeatherSession session;
  final FlightReadinessReport? report;

  @override
  State<_CollapsibleLocationCard> createState() =>
      _CollapsibleLocationCardState();
}

class _CollapsibleLocationCardState extends State<_CollapsibleLocationCard> {
  bool _isExpanded = false;
  final _searchController = TextEditingController();
  Future<List<FlightLocation>>? _searchFuture;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = widget.session.selectedLocation;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Lat: ${location.latitude.toStringAsFixed(4)} · Lon: ${location.longitude.toStringAsFixed(4)} · Elev. ${UnitFormatters.formatAltitude(location.elevation.toDouble(), widget.session.preferences.units, decimals: 0)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ],
              ),
              if (_isExpanded) ...[
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      AppStrings.get('cambiar_ubicacion'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      key: const ValueKey('gps-location-button'),
                      icon: const Icon(Icons.my_location_rounded),
                      iconSize: 20,
                      tooltip: AppStrings.get('mi_ubicacion_gps'),
                      onPressed: () {
                        widget.session.setLocationToCurrentGPS();
                        setState(() {
                          _isExpanded = false;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...widget.session.availableLocations.map((loc) {
                      final isSelected = loc.id == location.id;
                      return ChoiceChip(
                        key: ValueKey('location-chip-${loc.id}'),
                        label: Text(loc.name),
                        selected: isSelected,
                        onSelected: (_) {
                          widget.session.setLocation(loc);
                          setState(() {
                            _isExpanded = false;
                          });
                        },
                      );
                    }),
                    ActionChip(
                      key: const ValueKey('add-location-button'),
                      label: Text(AppStrings.get('buscar')),
                      avatar: const Icon(Icons.search_rounded, size: 16),
                      onPressed: () {
                        _showAddLocationDialog();
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAddLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(AppStrings.get('buscar_ciudad')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: AppStrings.get('escribe_nombre_ciudad'),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (val) {
                      _debounceTimer?.cancel();
                      _debounceTimer = Timer(
                        const Duration(milliseconds: 300),
                        () {
                          setDialogState(() {
                            _searchFuture = widget.session.searchCities(val);
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    width: double.maxFinite,
                    child: _searchFuture == null
                        ? Center(
                            child: Text(
                              AppStrings.get('escribe_buscar_ciudades'),
                            ),
                          )
                        : FutureBuilder<List<FlightLocation>>(
                            future: _searchFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    '${AppStrings.get('error')}: ${snapshot.error}',
                                  ),
                                );
                              }
                              final locations = snapshot.data ?? [];
                              if (locations.isEmpty) {
                                return Center(
                                  child: Text(
                                    AppStrings.get('sin_resultados_ciudades'),
                                  ),
                                );
                              }
                              return ListView.builder(
                                itemCount: locations.length,
                                itemBuilder: (context, index) {
                                  final loc = locations[index];
                                  return ListTile(
                                    key: ValueKey('search-location-${loc.id}'),
                                    title: Text(loc.name),
                                    subtitle: Text(
                                      '${loc.region}, ${loc.country}',
                                    ),
                                    trailing: const Icon(
                                      Icons.add_circle_outline_rounded,
                                    ),
                                    onTap: () {
                                      widget.session.addFavoriteLocation(loc);
                                      Navigator.pop(context);
                                      _searchController.clear();
                                      setState(() {
                                        _isExpanded = false;
                                        _searchFuture = null;
                                      });
                                    },
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _searchController.clear();
                  setState(() {
                    _searchFuture = null;
                  });
                },
                child: Text(AppStrings.get('cerrar')),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VerticalProfileTitleBlock extends StatelessWidget {
  const _VerticalProfileTitleBlock({
    required this.session,
    required this.location,
  });

  final WeatherSession session;
  final FlightLocation location;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular Outline Wind Icon Container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFCBD5E1),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.air_rounded,
              color: Color(0xFF0D9488),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // Title Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.get('perfil_vertical'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _descriptionFor(session, location),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Info Button on right
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            onPressed: () {
              // Information popup/tooltip
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(AppStrings.get('perfil_vertical_viento')),
                  content: Text(AppStrings.get('perfil_info')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppStrings.get('entendido')),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _descriptionFor(WeatherSession session, FlightLocation location) {
    final isReal = session.dataSource == WeatherDataSource.real;
    final providerText = isReal
        ? AppStrings.get('perfil_real_descripcion')
        : AppStrings.get('perfil_mock_descripcion');
    return '${location.name}, ${location.region}\n$providerText';
  }
}

class _WindStatsCard extends StatelessWidget {
  const _WindStatsCard({
    required this.label,
    required this.value,
    required this.subValue,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  final String label;
  final String value;
  final String subValue;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subValue,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _WindTableHeader extends StatelessWidget {
  const _WindTableHeader({required this.units});

  final UnitPreferences units;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelStyle = TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.5,
      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          // Altitud
          SizedBox(
            width: 75,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.get('altitud').toUpperCase(),
                  style: labelStyle,
                ),
                Text(
                  units.altitude.shortName,
                  style: labelStyle.copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          // Viento
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.get('viento').toUpperCase(), style: labelStyle),
                Text(
                  units.speed.shortName,
                  style: labelStyle.copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          // Ráfaga
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.get('rafaga').toUpperCase(), style: labelStyle),
                Text(
                  units.speed.shortName,
                  style: labelStyle.copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          // Temp
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.get('temp').toUpperCase(), style: labelStyle),
                Text(
                  units.temperature.shortName,
                  style: labelStyle.copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          // Estado
          SizedBox(
            width: 100,
            child: Text(
              AppStrings.get('estado').toUpperCase(),
              style: labelStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _RedesignedWindRow extends StatelessWidget {
  const _RedesignedWindRow({
    required this.row,
    required this.index,
    required this.isTarget,
    required this.isBestWind,
    required this.units,
  });

  final EvaluatedWindProfileRow row;
  final int index;
  final bool isTarget;
  final bool isBestWind;
  final UnitPreferences units;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderHighlightColor = isTarget
        ? const Color(0xFF0284C7).withValues(alpha: isDark ? 0.6 : 0.4) // Blue
        : const Color(
            0xFF22C55E,
          ).withValues(alpha: isDark ? 0.6 : 0.4); // Green

    final rowBgColor = isTarget
        ? (isDark
              ? const Color(0xFF0284C7).withValues(alpha: 0.1)
              : const Color(0xFFE0F2FE).withValues(alpha: 0.6))
        : isBestWind
        ? (isDark
              ? const Color(0xFF22C55E).withValues(alpha: 0.1)
              : const Color(0xFFDCFCE7).withValues(alpha: 0.6))
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: rowBgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isTarget || isBestWind)
              ? borderHighlightColor
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            // Column 1: ALTITUD
            SizedBox(
              width: 75,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatAltitude(row.altitude, units),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: isTarget
                          ? const Color(0xFF0284C7)
                          : isBestWind
                          ? const Color(0xFF15803D)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${AppStrings.get('nivel')} ${index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  if (isTarget) ...[
                    const SizedBox(height: 4),
                    _buildPill(
                      AppStrings.get('objetivo').toUpperCase(),
                      const Color(0xFFE0F2FE),
                      const Color(0xFF0369A1),
                    ),
                  ] else if (isBestWind) ...[
                    const SizedBox(height: 4),
                    _buildPill(
                      AppStrings.get('mejor').toUpperCase(),
                      const Color(0xFFDCFCE7),
                      const Color(0xFF15803D),
                    ),
                  ],
                ],
              ),
            ),

            // Column 2: VIENTO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (row.windDirectionDegrees != null)
                        Transform.rotate(
                          angle: (row.windDirectionDegrees! * math.pi / 180.0),
                          child: const Icon(
                            Icons.navigation_rounded,
                            size: 11,
                            color: Color(0xFF0EA5E9),
                          ),
                        ),
                      const SizedBox(width: 4),
                      Text(
                        UnitFormatters.formatSpeedValue(
                          row.windKmh,
                          units,
                          decimals: 0,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    row.windDirectionDegrees == null
                        ? '-'
                        : '${_windDirectionCardinal(row.windDirectionDegrees)} ${_fmt(row.windDirectionDegrees!)}°',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            // Column 3: RÁFAGA
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.air_rounded,
                        size: 11,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        UnitFormatters.formatSpeedValue(
                          row.gustKmh,
                          units,
                          decimals: 0,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    units.speed.shortName,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),

            // Column 4: TEMP.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.device_thermostat_rounded,
                        size: 11,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        UnitFormatters.formatTemperatureValue(
                          row.temperatureC,
                          units,
                          decimals: 0,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${AppStrings.get('sensacion')} ${UnitFormatters.formatTemperature(row.temperatureC - 1.7, units, decimals: 0)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            // Column 5: ESTADO
            SizedBox(
              width: 100,
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _statusDotColor(row, isTarget, isBestWind),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _statusLabel(row, isTarget, isBestWind),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _statusDotColor(row, isTarget, isBestWind),
                          ),
                        ),
                        Text(
                          _statusSublabel(row, isTarget, isBestWind),
                          style: TextStyle(
                            fontSize: 9,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
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

  Widget _buildPill(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
    );
  }

  String _statusLabel(
    EvaluatedWindProfileRow row,
    bool isTarget,
    bool isBestWind,
  ) {
    if (isTarget) return AppStrings.get('objetivo');
    if (isBestWind) return AppStrings.get('mejor_viento');
    return switch (row.status) {
      'blocked' => AppStrings.get('desfavorable'),
      'warning' => AppStrings.get('precaucion'),
      _ => AppStrings.get('favorable'),
    };
  }

  String _statusSublabel(
    EvaluatedWindProfileRow row,
    bool isTarget,
    bool isBestWind,
  ) {
    if (isTarget) return AppStrings.get('nivel_seleccionado');
    if (isBestWind) return AppStrings.get('mas_favorable');
    return switch (row.status) {
      'blocked' =>
        row.limitExceededAt == 'wind'
            ? AppStrings.get('viento_alto')
            : AppStrings.get('rafagas_altas'),
      'warning' =>
        row.limitExceededAt == 'wind'
            ? AppStrings.get('viento_elevado')
            : AppStrings.get('rafagas_elevadas'),
      _ => AppStrings.get('viento_estable'),
    };
  }

  Color _statusDotColor(
    EvaluatedWindProfileRow row,
    bool isTarget,
    bool isBestWind,
  ) {
    if (isTarget) return const Color(0xFF0284C7);
    if (isBestWind) return const Color(0xFF16A34A);
    return switch (row.status) {
      'blocked' => const Color(0xFFDC2626),
      'warning' => const Color(0xFFF59E0B),
      _ => const Color(0xFF16A34A),
    };
  }

  String _windDirectionCardinal(double? degrees) {
    if (degrees == null) return '';
    final normalized = (degrees % 360 + 360) % 360;
    final index = ((normalized + 11.25) / 22.5).floor() % 16;
    const directions = [
      'N',
      'NNE',
      'NE',
      'ENE',
      'E',
      'ESE',
      'SE',
      'SSE',
      'S',
      'SSO',
      'SO',
      'OSO',
      'O',
      'ONO',
      'NO',
      'NNO',
    ];
    return directions[index];
  }

  String _fmt(num value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }
}

class _WindLegendCard extends StatelessWidget {
  const _WindLegendCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final legendTitleStyle = const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
    );
    final legendSubstyle = TextStyle(
      fontSize: 9,
      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
    );

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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Direction Legend
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    Icons.navigation_rounded,
                    color: Color(0xFF0EA5E9),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.get('direccion_viento'),
                          style: legendTitleStyle,
                        ),
                        Text(
                          AppStrings.get('origen_viento'),
                          style: legendSubstyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _vDivider(isDark),
            const SizedBox(width: 8),

            // Gust Legend
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.air_rounded,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.get('rafagas'),
                          style: legendTitleStyle,
                        ),
                        Text(
                          AppStrings.get('picos_instantaneos'),
                          style: legendSubstyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _vDivider(isDark),
            const SizedBox(width: 8),

            // Status Legend
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDC2626),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.get('estado_operativo'),
                          style: legendTitleStyle,
                        ),
                        Text(
                          AppStrings.get('evaluacion_nivel'),
                          style: legendSubstyle,
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

  Widget _vDivider(bool isDark) {
    return Container(
      width: 1,
      height: 24,
      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
    );
  }
}

class _WindTipCard extends StatelessWidget {
  const _WindTipCard();

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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.air_rounded, color: Color(0xFF0EA5E9), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppStrings.get('ventana_optima_tip'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RealWeatherLoadingCard extends StatelessWidget {
  const _RealWeatherLoadingCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: EdgeInsets.zero,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                AppStrings.get('obteniendo_clima'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RealWeatherErrorCard extends StatelessWidget {
  const _RealWeatherErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: EdgeInsets.zero,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  color: _severityColor(RuleSeverity.blocked),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppStrings.get('error_clima'),
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(AppStrings.get('reintentar_mock')),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(AppStrings.get('reintentar')),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaticLoadingCard extends StatelessWidget {
  const _StaticLoadingCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: EdgeInsets.zero,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            AppStrings.get('cargando_datos'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

String _formatAltitude(String source, UnitPreferences units) {
  final meters = _altitudeMeters(source);
  if (meters == null) {
    return source.toLowerCase() == 'suelo' ? AppStrings.get('suelo') : source;
  }
  return UnitFormatters.formatAltitude(meters, units, decimals: 0);
}

double? _altitudeMeters(String source) {
  final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(source);
  return match == null ? null : double.tryParse(match.group(0)!);
}

Color _severityColor(RuleSeverity severity) {
  return switch (severity) {
    RuleSeverity.ok => const Color(0xFF16A34A),
    RuleSeverity.warning => const Color(0xFFF59E0B),
    RuleSeverity.blocked => const Color(0xFFDC2626),
  };
}

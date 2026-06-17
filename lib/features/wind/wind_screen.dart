import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/weather_session.dart';
import '../../data/location/flight_location.dart';
import '../../data/mock/mock_flight_data.dart';
import '../../domain/entities/flight_readiness_report.dart';
import '../../domain/rules/rule_severity.dart';
import '../../domain/rules/wind_profile_evaluator.dart';

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
        final report = session.currentReport;
        final location = session.selectedLocation;
        final rows = session.windProfileRows;

        final evaluator = WindProfileEvaluator(
          droneProfile: MockFlightData.droneProfile,
          missionProfile: MockFlightData.missionProfile,
        );

        final evaluatedRows = evaluator.evaluateProfile(rows);
        final bestWindRow = evaluator.findBestWindAltitude(rows);
        final targetAltitude =
            '${MockFlightData.droneProfile.preferredAltitudeMeters} m';

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
                                label: 'ALTITUD OBJETIVO',
                                value: targetAltitude,
                                subValue: 'Nivel seleccionado',
                                icon: Icons.gps_fixed_rounded,
                                iconColor: const Color(0xFF0284C7),
                                iconBg: const Color(0xFFE0F2FE),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _WindStatsCard(
                                label: 'MEJOR VIENTO',
                                value: bestWindRow.altitude,
                                subValue: 'Viento más favorable',
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
                                const _WindTableHeader(),
                                const SizedBox(height: 4),
                                const Divider(height: 1),
                                const SizedBox(height: 4),
                                ...List.generate(evaluatedRows.length, (index) {
                                  final row = evaluatedRows[index];
                                  return _RedesignedWindRow(
                                    row: row,
                                    index: index,
                                    isTarget: row.altitude == targetAltitude,
                                    isBestWind:
                                        row.altitude == bestWindRow.altitude,
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
                          'Lat: ${location.latitude.toStringAsFixed(4)} · Lon: ${location.longitude.toStringAsFixed(4)} · Elev. ${location.elevation} m',
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
                      'Cambiar Ubicación',
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
                      tooltip: 'Mi ubicación (GPS)',
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
                      label: const Text('Buscar'),
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
            title: const Text('Buscar ciudad'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Escribe nombre de ciudad...',
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
                        ? const Center(
                            child: Text('Escribe para buscar ciudades'),
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
                                  child: Text('Error: ${snapshot.error}'),
                                );
                              }
                              final locations = snapshot.data ?? [];
                              if (locations.isEmpty) {
                                return const Center(
                                  child: Text('No se encontraron ciudades'),
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
                child: const Text('Cerrar'),
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
                  'Perfil vertical',
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
                  title: const Text('Perfil vertical de viento'),
                  content: const Text(
                    'Evalúa la velocidad y ráfagas del viento a diferentes altitudes AGL '
                    '(Above Ground Level) para determinar la capa más segura de vuelo.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Entendido'),
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
        ? 'Perfil real aproximado con niveles 10, 80, 120 y 180 m.'
        : 'viento y ráfagas por altura AGL para el perfil seleccionado.';
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
  const _WindTableHeader();

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
                Text('ALTITUD', style: labelStyle),
                Text(
                  'm',
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
                Text('VIENTO', style: labelStyle),
                Text(
                  'km/h',
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
                Text('RÁFAGA', style: labelStyle),
                Text(
                  'km/h',
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
                Text('TEMP.', style: labelStyle),
                Text(
                  '°C',
                  style: labelStyle.copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          // Estado
          SizedBox(width: 100, child: Text('ESTADO', style: labelStyle)),
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
  });

  final EvaluatedWindProfileRow row;
  final int index;
  final bool isTarget;
  final bool isBestWind;

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
                    row.altitude,
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
                    'Nivel ${index + 1}',
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
                      'OBJETIVO',
                      const Color(0xFFE0F2FE),
                      const Color(0xFF0369A1),
                    ),
                  ] else if (isBestWind) ...[
                    const SizedBox(height: 4),
                    _buildPill(
                      'MEJOR',
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
                        _fmt(row.windKmh),
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
                        _fmt(row.gustKmh),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'km/h',
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
                        _fmt(row.temperatureC),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sensación ${_fmt(row.temperatureC - 1.7)}°', // Sensación estimation
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
    if (isTarget) return 'Objetivo';
    if (isBestWind) return 'Mejor viento';
    return switch (row.status) {
      'blocked' => 'Desfavorable',
      'warning' => 'Precaución',
      _ => 'Favorable',
    };
  }

  String _statusSublabel(
    EvaluatedWindProfileRow row,
    bool isTarget,
    bool isBestWind,
  ) {
    if (isTarget) return 'Nivel seleccionado';
    if (isBestWind) return 'Más favorable';
    return switch (row.status) {
      'blocked' =>
        row.limitExceededAt == 'wind' ? 'Viento alto' : 'Ráfagas altas',
      'warning' =>
        row.limitExceededAt == 'wind' ? 'Viento elevado' : 'Ráfagas elevadas',
      _ => 'Viento estable',
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
                        Text('Dirección del viento', style: legendTitleStyle),
                        Text('Origen del viento', style: legendSubstyle),
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
                        Text('Ráfagas', style: legendTitleStyle),
                        Text('Picos instantáneos', style: legendSubstyle),
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
                        Text('Estado operativo', style: legendTitleStyle),
                        Text('Evaluación del nivel', style: legendSubstyle),
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
                'Ventana óptima: menor viento y ráfagas más estables.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF475569),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              size: 20,
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
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Obteniendo clima real de Open-Meteo...',
                style: TextStyle(fontWeight: FontWeight.w800),
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
                const Expanded(
                  child: Text(
                    'No se pudo obtener clima real.',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Reintentar o volver a datos mock.'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
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
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Cargando datos de viento...',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

Color _severityColor(RuleSeverity severity) {
  return switch (severity) {
    RuleSeverity.ok => const Color(0xFF16A34A),
    RuleSeverity.warning => const Color(0xFFF59E0B),
    RuleSeverity.blocked => const Color(0xFFDC2626),
  };
}

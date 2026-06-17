import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/weather_session.dart';
import '../../data/location/flight_location.dart';
import '../../data/mock/mock_flight_data.dart';
import '../../domain/entities/flight_readiness_report.dart';
import '../../domain/rules/rule_severity.dart';

class ForecastScreen extends StatelessWidget {
  const ForecastScreen({super.key, required this.session});

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
        final rows = session.forecastRows;
        final location = session.selectedLocation;

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

                      // Title & Subtitle Info
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Forecast horario',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _descriptionFor(session, location),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      if (session.isLoadingReal)
                        const _RealWeatherLoadingCard()
                      else if (session.dataSource == WeatherDataSource.real &&
                          session.realError != null)
                        _RealWeatherErrorCard(onRetry: session.loadRealWeather)
                      else if (report == null)
                        const _StaticLoadingCard()
                      else ...[
                        // 2. Selected Window Card
                        _ForecastWindowStatsCard(session: session),
                        const SizedBox(height: 16),

                        // 3. Forecast Table Header
                        const _ForecastTableHeader(),
                        const SizedBox(height: 4),

                        // 4. Forecast Rows List
                        ...rows.map(
                          (row) => _RedesignedForecastRowTile(row: row),
                        ),
                        const SizedBox(height: 16),

                        // 5. Timeline Index Chart
                        _HourlyScoreTimeline(rows: rows),
                        const SizedBox(height: 16),

                        // 6. Bottom optimal window tip
                        const _ForecastTipCard(),
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

  String _descriptionFor(WeatherSession session, FlightLocation location) {
    final isReal = session.dataSource == WeatherDataSource.real;
    final providerName = isReal
        ? (session.realBundle?.providerName ?? 'Open-Meteo')
        : 'Mock Data';
    final sourceText = isReal ? 'clima real de $providerName' : 'datos mock';
    return '${location.name}, ${location.region} · $sourceText evaluado con AeroCheck.';
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

class _ForecastWindowStatsCard extends StatelessWidget {
  const _ForecastWindowStatsCard({required this.session});

  final WeatherSession session;

  @override
  Widget build(BuildContext context) {
    final report = session.currentReport;
    if (report == null) return const SizedBox.shrink();

    final window = report.bestWindow;
    final start = window.start;
    final end = window.end;
    final durationHours = end.difference(start).inHours;

    // Filter forecast rows that fall within the best window
    final windowRows = session.forecastRows.where((row) {
      if (row.time == null) return false;
      return !row.time!.isBefore(start) && row.time!.isBefore(end);
    }).toList();

    int aptoHours = 0;
    int noAptoHours = 0;
    double maxRainPercent = 0.0;

    for (final r in windowRows) {
      final s = r.status.toUpperCase();
      if (s == 'APTO' || s == 'READY') {
        aptoHours++;
      } else {
        noAptoHours++;
      }
      if (r.rainPercent > maxRainPercent) {
        maxRainPercent = r.rainPercent;
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textStyleValue = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w900,
      height: 1.2,
    );
    final textStyleLabel = TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.5,
      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        child: Row(
          children: [
            // Left calendar icon
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF0F766E),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Ventana Seleccionada
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('VENTANA SELECCIONADA', style: textStyleLabel),
                  const SizedBox(height: 2),
                  Text(
                    '${_time(start)} - ${_time(end)}',
                    style: textStyleValue.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '$durationHours horas',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            _vDivider(isDark),

            // Mejor Hora
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('MEJOR HORA', style: textStyleLabel),
                  const SizedBox(height: 2),
                  Text(
                    _time(start),
                    style: textStyleValue.copyWith(
                      color: const Color(0xFF0D9488),
                    ),
                  ),
                ],
              ),
            ),

            _vDivider(isDark),

            // Apto
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('APTO', style: textStyleLabel),
                  const SizedBox(height: 2),
                  Text('$aptoHours h', style: textStyleValue),
                ],
              ),
            ),

            _vDivider(isDark),

            // No Apto
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('NO APTO', style: textStyleLabel),
                  const SizedBox(height: 2),
                  Text('$noAptoHours h', style: textStyleValue),
                ],
              ),
            ),

            _vDivider(isDark),

            // Lluvia en Ventana
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'LLUVIA EN VENTANA',
                          style: textStyleLabel,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text('${_fmt(maxRainPercent)}%', style: textStyleValue),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.opacity_rounded,
                    color: Color(0xFF3B82F6),
                    size: 16,
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
      height: 32,
      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
    );
  }

  String _time(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  String _fmt(num value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }
}

class _ForecastTableHeader extends StatelessWidget {
  const _ForecastTableHeader();

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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          // Hora
          SizedBox(width: 46, child: Text('HORA', style: labelStyle)),
          // Estado / Razón Principal
          Expanded(
            child: Row(
              children: [
                Text('ESTADO', style: labelStyle),
                const SizedBox(width: 8),
                Text('RAZÓN PRINCIPAL', style: labelStyle),
              ],
            ),
          ),
          // Viento
          SizedBox(
            width: 58,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
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
          // Ráfagas
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('RÁFAGAS', style: labelStyle),
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
          // Lluvia
          SizedBox(
            width: 58,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('LLUVIA', style: labelStyle),
                Text(
                  '%',
                  style: labelStyle.copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          // Spacer for expandable chevron
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}

class _RedesignedForecastRowTile extends StatefulWidget {
  const _RedesignedForecastRowTile({required this.row});

  final ForecastRow row;

  @override
  State<_RedesignedForecastRowTile> createState() =>
      _RedesignedForecastRowTileState();
}

class _RedesignedForecastRowTileState
    extends State<_RedesignedForecastRowTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderHighlightColor = const Color(
      0xFF22C55E,
    ); // Green highlight border
    final isHighlight = row.isBestWindow;

    return Card(
      key: ValueKey('forecast-row-${row.hour}'),
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: isHighlight
          ? borderHighlightColor.withValues(alpha: 0.05)
          : (isDark ? const Color(0xFF1E293B) : Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isHighlight
              ? borderHighlightColor
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isHighlight ? 1.5 : 1,
        ),
      ),
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
            children: [
              Row(
                children: [
                  // Column 1: HORA
                  SizedBox(
                    width: 46,
                    child: Text(
                      row.hour,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: isHighlight && !isDark
                            ? const Color(0xFF16A34A)
                            : null,
                      ),
                    ),
                  ),

                  // Column 2: ESTADO & RAZÓN PRINCIPAL
                  Expanded(
                    child: Row(
                      children: [
                        _StatusIcon(
                          status: row.status,
                          reasonTitle: row.primaryReason,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 2,
                                children: [
                                  Text(
                                    row.status,
                                    style: TextStyle(
                                      color: _statusColor(row.status),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (row.isBestWindow) const _BestWindowPill(),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                row.primaryReason,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Column 3: VIENTO
                  SizedBox(
                    width: 58,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (row.windDirectionDegrees != null)
                              Transform.rotate(
                                angle:
                                    (row.windDirectionDegrees! *
                                    math.pi /
                                    180.0),
                                child: const Icon(
                                  Icons.navigation_rounded,
                                  size: 11,
                                  color: Color(0xFF0EA5E9),
                                ),
                              ),
                            const SizedBox(width: 3),
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
                          '${_windDirectionCardinal(row.windDirectionDegrees)} ${row.windDirectionDegrees == null ? "-" : _fmt(row.windDirectionDegrees!)}°',
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

                  // Column 4: RÁFAGAS
                  SizedBox(
                    width: 52,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _fmt(row.gustKmh),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (row.gustKmh - row.windKmh > 0)
                          Text(
                            'Δ ${_fmt(row.gustKmh - row.windKmh)}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFFF59E0B),
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          Text(
                            'sin ráfagas',
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

                  // Column 5: LLUVIA
                  SizedBox(
                    width: 58,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(
                              Icons.opacity_rounded,
                              size: 11,
                              color: Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${_fmt(row.rainPercent)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          row.rainPercent > 0 ? 'con lluvia' : 'sin lluvia',
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

                  // Chevron indicator on right
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                  ),
                ],
              ),

              // Expandable content
              if (_isExpanded) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                ...row.reasons.map(
                  (reason) => _ForecastReasonLine(reason: reason),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(num value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status, required this.reasonTitle});

  final String status;
  final String reasonTitle;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final icon = _iconForReasonTitle(reasonTitle);

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 14),
    );
  }
}

class _BestWindowPill extends StatelessWidget {
  const _BestWindowPill();

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF0F766E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: const Text(
        'Mejor hora',
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _ForecastReasonLine extends StatelessWidget {
  const _ForecastReasonLine({required this.reason});

  final ForecastReason reason;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(reason.severity);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular colored icon container
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(
              _iconForReasonTitle(reason.title),
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),

          // Rule Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reason.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reason.details,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HourlyScoreTimeline extends StatelessWidget {
  const _HourlyScoreTimeline({required this.rows});

  final List<ForecastRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ÍNDICE POR HORA',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: List.generate(rows.length, (index) {
                final row = rows[index];
                final hourStr = row.hour.split(':').first;
                final scoreColor = _indexColor(row.score);

                return SizedBox(
                  width: 50,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Hour text
                      Text(
                        hourStr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: row.isBestWindow
                              ? FontWeight.w900
                              : FontWeight.w700,
                          color: row.isBestWindow
                              ? const Color(0xFF16A34A)
                              : textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Dot and connecting lines
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Left connecting line
                          if (index > 0)
                            Positioned(
                              left: 0,
                              right: 25,
                              child: Container(
                                height: 2,
                                color: _lineColor(
                                  rows[index - 1].score,
                                  row.score,
                                ),
                              ),
                            ),
                          // Right connecting line
                          if (index < rows.length - 1)
                            Positioned(
                              left: 25,
                              right: 0,
                              child: Container(
                                height: 2,
                                color: _lineColor(
                                  row.score,
                                  rows[index + 1].score,
                                ),
                              ),
                            ),
                          // The Dot
                          Container(
                            width: row.isBestWindow ? 16 : 8,
                            height: row.isBestWindow ? 16 : 8,
                            decoration: BoxDecoration(
                              color: scoreColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF0F172A)
                                    : Colors.white,
                                width: row.isBestWindow ? 3 : 1.5,
                              ),
                              boxShadow: row.isBestWindow
                                  ? [
                                      BoxShadow(
                                        color: scoreColor.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Color _indexColor(int score) {
    if (score >= 80) return const Color(0xFF16A34A);
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFDC2626);
  }

  Color _lineColor(int score1, int score2) {
    final avg = (score1 + score2) / 2.0;
    return _indexColor(avg.round());
  }
}

class _ForecastTipCard extends StatelessWidget {
  const _ForecastTipCard();

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
            const Icon(
              Icons.task_alt_rounded,
              color: Color(0xFF16A34A),
              size: 20,
            ),
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
            'Cargando datos de vuelo...',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

Color _statusColor(String status) {
  final s = status.toUpperCase();
  if (s == 'APTO' || s == 'READY') {
    return const Color(0xFF16A34A);
  }
  if (s == 'PRECAUCION' || s == 'PRECAUCIÓN' || s == 'CAUTION') {
    return const Color(0xFFF59E0B);
  }
  return const Color(0xFFDC2626);
}

Color _severityColor(RuleSeverity severity) {
  return switch (severity) {
    RuleSeverity.ok => const Color(0xFF16A34A),
    RuleSeverity.warning => const Color(0xFFF59E0B),
    RuleSeverity.blocked => const Color(0xFFDC2626),
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

IconData _iconForReasonTitle(String title) {
  final t = title.toUpperCase();
  if (t.contains('VIENTO') ||
      t.contains('RÁFAGAS') ||
      t.contains('WIND') ||
      t.contains('GUST')) {
    return Icons.air_rounded;
  }
  if (t.contains('RESTRIC') ||
      t.contains('ZONA') ||
      t.contains('LIMIT') ||
      t.contains('NO VOLAR')) {
    return Icons.block_rounded;
  }
  if (t.contains('LLUVIA') || t.contains('PRECIP')) {
    return Icons.water_drop_rounded;
  }
  if (t.contains('SOL') ||
      t.contains('DIA') ||
      t.contains('NOCHE') ||
      t.contains('DAYLIGHT')) {
    return Icons.wb_sunny_rounded;
  }
  if (t.contains('VISIBIL')) {
    return Icons.visibility_rounded;
  }
  return Icons.warning_amber_rounded;
}

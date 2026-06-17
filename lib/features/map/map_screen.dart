import 'dart:async';
import 'package:flutter/material.dart';

import '../../app/airspace_state.dart';
import '../../app/weather_session.dart';
import '../../data/location/flight_location.dart';
import 'presentation/widgets/real_map_widget.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key, required this.session});

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
        final location = session.selectedLocation;
        final guideRadiusKm = session.guideRadiusKm;
        final airspaceState = session.airspaceState;

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
                      // 1. Title Block
                      _MapTitleBlock(session: session, location: location),
                      const SizedBox(height: 14),

                      // 2. Favorite Location Selector Row
                      _FavoriteLocationSelector(session: session),
                      const SizedBox(height: 14),

                      // 3. Radio Guia card
                      _GuideRadiusControl(session: session),
                      const SizedBox(height: 14),

                      // 4. Map View Stack
                      AspectRatio(
                        aspectRatio: 0.82,
                        child: Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: RealMapWidget(
                                  location: location,
                                  guideRadiusKm: guideRadiusKm,
                                  airspaceState: airspaceState,
                                ),
                              ),
                              // Compass Overlay
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(
                                            0xFF1E293B,
                                          ).withValues(alpha: 0.9)
                                        : Colors.white.withValues(alpha: 0.9),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'N',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      Icon(
                                        Icons.navigation_rounded,
                                        size: 14,
                                        color: isDark
                                            ? const Color(0xFF0EA5E9)
                                            : const Color(0xFF0284C7),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Legend Overlay
                              Positioned(
                                bottom: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(
                                            0xFF1E293B,
                                          ).withValues(alpha: 0.9)
                                        : Colors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.location_on_rounded,
                                            size: 14,
                                            color: isDark
                                                ? const Color(0xFF0EA5E9)
                                                : const Color(0xFF0284C7),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Ubicación',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF1E293B),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 16,
                                            height: 2,
                                            color: Colors.blue,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${guideRadiusKm.toStringAsFixed(0)} km',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? const Color(0xFFCBD5E1)
                                                  : const Color(0xFF475569),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            children: List.generate(
                                              3,
                                              (index) => Container(
                                                width: 4,
                                                height: 2,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 1,
                                                    ),
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '5 km (Zonas CTR)',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? const Color(0xFFCBD5E1)
                                                  : const Color(0xFF475569),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Floating Overlay Action Buttons
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _MapOverlayButton(
                                      icon: Icons.layers_rounded,
                                      onPressed: () {
                                        // Just a visual action
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    _MapOverlayButton(
                                      icon: Icons.gps_fixed_rounded,
                                      onPressed: () {
                                        // Centers/fits bounds visually
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 5. Summary Metrics Card
                      _MapSummaryMetricsCard(session: session),
                      const SizedBox(height: 14),

                      // 6. Airspace layer detail card (Only when there are airspaces loaded/empty/error)
                      _AirspaceLayerCard(state: airspaceState),
                      const SizedBox(height: 14),

                      // 7. Bottom Warning Tip Card
                      const _MapTipCard(),
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

class _MapTitleBlock extends StatelessWidget {
  const _MapTitleBlock({required this.session, required this.location});

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mapa operativo',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${location.label}\nLat: ${location.latitude.toStringAsFixed(4)} · Lon: ${location.longitude.toStringAsFixed(4)} · Elev. ${location.elevation} m',
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
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFCBD5E1),
                width: 1.0,
              ),
            ),
            child: Text(
              'UTC-3',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteLocationSelector extends StatelessWidget {
  const _FavoriteLocationSelector({required this.session});

  final WeatherSession session;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...session.availableLocations.map((loc) {
            final isSelected = loc.id == session.selectedLocation.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                key: ValueKey('map-location-${loc.id}'),
                avatar: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      )
                    : const Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                label: Text(
                  loc.name,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF334155)),
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFF0D9488),
                backgroundColor: isDark
                    ? const Color(0xFF1E293B)
                    : Colors.white,
                checkmarkColor: Colors.white,
                showCheckmark: false,
                side: BorderSide(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0)),
                ),
                onSelected: (_) => session.setLocation(loc),
              ),
            );
          }),
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  _showLocationOptionsSheet(context, session);
                },
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationOptionsSheet(BuildContext context, WeatherSession session) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.my_location_rounded,
                    color: Color(0xFF0D9488),
                  ),
                  title: const Text(
                    'Usar ubicación GPS actual',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onTap: () {
                    session.setLocationToCurrentGPS();
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF0D9488),
                  ),
                  title: const Text(
                    'Buscar otra ciudad...',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddLocationDialog(context, session);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddLocationDialog(BuildContext context, WeatherSession session) {
    showDialog(
      context: context,
      builder: (context) => _AddLocationDialog(session: session),
    );
  }
}

class _GuideRadiusControl extends StatelessWidget {
  const _GuideRadiusControl({required this.session});

  final WeatherSession session;

  String _formatRadius(double value) {
    return '${value.toStringAsFixed(0)} km';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = session.guideRadiusKm;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.radar_rounded,
                  color: Color(0xFF0F766E),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Radio guía',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                Text(
                  _formatRadius(radius),
                  key: const ValueKey('guide-radius-value'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: const Color(0xFF0F766E),
                inactiveTrackColor: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
                thumbColor: const Color(0xFF0F766E),
                overlayColor: const Color(0xFF0F766E).withValues(alpha: 0.12),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(
                key: const ValueKey('guide-radius-slider'),
                value: radius,
                min: WeatherSession.minGuideRadiusKm,
                max: WeatherSession.maxGuideRadiusKm,
                divisions: 14,
                label: _formatRadius(radius),
                onChanged: session.setGuideRadiusKm,
              ),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [1.0, 3.0, 5.0, 10.0, 15.0].map((val) {
                  final isSelected = (radius - val).abs() < 1.0;
                  return Text(
                    '${val.toStringAsFixed(0)} km',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.w900
                          : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? Colors.white : const Color(0xFF1E293B))
                          : (isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapOverlayButton extends StatelessWidget {
  const _MapOverlayButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Icon(
            icon,
            size: 18,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

class _MapSummaryMetricsCard extends StatelessWidget {
  const _MapSummaryMetricsCard({required this.session});

  final WeatherSession session;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final location = session.selectedLocation;
    final weather = session.currentReport?.weather;
    final airspaceState = session.airspaceState;

    final elevationStr = '${location.elevation} m';

    bool hasTma = false;
    if (airspaceState is AirspaceLoadedState) {
      hasTma = airspaceState.airspaces.any((a) => a.typeCode == 7);
    }
    final tmaStr = hasTma ? 'Activa' : 'No activa';

    String flightCategory = 'VFR';
    Color categoryColor = const Color(0xFF16A34A);
    if (weather != null) {
      final visibility = weather.visibilityKm ?? 10.0;
      final cloudBase = weather.cloudBaseMeters ?? 1000.0;
      final hasRain =
          (weather.precipitationProbability ?? 0) > 30 ||
          (weather.precipitationMmPerHour ?? 0) > 1.0;

      if (visibility < 5.0 || cloudBase < 300.0 || hasRain) {
        flightCategory = 'IFR';
        categoryColor = const Color(0xFFDC2626);
      } else if (visibility < 8.0 || cloudBase < 900.0) {
        flightCategory = 'MVFR';
        categoryColor = const Color(0xFFF59E0B);
      }
    }

    String windSpeedStr = 'Sin dato';
    String windDirectionStr = '';
    if (weather != null && weather.windKmh != null) {
      windSpeedStr = '${weather.windKmh!.toStringAsFixed(0)} km/h';
      final cardinal = weather.windDirectionCardinal ?? '';
      final deg = weather.windDirectionDegrees != null
          ? ' ${weather.windDirectionDegrees!.toStringAsFixed(0)}°'
          : '';
      windDirectionStr = '$cardinal$deg';
    }

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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: _MetricItem(
                icon: Icons.landscape_rounded,
                iconColor: const Color(0xFF64748B),
                label: 'Elevación',
                value: elevationStr,
              ),
            ),
            _vDivider(isDark),
            Expanded(
              child: _MetricItem(
                icon: Icons.radar_rounded,
                iconColor: const Color(0xFF0F766E),
                label: 'TMA',
                value: tmaStr,
                valueColor: hasTma ? const Color(0xFFF59E0B) : null,
              ),
            ),
            _vDivider(isDark),
            Expanded(
              child: _MetricItem(
                icon: Icons.circle,
                iconColor: categoryColor,
                iconSize: 10,
                label: 'Clima',
                value: flightCategory,
                valueColor: categoryColor,
              ),
            ),
            _vDivider(isDark),
            Expanded(
              child: _MetricItem(
                icon: Icons.air_rounded,
                iconColor: const Color(0xFF0EA5E9),
                label: 'Viento',
                value: windSpeedStr,
                subValue: windDirectionStr,
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
      height: 36,
      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.icon,
    required this.iconColor,
    this.iconSize = 18,
    required this.label,
    required this.value,
    this.subValue,
    this.valueColor,
  });

  final IconData icon;
  final Color iconColor;
  final double iconSize;
  final String label;
  final String value;
  final String? subValue;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final mainValueColor =
        valueColor ?? (isDark ? Colors.white : const Color(0xFF1E293B));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: iconSize),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: mainValueColor,
          ),
        ),
        if (subValue != null && subValue!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subValue!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ],
    );
  }
}

class _AirspaceLayerCard extends StatelessWidget {
  const _AirspaceLayerCard({required this.state});

  final AirspaceState state;

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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.airplanemode_active_rounded,
                  color: Color(0xFF0F766E),
                  size: 20,
                ),
              ),
              title: const Text(
                'Espacios aéreos OpenAIP',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
              subtitle: const Text(
                'Capa informativa, no oficial.',
                style: TextStyle(fontSize: 11),
              ),
            ),
            const Divider(height: 16),
            if (state is AirspaceLoadingState)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator.adaptive()),
              )
            else if (state is AirspaceErrorState)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No se pudo cargar espacios aéreos. Verifica tu conexión.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (state is AirspaceEmptyState)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No hay espacios aéreos en el radio configurado.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              )
            else if (state is AirspaceLoadedState)
              ...List.generate((state as AirspaceLoadedState).airspaces.length, (
                idx,
              ) {
                final airspace = (state as AirspaceLoadedState).airspaces[idx];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_rounded,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              airspace.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${airspace.icaoClassLabel} | ${airspace.typeLabel}',
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
              }),
            const SizedBox(height: 8),
            Text(
              'Datos cortesía de OpenAIP. Verifica siempre con autoridades oficiales.',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapTipCard extends StatelessWidget {
  const _MapTipCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? const Color(0xFF0369A1).withValues(alpha: 0.1)
        : const Color(0xFFE0F2FE).withValues(alpha: 0.6);
    final borderColor = isDark
        ? const Color(0xFF0284C7).withValues(alpha: 0.4)
        : const Color(0xFFBAE6FD);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF0284C7),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'El radio guía indica distancias desde la ubicación seleccionada. '
                'Verifica las condiciones antes de operar.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF334155),
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark
                  ? const Color(0xFF0284C7).withValues(alpha: 0.6)
                  : const Color(0xFF0284C7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddLocationDialog extends StatefulWidget {
  const _AddLocationDialog({required this.session});

  final WeatherSession session;

  @override
  State<_AddLocationDialog> createState() => _AddLocationDialogState();
}

class _AddLocationDialogState extends State<_AddLocationDialog> {
  late final TextEditingController _controller;
  Future<List<FlightLocation>>? _searchFuture;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchFuture = widget.session.searchCities(val);
        });
      }
    });
  }

  void _onLocationSelected(FlightLocation location) {
    widget.session.addFavoriteLocation(location);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Buscar ciudad'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Escribe nombre de ciudad...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              width: double.maxFinite,
              child: _searchFuture == null
                  ? const Center(child: Text('Escribe para buscar ciudades'))
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
                              key: ValueKey('map-search-location-${loc.id}'),
                              title: Text(loc.name),
                              subtitle: Text('${loc.region}, ${loc.country}'),
                              trailing: const Icon(
                                Icons.add_circle_outline_rounded,
                              ),
                              onTap: () => _onLocationSelected(loc),
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

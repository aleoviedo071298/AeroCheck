import 'package:flutter/material.dart';

import '../../app/airspace_state.dart';
import '../../app/weather_session.dart';
import '../../domain/i18n/app_strings.dart';
import '../../domain/units/unit_formatters.dart';
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
        AppStrings.currentLanguage = session.preferences.language;
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
                      // 1. Radio Guia card
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
                                            AppStrings.get('ubicacion_mapa'),
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
                                            UnitFormatters.formatDistance(
                                              guideRadiusKm,
                                              session.preferences.units,
                                              decimals: 0,
                                            ),
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
                                            '${UnitFormatters.formatDistance(5, session.preferences.units, decimals: 0)} (${AppStrings.get('zonas_ctr')})',
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

class _GuideRadiusControl extends StatelessWidget {
  const _GuideRadiusControl({required this.session});

  final WeatherSession session;

  String _formatRadius(double value) {
    return UnitFormatters.formatDistance(
      value,
      session.preferences.units,
      decimals: 0,
    );
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
                    AppStrings.get('radio_vuelo'),
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
                    _formatRadius(val),
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

class _MapSummaryMetricsCard extends StatelessWidget {
  const _MapSummaryMetricsCard({required this.session});

  final WeatherSession session;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final location = session.selectedLocation;
    final weather = session.currentReport?.weather;
    final airspaceState = session.airspaceState;

    final elevationStr = UnitFormatters.formatAltitude(
      location.elevation.toDouble(),
      session.preferences.units,
      decimals: 0,
    );

    bool hasTma = false;
    if (airspaceState is AirspaceLoadedState) {
      hasTma = airspaceState.airspaces.any((a) => a.typeCode == 7);
    }
    final tmaStr = hasTma
        ? AppStrings.get('activa')
        : AppStrings.get('no_activa');

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

    String windSpeedStr = AppStrings.get('sin_dato');
    String windDirectionStr = '';
    if (weather != null && weather.windKmh != null) {
      windSpeedStr = UnitFormatters.formatSpeed(
        weather.windKmh,
        session.preferences.units,
        decimals: 0,
      );
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
                label: AppStrings.get('elevacion'),
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
                label: AppStrings.get('clima'),
                value: flightCategory,
                valueColor: categoryColor,
              ),
            ),
            _vDivider(isDark),
            Expanded(
              child: _MetricItem(
                icon: Icons.air_rounded,
                iconColor: const Color(0xFF0EA5E9),
                label: AppStrings.get('viento'),
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
              title: Text(
                AppStrings.get('espacios_openaip'),
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
              subtitle: Text(
                AppStrings.get('capa_informativa'),
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
                  AppStrings.get('error_espacios'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (state is AirspaceEmptyState)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  AppStrings.get('sin_espacios'),
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
              AppStrings.get('atribucion_openaip'),
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
                AppStrings.get('radio_explicacion'),
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
          ],
        ),
      ),
    );
  }
}

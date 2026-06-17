import 'dart:async';
import 'package:flutter/material.dart';

import '../../app/weather_session.dart';
import '../../data/location/flight_location.dart';
import '../../domain/i18n/language.dart';
import '../../domain/units/unit_preferences.dart';
import 'screens/alerts_screen.dart';
import 'screens/data_sources_screen.dart';
import 'screens/language_screen.dart';
import 'screens/units_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.session});

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
        final count = session.availableLocations.length;
        final favoritesSub = count == 1 ? '1 guardada' : '$count guardadas';

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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ajustes MVP',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Configuración local para validar la experiencia antes de perfiles editables.',
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
                          IconButton(
                            icon: const Icon(Icons.ios_share_rounded),
                            color: isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF475569),
                            onPressed: () {
                              // Visual action
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 2. Card 1: Ubicacion & Favoritos summary
                      Card(
                        margin: EdgeInsets.zero,
                        elevation: 0,
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            children: [
                              ListTile(
                                leading: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0F766E),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.location_on_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                title: const Text(
                                  'Ubicación',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Guardada localmente',
                                  style: TextStyle(fontSize: 11),
                                ),
                                trailing: Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 160,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '${session.selectedLocation.name}, ${session.selectedLocation.region}',
                                          textAlign: TextAlign.right,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF0D9488),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: isDark
                                            ? const Color(0xFF64748B)
                                            : const Color(0xFF94A3B8),
                                      ),
                                    ],
                                  ),
                                ),
                                onTap: () {},
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Divider(
                                  height: 1,
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFF1F5F9),
                                ),
                              ),
                              ListTile(
                                leading: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0F766E),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.star_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                title: const Text(
                                  'Favoritos',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  favoritesSub,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: Icon(
                                  Icons.chevron_right_rounded,
                                  color: isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                ),
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 3. Card 2: Active Locations & Search Control
                      Card(
                        margin: EdgeInsets.zero,
                        elevation: 0,
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...session.availableLocations.map((loc) {
                                final isActive =
                                    loc.id == session.selectedLocation.id;
                                final canRemove =
                                    session.availableLocations.length > 1;

                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            onTap: () =>
                                                session.setLocation(loc),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${loc.name}, ${loc.region}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: 8,
                                                      height: 8,
                                                      decoration: BoxDecoration(
                                                        color: isActive
                                                            ? const Color(
                                                                0xFF22C55E,
                                                              )
                                                            : const Color(
                                                                0xFF94A3B8,
                                                              ),
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      isActive
                                                          ? 'Ubicación activa'
                                                          : 'Lat: ${loc.latitude.toStringAsFixed(4)} · Lon: ${loc.longitude.toStringAsFixed(4)}',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: isDark
                                                            ? const Color(
                                                                0xFF94A3B8,
                                                              )
                                                            : const Color(
                                                                0xFF64748B,
                                                              ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          key: ValueKey(
                                            'remove-favorite-${loc.id}',
                                          ),
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                          ),
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B),
                                          onPressed: canRemove
                                              ? () => session
                                                    .removeFavoriteLocation(loc)
                                              : null,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                );
                              }),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              _LocationSearchControl(session: session),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 4. Card 3: Datos, Unidades & Alertas
                      Card(
                        margin: EdgeInsets.zero,
                        elevation: 0,
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            children: [
                              ListTile(
                                leading: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.cloud_sync_rounded,
                                    color: Color(0xFF0F766E),
                                    size: 20,
                                  ),
                                ),
                                title: const Text(
                                  'Datos',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Clima real | Open-Meteo + OpenMeteo Geocoding',
                                  style: TextStyle(fontSize: 11),
                                ),
                                trailing: Icon(
                                  Icons.chevron_right_rounded,
                                  color: isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                ),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => DataSourcesScreen(
                                        language: session.preferences.language,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Divider(
                                  height: 1,
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFF1F5F9),
                                ),
                              ),
                              ListTile(
                                leading: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.straighten_rounded,
                                    color: Color(0xFF0F766E),
                                    size: 20,
                                  ),
                                ),
                                title: const Text(
                                  'Unidades',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  '${session.preferences.units.speed.displayName}, ${session.preferences.units.altitude.displayName}, ${session.preferences.units.temperature.displayName}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: Icon(
                                  Icons.chevron_right_rounded,
                                  color: isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                ),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => UnitsScreen(
                                        initialUnits: session.preferences.units,
                                        language: session.preferences.language,
                                        onSave: (units) async {
                                          await session.updateUnits(units);
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Divider(
                                  height: 1,
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFF1F5F9),
                                ),
                              ),
                              ListTile(
                                leading: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.language_rounded,
                                    color: Color(0xFF0F766E),
                                    size: 20,
                                  ),
                                ),
                                title: const Text(
                                  'Idioma',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  session.preferences.language.displayName,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: Icon(
                                  Icons.chevron_right_rounded,
                                  color: isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                ),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => LanguageScreen(
                                        initialLanguage:
                                            session.preferences.language,
                                        onSave: (language) async {
                                          await session.updateLanguage(
                                            language,
                                          );
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Divider(
                                  height: 1,
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFF1F5F9),
                                ),
                              ),
                              ListTile(
                                leading: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.notifications_active_rounded,
                                    color: Color(0xFF0F766E),
                                    size: 20,
                                  ),
                                ),
                                title: const Text(
                                  'Alertas',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Próxima fase: avisos por ventana apta.',
                                  style: TextStyle(fontSize: 11),
                                ),
                                trailing: Icon(
                                  Icons.chevron_right_rounded,
                                  color: isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                ),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => AlertsScreen(
                                        language: session.preferences.language,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 5. Bottom Info Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Los cambios se aplican en tiempo real.',
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

class _LocationSearchControl extends StatefulWidget {
  const _LocationSearchControl({required this.session});

  final WeatherSession session;

  @override
  State<_LocationSearchControl> createState() => _LocationSearchControlState();
}

class _LocationSearchControlState extends State<_LocationSearchControl> {
  final _controller = TextEditingController();
  Future<List<FlightLocation>>? _searchFuture;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchFuture = widget.session.searchCities(query);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const ValueKey('location-search-field'),
          controller: _controller,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    tooltip: 'Limpiar búsqueda',
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _searchFuture = null;
                      });
                    },
                    icon: const Icon(Icons.close_rounded),
                  )
                : IconButton(
                    tooltip: 'Usar GPS actual',
                    onPressed: () {
                      widget.session.setLocationToCurrentGPS();
                    },
                    icon: const Icon(Icons.my_location_rounded),
                    color: const Color(0xFF0F766E),
                  ),
            hintText: 'Buscar ciudad mundial',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            isDense: true,
          ),
          onChanged: _onSearchChanged,
        ),
        const SizedBox(height: 8),
        if (_searchFuture == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Escribe para buscar ciudades en el mundo',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
            ),
          )
        else
          FutureBuilder<List<FlightLocation>>(
            future: _searchFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                );
              }

              final locations = snapshot.data ?? [];
              if (locations.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No se encontraron ciudades',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: locations
                    .take(4)
                    .map(
                      (location) => _SearchResultTile(
                        location: location,
                        onAdd: () {
                          widget.session.addFavoriteLocation(location);
                          _controller.clear();
                          setState(() {
                            _searchFuture = null;
                          });
                        },
                      ),
                    )
                    .toList(),
              );
            },
          ),
      ],
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.location, required this.onAdd});

  final FlightLocation location;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        location.label,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
      ),
      subtitle: Text(location.country, style: const TextStyle(fontSize: 11)),
      trailing: IconButton(
        key: ValueKey('add-favorite-${location.id}'),
        tooltip: 'Agregar favorito',
        onPressed: onAdd,
        icon: const Icon(
          Icons.add_location_alt_rounded,
          color: Color(0xFF0F766E),
        ),
      ),
    );
  }
}

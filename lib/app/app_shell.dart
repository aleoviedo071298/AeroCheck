import 'dart:async';

import 'package:flutter/material.dart';

import '../features/conditions/conditions_screen.dart';
import '../features/forecast/forecast_screen.dart';
import '../features/map/map_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/wind/wind_screen.dart';
import 'weather_session.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final WeatherSession _weatherSession;
  var _index = 0;

  @override
  void initState() {
    super.initState();
    _weatherSession = WeatherSession();
    unawaited(_weatherSession.restorePreferences());
  }

  @override
  void dispose() {
    _weatherSession.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ConditionsScreen(session: _weatherSession),
      ForecastScreen(session: _weatherSession),
      WindScreen(session: _weatherSession),
      MapScreen(session: _weatherSession),
      SettingsScreen(session: _weatherSession),
    ];

    return AnimatedBuilder(
      animation: _weatherSession,
      builder: (context, _) {
        String updateTimeText = '';
        if (_weatherSession.realBundle != null) {
          final time = _weatherSession.realBundle!.current.time;
          updateTimeText =
              'Actualizado ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 32,
                    width: 32,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'AeroCheck',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            actions: [
              if ((_index == 0 || _index == 1 || _index == 2) &&
                  updateTimeText.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    updateTimeText,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Refrescar clima',
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  onPressed: () => _weatherSession.loadRealWeather(),
                ),
              ],
              IconButton(
                tooltip: 'Compartir',
                onPressed: () {},
                icon: const Icon(Icons.ios_share_rounded),
              ),
            ],
          ),
          body: IndexedStack(index: _index, children: screens),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.speed_rounded),
                label: 'Estado',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month_rounded),
                label: 'Forecast',
              ),
              NavigationDestination(
                icon: Icon(Icons.air_rounded),
                selectedIcon: Icon(Icons.air_rounded),
                label: 'Viento',
              ),
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map_rounded),
                label: 'Mapa',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: 'Ajustes',
              ),
            ],
          ),
        );
      },
    );
  }
}

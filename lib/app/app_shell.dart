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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AeroCheck',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0),
        ),
        actions: [
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
            icon: Icon(Icons.task_alt_rounded),
            label: 'Estado',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Forecast',
          ),
          NavigationDestination(icon: Icon(Icons.air_rounded), label: 'Viento'),
          NavigationDestination(icon: Icon(Icons.map_rounded), label: 'Mapa'),
          NavigationDestination(
            icon: Icon(Icons.tune_rounded),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/i18n/app_strings.dart';
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
  final _settingsResetNotifier = ValueNotifier<int>(0);
  var _index = 0;

  @override
  void initState() {
    super.initState();
    _weatherSession = WeatherSession();
    unawaited(_weatherSession.restorePreferences());
  }

  @override
  void dispose() {
    _settingsResetNotifier.dispose();
    _weatherSession.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ConditionsScreen(
        session: _weatherSession,
        onNavigateToForecast: () => setState(() => _index = 1),
      ),
      ForecastScreen(session: _weatherSession),
      WindScreen(session: _weatherSession),
      MapScreen(session: _weatherSession),
      SettingsScreen(
        session: _weatherSession,
        resetNotifier: _settingsResetNotifier,
      ),
    ];

    return AnimatedBuilder(
      animation: _weatherSession,
      builder: (context, _) {
        AppStrings.currentLanguage = _weatherSession.preferences.language;
        String updateTimeText = '';
        if (_weatherSession.realBundle != null) {
          final time = _weatherSession.realBundle!.current.time;
          updateTimeText =
              '${AppStrings.get('actualizado')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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
                  tooltip: AppStrings.get('refrescar_clima'),
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  onPressed: () => _weatherSession.loadRealWeather(),
                ),
              ],
              IconButton(
                tooltip: AppStrings.get('compartir'),
                onPressed: () {},
                icon: const Icon(Icons.ios_share_rounded),
              ),
            ],
          ),
          body: IndexedStack(index: _index, children: screens),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) {
              if (value == 4 && _index == 4) {
                _settingsResetNotifier.value++;
              }
              setState(() => _index = value);
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.speed_rounded),
                label: AppStrings.get('estado'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.calendar_month_outlined),
                selectedIcon: const Icon(Icons.calendar_month_rounded),
                label: AppStrings.get('forecast'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.air_rounded),
                selectedIcon: const Icon(Icons.air_rounded),
                label: AppStrings.get('viento'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.map_outlined),
                selectedIcon: const Icon(Icons.map_rounded),
                label: AppStrings.get('mapa'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings_rounded),
                label: AppStrings.get('ajustes'),
              ),
            ],
          ),
        );
      },
    );
  }
}

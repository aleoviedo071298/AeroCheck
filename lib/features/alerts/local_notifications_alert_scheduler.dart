import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/i18n/app_strings.dart';
import '../../domain/i18n/language.dart';
import 'alert_timing.dart';
import 'apto_windows.dart';
import 'alert_scheduler.dart';

class LocalNotificationsAlertScheduler implements AlertScheduler {
  LocalNotificationsAlertScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const _channelId = 'apto_windows';

  Future<void> _init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  @override
  Future<bool> ensurePermission() async {
    await _init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return false;
  }

  @override
  Future<void> cancelAll() async {
    await _init();
    await _plugin.cancelAll();
  }

  @override
  Future<void> scheduleWindowAlerts({
    required List<FlightWindow> windows,
    required int leadMinutes,
    required String locationLabel,
    required Language language,
  }) async {
    await _init();
    final now = DateTime.now();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Ventanas aptas',
        channelDescription: 'Avisos de ventanas aptas para volar',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    var id = 1000;
    for (final window in windows) {
      if (!shouldScheduleAlert(window, leadMinutes, now)) continue;
      final fire = alertFireTime(window, leadMinutes);
      final title = AppStrings.get('alerta_ventana_titulo', language: language);
      final body =
          '${_hhmm(window.start)}–${_hhmm(window.end)} · $locationLabel';
      await _plugin.zonedSchedule(
        id++,
        title,
        body,
        tz.TZDateTime.from(fire, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

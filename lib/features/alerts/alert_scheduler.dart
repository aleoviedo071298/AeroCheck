import '../../domain/i18n/language.dart';
import 'apto_windows.dart';

abstract class AlertScheduler {
  Future<bool> ensurePermission();
  Future<void> scheduleWindowAlerts({
    required List<FlightWindow> windows,
    required int leadMinutes,
    required String locationLabel,
    required Language language,
  });
  Future<void> cancelAll();
}

class FakeAlertScheduler implements AlertScheduler {
  bool permissionGranted = true;
  int cancelAllCalls = 0;
  List<FlightWindow> lastWindows = const [];
  int? lastLeadMinutes;

  @override
  Future<bool> ensurePermission() async => permissionGranted;

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
  }

  @override
  Future<void> scheduleWindowAlerts({
    required List<FlightWindow> windows,
    required int leadMinutes,
    required String locationLabel,
    required Language language,
  }) async {
    lastWindows = windows;
    lastLeadMinutes = leadMinutes;
  }
}

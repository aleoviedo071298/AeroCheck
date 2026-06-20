import 'apto_windows.dart';

DateTime alertFireTime(FlightWindow window, int leadMinutes) =>
    window.start.subtract(Duration(minutes: leadMinutes));

/// Quiet hours: 22:00 (inclusive) to 07:00 (exclusive).
bool isQuietHour(DateTime t) => t.hour >= 22 || t.hour < 7;

bool shouldScheduleAlert(FlightWindow window, int leadMinutes, DateTime now) {
  final fire = alertFireTime(window, leadMinutes);
  if (!fire.isAfter(now)) return false;
  if (isQuietHour(fire)) return false;
  return true;
}

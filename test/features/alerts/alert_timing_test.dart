import 'package:aerocheck/features/alerts/apto_windows.dart';
import 'package:aerocheck/features/alerts/alert_timing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FlightWindow win(int hour) => FlightWindow(
    start: DateTime(2026, 6, 16, hour),
    end: DateTime(2026, 6, 16, hour + 2),
  );

  test('alertFireTime subtracts the lead time', () {
    expect(alertFireTime(win(9), 30), DateTime(2026, 6, 16, 8, 30));
  });

  test('isQuietHour covers 22:00-07:00', () {
    expect(isQuietHour(DateTime(2026, 6, 16, 5, 30)), isTrue);
    expect(isQuietHour(DateTime(2026, 6, 16, 23)), isTrue);
    expect(isQuietHour(DateTime(2026, 6, 16, 8)), isFalse);
  });

  test('shouldScheduleAlert skips quiet-hour and past fires', () {
    final now = DateTime(2026, 6, 16, 7);
    expect(shouldScheduleAlert(win(9), 30, now), isTrue); // fire 08:30
    expect(
      shouldScheduleAlert(win(6), 30, now),
      isFalse,
    ); // fire 05:30 (quiet + past)
    expect(shouldScheduleAlert(win(7), 30, now), isFalse); // fire 06:30 (quiet)
  });
}

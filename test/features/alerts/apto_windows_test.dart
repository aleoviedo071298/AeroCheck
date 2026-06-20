import 'package:aerocheck/data/mock/mock_flight_data.dart';
import 'package:aerocheck/domain/rules/flight_readiness_status.dart';
import 'package:aerocheck/features/alerts/apto_windows.dart';
import 'package:flutter_test/flutter_test.dart';

ForecastRow r(DateTime t, FlightReadinessStatus s) => ForecastRow(
  hour: '${t.hour.toString().padLeft(2, '0')}:00',
  status: s,
  primaryReason: 'x',
  reasons: const [],
  isBestWindow: false,
  windKmh: 10,
  gustKmh: 16,
  rainPercent: 0,
  visibilityKm: 16,
  score: 90,
  time: t,
);

void main() {
  final now = DateTime(2026, 6, 16, 6); // 06:00
  const apto = FlightReadinessStatus.ready;
  const no = FlightReadinessStatus.notReady;

  test('groups contiguous APTO hours into one window', () {
    final windows = upcomingAptoWindows([
      r(DateTime(2026, 6, 16, 9), apto),
      r(DateTime(2026, 6, 16, 10), apto),
      r(DateTime(2026, 6, 16, 11), no),
      r(DateTime(2026, 6, 16, 12), apto),
    ], now: now);
    expect(windows.length, 2);
    expect(windows.first.start, DateTime(2026, 6, 16, 9));
    expect(windows.first.end, DateTime(2026, 6, 16, 11)); // hour after last APTO
    expect(windows[1].start, DateTime(2026, 6, 16, 12));
  });

  test('excludes past windows and windows beyond the horizon', () {
    final windows = upcomingAptoWindows([
      r(DateTime(2026, 6, 16, 5), apto), // before now
      r(DateTime(2026, 6, 16, 9), apto), // in window
      r(DateTime(2026, 6, 19, 9), apto), // beyond 48h
    ], now: now);
    expect(windows.length, 1);
    expect(windows.first.start, DateTime(2026, 6, 16, 9));
  });
}

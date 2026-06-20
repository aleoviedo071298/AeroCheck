import '../../data/mock/mock_flight_data.dart';
import '../../domain/rules/flight_readiness_status.dart';

class FlightWindow {
  const FlightWindow({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

List<FlightWindow> upcomingAptoWindows(
  List<ForecastRow> rows, {
  required DateTime now,
  Duration horizon = const Duration(hours: 48),
}) {
  final limit = now.add(horizon);
  final windows = <FlightWindow>[];
  DateTime? runStart;
  DateTime? lastHour;

  void close() {
    if (runStart != null && lastHour != null) {
      windows.add(
        FlightWindow(
          start: runStart!,
          end: lastHour!.add(const Duration(hours: 1)),
        ),
      );
    }
    runStart = null;
    lastHour = null;
  }

  for (final row in rows) {
    final t = row.time;
    if (t == null) continue;
    if (row.status == FlightReadinessStatus.ready) {
      // Close the current run if there is a gap (non-contiguous hours)
      if (lastHour != null &&
          t.difference(lastHour!).inHours > 1) {
        close();
      }
      runStart ??= t;
      lastHour = t;
    } else {
      close();
    }
  }
  close();

  return windows
      .where((w) => w.start.isAfter(now) && w.start.isBefore(limit))
      .toList();
}

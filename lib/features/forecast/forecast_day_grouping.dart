// lib/features/forecast/forecast_day_grouping.dart
import '../../data/mock/mock_flight_data.dart';
import '../../domain/i18n/language.dart';

class ForecastDay {
  const ForecastDay({required this.date, required this.rows});

  final DateTime date; // normalized to midnight
  final List<ForecastRow> rows;

  ForecastRow? get bestHour {
    if (rows.isEmpty) return null;
    var best = rows.first;
    for (final r in rows.skip(1)) {
      if (r.score > best.score) best = r;
    }
    return best;
  }
}

List<ForecastDay> groupForecastByDay(List<ForecastRow> rows) {
  final map = <DateTime, List<ForecastRow>>{};
  for (final row in rows) {
    final t = row.time;
    if (t == null) continue;
    final key = DateTime(t.year, t.month, t.day);
    (map[key] ??= <ForecastRow>[]).add(row);
  }
  final days = map.entries
      .map((e) => ForecastDay(date: e.key, rows: e.value))
      .toList();
  days.sort((a, b) => a.date.compareTo(b.date));
  return days;
}

String forecastDayLabel(DateTime date, DateTime today, Language language) {
  final d = DateTime(date.year, date.month, date.day);
  final t = DateTime(today.year, today.month, today.day);
  final diff = d.difference(t).inDays;
  final isEs = language == Language.es;
  if (diff == 0) return isEs ? 'Hoy' : 'Today';
  if (diff == 1) return isEs ? 'Mañana' : 'Tomorrow';
  const esShort = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  const enShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return (isEs ? esShort : enShort)[date.weekday - 1];
}

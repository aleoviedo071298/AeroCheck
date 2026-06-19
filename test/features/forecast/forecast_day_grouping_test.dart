// test/features/forecast/forecast_day_grouping_test.dart
import 'package:aerocheck/data/mock/mock_flight_data.dart';
import 'package:aerocheck/domain/i18n/language.dart';
import 'package:aerocheck/domain/rules/flight_readiness_status.dart';
import 'package:aerocheck/features/forecast/forecast_day_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

ForecastRow row(DateTime time, int score) => ForecastRow(
  hour: '${time.hour.toString().padLeft(2, '0')}:00',
  status: FlightReadinessStatus.caution,
  primaryReason: 'x',
  reasons: const [],
  isBestWindow: false,
  windKmh: 10,
  gustKmh: 16,
  rainPercent: 0,
  visibilityKm: 16,
  score: score,
  time: time,
);

void main() {
  test('groups rows by calendar day, sorted', () {
    final rows = [
      row(DateTime(2026, 6, 16, 22), 50),
      row(DateTime(2026, 6, 17, 9), 80),
      row(DateTime(2026, 6, 16, 23), 60),
    ];
    final days = groupForecastByDay(rows);
    expect(days.length, 2);
    expect(days.first.date, DateTime(2026, 6, 16));
    expect(days.first.rows.length, 2);
    expect(days[1].date, DateTime(2026, 6, 17));
  });

  test('bestHour returns the highest score, earliest on ties', () {
    final day = ForecastDay(
      date: DateTime(2026, 6, 16),
      rows: [
        row(DateTime(2026, 6, 16, 8), 70),
        row(DateTime(2026, 6, 16, 9), 90),
        row(DateTime(2026, 6, 16, 10), 90),
      ],
    );
    expect(day.bestHour!.time, DateTime(2026, 6, 16, 9));
  });

  test('day label is Hoy/Mañana then weekday', () {
    final today = DateTime(2026, 6, 16); // Tuesday
    expect(forecastDayLabel(DateTime(2026, 6, 16), today, Language.es), 'Hoy');
    expect(
      forecastDayLabel(DateTime(2026, 6, 17), today, Language.es),
      'Mañana',
    );
    expect(
      forecastDayLabel(DateTime(2026, 6, 16), today, Language.en),
      'Today',
    );
    expect(forecastDayLabel(DateTime(2026, 6, 19), today, Language.es), 'Vie');
  });
}

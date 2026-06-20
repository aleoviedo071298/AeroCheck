// test/features/forecast/forecast_widgets_test.dart
import 'package:aerocheck/data/mock/mock_flight_data.dart';
import 'package:aerocheck/domain/i18n/language.dart';
import 'package:aerocheck/domain/rules/flight_readiness_status.dart';
import 'package:aerocheck/domain/units/unit_preferences.dart';
import 'package:aerocheck/features/forecast/forecast_day_grouping.dart';
import 'package:aerocheck/features/forecast/widgets/focused_hour_card.dart';
import 'package:aerocheck/features/forecast/widgets/hour_scrubber.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ForecastRow row(DateTime time, int score, {bool best = false}) => ForecastRow(
  hour: '${time.hour.toString().padLeft(2, '0')}:00',
  status: best ? FlightReadinessStatus.ready : FlightReadinessStatus.notReady,
  primaryReason: 'Viento sobre el limite',
  reasons: const [],
  isBestWindow: false,
  windKmh: 14,
  gustKmh: 23,
  rainPercent: 0,
  visibilityKm: 16,
  score: score,
  windDirectionDegrees: 270,
  time: time,
);

void main() {
  testWidgets('FocusedHourCard shows the hour and metrics', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusedHourCard(
            row: row(DateTime(2026, 6, 16, 9), 90, best: true),
            units: const UnitPreferences(),
            language: Language.es,
            isBestHour: true,
            dayLabel: 'Hoy',
          ),
        ),
      ),
    );
    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('Hoy'), findsWidgets);
    expect(find.textContaining('14'), findsWidgets); // wind value
  });

  testWidgets(
    'HourScrubber taps select an hour and the best-hour button fires',
    (tester) async {
      DateTime? selectedHour;
      var wentToBest = false;
      final rows = [
        row(DateTime(2026, 6, 16, 8), 30),
        row(DateTime(2026, 6, 16, 9), 90, best: true),
        row(DateTime(2026, 6, 16, 10), 40),
      ];
      final days = groupForecastByDay(rows);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HourScrubber(
              days: days,
              selectedDate: DateTime(2026, 6, 16),
              selectedHour: DateTime(2026, 6, 16, 8),
              today: DateTime(2026, 6, 16),
              language: Language.es,
              onHourSelected: (t) => selectedHour = t,
              onDaySelected: (_) {},
              onGoToBest: () => wentToBest = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('scrubber-track')));
      await tester.pump();
      expect(selectedHour, isNotNull);

      await tester.tap(find.byKey(const ValueKey('go-to-best-hour')));
      await tester.pump();
      expect(wentToBest, isTrue);
    },
  );

  testWidgets('HourScrubber renders a gradient track container', (tester) async {
    final rows = [
      row(DateTime(2026, 6, 16, 8), 30),
      row(DateTime(2026, 6, 16, 9), 90, best: true),
      row(DateTime(2026, 6, 16, 10), 40),
    ];
    final days = groupForecastByDay(rows);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HourScrubber(
            days: days,
            selectedDate: DateTime(2026, 6, 16),
            selectedHour: DateTime(2026, 6, 16, 9),
            today: DateTime(2026, 6, 16),
            language: Language.es,
            sunrise: DateTime(2026, 6, 16, 7),
            sunset: DateTime(2026, 6, 16, 18),
            onHourSelected: (_) {},
            onDaySelected: (_) {},
            onGoToBest: () {},
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('scrubber-gradient')), findsOneWidget);
    expect(find.byKey(const ValueKey('scrubber-track')), findsOneWidget);
  });
}

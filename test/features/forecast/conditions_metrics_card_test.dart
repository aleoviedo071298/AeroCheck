import 'package:aerocheck/data/mock/mock_flight_data.dart';
import 'package:aerocheck/domain/i18n/language.dart';
import 'package:aerocheck/domain/rules/flight_readiness_status.dart';
import 'package:aerocheck/domain/units/unit_preferences.dart';
import 'package:aerocheck/features/forecast/widgets/conditions_metrics_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the four secondary metrics', (tester) async {
    final row = ForecastRow(
      hour: '09:00',
      status: FlightReadinessStatus.ready,
      primaryReason: 'x',
      reasons: const [],
      isBestWindow: false,
      windKmh: 10,
      gustKmh: 16,
      rainPercent: 0,
      visibilityKm: 16,
      score: 90,
      time: DateTime(2026, 6, 16, 9),
      temperatureC: 18,
      cloudCoverPercent: 40,
      precipitationMmPerHour: 0.2,
      dewPointC: 9,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConditionsMetricsCard(
            row: row,
            units: const UnitPreferences(),
            language: Language.es,
          ),
        ),
      ),
    );
    expect(find.text('TEMPERATURA'), findsOneWidget);
    expect(find.text('NUBOSIDAD'), findsOneWidget);
    expect(find.text('PUNTO DE ROCÍO'), findsOneWidget);
    expect(find.textContaining('40'), findsWidgets); // cloud cover %
  });
}

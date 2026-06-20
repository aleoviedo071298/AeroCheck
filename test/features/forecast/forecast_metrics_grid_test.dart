import 'package:aerocheck/data/mock/mock_flight_data.dart';
import 'package:aerocheck/domain/i18n/language.dart';
import 'package:aerocheck/domain/rules/flight_readiness_status.dart';
import 'package:aerocheck/domain/units/unit_preferences.dart';
import 'package:aerocheck/features/forecast/widgets/forecast_metrics_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the 10 forecast metric cards incl. UV and pressure', (
    tester,
  ) async {
    final row = ForecastRow(
      hour: '09:00',
      status: FlightReadinessStatus.ready,
      primaryReason: 'x',
      reasons: const [],
      isBestWindow: false,
      windKmh: 14,
      gustKmh: 23,
      rainPercent: 14,
      visibilityKm: 16,
      score: 90,
      windDirectionDegrees: 274,
      time: DateTime(2026, 6, 16, 9),
      temperatureC: 11,
      cloudCoverPercent: 73,
      precipitationMmPerHour: 0,
      dewPointC: 3,
      relativeHumidityPercent: 73,
      apparentTemperatureC: 9,
      pressureHpa: 1013,
      uvIndex: 4,
      weatherCode: 0,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ForecastMetricsGrid(
              row: row,
              units: const UnitPreferences(),
              language: Language.es,
            ),
          ),
        ),
      ),
    );
    expect(find.text('PRESIÓN'), findsOneWidget);
    expect(find.text('ÍNDICE UV'), findsOneWidget);
    expect(find.text('CONDICIÓN'), findsOneWidget);
    expect(find.text('KP'), findsNothing);
  });
}

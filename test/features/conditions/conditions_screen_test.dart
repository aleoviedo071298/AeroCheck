import 'package:aerocheck/app/aerocheck_app.dart';
import 'package:aerocheck/data/mock/mock_flight_data.dart';
import 'package:aerocheck/data/weather/weather_bundle.dart';
import 'package:aerocheck/data/weather/weather_repository.dart';
import 'package:aerocheck/domain/entities/weather_snapshot.dart';
import 'package:aerocheck/features/conditions/conditions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('conditions screen renders status, reasons, and best window', (
    tester,
  ) async {
    await tester.pumpWidget(const AeroCheckApp());

    expect(find.text('AeroCheck'), findsOneWidget);
    expect(find.text('PRECAUCION'), findsWidgets);
    expect(find.text('Mejor ventana'), findsOneWidget);
    expect(find.textContaining('Comodoro Rivadavia'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Motivos'), 300);
    expect(find.text('Motivos'), findsOneWidget);
  });

  testWidgets('conditions screen can switch between mock scenarios', (
    tester,
  ) async {
    await tester.pumpWidget(const AeroCheckApp());

    await tester.tap(find.text('APTO').first);
    await tester.pumpAndSettle();

    expect(find.text('APTO'), findsWidgets);

    await tester.tap(find.text('NO APTO').first);
    await tester.pumpAndSettle();

    expect(find.text('NO APTO'), findsWidgets);
    await tester.scrollUntilVisible(
      find.textContaining('Dentro de zona restringida'),
      300,
    );
    expect(find.textContaining('Dentro de zona restringida'), findsOneWidget);
  });

  testWidgets('conditions screen renders real weather from repository', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConditionsScreen(
            weatherRepository: _FakeWeatherRepository.success(),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Clima real'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Clima real | Open-Meteo'), findsOneWidget);
    expect(find.textContaining('Open-Meteo -'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('No disp.'), findsWidgets);
  });

  testWidgets('conditions screen shows error and can retry real weather', (
    tester,
  ) async {
    final repository = _FakeWeatherRepository.failThenSucceed();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ConditionsScreen(weatherRepository: repository)),
      ),
    );

    await tester.tap(find.text('Clima real'));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo obtener clima real.'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Clima real | Open-Meteo'), findsOneWidget);
  });
}

class _FakeWeatherRepository implements WeatherRepository {
  _FakeWeatherRepository.success() : _failFirst = false;

  _FakeWeatherRepository.failThenSucceed() : _failFirst = true;

  final bool _failFirst;
  var _calls = 0;

  @override
  Future<WeatherBundle> fetchWeather({
    required double latitude,
    required double longitude,
    required String locationLabel,
  }) async {
    _calls += 1;
    if (_failFirst && _calls == 1) {
      throw Exception('network unavailable');
    }

    return WeatherBundle(
      providerName: 'Open-Meteo',
      locationLabel: locationLabel,
      timezone: 'America/Argentina/Catamarca',
      current: WeatherSnapshot(
        time: DateTime(2026, 6, 16, 13),
        locationLabel: locationLabel,
        temperatureC: 16,
        dewPointC: 8,
        windKmh: 12,
        gustKmh: 18,
        windDirectionDegrees: 230,
        precipitationProbability: 0,
        precipitationMmPerHour: 0,
        cloudCoverPercent: 28,
        cloudBaseMeters: null,
        visibilityKm: 16,
        kpIndex: null,
        isDaylight: true,
        isInsideRestrictedArea: false,
        isNearRestrictedArea: false,
      ),
      hourlySnapshots: [MockFlightData.goodToFly, MockFlightData.cautionWind],
      windProfileRows: MockFlightData.windProfileRows(),
    );
  }
}

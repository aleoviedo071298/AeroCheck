import 'package:aerocheck/app/weather_session.dart';
import 'package:aerocheck/data/location/default_flight_locations.dart';
import 'package:aerocheck/data/mock/mock_flight_data.dart';
import 'package:aerocheck/data/weather/weather_bundle.dart';
import 'package:aerocheck/data/weather/weather_repository.dart';
import 'package:aerocheck/domain/entities/weather_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'uses real bundle for forecast and wind rows after real weather loads',
    () async {
      final session = WeatherSession(
        weatherRepository: _FakeWeatherRepository(),
      );

      expect(session.dataSource, WeatherDataSource.mock);
      expect(session.forecastRows.first.hour, '08:00');

      await session.loadRealWeather();
      session.setDataSource(WeatherDataSource.real);

      expect(session.realBundle, isNotNull);
      expect(session.forecastRows.first.hour, '13:00');
      expect(session.forecastRows.first.windKmh, 12);
      expect(session.windProfileRows.first.altitude, '10 m');
      expect(session.windProfileRows.first.windKmh, 12);
      expect(session.currentReport, isNotNull);
    },
  );

  test('reloads real weather with selected location coordinates', () async {
    final repository = _FakeWeatherRepository();
    final session = WeatherSession(weatherRepository: repository);

    session.setLocation(DefaultFlightLocations.mendoza);
    session.setDataSource(WeatherDataSource.real);
    await Future<void>.delayed(Duration.zero);

    expect(session.selectedLocation, DefaultFlightLocations.mendoza);
    expect(repository.lastLatitude, DefaultFlightLocations.mendoza.latitude);
    expect(repository.lastLongitude, DefaultFlightLocations.mendoza.longitude);
    expect(repository.lastLocationLabel, DefaultFlightLocations.mendoza.label);
  });
}

class _FakeWeatherRepository implements WeatherRepository {
  double? lastLatitude;
  double? lastLongitude;
  String? lastLocationLabel;

  @override
  Future<WeatherBundle> fetchWeather({
    required double latitude,
    required double longitude,
    required String locationLabel,
  }) async {
    lastLatitude = latitude;
    lastLongitude = longitude;
    lastLocationLabel = locationLabel;

    return WeatherBundle(
      providerName: 'Open-Meteo',
      locationLabel: locationLabel,
      timezone: 'America/Argentina/Catamarca',
      current: _snapshot(DateTime(2026, 6, 16, 13), locationLabel),
      hourlySnapshots: [
        _snapshot(DateTime(2026, 6, 16, 13), locationLabel),
        _snapshot(DateTime(2026, 6, 16, 14), locationLabel),
      ],
      windProfileRows: const [
        WindProfileRow(
          altitude: '10 m',
          windKmh: 12,
          gustKmh: 18,
          temperatureC: 16,
        ),
      ],
    );
  }

  WeatherSnapshot _snapshot(DateTime time, String locationLabel) {
    return WeatherSnapshot(
      time: time,
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
    );
  }
}

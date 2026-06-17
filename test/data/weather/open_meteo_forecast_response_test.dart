import 'package:aerocheck/data/weather/dto/open_meteo_forecast_response.dart';
import 'package:aerocheck/data/weather/open_meteo_weather_repository.dart';
import 'package:aerocheck/data/weather/weather_repository_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const locationLabel = 'Comodoro Rivadavia, Chubut';

  test('maps Open-Meteo current weather into WeatherSnapshot', () {
    final response = OpenMeteoForecastResponse.fromJsonString(
      _openMeteoFixture,
    );
    final bundle = response.toWeatherBundle(locationLabel: locationLabel);

    expect(bundle.providerName, 'Open-Meteo');
    expect(bundle.locationLabel, locationLabel);
    expect(bundle.timezone, 'America/Argentina/Catamarca');
    expect(bundle.current.locationLabel, locationLabel);
    expect(bundle.current.time, DateTime(2026, 6, 16, 13));
    expect(bundle.current.temperatureC, 16.2);
    expect(bundle.current.dewPointC, 8.4);
    expect(bundle.current.windKmh, 19.1);
    expect(bundle.current.gustKmh, 31.2);
    expect(bundle.current.windDirectionDegrees, 245);
    expect(bundle.current.precipitationProbability, 18);
    expect(bundle.current.precipitationMmPerHour, 0);
    expect(bundle.current.cloudCoverPercent, 54);
    expect(bundle.current.visibilityKm, 14);
    expect(bundle.current.cloudBaseMeters, isNull);
    expect(bundle.current.kpIndex, isNull);
    expect(bundle.current.isDaylight, isTrue);
    expect(bundle.current.isInsideRestrictedArea, isFalse);
    expect(bundle.current.isNearRestrictedArea, isFalse);
  });

  test(
    'maps hourly rows and converts visibility from meters to kilometers',
    () {
      final response = OpenMeteoForecastResponse.fromJsonString(
        _openMeteoFixture,
      );
      final bundle = response.toWeatherBundle(locationLabel: locationLabel);

      expect(bundle.hourlySnapshots, hasLength(3));
      expect(bundle.hourlySnapshots[0].visibilityKm, 16);
      expect(bundle.hourlySnapshots[1].visibilityKm, 14);
      expect(bundle.hourlySnapshots[2].precipitationProbability, 72);
      expect(bundle.hourlySnapshots[2].isDaylight, isTrue);
    },
  );

  test('maps wind profile from Open-Meteo height variables', () {
    final response = OpenMeteoForecastResponse.fromJsonString(
      _openMeteoFixture,
    );
    final bundle = response.toWeatherBundle(locationLabel: locationLabel);

    expect(bundle.windProfileRows, hasLength(4));
    expect(bundle.windProfileRows[0].altitude, '10 m');
    expect(bundle.windProfileRows[0].windKmh, 19.1);
    expect(bundle.windProfileRows[0].gustKmh, 31.2);
    expect(bundle.windProfileRows[1].altitude, '80 m');
    expect(bundle.windProfileRows[1].windKmh, 21);
    expect(bundle.windProfileRows[1].gustKmh, 0);
    expect(bundle.windProfileRows[2].altitude, '120 m');
    expect(bundle.windProfileRows[2].windKmh, 24);
  });

  test('throws a controlled exception for invalid response shape', () {
    expect(
      () => OpenMeteoForecastResponse.fromJsonString('[]'),
      throwsA(isA<WeatherRepositoryException>()),
    );
  });

  test('repository builds request and maps successful fake response', () async {
    Uri? requestedUri;
    final repository = OpenMeteoWeatherRepository(
      client: MockClient((request) async {
        requestedUri = request.url;
        return http.Response(_openMeteoFixture, 200);
      }),
    );

    final bundle = await repository.fetchWeather(
      latitude: -45.8641,
      longitude: -67.4966,
      locationLabel: locationLabel,
    );

    expect(bundle.current.windKmh, 19.1);
    expect(requestedUri, isNotNull);
    expect(requestedUri!.queryParameters['latitude'], '-45.8641');
    expect(requestedUri!.queryParameters['longitude'], '-67.4966');
    expect(requestedUri!.queryParameters['timezone'], 'auto');
    expect(requestedUri!.queryParameters['windspeed_unit'], 'kmh');
    expect(
      requestedUri!.queryParameters['hourly'],
      contains('wind_speed_120m'),
    );
  });

  test(
    'repository throws controlled exception for non-success status',
    () async {
      final repository = OpenMeteoWeatherRepository(
        client: MockClient((request) async => http.Response('failure', 503)),
      );

      expect(
        () => repository.fetchWeather(
          latitude: -45.8641,
          longitude: -67.4966,
          locationLabel: locationLabel,
        ),
        throwsA(isA<WeatherRepositoryException>()),
      );
    },
  );
}

const _openMeteoFixture = '''
{
  "latitude": -45.875,
  "longitude": -67.5,
  "generationtime_ms": 0.071,
  "utc_offset_seconds": -10800,
  "timezone": "America/Argentina/Catamarca",
  "timezone_abbreviation": "GMT-3",
  "current": {
    "time": "2026-06-16T13:00",
    "temperature_2m": 16.2,
    "relative_humidity_2m": 61,
    "dew_point_2m": 8.4,
    "is_day": 1,
    "precipitation": 0.0,
    "rain": 0.0,
    "weather_code": 3,
    "cloud_cover": 54,
    "wind_speed_10m": 19.1,
    "wind_direction_10m": 245,
    "wind_gusts_10m": 31.2
  },
  "hourly": {
    "time": [
      "2026-06-16T12:00",
      "2026-06-16T13:00",
      "2026-06-16T14:00"
    ],
    "temperature_2m": [16.0, 16.2, 15.8],
    "dew_point_2m": [8.2, 8.4, 8.3],
    "precipitation_probability": [0, 18, 72],
    "precipitation": [0.0, 0.0, 1.2],
    "cloud_cover": [28, 54, 88],
    "visibility": [16000, 14000, 2200],
    "wind_speed_10m": [12.0, 19.1, 24.0],
    "wind_speed_80m": [17.0, 21.0, 28.0],
    "wind_speed_120m": [19.0, 24.0, 31.0],
    "wind_speed_180m": [22.0, 26.0, 34.0],
    "wind_direction_10m": [230, 245, 260],
    "wind_direction_80m": [232, 248, 262],
    "wind_direction_120m": [235, 250, 265],
    "wind_direction_180m": [236, 251, 266],
    "wind_gusts_10m": [18.0, 31.2, 43.0],
    "is_day": [1, 1, 1]
  }
}
''';

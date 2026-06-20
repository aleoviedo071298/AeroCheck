import 'package:http/http.dart' as http;

import 'dto/open_meteo_forecast_response.dart';
import 'weather_bundle.dart';
import 'weather_repository.dart';
import 'weather_repository_exception.dart';

class OpenMeteoWeatherRepository implements WeatherRepository {
  OpenMeteoWeatherRepository({http.Client? client, Uri? endpoint})
    : _client = client ?? http.Client(),
      _endpoint =
          endpoint ?? Uri.parse('https://api.open-meteo.com/v1/forecast');

  final http.Client _client;
  final Uri _endpoint;

  @override
  Future<WeatherBundle> fetchWeather({
    required double latitude,
    required double longitude,
    required String locationLabel,
  }) async {
    final uri = _endpoint.replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'timezone': 'auto',
        'forecast_days': '7',
        'current': [
          'temperature_2m',
          'relative_humidity_2m',
          'dew_point_2m',
          'is_day',
          'precipitation',
          'rain',
          'weather_code',
          'cloud_cover',
          'wind_speed_10m',
          'wind_direction_10m',
          'wind_gusts_10m',
          'apparent_temperature',
          'pressure_msl',
          'uv_index',
        ].join(','),
        'daily': 'sunrise,sunset',
        'hourly': [
          'temperature_2m',
          'dew_point_2m',
          'precipitation_probability',
          'precipitation',
          'cloud_cover',
          'visibility',
          'wind_speed_10m',
          'wind_speed_80m',
          'wind_speed_120m',
          'wind_speed_180m',
          'wind_direction_10m',
          'wind_direction_80m',
          'wind_direction_120m',
          'wind_direction_180m',
          'wind_gusts_10m',
          'is_day',
          'relative_humidity_2m',
          'apparent_temperature',
          'pressure_msl',
          'weather_code',
          'uv_index',
        ].join(','),
        'windspeed_unit': 'kmh',
        'temperature_unit': 'celsius',
        'precipitation_unit': 'mm',
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WeatherRepositoryException(
        'Open-Meteo request failed with status ${response.statusCode}.',
      );
    }

    return OpenMeteoForecastResponse.fromJsonString(
      response.body,
    ).toWeatherBundle(locationLabel: locationLabel);
  }
}

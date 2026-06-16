import 'weather_bundle.dart';

abstract class WeatherRepository {
  Future<WeatherBundle> fetchWeather({
    required double latitude,
    required double longitude,
    required String locationLabel,
  });
}

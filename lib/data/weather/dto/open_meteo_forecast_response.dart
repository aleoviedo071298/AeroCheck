import 'dart:convert';

import '../../../domain/entities/weather_snapshot.dart';
import '../../mock/mock_flight_data.dart';
import '../weather_bundle.dart';
import '../weather_repository_exception.dart';

class OpenMeteoForecastResponse {
  const OpenMeteoForecastResponse({
    required this.timezone,
    required this.utcOffsetSeconds,
    required this.current,
    required this.hourly,
  });

  factory OpenMeteoForecastResponse.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?>) {
      throw const WeatherRepositoryException(
        'Open-Meteo response must be a JSON object.',
      );
    }
    return OpenMeteoForecastResponse.fromJson(decoded);
  }

  factory OpenMeteoForecastResponse.fromJson(Map<String, Object?> json) {
    return OpenMeteoForecastResponse(
      timezone: _string(json, 'timezone'),
      utcOffsetSeconds: _int(json, 'utc_offset_seconds'),
      current: _object(json, 'current'),
      hourly: _object(json, 'hourly'),
    );
  }

  final String timezone;
  final int utcOffsetSeconds;
  final Map<String, Object?> current;
  final Map<String, Object?> hourly;

  WeatherBundle toWeatherBundle({required String locationLabel}) {
    final hourlySnapshots = _hourlySnapshots(locationLabel);
    final currentSnapshot = _currentSnapshot(locationLabel, hourlySnapshots);

    return WeatherBundle(
      providerName: 'Open-Meteo',
      locationLabel: locationLabel,
      timezone: timezone,
      current: currentSnapshot,
      hourlySnapshots: hourlySnapshots,
      windProfileRows: _windProfileRows(),
    );
  }

  WeatherSnapshot _currentSnapshot(
    String locationLabel,
    List<WeatherSnapshot> hourlySnapshots,
  ) {
    final currentTime = _dateTime(current, 'time');
    final nearest = _nearestHourly(currentTime, hourlySnapshots);

    return WeatherSnapshot(
      time: currentTime,
      locationLabel: locationLabel,
      temperatureC: _optionalDouble(current, 'temperature_2m'),
      dewPointC: _optionalDouble(current, 'dew_point_2m'),
      windKmh: _optionalDouble(current, 'wind_speed_10m'),
      gustKmh: _optionalDouble(current, 'wind_gusts_10m'),
      windDirectionDegrees: _optionalDouble(current, 'wind_direction_10m'),
      precipitationProbability: nearest?.precipitationProbability,
      precipitationMmPerHour:
          _optionalDouble(current, 'precipitation') ??
          nearest?.precipitationMmPerHour,
      cloudCoverPercent: _optionalDouble(current, 'cloud_cover'),
      cloudBaseMeters: null,
      visibilityKm: nearest?.visibilityKm,
      kpIndex: null,
      isDaylight: _optionalInt(current, 'is_day') == 1,
      isInsideRestrictedArea: false,
      isNearRestrictedArea: false,
    );
  }

  List<WeatherSnapshot> _hourlySnapshots(String locationLabel) {
    final times = _list(hourly, 'time');
    final snapshots = <WeatherSnapshot>[];

    for (var index = 0; index < times.length; index += 1) {
      final rawTime = times[index];
      if (rawTime is! String) {
        throw WeatherRepositoryException(
          'Open-Meteo hourly time[$index] must be a string.',
        );
      }

      snapshots.add(
        WeatherSnapshot(
          time: DateTime.parse(rawTime),
          locationLabel: locationLabel,
          temperatureC: _optionalDoubleAt(hourly, 'temperature_2m', index),
          dewPointC: _optionalDoubleAt(hourly, 'dew_point_2m', index),
          windKmh: _optionalDoubleAt(hourly, 'wind_speed_10m', index),
          gustKmh: _optionalDoubleAt(hourly, 'wind_gusts_10m', index),
          windDirectionDegrees: _optionalDoubleAt(
            hourly,
            'wind_direction_10m',
            index,
          ),
          precipitationProbability: _optionalDoubleAt(
            hourly,
            'precipitation_probability',
            index,
          ),
          precipitationMmPerHour: _optionalDoubleAt(
            hourly,
            'precipitation',
            index,
          ),
          cloudCoverPercent: _optionalDoubleAt(hourly, 'cloud_cover', index),
          cloudBaseMeters: null,
          visibilityKm: _metersToKm(
            _optionalDoubleAt(hourly, 'visibility', index),
          ),
          kpIndex: null,
          isDaylight: _optionalIntAt(hourly, 'is_day', index) == 1,
          isInsideRestrictedArea: false,
          isNearRestrictedArea: false,
        ),
      );
    }

    return snapshots;
  }

  WeatherSnapshot? _nearestHourly(
    DateTime currentTime,
    List<WeatherSnapshot> hourlySnapshots,
  ) {
    if (hourlySnapshots.isEmpty) {
      return null;
    }

    WeatherSnapshot nearest = hourlySnapshots.first;
    var nearestDifference = nearest.time.difference(currentTime).abs();

    for (final snapshot in hourlySnapshots.skip(1)) {
      final difference = snapshot.time.difference(currentTime).abs();
      if (difference < nearestDifference) {
        nearest = snapshot;
        nearestDifference = difference;
      }
    }

    return nearest;
  }

  List<WindProfileRow> _windProfileRows() {
    final firstTemperature =
        _optionalDoubleAt(hourly, 'temperature_2m', 0) ?? 0;
    return [
      WindProfileRow(
        altitude: '10 m',
        windKmh: _optionalDoubleAt(hourly, 'wind_speed_10m', 0) ?? 0,
        gustKmh: _optionalDoubleAt(hourly, 'wind_gusts_10m', 0) ?? 0,
        temperatureC: firstTemperature,
      ),
      WindProfileRow(
        altitude: '80 m',
        windKmh: _optionalDoubleAt(hourly, 'wind_speed_80m', 0) ?? 0,
        gustKmh: 0,
        temperatureC: firstTemperature,
      ),
      WindProfileRow(
        altitude: '120 m',
        windKmh: _optionalDoubleAt(hourly, 'wind_speed_120m', 0) ?? 0,
        gustKmh: 0,
        temperatureC: firstTemperature,
      ),
      WindProfileRow(
        altitude: '180 m',
        windKmh: _optionalDoubleAt(hourly, 'wind_speed_180m', 0) ?? 0,
        gustKmh: 0,
        temperatureC: firstTemperature,
      ),
    ];
  }

  static Map<String, Object?> _object(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is Map<String, Object?>) {
      return value;
    }
    throw WeatherRepositoryException(
      'Open-Meteo field "$key" must be an object.',
    );
  }

  static String _string(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is String) {
      return value;
    }
    throw WeatherRepositoryException(
      'Open-Meteo field "$key" must be a string.',
    );
  }

  static int _int(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    throw WeatherRepositoryException('Open-Meteo field "$key" must be an int.');
  }

  static DateTime _dateTime(Map<String, Object?> json, String key) {
    return DateTime.parse(_string(json, key));
  }

  static List<Object?> _list(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is List<Object?>) {
      return value;
    }
    throw WeatherRepositoryException('Open-Meteo field "$key" must be a list.');
  }

  static double? _optionalDouble(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    throw WeatherRepositoryException(
      'Open-Meteo field "$key" must be numeric.',
    );
  }

  static int? _optionalInt(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    throw WeatherRepositoryException('Open-Meteo field "$key" must be an int.');
  }

  static double? _optionalDoubleAt(
    Map<String, Object?> json,
    String key,
    int index,
  ) {
    final value = _optionalValueAt(json, key, index);
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    throw WeatherRepositoryException(
      'Open-Meteo field "$key[$index]" must be numeric.',
    );
  }

  static int? _optionalIntAt(Map<String, Object?> json, String key, int index) {
    final value = _optionalValueAt(json, key, index);
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    throw WeatherRepositoryException(
      'Open-Meteo field "$key[$index]" must be an int.',
    );
  }

  static Object? _optionalValueAt(
    Map<String, Object?> json,
    String key,
    int index,
  ) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is! List<Object?>) {
      throw WeatherRepositoryException(
        'Open-Meteo field "$key" must be a list.',
      );
    }
    if (index >= value.length) {
      return null;
    }
    return value[index];
  }

  static double? _metersToKm(double? meters) {
    if (meters == null) {
      return null;
    }
    return meters / 1000;
  }
}

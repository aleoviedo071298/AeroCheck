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
    this.daily,
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
      daily: json['daily'] is Map<String, Object?>
          ? json['daily'] as Map<String, Object?>
          : null,
    );
  }

  final String timezone;
  final int utcOffsetSeconds;
  final Map<String, Object?> current;
  final Map<String, Object?> hourly;
  final Map<String, Object?>? daily;

  WeatherBundle toWeatherBundle({required String locationLabel}) {
    final hourlySnapshots = _hourlySnapshots(locationLabel);
    final currentSnapshot = _currentSnapshot(locationLabel, hourlySnapshots);
    final nearestIndex = _nearestHourlyIndex(
      currentSnapshot.time,
      hourlySnapshots,
    );

    return WeatherBundle(
      providerName: 'Open-Meteo',
      locationLabel: locationLabel,
      timezone: timezone,
      current: currentSnapshot,
      hourlySnapshots: hourlySnapshots,
      windProfileRows: _windProfileRows(nearestIndex),
      dailySun: _dailySun(),
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
      relativeHumidityPercent: _optionalDouble(current, 'relative_humidity_2m'),
      apparentTemperatureC: _optionalDouble(current, 'apparent_temperature'),
      pressureHpa: _optionalDouble(current, 'pressure_msl'),
      uvIndex: _optionalDouble(current, 'uv_index'),
      weatherCode: _optionalInt(current, 'weather_code'),
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
          relativeHumidityPercent: _optionalDoubleAt(hourly, 'relative_humidity_2m', index),
          apparentTemperatureC: _optionalDoubleAt(hourly, 'apparent_temperature', index),
          pressureHpa: _optionalDoubleAt(hourly, 'pressure_msl', index),
          uvIndex: _optionalDoubleAt(hourly, 'uv_index', index),
          weatherCode: _optionalIntAt(hourly, 'weather_code', index),
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

  int _nearestHourlyIndex(
    DateTime currentTime,
    List<WeatherSnapshot> hourlySnapshots,
  ) {
    if (hourlySnapshots.isEmpty) {
      return 0;
    }

    var nearestIndex = 0;
    var nearestDifference = hourlySnapshots[0].time
        .difference(currentTime)
        .abs();

    for (var i = 1; i < hourlySnapshots.length; i++) {
      final difference = hourlySnapshots[i].time.difference(currentTime).abs();
      if (difference < nearestDifference) {
        nearestIndex = i;
        nearestDifference = difference;
      }
    }

    return nearestIndex;
  }

  List<WindProfileRow> _windProfileRows(int index) {
    final temperature = _optionalDoubleAt(hourly, 'temperature_2m', index) ?? 0;
    return [
      WindProfileRow(
        altitude: '10 m',
        windKmh: _optionalDoubleAt(hourly, 'wind_speed_10m', index) ?? 0,
        gustKmh: _optionalDoubleAt(hourly, 'wind_gusts_10m', index) ?? 0,
        temperatureC: temperature,
        windDirectionDegrees: _optionalDoubleAt(
          hourly,
          'wind_direction_10m',
          index,
        ),
      ),
      WindProfileRow(
        altitude: '80 m',
        windKmh: _optionalDoubleAt(hourly, 'wind_speed_80m', index) ?? 0,
        gustKmh: 0,
        temperatureC: temperature,
        windDirectionDegrees: _optionalDoubleAt(
          hourly,
          'wind_direction_80m',
          index,
        ),
      ),
      WindProfileRow(
        altitude: '120 m',
        windKmh: _optionalDoubleAt(hourly, 'wind_speed_120m', index) ?? 0,
        gustKmh: 0,
        temperatureC: temperature,
        windDirectionDegrees: _optionalDoubleAt(
          hourly,
          'wind_direction_120m',
          index,
        ),
      ),
      WindProfileRow(
        altitude: '180 m',
        windKmh: _optionalDoubleAt(hourly, 'wind_speed_180m', index) ?? 0,
        gustKmh: 0,
        temperatureC: temperature,
        windDirectionDegrees: _optionalDoubleAt(
          hourly,
          'wind_direction_180m',
          index,
        ),
      ),
    ];
  }

  List<DaySunTimes> _dailySun() {
    final d = daily;
    if (d == null) return const [];
    final times = d['time'];
    final sunrises = d['sunrise'];
    final sunsets = d['sunset'];
    if (times is! List || sunrises is! List || sunsets is! List) {
      return const [];
    }
    final out = <DaySunTimes>[];
    for (var i = 0; i < times.length; i++) {
      if (i >= sunrises.length || i >= sunsets.length) break;
      final dateStr = times[i];
      final sr = sunrises[i];
      final ss = sunsets[i];
      if (dateStr is! String || sr is! String || ss is! String) continue;
      try {
        final date = DateTime.parse(dateStr);
        out.add(
          DaySunTimes(
            date: DateTime(date.year, date.month, date.day),
            sunrise: DateTime.parse(sr),
            sunset: DateTime.parse(ss),
          ),
        );
      } catch (_) {
        // Skip malformed entries.
      }
    }
    return out;
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

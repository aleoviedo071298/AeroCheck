import 'unit_preferences.dart';
import 'unit_converters.dart';

class UnitFormatters {
  static String formatSpeedValue(
    double? value,
    UnitPreferences units, {
    int decimals = 1,
  }) {
    if (value == null) return '—';
    return UnitConverters.convertSpeed(
      value,
      SpeedUnit.kmh,
      units.speed,
    ).toStringAsFixed(decimals);
  }

  static String formatAltitudeValue(
    double? value,
    UnitPreferences units, {
    int decimals = 0,
  }) {
    if (value == null) return '—';
    return UnitConverters.convertAltitude(
      value,
      AltitudeUnit.m,
      units.altitude,
    ).toStringAsFixed(decimals);
  }

  static String formatTemperatureValue(
    double? value,
    UnitPreferences units, {
    int decimals = 1,
  }) {
    if (value == null) return '—';
    return UnitConverters.convertTemperature(
      value,
      TemperatureUnit.c,
      units.temperature,
    ).toStringAsFixed(decimals);
  }

  // Format a speed value according to preferences
  static String formatSpeed(
    double? value,
    UnitPreferences units, {
    int decimals = 1,
  }) {
    if (value == null) return '—';
    final converted = UnitConverters.convertSpeed(
      value,
      SpeedUnit.kmh,
      units.speed,
    );
    return '${converted.toStringAsFixed(decimals)} ${units.speed.shortName}';
  }

  // Format an altitude value according to preferences
  static String formatAltitude(
    double? value,
    UnitPreferences units, {
    int decimals = 0,
  }) {
    if (value == null) return '—';
    final converted = UnitConverters.convertAltitude(
      value,
      AltitudeUnit.m,
      units.altitude,
    );
    return '${converted.toStringAsFixed(decimals)} ${units.altitude.shortName}';
  }

  // Format a distance value according to preferences
  static String formatDistance(
    double? value,
    UnitPreferences units, {
    int decimals = 1,
  }) {
    if (value == null) return '—';
    final converted = UnitConverters.convertDistance(
      value,
      DistanceUnit.km,
      units.distance,
    );
    return '${converted.toStringAsFixed(decimals)} ${units.distance.shortName}';
  }

  // Format a temperature value according to preferences
  static String formatTemperature(
    double? value,
    UnitPreferences units, {
    int decimals = 1,
  }) {
    if (value == null) return '—';
    final converted = UnitConverters.convertTemperature(
      value,
      TemperatureUnit.c,
      units.temperature,
    );
    return '${converted.toStringAsFixed(decimals)} ${units.temperature.shortName}';
  }

  // Format a pressure value according to preferences
  static String formatPressure(
    double? value,
    UnitPreferences units, {
    int decimals = 1,
  }) {
    if (value == null) return '—';
    final converted = UnitConverters.convertPressure(
      value,
      PressureUnit.hpa,
      units.pressure,
    );
    return '${converted.toStringAsFixed(decimals)} ${units.pressure.shortName}';
  }

  // Format a precipitation value according to preferences
  static String formatPrecipitation(
    double? value,
    UnitPreferences units, {
    int decimals = 1,
  }) {
    if (value == null) return '—';
    final converted = UnitConverters.convertPrecipitation(
      value,
      PrecipitationUnit.mm,
      units.precipitation,
    );
    return '${converted.toStringAsFixed(decimals)} ${units.precipitation.shortName}';
  }

  // Format a percentage value (no conversion needed)
  static String formatPercentage(double? value, {int decimals = 0}) {
    if (value == null) return '—';
    return '${value.toStringAsFixed(decimals)} %';
  }

  // Format a cardinal direction + degrees
  static String formatWindDirection(
    double? degrees, {
    bool includeSymbol = true,
  }) {
    if (degrees == null) return '—';
    final cardinal = _cardinalDirection(degrees);
    final symbol = includeSymbol ? '°' : '';
    return '$cardinal ${degrees.toStringAsFixed(0)}$symbol';
  }

  static String _cardinalDirection(double degrees) {
    final normalized = ((degrees + 11.25) % 360).toInt();
    return switch (normalized ~/ 45) {
      0 => 'N',
      1 => 'NE',
      2 => 'E',
      3 => 'SE',
      4 => 'S',
      5 => 'SW',
      6 => 'W',
      7 => 'NW',
      _ => 'N',
    };
  }
}

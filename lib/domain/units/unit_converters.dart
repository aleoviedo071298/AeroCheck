import 'unit_preferences.dart';

class UnitConverters {
  // Speed conversions (base: km/h)
  static double convertSpeed(double value, SpeedUnit from, SpeedUnit to) {
    if (from == to) return value;

    double inKmh = _toKmh(value, from);
    return _fromKmh(inKmh, to);
  }

  static double _toKmh(double value, SpeedUnit unit) {
    return switch (unit) {
      SpeedUnit.kmh => value,
      SpeedUnit.ms => value * 3.6,
      SpeedUnit.kt => value * 1.852,
      SpeedUnit.mph => value * 1.60934,
    };
  }

  static double _fromKmh(double value, SpeedUnit unit) {
    return switch (unit) {
      SpeedUnit.kmh => value,
      SpeedUnit.ms => value / 3.6,
      SpeedUnit.kt => value / 1.852,
      SpeedUnit.mph => value / 1.60934,
    };
  }

  // Altitude conversions (base: m)
  static double convertAltitude(
    double value,
    AltitudeUnit from,
    AltitudeUnit to,
  ) {
    if (from == to) return value;

    double inMeters = switch (from) {
      AltitudeUnit.m => value,
      AltitudeUnit.ft => value * 0.3048,
    };

    return switch (to) {
      AltitudeUnit.m => inMeters,
      AltitudeUnit.ft => inMeters / 0.3048,
    };
  }

  // Distance conversions (base: km)
  static double convertDistance(
    double value,
    DistanceUnit from,
    DistanceUnit to,
  ) {
    if (from == to) return value;

    double inKm = switch (from) {
      DistanceUnit.km => value,
      DistanceUnit.m => value / 1000,
      DistanceUnit.nm => value * 1.852,
      DistanceUnit.mi => value * 1.60934,
    };

    return switch (to) {
      DistanceUnit.km => inKm,
      DistanceUnit.m => inKm * 1000,
      DistanceUnit.nm => inKm / 1.852,
      DistanceUnit.mi => inKm / 1.60934,
    };
  }

  // Temperature conversions (base: °C)
  static double convertTemperature(
    double value,
    TemperatureUnit from,
    TemperatureUnit to,
  ) {
    if (from == to) return value;

    if (from == TemperatureUnit.c && to == TemperatureUnit.f) {
      return (value * 9 / 5) + 32;
    } else if (from == TemperatureUnit.f && to == TemperatureUnit.c) {
      return (value - 32) * 5 / 9;
    }

    return value;
  }

  // Pressure conversions (base: hPa)
  static double convertPressure(
    double value,
    PressureUnit from,
    PressureUnit to,
  ) {
    if (from == to) return value;

    if (from == PressureUnit.hpa && to == PressureUnit.inhg) {
      return value * 0.02953;
    } else if (from == PressureUnit.inhg && to == PressureUnit.hpa) {
      return value / 0.02953;
    }

    return value;
  }

  // Precipitation conversions (base: mm)
  static double convertPrecipitation(
    double value,
    PrecipitationUnit from,
    PrecipitationUnit to,
  ) {
    if (from == to) return value;

    if (from == PrecipitationUnit.mm && to == PrecipitationUnit.inches) {
      return value / 25.4;
    } else if (from == PrecipitationUnit.inches && to == PrecipitationUnit.mm) {
      return value * 25.4;
    }

    return value;
  }

  // Batch convert a value with user preferences
  static double formatValueWithPreferences(
    double value,
    String type,
    UnitPreferences units,
  ) {
    return switch (type) {
      'speed' => convertSpeed(value, SpeedUnit.kmh, units.speed),
      'altitude' => convertAltitude(value, AltitudeUnit.m, units.altitude),
      'distance' => convertDistance(value, DistanceUnit.km, units.distance),
      'temperature' => convertTemperature(
        value,
        TemperatureUnit.c,
        units.temperature,
      ),
      'pressure' => convertPressure(value, PressureUnit.hpa, units.pressure),
      'precipitation' => convertPrecipitation(
        value,
        PrecipitationUnit.mm,
        units.precipitation,
      ),
      _ => value,
    };
  }
}

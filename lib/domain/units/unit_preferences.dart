enum SpeedUnit { kmh, ms, kt, mph }

enum AltitudeUnit { m, ft }

enum DistanceUnit { km, m, nm, mi }

enum TemperatureUnit { c, f }

enum PressureUnit { hpa, inhg }

enum PrecipitationUnit { mm, inches }

extension SpeedUnitDisplay on SpeedUnit {
  String get displayName {
    return switch (this) {
      SpeedUnit.kmh => 'km/h',
      SpeedUnit.ms => 'm/s',
      SpeedUnit.kt => 'kt',
      SpeedUnit.mph => 'mph',
    };
  }

  String get shortName {
    return switch (this) {
      SpeedUnit.kmh => 'km/h',
      SpeedUnit.ms => 'm/s',
      SpeedUnit.kt => 'kt',
      SpeedUnit.mph => 'mph',
    };
  }
}

extension AltitudeUnitDisplay on AltitudeUnit {
  String get displayName {
    return switch (this) {
      AltitudeUnit.m => 'm',
      AltitudeUnit.ft => 'ft',
    };
  }

  String get shortName {
    return switch (this) {
      AltitudeUnit.m => 'm',
      AltitudeUnit.ft => 'ft',
    };
  }
}

extension DistanceUnitDisplay on DistanceUnit {
  String get displayName {
    return switch (this) {
      DistanceUnit.km => 'km',
      DistanceUnit.m => 'm',
      DistanceUnit.nm => 'NM',
      DistanceUnit.mi => 'mi',
    };
  }

  String get shortName {
    return switch (this) {
      DistanceUnit.km => 'km',
      DistanceUnit.m => 'm',
      DistanceUnit.nm => 'NM',
      DistanceUnit.mi => 'mi',
    };
  }
}

extension TemperatureUnitDisplay on TemperatureUnit {
  String get displayName {
    return switch (this) {
      TemperatureUnit.c => '°C',
      TemperatureUnit.f => '°F',
    };
  }

  String get shortName {
    return switch (this) {
      TemperatureUnit.c => '°C',
      TemperatureUnit.f => '°F',
    };
  }
}

extension PressureUnitDisplay on PressureUnit {
  String get displayName {
    return switch (this) {
      PressureUnit.hpa => 'hPa',
      PressureUnit.inhg => 'inHg',
    };
  }

  String get shortName {
    return switch (this) {
      PressureUnit.hpa => 'hPa',
      PressureUnit.inhg => 'inHg',
    };
  }
}

extension PrecipitationUnitDisplay on PrecipitationUnit {
  String get displayName {
    return switch (this) {
      PrecipitationUnit.mm => 'mm',
      PrecipitationUnit.inches => 'in',
    };
  }

  String get shortName {
    return switch (this) {
      PrecipitationUnit.mm => 'mm',
      PrecipitationUnit.inches => 'in',
    };
  }
}

class UnitPreferences {
  const UnitPreferences({
    this.speed = SpeedUnit.kmh,
    this.altitude = AltitudeUnit.m,
    this.distance = DistanceUnit.km,
    this.temperature = TemperatureUnit.c,
    this.pressure = PressureUnit.hpa,
    this.precipitation = PrecipitationUnit.mm,
  });

  final SpeedUnit speed;
  final AltitudeUnit altitude;
  final DistanceUnit distance;
  final TemperatureUnit temperature;
  final PressureUnit pressure;
  final PrecipitationUnit precipitation;

  UnitPreferences copyWith({
    SpeedUnit? speed,
    AltitudeUnit? altitude,
    DistanceUnit? distance,
    TemperatureUnit? temperature,
    PressureUnit? pressure,
    PrecipitationUnit? precipitation,
  }) {
    return UnitPreferences(
      speed: speed ?? this.speed,
      altitude: altitude ?? this.altitude,
      distance: distance ?? this.distance,
      temperature: temperature ?? this.temperature,
      pressure: pressure ?? this.pressure,
      precipitation: precipitation ?? this.precipitation,
    );
  }

  Map<String, String> toJson() {
    return {
      'speed': speed.toString().split('.').last,
      'altitude': altitude.toString().split('.').last,
      'distance': distance.toString().split('.').last,
      'temperature': temperature.toString().split('.').last,
      'pressure': pressure.toString().split('.').last,
      'precipitation': precipitation.toString().split('.').last,
    };
  }

  static UnitPreferences fromJson(Map<String, dynamic> json) {
    return UnitPreferences(
      speed: _parseSpeedUnit(json['speed']),
      altitude: _parseAltitudeUnit(json['altitude']),
      distance: _parseDistanceUnit(json['distance']),
      temperature: _parseTemperatureUnit(json['temperature']),
      pressure: _parsePressureUnit(json['pressure']),
      precipitation: _parsePrecipitationUnit(json['precipitation']),
    );
  }

  static SpeedUnit _parseSpeedUnit(String? value) {
    return switch (value) {
      'ms' => SpeedUnit.ms,
      'kt' => SpeedUnit.kt,
      'mph' => SpeedUnit.mph,
      _ => SpeedUnit.kmh,
    };
  }

  static AltitudeUnit _parseAltitudeUnit(String? value) {
    return switch (value) {
      'ft' => AltitudeUnit.ft,
      _ => AltitudeUnit.m,
    };
  }

  static DistanceUnit _parseDistanceUnit(String? value) {
    return switch (value) {
      'm' => DistanceUnit.m,
      'nm' => DistanceUnit.nm,
      'mi' => DistanceUnit.mi,
      _ => DistanceUnit.km,
    };
  }

  static TemperatureUnit _parseTemperatureUnit(String? value) {
    return switch (value) {
      'f' => TemperatureUnit.f,
      _ => TemperatureUnit.c,
    };
  }

  static PressureUnit _parsePressureUnit(String? value) {
    return switch (value) {
      'inhg' => PressureUnit.inhg,
      _ => PressureUnit.hpa,
    };
  }

  static PrecipitationUnit _parsePrecipitationUnit(String? value) {
    return switch (value) {
      'inches' => PrecipitationUnit.inches,
      _ => PrecipitationUnit.mm,
    };
  }
}

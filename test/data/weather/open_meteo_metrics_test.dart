import 'package:aerocheck/data/weather/dto/open_meteo_forecast_response.dart';
import 'package:flutter_test/flutter_test.dart';

const _json = '''
{
 "timezone":"UTC","utc_offset_seconds":0,
 "current":{"time":"2026-06-16T13:00","temperature_2m":16,"apparent_temperature":14,
   "relative_humidity_2m":70,"pressure_msl":1013,"uv_index":4,"weather_code":3,"is_day":1},
 "hourly":{"time":["2026-06-16T13:00"],"temperature_2m":[16],"apparent_temperature":[14],
   "relative_humidity_2m":[70],"pressure_msl":[1012],"uv_index":[5],"weather_code":[61]}
}''';

void main() {
  test(
    'parses pressure, uv, weather_code, apparent temp and hourly humidity',
    () {
      final bundle = OpenMeteoForecastResponse.fromJsonString(
        _json,
      ).toWeatherBundle(locationLabel: 'x');
      expect(bundle.current.pressureHpa, 1013);
      expect(bundle.current.uvIndex, 4);
      expect(bundle.current.weatherCode, 3);
      expect(bundle.current.apparentTemperatureC, 14);
      final h = bundle.hourlySnapshots.first;
      expect(h.relativeHumidityPercent, 70);
      expect(h.pressureHpa, 1012);
      expect(h.uvIndex, 5);
      expect(h.weatherCode, 61);
      expect(h.apparentTemperatureC, 14);
    },
  );
}

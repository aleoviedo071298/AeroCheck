import 'package:aerocheck/data/weather/dto/open_meteo_forecast_response.dart';
import 'package:flutter_test/flutter_test.dart';

const _withDaily = '''
{
 "timezone":"America/Argentina/Catamarca","utc_offset_seconds":-10800,
 "current":{"time":"2026-06-16T13:00","temperature_2m":16,"is_day":1},
 "hourly":{"time":["2026-06-16T13:00"],"temperature_2m":[16]},
 "daily":{"time":["2026-06-16","2026-06-17"],
   "sunrise":["2026-06-16T08:10","2026-06-17T08:11"],
   "sunset":["2026-06-16T18:05","2026-06-17T18:06"]}
}''';

const _noDaily = '''
{
 "timezone":"UTC","utc_offset_seconds":0,
 "current":{"time":"2026-06-16T13:00","temperature_2m":16,"is_day":1},
 "hourly":{"time":["2026-06-16T13:00"],"temperature_2m":[16]}
}''';

void main() {
  test('parses daily sunrise/sunset into dailySun', () {
    final bundle = OpenMeteoForecastResponse.fromJsonString(
      _withDaily,
    ).toWeatherBundle(locationLabel: 'x');
    expect(bundle.dailySun.length, 2);
    final day = bundle.sunTimesFor(DateTime(2026, 6, 16))!;
    expect(day.sunrise, DateTime(2026, 6, 16, 8, 10));
    expect(day.sunset, DateTime(2026, 6, 16, 18, 5));
  });

  test('missing daily yields an empty dailySun, no throw', () {
    final bundle = OpenMeteoForecastResponse.fromJsonString(
      _noDaily,
    ).toWeatherBundle(locationLabel: 'x');
    expect(bundle.dailySun, isEmpty);
    expect(bundle.sunTimesFor(DateTime(2026, 6, 16)), isNull);
  });
}

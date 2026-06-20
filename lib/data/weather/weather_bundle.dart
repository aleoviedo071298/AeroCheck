import '../../domain/entities/weather_snapshot.dart';
import '../mock/mock_flight_data.dart';

class DaySunTimes {
  const DaySunTimes({
    required this.date,
    required this.sunrise,
    required this.sunset,
  });

  final DateTime date; // normalized to midnight
  final DateTime sunrise;
  final DateTime sunset;
}

class WeatherBundle {
  const WeatherBundle({
    required this.providerName,
    required this.locationLabel,
    required this.timezone,
    required this.current,
    required this.hourlySnapshots,
    required this.windProfileRows,
    this.dailySun = const [],
  });

  final String providerName;
  final String locationLabel;
  final String timezone;
  final WeatherSnapshot current;
  final List<WeatherSnapshot> hourlySnapshots;
  final List<WindProfileRow> windProfileRows;
  final List<DaySunTimes> dailySun;

  DaySunTimes? sunTimesFor(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    for (final d in dailySun) {
      if (d.date == key) return d;
    }
    return null;
  }

  WeatherBundle copyWithKpIndex(double kpIndex) {
    return WeatherBundle(
      providerName: providerName,
      locationLabel: locationLabel,
      timezone: timezone,
      current: current.copyWith(kpIndex: kpIndex),
      hourlySnapshots: hourlySnapshots
          .map((snapshot) => snapshot.copyWith(kpIndex: kpIndex))
          .toList(),
      windProfileRows: windProfileRows,
      dailySun: dailySun,
    );
  }
}

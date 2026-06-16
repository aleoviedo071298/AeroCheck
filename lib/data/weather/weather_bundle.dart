import '../../domain/entities/weather_snapshot.dart';
import '../mock/mock_flight_data.dart';

class WeatherBundle {
  const WeatherBundle({
    required this.providerName,
    required this.locationLabel,
    required this.timezone,
    required this.current,
    required this.hourlySnapshots,
    required this.windProfileRows,
  });

  final String providerName;
  final String locationLabel;
  final String timezone;
  final WeatherSnapshot current;
  final List<WeatherSnapshot> hourlySnapshots;
  final List<WindProfileRow> windProfileRows;
}

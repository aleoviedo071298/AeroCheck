import '../../data/mock/mock_flight_data.dart';
import '../entities/drone_profile.dart';
import '../entities/mission_profile.dart';

class EvaluatedWindProfileRow {
  const EvaluatedWindProfileRow({
    required this.altitude,
    required this.windKmh,
    required this.gustKmh,
    required this.temperatureC,
    required this.status,
    required this.limitExceededAt,
    this.windDirectionDegrees,
  });

  final String altitude;
  final double windKmh;
  final double gustKmh;
  final double temperatureC;
  final String status; // 'ok', 'warning', or 'blocked'
  final String? limitExceededAt; // 'wind', 'gust', or null if ok
  final double? windDirectionDegrees;

  WindProfileRow toBaseRow() => WindProfileRow(
    altitude: altitude,
    windKmh: windKmh,
    gustKmh: gustKmh,
    temperatureC: temperatureC,
    windDirectionDegrees: windDirectionDegrees,
  );
}

class WindProfileEvaluator {
  const WindProfileEvaluator({
    required this.droneProfile,
    required this.missionProfile,
  });

  final DroneProfile droneProfile;
  final MissionProfile missionProfile;

  List<EvaluatedWindProfileRow> evaluateProfile(List<WindProfileRow> rows) {
    return rows.map(evaluateRow).toList();
  }

  EvaluatedWindProfileRow evaluateRow(WindProfileRow row) {
    final effectiveMaxWind =
        droneProfile.maxWindKmh * missionProfile.windModifier;
    final effectiveMaxGust =
        droneProfile.maxGustKmh * missionProfile.gustModifier;

    String status = 'ok';
    String? limitExceededAt;

    if (row.windKmh > effectiveMaxWind) {
      status = 'blocked';
      limitExceededAt = 'wind';
    } else if (row.gustKmh > effectiveMaxGust) {
      status = 'blocked';
      limitExceededAt = 'gust';
    } else if (row.windKmh > effectiveMaxWind * 0.8) {
      status = 'warning';
      limitExceededAt = 'wind';
    } else if (row.gustKmh > effectiveMaxGust * 0.8) {
      status = 'warning';
      limitExceededAt = 'gust';
    }

    return EvaluatedWindProfileRow(
      altitude: row.altitude,
      windKmh: row.windKmh,
      gustKmh: row.gustKmh,
      temperatureC: row.temperatureC,
      status: status,
      limitExceededAt: limitExceededAt,
      windDirectionDegrees: row.windDirectionDegrees,
    );
  }

  WindProfileRow findBestWindAltitude(List<WindProfileRow> rows) {
    if (rows.isEmpty) {
      return const WindProfileRow(
        altitude: 'N/A',
        windKmh: 0,
        gustKmh: 0,
        temperatureC: 0,
      );
    }

    WindProfileRow best = rows.first;
    double bestScore = _scoreAltitude(best);

    for (final row in rows.skip(1)) {
      final score = _scoreAltitude(row);
      if (score > bestScore) {
        bestScore = score;
        best = row;
      }
    }

    return best;
  }

  // Lower wind and gust = higher score
  double _scoreAltitude(WindProfileRow row) {
    return -(row.windKmh + row.gustKmh / 2);
  }
}

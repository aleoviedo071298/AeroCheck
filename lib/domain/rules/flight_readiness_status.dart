enum FlightReadinessStatus { ready, caution, notReady }

extension FlightReadinessStatusLabel on FlightReadinessStatus {
  String get label => switch (this) {
    FlightReadinessStatus.ready => 'APTO',
    FlightReadinessStatus.caution => 'PRECAUCION',
    FlightReadinessStatus.notReady => 'NO APTO',
  };
}

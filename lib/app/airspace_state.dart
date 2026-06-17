import '../data/regulatory/airport.dart';
import '../data/regulatory/airspace.dart';

sealed class AirspaceState {
  const AirspaceState();
}

class AirspaceLoadingState extends AirspaceState {
  const AirspaceLoadingState();
}

class AirspaceLoadedState extends AirspaceState {
  const AirspaceLoadedState({required this.airspaces, required this.airports});

  final List<Airspace> airspaces;
  final List<Airport> airports;
}

class AirspaceEmptyState extends AirspaceState {
  const AirspaceEmptyState();
}

class AirspaceErrorState extends AirspaceState {
  const AirspaceErrorState(this.error);

  final Object error;
}

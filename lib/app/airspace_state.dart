import '../data/regulatory/airspace.dart';

sealed class AirspaceState {
  const AirspaceState();
}

class AirspaceLoadingState extends AirspaceState {
  const AirspaceLoadingState();
}

class AirspaceLoadedState extends AirspaceState {
  const AirspaceLoadedState(this.airspaces);

  final List<Airspace> airspaces;
}

class AirspaceEmptyState extends AirspaceState {
  const AirspaceEmptyState();
}

class AirspaceErrorState extends AirspaceState {
  const AirspaceErrorState(this.error);

  final Object error;
}

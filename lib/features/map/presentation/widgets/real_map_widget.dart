import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/airspace_state.dart';
import '../../../../data/location/flight_location.dart';
import '../../../../data/mock/mock_sensitive_zone.dart';
import '../../../../data/regulatory/airspace.dart';

class RealMapWidget extends StatefulWidget {
  const RealMapWidget({
    super.key,
    required this.location,
    required this.guideRadiusKm,
    required this.detectedMockZones,
    required this.airspaceState,
  });

  final FlightLocation location;
  final double guideRadiusKm;
  final List<MockSensitiveZoneDetection> detectedMockZones;
  final AirspaceState airspaceState;

  @override
  State<RealMapWidget> createState() => _RealMapWidgetState();
}

class _RealMapWidgetState extends State<RealMapWidget> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitBounds();
    });
  }

  @override
  void didUpdateWidget(RealMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location ||
        oldWidget.guideRadiusKm != widget.guideRadiusKm) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitBounds();
      });
    }
  }

  void _fitBounds() {
    final location = LatLng(
      widget.location.latitude,
      widget.location.longitude,
    );
    _mapController.move(location, 13);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = LatLng(
      widget.location.latitude,
      widget.location.longitude,
    );
    developer.log(
      'Location: ${widget.location.label} at (${widget.location.latitude}, ${widget.location.longitude})',
      name: 'AeroCheck.Map',
    );

    final layers = <Widget>[
      // Base map layer
      TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.aerocheck.app',
      ),

      // Guide radius circle
      CircleLayer(
        circles: [
          CircleMarker(
            point: location,
            radius: widget.guideRadiusKm * 111,
            useRadiusInMeter: true,
            color: Colors.blue.withValues(alpha: 0.1),
            borderColor: Colors.blue.withValues(alpha: 0.5),
            borderStrokeWidth: 2,
          ),
        ],
      ),

      // OpenAIP airspaces
      if (widget.airspaceState is AirspaceLoadedState) ...[
        _buildAirspaceDebugLayer(),
        PolygonLayer(
          polygons: (widget.airspaceState as AirspaceLoadedState).airspaces
              .map((airspace) => _buildAirspacePolygon(airspace))
              .toList(),
        ),
      ],

      // Mock sensitive zones
      MarkerLayer(
        markers: widget.detectedMockZones.map((detection) {
          final zone = detection.zone;
          developer.log(
            'Mock zone: ${zone.name} at (${zone.latitude}, ${zone.longitude})',
            name: 'AeroCheck.Map',
          );
          return Marker(
            point: LatLng(zone.latitude, zone.longitude),
            width: 24,
            height: 24,
            alignment: Alignment.center,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.8),
                  width: 2,
                ),
                color: Colors.red.withValues(alpha: 0.2),
              ),
            ),
          );
        }).toList(),
      ),

      // Location marker
      MarkerLayer(
        markers: [
          Marker(
            point: location,
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: const Icon(
              Icons.location_on_rounded,
              color: Colors.blue,
              size: 32,
            ),
          ),
        ],
      ),
    ];

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: location,
        initialZoom: 13,
        minZoom: 5,
        maxZoom: 19,
      ),
      children: layers,
    );
  }

  Polygon _buildAirspacePolygon(Airspace airspace) {
    final points = airspace.coordinates
        .map((coord) => LatLng(coord.latitude, coord.longitude))
        .toList();

    final (fillColor, borderColor) = _colorForAirspace(airspace);

    return Polygon(
      points: points,
      color: fillColor,
      borderColor: borderColor,
      borderStrokeWidth: 2,
      isDotted: false,
      label: airspace.name,
    );
  }

  (Color fillColor, Color borderColor) _colorForAirspace(Airspace airspace) {
    const controlled = {0, 1, 2, 3}; // Classes A, B, C, D

    if (controlled.contains(airspace.icaoClassCode)) {
      return (
        Colors.red.withValues(alpha: 0.4),
        Colors.red.withValues(alpha: 0.9),
      );
    } else {
      return (
        Colors.yellow.withValues(alpha: 0.35),
        Colors.orange.withValues(alpha: 0.85),
      );
    }
  }

  Widget _buildAirspaceDebugLayer() {
    final state = widget.airspaceState;
    if (state is! AirspaceLoadedState) {
      return const SizedBox();
    }

    final airspaces = state.airspaces;
    developer.log(
      'OpenAIP: Loaded ${airspaces.length} airspaces',
      name: 'AeroCheck.Map',
    );

    for (final airspace in airspaces) {
      developer.log(
        '${airspace.name}: ${airspace.coordinates.length} coords, Class ${airspace.icaoClassLabel}',
        name: 'AeroCheck.Map',
      );
      if (airspace.coordinates.isNotEmpty) {
        final first = airspace.coordinates.first;
        developer.log(
          'First coord: ${first.latitude}, ${first.longitude}',
          name: 'AeroCheck.Map',
        );
      }
    }

    final markers = airspaces
        .map((airspace) {
          if (airspace.coordinates.isEmpty) return null;
          final centerLat =
              airspace.coordinates
                  .map((c) => c.latitude)
                  .reduce((a, b) => a + b) /
              airspace.coordinates.length;
          final centerLng =
              airspace.coordinates
                  .map((c) => c.longitude)
                  .reduce((a, b) => a + b) /
              airspace.coordinates.length;

          return Marker(
            point: LatLng(centerLat, centerLng),
            width: 30,
            height: 30,
            alignment: Alignment.center,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green,
                border: Border.all(color: Colors.green.shade900, width: 2),
              ),
              child: const Center(
                child: Text(
                  'A',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          );
        })
        .whereType<Marker>()
        .toList();

    return MarkerLayer(markers: markers);
  }
}

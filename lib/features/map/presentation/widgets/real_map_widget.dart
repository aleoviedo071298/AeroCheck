import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/airspace_state.dart';
import '../../../../data/location/flight_location.dart';
import '../../../../data/regulatory/airspace.dart';

class RealMapWidget extends StatefulWidget {
  const RealMapWidget({
    super.key,
    required this.location,
    required this.guideRadiusKm,
    required this.airspaceState,
  });

  final FlightLocation location;
  final double guideRadiusKm;
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
            radius: widget.guideRadiusKm * 1000,
            useRadiusInMeter: true,
            color: Colors.blue.withValues(alpha: 0.1),
            borderColor: Colors.blue.withValues(alpha: 0.5),
            borderStrokeWidth: 2,
          ),
        ],
      ),

      // OpenAIP airspaces & airports
      if (widget.airspaceState is AirspaceLoadedState) ...[
        // 1. Draw Special Use Airspace polygons (Restricted, Danger, Prohibited: types 1, 2, 3)
        PolygonLayer(
          polygons: (widget.airspaceState as AirspaceLoadedState).airspaces
              .where(
                (a) => a.typeCode == 1 || a.typeCode == 2 || a.typeCode == 3,
              )
              .map((airspace) => _buildAirspacePolygon(airspace))
              .toList(),
        ),
        // 2. Draw 5 km Drone Restricted Area circles around airports (types 1, 2, 3, 4)
        CircleLayer(
          circles: (widget.airspaceState as AirspaceLoadedState).airports
              .where(
                (ap) =>
                    ap.typeCode == 1 ||
                    ap.typeCode == 2 ||
                    ap.typeCode == 3 ||
                    ap.typeCode == 4,
              )
              .map(
                (airport) => CircleMarker(
                  point: LatLng(airport.latitude, airport.longitude),
                  radius: 5000, // 5 km
                  useRadiusInMeter: true,
                  color: Colors.red.withValues(alpha: 0.1),
                  borderColor: Colors.red.withValues(alpha: 0.6),
                  borderStrokeWidth: 2,
                ),
              )
              .toList(),
        ),
      ],

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
        Colors.red.withValues(alpha: 0.08),
        Colors.red.withValues(alpha: 0.6),
      );
    } else {
      return (
        Colors.yellow.withValues(alpha: 0.05),
        Colors.orange.withValues(alpha: 0.5),
      );
    }
  }
}

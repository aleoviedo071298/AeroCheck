import 'package:aerocheck/app/airspace_state.dart';
import 'package:aerocheck/data/location/flight_location.dart';
import 'package:aerocheck/features/map/presentation/widgets/real_map_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('RealMapWidget renders map layers and buttons', (tester) async {
    const mockLocation = FlightLocation(
      id: 'test',
      name: 'Test Location',
      region: 'Test Region',
      country: 'Test Country',
      latitude: -45.8641,
      longitude: -67.4966,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RealMapWidget(
            location: mockLocation,
            guideRadiusKm: 5.0,
            airspaceState: AirspaceEmptyState(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify map is rendered
    expect(find.byType(FlutterMap), findsOneWidget);

    // Verify overlay buttons are rendered (Layers and GPS center)
    expect(find.byIcon(Icons.layers_rounded), findsOneWidget);
    expect(find.byIcon(Icons.gps_fixed_rounded), findsOneWidget);

    // Get the base map TileLayer
    var tileLayerFinder = find
        .descendant(
          of: find.byType(FlutterMap),
          matching: find.byType(TileLayer),
        )
        .first;
    var tileLayer = tester.widget<TileLayer>(tileLayerFinder);

    // Verify initially it points to OpenStreetMap
    expect(tileLayer.urlTemplate, contains('openstreetmap.org'));

    // Tap layer toggle button
    await tester.tap(find.byIcon(Icons.layers_rounded));
    await tester.pumpAndSettle();

    // Verify TileLayer URL template changed to ArcGIS Online satellite view
    tileLayer = tester.widget<TileLayer>(tileLayerFinder);
    expect(tileLayer.urlTemplate, contains('arcgisonline.com'));

    // Tap layer toggle button again to switch back
    await tester.tap(find.byIcon(Icons.layers_rounded));
    await tester.pumpAndSettle();

    tileLayer = tester.widget<TileLayer>(tileLayerFinder);
    expect(tileLayer.urlTemplate, contains('openstreetmap.org'));
  });
}

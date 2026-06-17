# Real Map Visualization MVP Spec

## Objective

Replace the map placeholder with a real interactive map using OpenStreetMap (free). Display drone location, guide radius, OpenAIP airspaces, and mock sensitive zones on a live map.

## Data sources (all free)

1. **OpenStreetMap** - base map tiles (via flutter_map)
2. **OpenAIP** - airspace polygons (already integrated)
3. **Mock sensitive zones** - test zones (already available)
4. **Device location** - GPS (optional, for future MVP+)

## What's new

1. **Interactive Map Widget** (replaces placeholder)
   - Zoom and pan enabled
   - Center on selected location
   - Auto-zoom to fit all visible elements

2. **Map Layers**
   - Base layer: OpenStreetMap (tile-based)
   - Location marker: Selected location (blue pin)
   - Guide radius: Circle overlay (0.5-15 km configurable)
   - OpenAIP airspaces: Polygon overlays with class colors (A-G)
   - Mock sensitive zones: Red circle overlays
   - Attribution: OpenStreetMap + OpenAIP credits

3. **Visual Design**
   - Guide radius: Blue semi-transparent circle
   - Location marker: Centered blue pin icon
   - OpenAIP polygons: Color by ICAO class
     - A, B, C, D (controlled): Red/orange with opacity
     - E, F, G (uncontrolled): Yellow/light orange
   - Mock zones: Red circle with dashed border
   - Info popup on tap: Show airspace name, class, type

4. **Responsive Behavior**
   - Zoom to fit all airspaces + location (on load)
   - Pan with finger
   - Zoom with pinch/double-tap
   - Recenter on location when selected

## Commands

```powershell
flutter pub add flutter_map
dart format lib test docs
flutter test
flutter analyze
```

## Project structure

```text
lib/
  features/
    map/
      presentation/
        pages/
          map_page.dart                  ← update: use real map
        widgets/
          map_widget.dart                ← new: flutter_map wrapper
          airspace_marker.dart           ← new: airspace popup
          location_marker.dart           ← new: location pin
          guide_radius_circle.dart       ← new: guide radius overlay
  domain/
    models/
      map_layer.dart                     ← new: layer visibility states
```

Test structure:

```text
test/
  features/
    map/
      presentation/
        widgets/
          map_widget_test.dart           ← new: map rendering tests
```

## Testing strategy

1. **Map Widget Tests**
   - Verify map renders with correct center and zoom
   - Verify layers are added (airspace, location, radius)
   - Verify zoom bounds respect airspace extent

2. **Airspace Polygon Rendering**
   - Verify polygons from OpenAIP are drawn
   - Verify colors match ICAO class
   - Verify tap shows info popup

3. **Location Marker**
   - Verify marker is centered on selected location
   - Verify marker updates when location changes

4. **Guide Radius**
   - Verify circle radius matches configured km
   - Verify circle updates on radius change

## Boundaries

- **MVP table-only visualization**: No 3D terrain or satellite imagery in this slice.
- **No user location (GPS)**: Start with selected location from favorites only.
- **No map editing**: Can't draw or modify on map yet.
- **No custom basemap**: Use OSM default.
- **Free tier only**: No paid map services (Mapbox, Google Maps Pro).
- **Offline not supported**: Requires internet for tiles.

## Dependencies

```yaml
flutter_map: ^6.0.0  # OpenStreetMap-based mapping
latlong2: ^0.9.0     # Lat/lng utilities
```

## Success criteria

- [ ] Interactive OpenStreetMap renders with flutter_map.
- [ ] Guide radius circle updates on slider change.
- [ ] OpenAIP airspaces render as colored polygons.
- [ ] Mock sensitive zones render as red circles.
- [ ] Tap on airspace shows popup with details.
- [ ] Map auto-zooms to fit all elements on load.
- [ ] Location marker centers on selected location.
- [ ] Map credits (OpenStreetMap, OpenAIP) are visible.
- [ ] All tests pass, code formatted, analyze clean.
- [ ] No secrets or build outputs staged.

## Open questions

1. Should map allow tap-to-select new locations?
2. Should we show wind arrows/barbs on the map?
3. Should we add a "my location" button for GPS?
4. Should airspace tap show altitude limits?
5. Should we cache offline map tiles in future MVP+?

## Acceptance criteria

- Real interactive map renders using free OpenStreetMap data.
- All existing map layers (airspace, zones, radius) display correctly.
- Map is zoomable, pannable, and responsive.
- Map updates when location or radius changes.
- User can see flight planning context at a glance.

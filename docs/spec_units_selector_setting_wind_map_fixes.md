# Spec: Improve Units Page, Settings Header, Wind Header, and Map Actions

## Objective

1. **Improve the Unit Selector UI**: Redesign the Units configuration screen (`units_screen.dart`) to match the user's uploaded photo:
   - A single unified card with thin borders and circular/rounded items.
   - Clean rows showing icons, title, and descriptive subtitle.
   - Customized horizontal button segmented options on the right with a green checkmark and green background for the active choice.
   - Align labels to both Spanish and English.
2. **Settings Screen share button**: Remove the share/upload button from the top right of the Settings screen header.
3. **Wind Screen info button**: Remove the circle-i info button from the top right of the Vertical profile header.
4. **Map Screen overlay buttons**: Implement the functionality of the two map buttons:
   - Layer Button (`Icons.layers_rounded`): Toggle between standard OpenStreetMap tiles and satellite imagery (Esri World Imagery).
   - GPS/Center Button (`Icons.gps_fixed_rounded`): Re-center map view and fit bounds on the selected target location.

## Commands

```text
dart format lib test
flutter test
flutter analyze
```

## Project Structure

```text
lib/features/settings/screens/units_screen.dart (Redesign layout, custom button selections, and subtitles)
lib/features/settings/settings_screen.dart (Remove share button)
lib/features/wind/wind_screen.dart (Remove info button)
lib/features/map/map_screen.dart (Remove dummy actions, delegate buttons to map widget)
lib/features/map/presentation/widgets/real_map_widget.dart (Add buttons to stack overlay, implement satellite toggle and GPS centering)
```

## Testing Strategy

- Update unit and widget tests in `test/features/settings/settings_screen_test.dart` or `test/features/wind/wind_screen_test.dart` if they assert on deleted elements (e.g. sharing or info dialog actions).
- Verify map overlay buttons do not throw exceptions.
- Keep all existing tests green.

## Boundaries

- Do not alter underlying unit converter math or persistent preference keys.
- Do not affect airspace data query logic or visibility rules.

## Success Criteria

- The Units screen matches the look of the design: clean row icons, subtitles, and checkmarked selection buttons.
- The Settings and Wind screens no longer display the share and info icon buttons in their headers respectively.
- Pressing the GPS button on the map moves the map controller back to the target location.
- Pressing the Layer button toggles between OSM map tiles and satellite view.

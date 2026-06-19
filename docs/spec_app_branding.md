# Spec: App Branding (Name and Icon)

## Objective

Configure the application branding so that when installed on a device (Android and iOS), it is named "AeroCheck" and uses the header logo (`assets/images/logo.png`) as its launcher icon.

## Commands

```text
flutter pub get
dart run flutter_launcher_icons
dart format lib test docs
flutter test
flutter analyze
```

## Project Structure

```text
pubspec.yaml
  - Add flutter_launcher_icons dev dependency and its configuration.
android/app/src/main/AndroidManifest.xml
  - Change android:label to "AeroCheck"
ios/Runner/Info.plist
  - Change CFBundleDisplayName and CFBundleName to "AeroCheck"
android/app/src/main/res/
  - Generated icon assets in mipmap folders
ios/Runner/Assets.xcassets/AppIcon.appiconset/
  - Generated icon assets
```

## Testing Strategy

- Build check: Verify the application compiles successfully after generating the launcher icons.
- File validation: Check that `AndroidManifest.xml` and `Info.plist` files are correctly modified and valid.
- Asset verification: Confirm that mipmap launcher icons and iOS AppIcon images are updated with the header logo image content.

## Boundaries

- Only update platform branding assets (display names and launcher icons).
- Do not modify any operational logic, decision rules, or UI themes/components.
- Use `assets/images/logo.png` as the single source of truth for the icon.

## Success Criteria

- App compiles and runs without issues.
- When installed, the app name shows as "AeroCheck" on both platforms.
- The launcher icon matches `assets/images/logo.png`.
- `flutter test` and `flutter analyze` pass.

## Open Questions

None.

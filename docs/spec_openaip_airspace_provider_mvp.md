# Spec: OpenAIP Airspace Provider MVP

## Objective

Prepare an OpenAIP Core API adapter for nearby airspace lookup.

The MVP should:

- Use OpenAIP `GET /airspaces` with `pos`, `dist`, `limit`, and `fields`.
- Send the API key in the `x-openaip-api-key` header.
- Keep the API key out of source control and documentation examples.
- Parse a compact airspace model for later map/status integration.
- Keep current mock sensitive-zone behavior unchanged in this slice.

## Commands

```text
dart format lib test docs
flutter test
flutter analyze
```

## Project Structure

```text
lib/data/regulatory/airspace.dart
lib/data/regulatory/airspace_repository.dart
lib/data/regulatory/openaip_airspace_repository.dart
lib/data/regulatory/openaip_config.dart
lib/data/regulatory/regulatory_repository_exception.dart
test/data/regulatory/openaip_airspace_repository_test.dart
```

## Configuration

For local experiments, pass the OpenAIP key with:

```text
flutter run --dart-define=OPENAIP_API_KEY=...
```

Do not commit the key. For production mobile releases, prefer a backend/proxy because API keys embedded in Android/iOS apps can be extracted.

## Testing Strategy

- Unit test verifies request URL, query parameters, and header authentication.
- Unit test verifies OpenAIP airspace JSON maps into the compact model.
- Unit test verifies non-success responses and missing keys fail with controlled exceptions.

## Boundaries

- Do not connect OpenAIP to flight readiness rules in this slice.
- Do not present OpenAIP data as official flight authorization.
- Do not add map tiles or vector rendering yet.

## Success Criteria

- OpenAIP adapter is implemented and tested.
- No secret is committed.
- `flutter test` passes.
- `flutter analyze` passes.

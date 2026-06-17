import 'package:aerocheck/domain/entities/weather_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WeatherSnapshot.windDirectionCardinal', () {
    WeatherSnapshot createSnapshot(double? degrees) {
      return WeatherSnapshot(
        time: DateTime.now(),
        locationLabel: 'Test',
        windDirectionDegrees: degrees,
        isDaylight: true,
        isInsideRestrictedArea: false,
        isNearRestrictedArea: false,
      );
    }

    test('returns null when windDirectionDegrees is null', () {
      final snapshot = createSnapshot(null);
      expect(snapshot.windDirectionCardinal, isNull);
    });

    test('correctly maps primary directions', () {
      expect(createSnapshot(0).windDirectionCardinal, equals('N'));
      expect(createSnapshot(360).windDirectionCardinal, equals('N'));
      expect(createSnapshot(90).windDirectionCardinal, equals('E'));
      expect(createSnapshot(180).windDirectionCardinal, equals('S'));
      expect(createSnapshot(270).windDirectionCardinal, equals('O'));
    });

    test('correctly maps secondary directions', () {
      expect(createSnapshot(45).windDirectionCardinal, equals('NE'));
      expect(createSnapshot(135).windDirectionCardinal, equals('SE'));
      expect(createSnapshot(225).windDirectionCardinal, equals('SO'));
      expect(createSnapshot(315).windDirectionCardinal, equals('NO'));
    });

    test('correctly maps intermediate directions', () {
      expect(createSnapshot(22.5).windDirectionCardinal, equals('NNE'));
      expect(createSnapshot(67.5).windDirectionCardinal, equals('ENE'));
      expect(createSnapshot(112.5).windDirectionCardinal, equals('ESE'));
      expect(createSnapshot(157.5).windDirectionCardinal, equals('SSE'));
      expect(createSnapshot(202.5).windDirectionCardinal, equals('SSO'));
      expect(createSnapshot(247.5).windDirectionCardinal, equals('OSO'));
      expect(createSnapshot(292.5).windDirectionCardinal, equals('ONO'));
      expect(createSnapshot(337.5).windDirectionCardinal, equals('NNO'));
    });

    test('handles boundary degrees roundings', () {
      // 11.24 should be N, 11.25 should be NNE
      expect(createSnapshot(11.24).windDirectionCardinal, equals('N'));
      expect(createSnapshot(11.25).windDirectionCardinal, equals('NNE'));

      // 348.74 is NNO, 348.75 is N
      expect(createSnapshot(348.74).windDirectionCardinal, equals('NNO'));
      expect(createSnapshot(348.75).windDirectionCardinal, equals('N'));
    });

    test('handles negative angles and angles > 360', () {
      expect(
        createSnapshot(-45).windDirectionCardinal,
        equals('NO'),
      ); // -45 is 315 (NO)
      expect(
        createSnapshot(405).windDirectionCardinal,
        equals('NE'),
      ); // 405 is 45 (NE)
    });
  });
}

import 'package:aerocheck/data/kp_index/noaa_kp_index_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NoaaKpIndexService.interpretKp', () {
    test('returns "Quieto" for Kp < 3', () {
      expect(NoaaKpIndexService.interpretKp(0.0), 'Quieto');
      expect(NoaaKpIndexService.interpretKp(2.5), 'Quieto');
    });

    test('returns "Inestable" for 3 <= Kp < 5', () {
      expect(NoaaKpIndexService.interpretKp(3.0), 'Inestable');
      expect(NoaaKpIndexService.interpretKp(4.5), 'Inestable');
    });

    test('returns "Tormenta Menor" for 5 <= Kp < 7', () {
      expect(NoaaKpIndexService.interpretKp(5.0), 'Tormenta Menor');
      expect(NoaaKpIndexService.interpretKp(6.5), 'Tormenta Menor');
    });

    test('returns "Tormenta Mayor" for 7 <= Kp < 9', () {
      expect(NoaaKpIndexService.interpretKp(7.0), 'Tormenta Mayor');
      expect(NoaaKpIndexService.interpretKp(8.5), 'Tormenta Mayor');
    });

    test('returns "Tormenta Severa" for Kp >= 9', () {
      expect(NoaaKpIndexService.interpretKp(9.0), 'Tormenta Severa');
      expect(NoaaKpIndexService.interpretKp(9.5), 'Tormenta Severa');
    });
  });
}

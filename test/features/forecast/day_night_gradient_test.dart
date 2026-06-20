import 'package:aerocheck/features/forecast/day_night_gradient.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool nonDecreasing(List<double> s) {
    for (var i = 1; i < s.length; i++) {
      if (s[i] < s[i - 1]) return false;
    }
    return true;
  }

  test('full day produces a multi-stop gradient within [0,1]', () {
    final g = dayNightGradient(
      trackStart: DateTime(2026, 6, 16, 0),
      trackEnd: DateTime(2026, 6, 16, 23),
      sunrise: DateTime(2026, 6, 16, 6),
      sunset: DateTime(2026, 6, 16, 18),
    );
    expect(g.colors.length, g.stops.length);
    expect(g.stops.length, greaterThan(2));
    expect(g.stops.first, 0.0);
    expect(g.stops.last, 1.0);
    expect(nonDecreasing(g.stops), isTrue);
  });

  test('evening-only track (sunset before start) is solid night', () {
    final g = dayNightGradient(
      trackStart: DateTime(2026, 6, 16, 20),
      trackEnd: DateTime(2026, 6, 16, 23),
      sunrise: DateTime(2026, 6, 16, 6),
      sunset: DateTime(2026, 6, 16, 18),
    );
    expect(g.stops, [0.0, 1.0]);
    expect(g.colors.first, g.colors.last);
  });

  test('null sun returns a neutral 2-stop gradient', () {
    final g = dayNightGradient(
      trackStart: DateTime(2026, 6, 16, 0),
      trackEnd: DateTime(2026, 6, 16, 23),
    );
    expect(g.stops, [0.0, 1.0]);
    expect(g.colors.first, g.colors.last);
  });
}

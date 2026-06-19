// test/domain/rules/flight_rules_config_test.dart
import 'package:aerocheck/domain/rules/flight_rules_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults match the documented baseline values', () {
    const config = FlightRulesConfig.defaults();
    expect(config.windWarningKmh, 22);
    expect(config.windBlockedKmh, 28);
    expect(config.gustBlockedKmh, 40);
    expect(config.precipProbabilityBlockedPercent, 55);
    expect(config.visibilityBlockedKm, 2.8);
    expect(config.targetAltitudeMeters, 120);
    expect(config.kpBlocked, 6);
    expect(config.allowNightFlight, isFalse);
  });

  test('copyWith changes only the named field', () {
    const config = FlightRulesConfig.defaults();
    final updated = config.copyWith(windBlockedKmh: 35);
    expect(updated.windBlockedKmh, 35);
    expect(updated.windWarningKmh, config.windWarningKmh);
    expect(updated.gustBlockedKmh, config.gustBlockedKmh);
  });

  test('round-trips through JSON', () {
    final config = const FlightRulesConfig.defaults().copyWith(
      windBlockedKmh: 30,
      allowNightFlight: true,
      targetAltitudeMeters: 90,
    );
    final restored = FlightRulesConfig.fromJson(config.toJson());
    expect(restored, config);
  });

  test('fromJson falls back to defaults for missing keys', () {
    final restored = FlightRulesConfig.fromJson(const {});
    expect(restored, const FlightRulesConfig.defaults());
  });
}

import 'package:aerocheck/features/shared/weather_condition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps WMO codes to condition label keys', () {
    expect(weatherConditionFor(0).labelKey, 'cielo_despejado');
    expect(weatherConditionFor(2).labelKey, 'cielo_parcial');
    expect(weatherConditionFor(3).labelKey, 'cielo_nublado');
    expect(weatherConditionFor(45).labelKey, 'cielo_niebla');
    expect(weatherConditionFor(53).labelKey, 'cielo_llovizna');
    expect(weatherConditionFor(61).labelKey, 'cielo_lluvia');
    expect(weatherConditionFor(73).labelKey, 'cielo_nieve');
    expect(weatherConditionFor(95).labelKey, 'cielo_tormenta');
    expect(weatherConditionFor(null).labelKey, 'sin_dato');
  });
}

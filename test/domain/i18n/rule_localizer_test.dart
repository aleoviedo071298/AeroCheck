import 'package:aerocheck/domain/i18n/rule_localizer.dart';
import 'package:aerocheck/domain/i18n/language.dart';
import 'package:aerocheck/domain/rules/rule_severity.dart';
import 'package:aerocheck/domain/units/unit_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RuleLocalizer Tests', () {
    const unitsMetric = UnitPreferences(
      speed: SpeedUnit.kmh,
      altitude: AltitudeUnit.m,
      distance: DistanceUnit.km,
      temperature: TemperatureUnit.c,
      pressure: PressureUnit.hpa,
      precipitation: PrecipitationUnit.mm,
    );

    const unitsImperial = UnitPreferences(
      speed: SpeedUnit.ms,
      altitude: AltitudeUnit.ft,
      distance: DistanceUnit.mi,
      temperature: TemperatureUnit.f,
      pressure: PressureUnit.inhg,
      precipitation: PrecipitationUnit.inches,
    );

    test('translates rule titles correctly', () {
      expect(
        RuleLocalizer.getLocalizedTitle(
          'WIND_SPEED',
          RuleSeverity.blocked,
          Language.es,
        ),
        'Viento sobre el límite',
      );
      expect(
        RuleLocalizer.getLocalizedTitle(
          'WIND_SPEED',
          RuleSeverity.blocked,
          Language.en,
        ),
        'Wind over limit',
      );
      expect(
        RuleLocalizer.getLocalizedTitle(
          'DAYLIGHT',
          RuleSeverity.blocked,
          Language.es,
        ),
        'Vuelo nocturno no habilitado',
      );
      expect(
        RuleLocalizer.getLocalizedTitle(
          'DAYLIGHT',
          RuleSeverity.blocked,
          Language.en,
        ),
        'Night flight not enabled',
      );
    });

    test('formats rule details with correct units', () {
      expect(
        RuleLocalizer.getLocalizedDetails(
          'WIND_SPEED',
          RuleSeverity.blocked,
          39.3,
          23.8,
          Language.es,
          unitsMetric,
        ),
        '39.3 km/h sobre límite de 23.8 km/h.',
      );

      expect(
        RuleLocalizer.getLocalizedDetails(
          'WIND_SPEED',
          RuleSeverity.blocked,
          39.3,
          23.8,
          Language.en,
          unitsImperial,
        ),
        '10.9 m/s over limit of 6.6 m/s.',
      );
    });
  });
}

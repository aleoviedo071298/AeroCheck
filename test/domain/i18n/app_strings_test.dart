import 'package:aerocheck/domain/i18n/app_strings.dart';
import 'package:aerocheck/domain/i18n/language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves representative screen strings in both languages', () {
    expect(
      AppStrings.get('forecast_horario', language: Language.es),
      'Forecast horario',
    );
    expect(
      AppStrings.get('forecast_horario', language: Language.en),
      'Hourly forecast',
    );
    expect(
      AppStrings.get('buscar_ciudad', language: Language.en),
      'Search city',
    );
    expect(
      AppStrings.get('estado_operativo', language: Language.en),
      'Operational status',
    );
    expect(
      AppStrings.get('indice_por_hora', language: Language.en),
      'Hourly index',
    );
    expect(
      AppStrings.get('opciones_futuras', language: Language.en),
      'Options available in future versions:',
    );
  });
}

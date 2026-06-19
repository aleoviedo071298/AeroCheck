import '../i18n/app_strings.dart';
import '../i18n/language.dart';

enum FlightReadinessStatus { ready, caution, notReady }

extension FlightReadinessStatusLabel on FlightReadinessStatus {
  String get label => switch (this) {
    FlightReadinessStatus.ready => 'APTO',
    FlightReadinessStatus.caution => 'PRECAUCION',
    FlightReadinessStatus.notReady => 'NO APTO',
  };

  String getLocalizedLabel({Language? language}) {
    return switch (this) {
      FlightReadinessStatus.ready => AppStrings.get('apto', language: language),
      FlightReadinessStatus.caution => AppStrings.get(
        'precaucion',
        language: language,
      ),
      FlightReadinessStatus.notReady => AppStrings.get(
        'no_apto',
        language: language,
      ),
    };
  }
}

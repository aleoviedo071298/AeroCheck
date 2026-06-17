enum Language { es, en }

extension LanguageDisplay on Language {
  String get displayName {
    return switch (this) {
      Language.es => 'Español',
      Language.en => 'English',
    };
  }

  String get code {
    return switch (this) {
      Language.es => 'es',
      Language.en => 'en',
    };
  }
}

class LanguageHelper {
  static Language fromCode(String code) {
    return switch (code) {
      'en' => Language.en,
      _ => Language.es,
    };
  }
}

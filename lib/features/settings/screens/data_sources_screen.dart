import 'package:flutter/material.dart';

import '../../../domain/i18n/app_strings.dart';
import '../../../domain/i18n/language.dart';

class DataSourcesScreen extends StatelessWidget {
  const DataSourcesScreen({super.key, required this.language});

  final Language language;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('fuentes_de_datos', language: language)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DataSourceCard(
              title: AppStrings.get('clima', language: language),
              source: AppStrings.get('open_meteo', language: language),
              usage: AppStrings.get('clima_uso', language: language),
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _DataSourceCard(
              title: AppStrings.get('geocoding', language: language),
              source: AppStrings.get(
                'open_meteo_geocoding',
                language: language,
              ),
              usage: AppStrings.get('geocoding_uso', language: language),
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _DataSourceCard(
              title: AppStrings.get('espacios_aereos', language: language),
              source: AppStrings.get('openaip', language: language),
              usage: AppStrings.get('espacios_uso', language: language),
              isDark: isDark,
            ),
            const SizedBox(height: 24),
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.get('importante', language: language),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.get('piloto_validar', language: language),
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataSourceCard extends StatelessWidget {
  const _DataSourceCard({
    required this.title,
    required this.source,
    required this.usage,
    required this.isDark,
  });

  final String title;
  final String source;
  final String usage;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF475569),
                  fontSize: 13,
                ),
                children: [
                  const TextSpan(
                    text: 'Fuente: ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: source),
                ],
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF475569),
                  fontSize: 13,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(
                    text: 'Uso: ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: usage),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

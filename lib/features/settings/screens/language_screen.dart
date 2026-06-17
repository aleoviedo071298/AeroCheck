import 'package:flutter/material.dart';

import '../../../domain/i18n/app_strings.dart';
import '../../../domain/i18n/language.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({
    super.key,
    required this.initialLanguage,
    required this.onSave,
  });

  final Language initialLanguage;
  final void Function(Language) onSave;

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late Language selectedLanguage;

  @override
  void initState() {
    super.initState();
    selectedLanguage = widget.initialLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.get('seleccionar_idioma', language: selectedLanguage),
        ),
        centerTitle: false,
      ),
      body: Container(
        color: const Color(0xFFF1F5F9),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...Language.values.map(
                (lang) => _LanguageOption(
                  language: lang,
                  isSelected: selectedLanguage == lang,
                  onTap: () {
                    setState(() {
                      selectedLanguage = lang;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        AppStrings.get('cancelar', language: selectedLanguage),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        widget.onSave(selectedLanguage);
                        Navigator.pop(context, selectedLanguage);
                      },
                      child: Text(
                        AppStrings.get('guardar', language: selectedLanguage),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  final Language language;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFF0F766E)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language.displayName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        language.code.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF0F766E),
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

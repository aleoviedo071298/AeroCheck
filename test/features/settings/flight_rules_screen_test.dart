import 'package:aerocheck/domain/i18n/language.dart';
import 'package:aerocheck/domain/rules/flight_rules_config.dart';
import 'package:aerocheck/domain/units/unit_preferences.dart';
import 'package:aerocheck/features/settings/screens/flight_rules_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host({
    required void Function(FlightRulesConfig) onSave,
    VoidCallback? onBack,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: FlightRulesScreen(
          initialConfig: const FlightRulesConfig.defaults(),
          units: const UnitPreferences(),
          language: Language.es,
          onSave: onSave,
          onBack: onBack ?? () {},
        ),
      ),
    );
  }

  testWidgets('renders the title and section headers', (tester) async {
    await tester.pumpWidget(host(onSave: (_) {}));
    expect(find.text('Reglas de vuelo'), findsOneWidget);
    expect(find.text('Viento'), findsWidgets);
  });

  testWidgets('increment then save returns a higher wind block', (tester) async {
    FlightRulesConfig? saved;
    await tester.pumpWidget(host(onSave: (c) => saved = c));

    await tester.tap(find.byKey(const ValueKey('plus-windBlockedKmh')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('flight-rules-save')));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.windBlockedKmh, greaterThan(28));
  });

  testWidgets('restore defaults reverts edits', (tester) async {
    FlightRulesConfig? saved;
    await tester.pumpWidget(host(onSave: (c) => saved = c));

    await tester.tap(find.byKey(const ValueKey('plus-windBlockedKmh')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('flight-rules-restore')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('flight-rules-save')));
    await tester.pump();

    expect(saved, const FlightRulesConfig.defaults());
  });
}

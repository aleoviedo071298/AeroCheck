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

  testWidgets('increment then save returns a higher wind block', (
    tester,
  ) async {
    FlightRulesConfig? saved;
    await tester.pumpWidget(host(onSave: (c) => saved = c));

    await tester.tap(find.byKey(const ValueKey('plus-windBlockedKmh')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('flight-rules-save')));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.windBlockedKmh, greaterThan(28));
  });

  testWidgets('temperature min block can go below zero', (tester) async {
    FlightRulesConfig? saved;
    await tester.pumpWidget(host(onSave: (c) => saved = c));

    // Scroll until the minus button for temperatureMinBlockedC is visible.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('minus-temperatureMinBlockedC')),
      100,
    );
    await tester.pump();

    // Default temperatureMinBlockedC is -5; tap minus 3 times → should reach -8.
    await tester.tap(find.byKey(const ValueKey('minus-temperatureMinBlockedC')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('minus-temperatureMinBlockedC')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('minus-temperatureMinBlockedC')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('flight-rules-save')));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.temperatureMinBlockedC, lessThan(-5));
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

  testWidgets('renders severity badges for parameters', (tester) async {
    await tester.pumpWidget(host(onSave: (_) {}));
    expect(find.text('Precaución'), findsWidgets);
    expect(find.text('Bloqueo'), findsWidgets);
  });

  testWidgets('warning cannot exceed block (direct polarity)', (tester) async {
    FlightRulesConfig? saved;
    await tester.pumpWidget(host(onSave: (c) => saved = c));

    // Default wind warning 22, block 28. Raising warning past block clamps it.
    for (var i = 0; i < 12; i++) {
      await tester.tap(find.byKey(const ValueKey('plus-windWarningKmh')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const ValueKey('flight-rules-save')));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.windWarningKmh, lessThanOrEqualTo(saved!.windBlockedKmh));
  });

  testWidgets('warning cannot drop below block (inverted polarity)', (
    tester,
  ) async {
    FlightRulesConfig? saved;
    await tester.pumpWidget(host(onSave: (c) => saved = c));

    // Visibility is inverted: warning (4 km) must stay >= block (2.8 km).
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('minus-visibilityWarningKm')),
      100,
    );
    await tester.pump();
    for (var i = 0; i < 8; i++) {
      await tester.tap(find.byKey(const ValueKey('minus-visibilityWarningKm')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const ValueKey('flight-rules-save')));
    await tester.pump();

    expect(saved, isNotNull);
    expect(
      saved!.visibilityWarningKm,
      greaterThanOrEqualTo(saved!.visibilityBlockedKm),
    );
  });
}

import 'package:aerocheck/features/shared/widgets/metric_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders label, value and sub-value', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MetricCard(
            label: 'VIENTO',
            value: '14 km/h',
            subValue: '↗ NO 274°',
            icon: Icons.air_rounded,
            accentColor: Color(0xFF0EA5E9),
          ),
        ),
      ),
    );
    expect(find.text('VIENTO'), findsOneWidget);
    expect(find.text('14 km/h'), findsOneWidget);
    expect(find.text('↗ NO 274°'), findsOneWidget);
  });
}

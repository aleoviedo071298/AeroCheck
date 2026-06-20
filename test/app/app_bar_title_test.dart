import 'package:aerocheck/app/widgets/app_bar_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the location line when a location is given', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(56),
            child: AppBarTitle(location: 'Comodoro Rivadavia'),
          ),
        ),
      ),
    );
    expect(find.text('AeroCheck'), findsOneWidget);
    expect(find.text('Comodoro Rivadavia'), findsOneWidget);
  });

  testWidgets('hides the location line when null', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(56),
            child: AppBarTitle(),
          ),
        ),
      ),
    );
    expect(find.text('AeroCheck'), findsOneWidget);
    expect(find.text('Comodoro Rivadavia'), findsNothing);
  });
}

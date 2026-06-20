import 'package:aerocheck/app/widgets/app_bar_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the AeroCheck title', (tester) async {
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
  });
}

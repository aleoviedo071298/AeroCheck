import 'package:aerocheck/app/aerocheck_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('conditions screen renders status, reasons, and best window', (
    tester,
  ) async {
    await tester.pumpWidget(const AeroCheckApp());

    expect(find.text('AeroCheck'), findsOneWidget);
    expect(find.text('PRECAUCION'), findsOneWidget);
    expect(find.text('Motivos'), findsOneWidget);
    expect(find.text('Mejor ventana'), findsOneWidget);
    expect(find.textContaining('Comodoro Rivadavia'), findsOneWidget);
  });
}

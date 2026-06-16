import 'package:aerocheck/app/aerocheck_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('conditions screen renders status, reasons, and best window', (
    tester,
  ) async {
    await tester.pumpWidget(const AeroCheckApp());

    expect(find.text('AeroCheck'), findsOneWidget);
    expect(find.text('PRECAUCION'), findsWidgets);
    expect(find.text('Motivos'), findsOneWidget);
    expect(find.text('Mejor ventana'), findsOneWidget);
    expect(find.textContaining('Comodoro Rivadavia'), findsOneWidget);
  });

  testWidgets('conditions screen can switch between mock scenarios', (
    tester,
  ) async {
    await tester.pumpWidget(const AeroCheckApp());

    await tester.tap(find.text('APTO').first);
    await tester.pumpAndSettle();

    expect(find.text('APTO'), findsWidgets);
    expect(find.text('No hay alertas para esta ventana.'), findsOneWidget);

    await tester.tap(find.text('NO APTO').first);
    await tester.pumpAndSettle();

    expect(find.text('NO APTO'), findsWidgets);
    expect(find.textContaining('Dentro de zona restringida'), findsOneWidget);
  });
}

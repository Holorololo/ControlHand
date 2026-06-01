import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:movilcontrol/app/app.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('renders dashboard shell without backend', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MovilControlApp(autoConnect: false));

    expect(find.text('MovilControl'), findsOneWidget);
    expect(find.text('Conexion local'), findsOneWidget);
    expect(find.text('Camara y deteccion'), findsOneWidget);
    expect(find.text('Pista del auto'), findsOneWidget);
    expect(find.text('Conectar'), findsOneWidget);
  });
}

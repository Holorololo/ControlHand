import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:movilcontrol/app/app.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('renders desktop shell without backend', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MovilControlApp(autoConnect: false));

    expect(find.text('MOVILCONTROL // NEON DRIVE'), findsOneWidget);
    expect(find.text('Centro de control'), findsOneWidget);
    expect(find.text('Preview procesado'), findsOneWidget);
    expect(find.text('Estado del auto'), findsOneWidget);
    expect(find.text('Conectar'), findsAtLeastNWidgets(1));
  });
}

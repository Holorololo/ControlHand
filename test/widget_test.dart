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
    expect(find.text('Bluetooth y control'), findsOneWidget);
    expect(find.text('Backend en la computadora'), findsNothing);
    expect(find.text('Preview procesado'), findsNothing);
    expect(find.text('Host'), findsNothing);
    expect(find.text('Puerto'), findsNothing);
  });
}

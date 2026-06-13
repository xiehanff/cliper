import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_services.dart';
import '../helpers/widget_test_app.dart';

void main() {
  testWidgets('empty state shows localized empty text', (tester) async {
    final controller = createTestController();
    await tester.pumpWidget(buildTestableWidget(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('空'), findsOneWidget);

    controller.switchLanguage('en');
    await tester.pumpAndSettle();

    expect(find.text('Empty'), findsOneWidget);
  });
}

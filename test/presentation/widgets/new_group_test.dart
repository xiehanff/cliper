import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_services.dart';
import '../helpers/widget_test_app.dart';

void main() {
  testWidgets('creating a new group adds it to sidebar', (tester) async {
    final controller = createTestController();
    await tester.pumpWidget(buildTestableWidget(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('新建分组'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Work');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(controller.groups.length, 1);
    expect(controller.groups.first.name, 'Work');
    expect(find.text('Work'), findsOneWidget);
  });
}

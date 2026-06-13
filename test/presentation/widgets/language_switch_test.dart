import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_services.dart';
import '../helpers/widget_test_app.dart';

void main() {
  testWidgets('language switch toggles between zh and en', (tester) async {
    final controller = createTestController();
    await tester.pumpWidget(buildTestableWidget(controller: controller));
    await tester.pumpAndSettle();

    expect(controller.currentLanguage, 'zh');
    expect(find.byIcon(Icons.language_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.language_outlined));
    await tester.pumpAndSettle();

    expect(controller.currentLanguage, 'en');
    expect(find.text('Realtime History'), findsWidgets);

    await tester.tap(find.byIcon(Icons.language_outlined));
    await tester.pumpAndSettle();

    expect(controller.currentLanguage, 'zh');
    expect(find.byIcon(Icons.language_outlined), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_services.dart';
import '../helpers/widget_test_app.dart';

void main() {
  testWidgets('shortcut recorder toggles recording state text', (tester) async {
    final controller = createTestController();
    await tester.pumpWidget(buildTestableWidget(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('等待按键'), findsNothing);

    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();

    expect(find.text('等待按键'), findsOneWidget);
  });

  testWidgets('shortcut recorder captures control+a', (tester) async {
    final controller = createTestController();
    await tester.pumpWidget(buildTestableWidget(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(controller.currentShortcut, 'CommandOrControl+a');
    expect(find.text('等待按键'), findsNothing);
  });
}

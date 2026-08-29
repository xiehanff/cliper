import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_services.dart';
import '../helpers/widget_test_app.dart';

void main() {
  testWidgets('settings panel opens and closes', (tester) async {
    final controller = createTestController();
    await tester.pumpWidget(buildTestableWidget(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('设置'), findsNothing);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('设置'), findsOneWidget);

    // 浮窗已无关闭按钮,点击浮窗外部区域关闭
    await tester.tapAt(const Offset(20, 400));
    await tester.pumpAndSettle();

    expect(find.text('设置'), findsNothing);
  });

  testWidgets('settings panel toggles auto launch', (tester) async {
    final controller = createTestController();
    await tester.pumpWidget(buildTestableWidget(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(controller.autoLaunch, false);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(controller.autoLaunch, true);
  });
}

import 'package:cliper/presentation/widgets/sidebar/color_dot.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_services.dart';
import '../helpers/widget_test_app.dart';

void main() {
  testWidgets('color picker expands and collapses', (tester) async {
    final controller = createTestController();
    controller.createGroup('Work', '#4ECDC4');

    await tester.pumpWidget(buildTestableWidget(controller: controller));
    await tester.pumpAndSettle();

    expect(find.byType(ColorDot), findsOneWidget);

    await tester.tap(find.byType(ColorDot));
    await tester.pumpAndSettle();

    expect(find.byType(ColorDot), findsNWidgets(8));

    await tester.tapAt(const Offset(300, 300));
    await tester.pumpAndSettle();

    expect(find.byType(ColorDot), findsOneWidget);
  });

  testWidgets('color picker updates an existing group color', (tester) async {
    final controller = createTestController();
    controller.createGroup('Work', '#FF6B6B');

    await tester.pumpWidget(buildTestableWidget(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ColorDot).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ColorDot).last);
    await tester.pumpAndSettle();

    expect(controller.groups.first.color, '#9CA3AF');
  });
}

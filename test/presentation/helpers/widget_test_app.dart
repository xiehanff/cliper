import 'package:cliper/app/app.dart';
import 'package:cliper/application/controllers/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'fake_services.dart';

Widget buildTestableWidget({
  AppController? controller,
}) {
  return ChangeNotifierProvider<AppController>.value(
    value: controller ?? createTestController(),
    child: const CliperApp(),
  );
}
